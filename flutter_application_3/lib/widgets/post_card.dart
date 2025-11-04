import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../repository/post_repository.dart';
import '../providers/user_provider.dart';
import '../providers/user_info_service.dart';

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

class _PostCardState extends State<PostCard> {
  String? _displayName;
  String? _username;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userInfoService = context.read<UserInfoService>();
    final info = await userInfoService.getUserInfo(widget.post.userId);
    if (mounted) {
      setState(() {
        _displayName = info.displayName;
        _username = info.username;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final userInfoService = context.watch<UserInfoService>();
    
    // Use fetched names if available, otherwise fallback to stored values
    final displayName = _displayName ?? widget.post.displayName;
    final handle = _username ?? widget.post.handle;
    final isCurrentUser = userInfoService.isCurrentUser(widget.post.userId);

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
                  if (!kIsWeb && isCurrentUser && userProvider.profileImagePath != null) {
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
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Report', child: Text('Report')),
                    PopupMenuItem(value: 'Share', child: Text('Share')),
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
            const SizedBox(height: 12),
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
                IconButton(
                  onPressed: widget.onLike,
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
