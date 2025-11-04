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
    final userProvider = context.watch<UserProvider>();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? theme.colorScheme.primary
              : theme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha((0.06 * 255).round()),
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
                // Use the watched UserProvider above so this updates when the user
                // changes their profile image or username in settings.
                Builder(builder: (context) {
                  final userHandle = (userProvider.username != null && userProvider.username!.isNotEmpty)
                      ? '@${userProvider.username}'
                      : '@you';
                  if (!kIsWeb && post.handle == userHandle && userProvider.profileImagePath != null) {
                    return ClipOval(
                      child: Image.file(
                        File(userProvider.profileImagePath!),
                        key: ValueKey(userProvider.profileImagePath),
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
                }),
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
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withAlpha((0.65 * 255).round())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.handle,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withAlpha((0.7 * 255).round())),
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
                      child: post.imageUrl!.startsWith('http')
                          ? Image.network(
                              post.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (c, e, s) => Container(
                                color: theme.cardColor,
                                child: Center(
                                    child: Icon(Icons.broken_image,
                                        color: theme.colorScheme.onSurface
                                            .withAlpha((0.6 * 255).round()))),
                              ),
                            )
                          : Image.file(
                              File(post.imageUrl!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (c, e, s) => Container(
                                color: theme.cardColor,
                                child: Center(
                                    child: Icon(Icons.broken_image,
                                        color: theme.colorScheme.onSurface
                                            .withAlpha((0.6 * 255).round()))),
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
                          border: Border.all(
                              color: theme.colorScheme.secondary, width: 4),
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
                    color: post.liked
                        ? theme.colorScheme.primary
                        : (theme.brightness == Brightness.light
                            ? theme.colorScheme.onSurface
                                .withAlpha((0.7 * 255).round())
                            : theme.colorScheme.onSurface
                                .withAlpha((0.85 * 255).round())),
                  ),
                  splashRadius: 20,
                ),
                Text('${post.likes}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: onComments,
                  icon: Icon(
                    Icons.mode_comment_outlined,
                    color: theme.brightness == Brightness.light
                        ? theme.colorScheme.onSurface
                            .withAlpha((0.7 * 255).round())
                        : theme.colorScheme.onSurface
                            .withAlpha((0.85 * 255).round()),
                  ),
                ),
                Text('${post.comments.length}'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    final wasSaved = post.saved;
                    context.read<PostRepository>().toggleSave(post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(wasSaved ? 'Removed from saved' : 'Saved')),
                    );
                  },
                  icon: Icon(
                    post.saved ? Icons.bookmark : Icons.bookmark_border,
                    color: post.saved
                        ? theme.colorScheme.primary
                        : (theme.brightness == Brightness.light
                            ? theme.colorScheme.onSurface
                                .withAlpha((0.7 * 255).round())
                            : theme.colorScheme.onSurface
                                .withAlpha((0.85 * 255).round())),
                  ),
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
