import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/post_repository.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_service.dart';
import '../providers/user_provider.dart';
import '../widgets/post_card.dart';
import '../pages/create_post_page.dart';
import '../pages/post_detail_page.dart';
import '../utils/page_transitions.dart';

class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  Future<void> _createNewPost(BuildContext context) async {
    final newPost = await Navigator.push<Post>(
      context,
      SlideUpPageRoute(page: const CreatePostPage()),
    );

    if (!context.mounted) return;

    if (newPost != null) {
      context.read<PostRepository>().addPost(newPost);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // New post button
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () => _createNewPost(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'New Post',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withAlpha((0.7 * 255).round()),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Posts list
          Expanded(
            child: Consumer<PostRepository>(
              builder: (context, repo, _) {
                final posts = repo.getPosts();
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 8),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: PostCard(
                        post: post,
                        onLike: () {
                          final settings = context.read<AppSettingsProvider>();
                          final authService = context.read<AuthService>();
                          final userProvider = context.read<UserProvider>();
                          repo.toggleLike(
                            post.id, 
                            autoSave: settings.autoSaveOnLike,
                            currentUserId: authService.user?.uid,
                            currentUserName: userProvider.displayName.isNotEmpty ? userProvider.displayName : 'You',
                            currentUserHandle: (userProvider.username != null && userProvider.username!.isNotEmpty) ? '@${userProvider.username}' : '@you',
                          );
                        },
                        onComments: () async {
                          final updated = await Navigator.push<Post>(
                            context,
                            SlideUpPageRoute(page: PostDetailPage(post: post)),
                          );
                          if (updated != null) {
                            repo.updatePost(updated);
                          }
                        },
                        onMenuSelected: (value) async {
                          if (value == 'Delete') {
                            // Show confirmation dialog
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Post'),
                                content: const Text('Are you sure you want to delete this post?'),
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
                            
                            if (confirm == true && context.mounted) {
                              final success = repo.deletePost(post.id);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Post deleted'),
                                    backgroundColor: Colors.grey[800],
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          } else if (value == 'Report') {
                            // Show report dialog
                            final reasons = [
                              'Spam or misleading',
                              'Harassment or bullying',
                              'Inappropriate content',
                              'False information',
                              'Other',
                            ];
                            String? selectedReason;
                            final reasonController = TextEditingController();
                            
                            final reported = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => StatefulBuilder(
                                builder: (context, setState) => AlertDialog(
                                  title: const Text('Report Post'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Why are you reporting this post?'),
                                        const SizedBox(height: 16),
                                        ...reasons.map((reason) => RadioListTile<String>(
                                          title: Text(reason),
                                          value: reason,
                                          groupValue: selectedReason,
                                          onChanged: (value) {
                                            setState(() => selectedReason = value);
                                          },
                                        )).toList(),
                                        if (selectedReason == 'Other') ...[
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: reasonController,
                                            decoration: const InputDecoration(
                                              labelText: 'Please specify',
                                              border: OutlineInputBorder(),
                                            ),
                                            maxLines: 3,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: selectedReason != null
                                        ? () => Navigator.pop(dialogContext, true)
                                        : null,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                      child: const Text('Report'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            
                            if (reported == true && context.mounted) {
                              final authService = context.read<AuthService>();
                              final userId = authService.user?.uid ?? 'guest';
                              final reason = selectedReason == 'Other' 
                                ? reasonController.text.trim()
                                : selectedReason!;
                              
                              final success = await repo.reportPost(post.id, reason, userId);
                              
                              if (success && context.mounted) {
                                // Show success message with hide option
                                final hidePost = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Report Submitted'),
                                    content: const Text(
                                      'Thank you for reporting this post. Our team will review it shortly.\n\nWould you like to hide this post from your feed?'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Yes, Hide Post'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (hidePost == true && context.mounted) {
                                  repo.hidePost(post.id, userId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Post hidden'),
                                      backgroundColor: Colors.grey[800],
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$value on post ${post.id}'),
                                backgroundColor: Colors.grey[800],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
