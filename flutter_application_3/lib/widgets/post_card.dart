import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../repository/post_repository.dart';
import '../providers/user_provider.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComments,
    required this.onMenuSelected,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.light ? theme.colorScheme.primary : theme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar, names, date, and three-dot menu
            Row(
              children: [
                // Profile picture - show custom image only for user's own posts
                Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    // Only show custom profile picture for user's own posts (@you) and on mobile
                    if (!kIsWeb && post.handle == '@you' && userProvider.profileImagePath != null) {
                      return ClipOval(
                        child: Image.file(
                          File(userProvider.profileImagePath!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // If image fails to load, show FBLA logo
                            return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'FBLA',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                          },
                        ),
                      );
                    } else {
                      // Show FBLA logo for all other posts or on web
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'FBLA',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post.dateLabel,
                            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.handle,
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: onMenuSelected,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Report', child: Text('Report')),
                    PopupMenuItem(value: 'Share', child: Text('Share')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              post.body,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (post.imageUrl != null) ...[
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (c, e, s) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 36,
                      top: 36,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.secondary, width: 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  onPressed: onLike,
                    icon: Icon(
                    post.liked ? Icons.favorite : Icons.favorite_border,
                    color: post.liked ? theme.colorScheme.secondary : null,
                  ),
                ),
                Text('${post.likes}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: onComments,
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                Text('${post.comments.length}'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    final wasSaved = post.saved;
                    context.read<PostRepository>().toggleSave(post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(wasSaved ? 'Removed from saved' : 'Saved')),
                    );
                  },
                  icon: Icon(post.saved ? Icons.bookmark : Icons.bookmark_border),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}