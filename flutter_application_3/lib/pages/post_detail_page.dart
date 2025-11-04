import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../repository/post_repository.dart';

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
    final newComment = Comment(
      authorHandle: (up.username != null && up.username!.isNotEmpty) ? '@${up.username}' : '@you',
      authorName: up.displayName.isNotEmpty ? up.displayName : 'You',
      text: text,
      dateLabel: dateLabel,
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('FBLA',
                          style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
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
                                leading: const Icon(Icons.person_outline),
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
                                    TextButton(
                                        onPressed: () => _startReply(c),
                                        child: const Text('Reply',
                                            style: TextStyle(fontSize: 12))),
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
                                              leading: const Icon(
                                                  Icons
                                                      .subdirectory_arrow_right,
                                                  size: 20),
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
                                              subtitle: Text(reply.text,
                                                  style: const TextStyle(
                                                      fontSize: 13)),
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
