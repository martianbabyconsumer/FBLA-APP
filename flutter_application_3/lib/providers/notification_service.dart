import 'dart:async';
import 'package:flutter/material.dart';

/// A lightweight in-app notification service for demo/testing purposes.
///
/// This does not use platform push or local notifications. Instead it
/// schedules timers and shows SnackBars via a provided
/// `GlobalKey<ScaffoldMessengerState>` so notifications appear even when
/// the current page/context is not directly available.
class NotificationService {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  NotificationService(this.scaffoldMessengerKey);

  final Map<String, Timer> _timers = {};

  /// Schedule a simple in-app notification to appear after [delay].
  /// Returns an ID that can be used to cancel it.
  String scheduleNotification({
    required String title,
    required String body,
    required Duration delay,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _timers[id] = Timer(delay, () {
      _showNotification(title: title, body: body);
      _timers.remove(id);
    });
    return id;
  }

  void _showNotification({required String title, required String body}) {
    // Use the scaffold messenger key to show a SnackBar from anywhere
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$title — $body'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Cancel a scheduled notification by ID.
  void cancelNotification(String id) {
    final t = _timers.remove(id);
    t?.cancel();
  }

  /// Cancel all scheduled notifications.
  void cancelAll() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  void dispose() {
    cancelAll();
  }
}
