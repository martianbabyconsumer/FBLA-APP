import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/post_repository.dart';
import '../widgets/post_card.dart';
import '../pages/create_post_page.dart';
import '../pages/post_detail_page.dart';

class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  Future<void> _createNewPost(BuildContext context) async {
    final newPost = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    if (!context.mounted) return;

    if (newPost != null) {
      context.read<PostRepository>().addPost(newPost);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // New post button
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () => _createNewPost(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      'New Post',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: PostCard(
                        post: post,
                        onLike: () => repo.toggleLike(post.id),
                        onComments: () async {
                          final updated = await Navigator.push<Post>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailPage(post: post),
                            ),
                          );
                          if (updated != null) {
                            repo.updatePost(updated);
                          }
                        },
                        onMenuSelected: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$value on post ${post.id}')),
                          );
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