import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../repository/post_repository.dart';
import '../providers/user_provider.dart';

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
    
    // Validate comment is not empty
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate minimum length (at least 1 non-space character already checked above)
    // Validate maximum length
    if (text.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment must be 500 characters or less'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final now = DateTime.now();
    final dateLabel = '${now.month}/${now.day}';
    final newComment = Comment(
      authorHandle: '@you',
      authorName: 'You',
      text: text,
      dateLabel: dateLabel,
      replies: []
    );

    setState(() {
      if (parentComment != null) {
        parentComment.replies.add(newComment);
      } else {
        _post.comments.add(newComment);
      }
      _replyingTo = null;
    });

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
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop && mounted) {
          Navigator.of(context).pop(_post);
        }
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
                  // Profile picture - show custom image only for user's own posts
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      // Only show custom profile picture for user's own posts (@you) and on mobile
                      if (!kIsWeb && _post.handle == '@you' && userProvider.profileImagePath != null) {
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
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    'FBLA',
                                    style: TextStyle(
                                      color: Colors.white,
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
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'FBLA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_post.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text(
                              _post.handle,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _post.dateLabel,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _post.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _post.body,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_post.imageUrl != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _post.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => Container(
                      height: 200,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Consumer<PostRepository>(
                builder: (context, repo, _) {
                  return Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          repo.toggleLike(_post.id);
                          final refreshed = repo.getPostById(_post.id);
                          if (refreshed != null) {
                            setState(() {
                              _post = refreshed;
                            });
                          }
                        },
                        icon: Icon(
                          _post.liked ? Icons.favorite : Icons.favorite_border,
                          color: _post.liked ? Colors.pink : null,
                        ),
                      ),
                      Text('${_post.likes}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.mode_comment_outlined),
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
                                leading: const Icon(Icons.person_outline),
                                title: Row(
                                  children: [
                                    Text(c.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text(
                                      c.authorHandle,
                                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      c.dateLabel,
                                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.text),
                                    const SizedBox(height: 4),
                                    TextButton(
                                      onPressed: () => _startReply(c),
                                      child: const Text('Reply', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                              if (c.replies.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 56),
                                  child: Column(
                                    children: c.replies.map((reply) => ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.subdirectory_arrow_right, size: 20),
                                      title: Row(
                                        children: [
                                          Text(
                                            reply.authorName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            reply.dateLabel,
                                            style: TextStyle(
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(reply.text, style: const TextStyle(fontSize: 13)),
                                    )).toList(),
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
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Replying to ${_replyingTo!.authorName}',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: _cancelReply,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
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
                          hintText: _replyingTo != null ? 'Write a reply...' : 'Write a comment...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          ),
                        ),
                        onSubmitted: (_) => _addComment(parentComment: _replyingTo),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _addComment(parentComment: _replyingTo),
                      icon: const Icon(Icons.send),
                    ),
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