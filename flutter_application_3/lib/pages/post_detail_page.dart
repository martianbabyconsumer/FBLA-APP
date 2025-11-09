import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_service.dart';
import '../providers/app_settings_provider.dart';
import '../repository/post_repository.dart';
import 'member_profile_page.dart';

// Post detail page to view/add comments. Returns updated Post when popping.
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post});

  final Post post;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late Post _post;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _post = widget.post.copy();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addComment({Comment? parentComment}) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final dateLabel = '${now.month}/${now.day}';
    final up = context.read<UserProvider>();
    final authService = context.read<AuthService>();
    final newComment = Comment(
      authorHandle: (up.username != null && up.username!.isNotEmpty) ? '@${up.username}' : '@you',
      authorName: up.displayName.isNotEmpty ? up.displayName : 'You',
      text: text,
      dateLabel: dateLabel,
      userId: authService.user?.uid, // Add user ID to track comment ownership
      profileImagePath: up.profileImagePath, // Store user's profile picture
      replies: [],
    );

    setState(() {
      if (parentComment != null) {
        parentComment.replies.add(newComment);
      } else {
        _post.comments.add(newComment);
      }
      _replyingTo = null;
    });
    
    // Update the repository to persist the comment and create notification
    final repo = context.read<PostRepository>();
    if (parentComment == null) {
      // Only create notifications for top-level comments, not replies
      repo.addComment(_post.id, newComment, currentUserId: authService.user?.uid);
    }
    repo.updatePost(_post);

    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 72,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
    });
    _controller.clear();
    FocusScope.of(context).requestFocus(FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
    _controller.clear();
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Remove from local state first for immediate UI update
      setState(() {
        _removeCommentFromList(_post.comments, comment);
      });
      
      // Then update the repository
      final repo = context.read<PostRepository>();
      repo.deleteComment(_post.id, comment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    }
  }

  bool _removeCommentFromList(List<Comment> comments, Comment target) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == target.id) {
        comments.removeAt(i);
        return true;
      }
      if (_removeCommentFromList(comments[i].replies, target)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_post);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Post'),
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(_post),
              icon: const Icon(Icons.check),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Profile picture - show stored profile image from post
                  Builder(builder: (context) {
                    final hasProfileImage = _post.profileImagePath != null && _post.profileImagePath!.isNotEmpty;
                    final isBlobUrl = hasProfileImage && _post.profileImagePath!.startsWith('blob:');
                    final useNetworkImage = kIsWeb || isBlobUrl;

                    if (hasProfileImage && useNetworkImage) {
                      // Use Image.network for web blob URLs
                      return ClipOval(
                        child: Image.network(
                          _post.profileImagePath!,
                          key: ValueKey('${_post.profileImagePath}_${_post.userId}'),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          gaplessPlayback: false,
                          errorBuilder: (context, error, stackTrace) {
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
                    } else if (hasProfileImage) {
                      // Use Image.file for mobile file paths
                      return ClipOval(
                        child: Image.file(
                          File(_post.profileImagePath!),
                          key: ValueKey('${_post.profileImagePath}_${_post.userId}'),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          gaplessPlayback: false,
                          errorBuilder: (context, error, stackTrace) {
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_post.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text(_post.handle,
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha((0.65 * 255).round()),
                                    fontSize: 14)),
                            const SizedBox(width: 8),
                            Text(_post.dateLabel,
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha((0.65 * 255).round()),
                                    fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_post.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_post.body, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              if (_post.imageUrl != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _post.imageUrl!.startsWith('http')
                      ? Image.network(
                          _post.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (c, e, s) => Container(
                            height: 200,
                            color: theme.cardColor,
                            child: Center(
                                child: Icon(Icons.broken_image,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha((0.6 * 255).round()))),
                          ),
                        )
                      : Image.file(
                          File(_post.imageUrl!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (c, e, s) => Container(
                            height: 200,
                            color: theme.cardColor,
                            child: Center(
                                child: Icon(Icons.broken_image,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha((0.6 * 255).round()))),
                          ),
                        ),
                ),
              ],
              const SizedBox(height: 16),
              Consumer2<PostRepository, AppSettingsProvider>(
                builder: (context, repo, settings, _) {
                  final authService = context.read<AuthService>();
                  final userProvider = context.read<UserProvider>();
                  return Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          repo.toggleLike(
                            _post.id, 
                            autoSave: settings.autoSaveOnLike,
                            currentUserId: authService.user?.uid,
                            currentUserName: userProvider.displayName.isNotEmpty ? userProvider.displayName : 'You',
                            currentUserHandle: (userProvider.username != null && userProvider.username!.isNotEmpty) ? '@${userProvider.username}' : '@you',
                          );
                          final refreshed = repo.getPostById(_post.id);
                          if (refreshed != null) {
                            setState(() {
                              _post = refreshed;
                            });
                          }
                        },
                        icon: Icon(
                          _post.liked ? Icons.favorite : Icons.favorite_border,
                          color: _post.liked
                              ? theme.colorScheme.primary
                              : (theme.brightness == Brightness.light
                                  ? theme.colorScheme.onSurface
                                      .withAlpha((0.7 * 255).round())
                                  : theme.colorScheme.onSurface
                                      .withAlpha((0.85 * 255).round())),
                        ),
                      ),
                      Text('${_post.likes}'),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.mode_comment_outlined,
                        color: theme.brightness == Brightness.light
                            ? theme.colorScheme.onSurface
                                .withAlpha((0.7 * 255).round())
                            : theme.colorScheme.onSurface
                                .withAlpha((0.85 * 255).round()),
                      ),
                      const SizedBox(width: 8),
                      Text('${_post.comments.length}'),
                    ],
                  );
                },
              ),
              const Divider(),
              Expanded(
                child: _post.comments.isEmpty
                    ? const Center(child: Text('No comments yet'))
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: _post.comments.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final c = _post.comments[i];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: Builder(builder: (context) {
                                  final profileImagePath = c.profileImagePath;
                                  final isWebBlob = kIsWeb || (profileImagePath != null && profileImagePath.startsWith('blob:'));
                                  final authService = context.read<AuthService>();
                                  final isOwnComment = c.userId == authService.user?.uid;
                                  
                                  final profileWidget = profileImagePath != null && profileImagePath.isNotEmpty
                                    ? ClipOval(
                                        child: isWebBlob
                                          ? Image.network(
                                              profileImagePath,
                                              key: ValueKey('${profileImagePath}_${c.userId}'),
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              gaplessPlayback: false,
                                              errorBuilder: (context, error, stackTrace) {
                                                return ClipOval(
                                                  child: Image.asset(
                                                    'assets/images/feffe.webp',
                                                    width: 40,
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: theme.colorScheme.surfaceContainerHighest,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          Icons.person,
                                                          size: 25,
                                                          color: theme.colorScheme.onSurfaceVariant,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            )
                                          : Image.file(
                                              File(profileImagePath),
                                              key: ValueKey('${profileImagePath}_${c.userId}'),
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              gaplessPlayback: false,
                                              errorBuilder: (context, error, stackTrace) {
                                                return ClipOval(
                                                  child: Image.asset(
                                                    'assets/images/feffe.webp',
                                                    width: 40,
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: theme.colorScheme.surfaceContainerHighest,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          Icons.person,
                                                          size: 25,
                                                          color: theme.colorScheme.onSurfaceVariant,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                      )
                                    : ClipOval(
                                        child: Image.asset(
                                          'assets/images/feffe.webp',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                size: 25,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            );
                                          },
                                        ),
                                      );

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MemberProfilePage(
                                            userId: c.userId ?? '',
                                            isOwnProfile: isOwnComment,
                                          ),
                                        ),
                                      );
                                    },
                                    child: profileWidget,
                                  );
                                }),
                                title: Row(
                                  children: [
                                    Text(c.authorName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text(c.authorHandle,
                                        style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withAlpha(
                                                    (0.65 * 255).round()))),
                                    const SizedBox(width: 8),
                                    Text(c.dateLabel,
                                        style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withAlpha(
                                                    (0.65 * 255).round()))),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.text),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        TextButton(
                                            onPressed: () => _startReply(c),
                                            child: const Text('Reply',
                                                style: TextStyle(fontSize: 12))),
                                        Consumer<AuthService>(
                                          builder: (context, authService, _) {
                                            if (authService.user?.uid == c.userId) {
                                              return TextButton(
                                                onPressed: () => _deleteComment(c),
                                                child: Text('Delete',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: theme.colorScheme.error,
                                                    )),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (c.replies.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 56),
                                  child: Column(
                                    children: c.replies
                                        .map((reply) => ListTile(
                                              dense: true,
                                              leading: Builder(builder: (context) {
                                                final profileImagePath = reply.profileImagePath;
                                                final isWebBlob = kIsWeb || (profileImagePath != null && profileImagePath.startsWith('blob:'));
                                                final authService = context.read<AuthService>();
                                                final isOwnReply = reply.userId == authService.user?.uid;
                                                
                                                final replyProfileWidget = profileImagePath != null && profileImagePath.isNotEmpty
                                                  ? ClipOval(
                                                      child: isWebBlob
                                                        ? Image.network(
                                                            profileImagePath,
                                                            key: ValueKey('${profileImagePath}_${reply.userId}'),
                                                            width: 32,
                                                            height: 32,
                                                            fit: BoxFit.cover,
                                                            gaplessPlayback: false,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return ClipOval(
                                                                child: Image.asset(
                                                                  'assets/images/feffe.webp',
                                                                  width: 32,
                                                                  height: 32,
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (context, error, stackTrace) {
                                                                    return Container(
                                                                      width: 32,
                                                                      height: 32,
                                                                      decoration: BoxDecoration(
                                                                        color: theme.colorScheme.surfaceContainerHighest,
                                                                        shape: BoxShape.circle,
                                                                      ),
                                                                      child: Icon(
                                                                        Icons.person,
                                                                        size: 20,
                                                                        color: theme.colorScheme.onSurfaceVariant,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              );
                                                            },
                                                          )
                                                        : Image.file(
                                                            File(profileImagePath),
                                                            key: ValueKey('${profileImagePath}_${reply.userId}'),
                                                            width: 32,
                                                            height: 32,
                                                            fit: BoxFit.cover,
                                                            gaplessPlayback: false,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return ClipOval(
                                                                child: Image.asset(
                                                                  'assets/images/feffe.webp',
                                                                  width: 32,
                                                                  height: 32,
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (context, error, stackTrace) {
                                                                    return Container(
                                                                      width: 32,
                                                                      height: 32,
                                                                      decoration: BoxDecoration(
                                                                        color: theme.colorScheme.surfaceContainerHighest,
                                                                        shape: BoxShape.circle,
                                                                      ),
                                                                      child: Icon(
                                                                        Icons.person,
                                                                        size: 20,
                                                                        color: theme.colorScheme.onSurfaceVariant,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                    )
                                                  : ClipOval(
                                                      child: Image.asset(
                                                        'assets/images/feffe.webp',
                                                        width: 32,
                                                        height: 32,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            width: 32,
                                                            height: 32,
                                                            decoration: BoxDecoration(
                                                              color: theme.colorScheme.surfaceContainerHighest,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: Icon(
                                                              Icons.person,
                                                              size: 20,
                                                              color: theme.colorScheme.onSurfaceVariant,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );

                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => MemberProfilePage(
                                                          userId: reply.userId ?? '',
                                                          isOwnProfile: isOwnReply,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: replyProfileWidget,
                                                );
                                              }),
                                              title: Row(
                                                children: [
                                                  Text(reply.authorName,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13)),
                                                  const SizedBox(width: 8),
                                                  Text(reply.dateLabel,
                                                      style: TextStyle(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withAlpha(
                                                                  (0.65 * 255)
                                                                      .round()),
                                                          fontSize: 12)),
                                                ],
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(reply.text,
                                                      style: const TextStyle(
                                                          fontSize: 13)),
                                                  Consumer<AuthService>(
                                                    builder: (context, authService, _) {
                                                      if (authService.user?.uid == reply.userId) {
                                                        return TextButton(
                                                          onPressed: () => _deleteComment(reply),
                                                          style: TextButton.styleFrom(
                                                            padding: EdgeInsets.zero,
                                                            minimumSize: const Size(0, 0),
                                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                          ),
                                                          child: Text('Delete',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: theme.colorScheme.error,
                                                              )),
                                                        );
                                                      }
                                                      return const SizedBox.shrink();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
              const Divider(),
              if (_replyingTo != null)
                Container(
                  color: theme.cardColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('Replying to ${_replyingTo!.authorName}',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha((0.65 * 255).round()),
                                  fontSize: 12))),
                      IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: _cancelReply,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints()),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: _replyingTo != null
                              ? 'Write a reply...'
                              : 'Write a comment...',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide:
                                  BorderSide(color: theme.dividerColor)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide:
                                  BorderSide(color: theme.dividerColor)),
                        ),
                        onSubmitted: (_) =>
                            _addComment(parentComment: _replyingTo),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                        onPressed: () =>
                            _addComment(parentComment: _replyingTo),
                        icon: const Icon(Icons.send)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
