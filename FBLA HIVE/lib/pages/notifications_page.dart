import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/notification_repository.dart';
import '../repository/post_repository.dart';
import '../providers/auth_service.dart';
import '../pages/post_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void dispose() {
    // Clear all notifications when leaving the page
    final authService = context.read<AuthService>();
    final userId = authService.user?.uid;
    if (userId != null) {
      final notificationRepo = context.read<NotificationRepository>();
      notificationRepo.clearAllNotifications(userId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final userId = authService.user?.uid;
    
    print('DEBUG NotificationsPage: Building with userId: $userId');
    
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: const Center(
          child: Text('Please sign in to view notifications'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationRepository>(
            builder: (context, notificationRepo, _) {
              final notifications = notificationRepo.getNotifications(userId);
              final hasNotifications = notifications.isNotEmpty;
              
              return TextButton.icon(
                onPressed: hasNotifications ? () {
                  notificationRepo.clearAllNotifications(userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications cleared'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } : null,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: hasNotifications 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.4),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<NotificationRepository, PostRepository>(
        builder: (context, notificationRepo, postRepo, _) {
          final notifications = notificationRepo.getNotifications(userId);
          final likeNotifications = notifications.where((n) => n.type == NotificationType.like).toList();
          final commentNotifications = notifications.where((n) => n.type == NotificationType.comment).toList();
          
          print('DEBUG NotificationsPage: ${notifications.length} total notifications');
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Likes Section  
              const Text(
                'Likes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (likeNotifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No likes yet', style: TextStyle(color: Colors.grey)),
                )
              else
                ...likeNotifications.map((notification) {
                  final post = postRepo.getPostById(notification.postId);
                  final theme = Theme.of(context);
                  return ListTile(
                    leading: Icon(Icons.favorite, color: theme.colorScheme.primary, size: 32),
                    title: Text('${notification.actorName} liked your post "${notification.postTitle}"'),
                    subtitle: Text(notification.actorHandle.toUpperCase()),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      if (post != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PostDetailPage(post: post),
                          ),
                        );
                      }
                    },
                  );
                }),
              
              const SizedBox(height: 24),
              
              // Comments Section
              const Text(
                'Comments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (commentNotifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No comments yet', style: TextStyle(color: Colors.grey)),
                )
              else
                ...commentNotifications.map((notification) {
                  final post = postRepo.getPostById(notification.postId);
                  final theme = Theme.of(context);
                  return ListTile(
                    leading: Icon(Icons.comment, color: theme.colorScheme.primary, size: 32),
                    title: Text('${notification.actorName} commented on your post "${notification.postTitle}"'),
                    subtitle: Text(notification.actorHandle.toUpperCase()),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      if (post != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PostDetailPage(post: post),
                          ),
                        );
                      }
                    },
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
