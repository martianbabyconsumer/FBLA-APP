import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../repository/post_repository.dart';
import '../providers/user_info_service.dart';
import 'poll_widget.dart';

class PostCard extends StatefulWidget {
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
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _onLikeTapped() {
    widget.onLike();
    if (widget.post.liked) {
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userInfoService = context.read<UserInfoService>();
    
    // Use post's stored display name and handle directly
    final displayName = widget.post.displayName;
    final handle = widget.post.handle;
    final isOwnPost = userInfoService.isCurrentUser(widget.post.userId);

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
                // Profile picture - show stored profile image from post
                // This ensures profile pictures stay consistent regardless of theme
                // and update across all past posts when user changes their picture
                Builder(builder: (context) {
                  if (!kIsWeb && widget.post.profileImagePath != null && widget.post.profileImagePath!.isNotEmpty) {
                    return ClipOval(
                      child: Image.file(
                        File(widget.post.profileImagePath!),
                        key: ValueKey(widget.post.profileImagePath), // Use profileImagePath as key to force rebuild
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // If image fails to load, show default avatar
                          return ClipOval(
                            child: Image.asset(
                              'assets/images/feffe.webp',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 30,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    // Show default avatar for users without profile pictures
                    return ClipOval(
                      child: Image.asset(
                        'assets/images/feffe.webp',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
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
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.post.dateLabel,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withAlpha((0.65 * 255).round())),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        handle,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withAlpha((0.7 * 255).round())),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: widget.onMenuSelected,
                  itemBuilder: (context) => [
                    if (isOwnPost)
                      const PopupMenuItem(value: 'Delete', child: Text('Delete')),
                    const PopupMenuItem(value: 'Report', child: Text('Report')),
                    const PopupMenuItem(value: 'Share', child: Text('Share')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.post.body,
              style: const TextStyle(fontSize: 14),
            ),
            // Tags
            if (widget.post.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.post.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            // Poll
            if (widget.post.poll != null) ...[
              PollWidget(poll: widget.post.poll!, postId: widget.post.id),
              const SizedBox(height: 12),
            ],
            if (widget.post.imageUrl != null) ...[
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.post.imageUrl!.startsWith('http')
                          ? Image.network(
                              widget.post.imageUrl!,
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
                              File(widget.post.imageUrl!),
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
                ScaleTransition(
                  scale: _likeScale,
                  child: IconButton(
                    onPressed: _onLikeTapped,
                    icon: Icon(
                      widget.post.liked ? Icons.favorite : Icons.favorite_border,
                      color: widget.post.liked
                          ? theme.colorScheme.primary
                          : (theme.brightness == Brightness.light
                              ? theme.colorScheme.onSurface
                                  .withAlpha((0.7 * 255).round())
                              : theme.colorScheme.onSurface
                                  .withAlpha((0.85 * 255).round())),
                    ),
                    splashRadius: 20,
                  ),
                ),
                Text('${widget.post.likes}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: widget.onComments,
                  icon: Icon(
                    Icons.mode_comment_outlined,
                    color: theme.brightness == Brightness.light
                        ? theme.colorScheme.onSurface
                            .withAlpha((0.7 * 255).round())
                        : theme.colorScheme.onSurface
                            .withAlpha((0.85 * 255).round()),
                  ),
                ),
                Text('${widget.post.comments.length}'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    final wasSaved = widget.post.saved;
                    context.read<PostRepository>().toggleSave(widget.post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(wasSaved ? 'Removed from saved' : 'Saved')),
                    );
                  },
                  icon: Icon(
                    widget.post.saved ? Icons.bookmark : Icons.bookmark_border,
                    color: widget.post.saved
                        ? theme.colorScheme.primary
                        : (theme.brightness == Brightness.light
                            ? theme.colorScheme.onSurface
                                .withAlpha((0.7 * 255).round())
                            : theme.colorScheme.onSurface
                                .withAlpha((0.85 * 255).round())),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
