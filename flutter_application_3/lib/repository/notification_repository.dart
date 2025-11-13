import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const String _notificationsKey = 'app_notifications';

enum NotificationType {
  like,
  comment,
  reply,
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.postId,
    required this.postTitle,
    required this.actorName,
    required this.actorHandle,
    required this.timestamp,
    this.commentText,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String postId;
  final String postTitle;
  final String actorName; // Person who liked/commented
  final String actorHandle;
  final DateTime timestamp;
  final String? commentText; // For comment notifications
  bool isRead;

  String get message {
    switch (type) {
      case NotificationType.like:
        return '$actorName liked your post';
      case NotificationType.comment:
        return '$actorName commented on your post';
      case NotificationType.reply:
        return '$actorName replied to your comment';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'postId': postId,
    'postTitle': postTitle,
    'actorName': actorName,
    'actorHandle': actorHandle,
    'timestamp': timestamp.toIso8601String(),
    'commentText': commentText,
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    type: NotificationType.values[json['type'] as int],
    postId: json['postId'] as String,
    postTitle: json['postTitle'] as String,
    actorName: json['actorName'] as String,
    actorHandle: json['actorHandle'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    commentText: json['commentText'] as String?,
    isRead: json['isRead'] as bool? ?? false,
  );

  AppNotification copy() => AppNotification(
    id: id,
    type: type,
    postId: postId,
    postTitle: postTitle,
    actorName: actorName,
    actorHandle: actorHandle,
    timestamp: timestamp,
    commentText: commentText,
    isRead: isRead,
  );
}

abstract class NotificationRepository extends ChangeNotifier {
  List<AppNotification> getNotifications(String userId);
  int getUnreadCount(String userId);
  Future<void> addNotification(AppNotification notification, String userId);
  Future<void> markAsRead(String notificationId, String userId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notificationId, String userId);
  Future<void> clearAllNotifications(String userId);
  Future<void> initialize();
}

class InMemoryNotificationRepository extends NotificationRepository {
  final Map<String, List<AppNotification>> _notificationsByUser = {};

  @override
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_notificationsKey);
      if (notificationsJson != null) {
        final Map<String, dynamic> decoded = json.decode(notificationsJson);
        decoded.forEach((userId, notificationsList) {
          _notificationsByUser[userId] = (notificationsList as List)
              .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
              .toList();
        });
      }
      notifyListeners();
    } catch (_) {
      // If loading fails, start with empty notifications
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toEncode = {};
      _notificationsByUser.forEach((userId, notifications) {
        toEncode[userId] = notifications.map((n) => n.toJson()).toList();
      });
      await prefs.setString(_notificationsKey, json.encode(toEncode));
    } catch (_) {
      // Silently fail
    }
  }

  @override
  List<AppNotification> getNotifications(String userId) {
    final notifications = _notificationsByUser[userId] ?? [];
    print('DEBUG NotificationRepo: Getting notifications for user $userId - found ${notifications.length}');
    // Sort by timestamp, newest first
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(notifications.map((n) => n.copy()));
  }

  @override
  int getUnreadCount(String userId) {
    final notifications = _notificationsByUser[userId] ?? [];
    return notifications.where((n) => !n.isRead).length;
  }

  @override
  Future<void> addNotification(AppNotification notification, String userId) async {
    print('DEBUG NotificationRepo: Adding notification for user $userId: ${notification.message}');
    if (!_notificationsByUser.containsKey(userId)) {
      _notificationsByUser[userId] = [];
    }
    
    // Check for duplicate notifications (same actor, same post, same type within last 5 minutes)
    final existingNotifications = _notificationsByUser[userId]!;
    final recentDuplicate = existingNotifications.where((n) {
      final isRecent = DateTime.now().difference(n.timestamp).inMinutes < 5;
      final isSameType = n.type == notification.type;
      final isSamePost = n.postId == notification.postId;
      final isSameActor = n.actorName == notification.actorName;
      return isRecent && isSameType && isSamePost && isSameActor;
    }).isNotEmpty;
    
    if (recentDuplicate) {
      print('DEBUG NotificationRepo: Skipping duplicate notification from ${notification.actorName}');
      return;
    }
    
    _notificationsByUser[userId]!.insert(0, notification);
    
    // Keep only last 100 notifications per user
    if (_notificationsByUser[userId]!.length > 100) {
      _notificationsByUser[userId] = _notificationsByUser[userId]!.sublist(0, 100);
    }
    
    print('DEBUG NotificationRepo: User $userId now has ${_notificationsByUser[userId]!.length} notifications');
    await _persist();
    notifyListeners();
    print('DEBUG NotificationRepo: Notification persisted and listeners notified');
  }

  @override
  Future<void> markAsRead(String notificationId, String userId) async {
    final notifications = _notificationsByUser[userId];
    if (notifications == null) return;
    
    final idx = notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      notifications[idx].isRead = true;
      await _persist();
      notifyListeners();
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final notifications = _notificationsByUser[userId];
    if (notifications == null) return;
    
    for (var notification in notifications) {
      notification.isRead = true;
    }
    await _persist();
    notifyListeners();
  }

  @override
  Future<void> deleteNotification(String notificationId, String userId) async {
    final notifications = _notificationsByUser[userId];
    if (notifications == null) return;
    
    notifications.removeWhere((n) => n.id == notificationId);
    await _persist();
    notifyListeners();
  }

  @override
  Future<void> clearAllNotifications(String userId) async {
    _notificationsByUser[userId]?.clear();
    await _persist();
    notifyListeners();
  }
  
  /// Clear notifications from bot accounts that may be stale from previous sessions
  /// This prevents phantom notifications when bot likes are reset on app restart
  Future<void> clearBotNotifications() async {
    // Remove all notifications from bot actors across all users
    _notificationsByUser.forEach((userId, notifications) {
      notifications.removeWhere((notification) {
        // Check if the notification is a like from a bot
        return notification.type == NotificationType.like && 
               (notification.actorHandle.contains('bot_') || 
                notification.actorHandle.startsWith('@fbla_') ||
                notification.actorHandle.startsWith('@sfhs_') ||
                notification.actorHandle.startsWith('@austin_'));
      });
    });
    
    print('DEBUG: Cleared stale bot notifications');
    await _persist();
    notifyListeners();
  }
}
