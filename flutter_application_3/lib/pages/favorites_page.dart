import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/post_repository.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: Consumer<PostRepository>(
        builder: (context, repo, child) {
          final favs = repo.getFavorites();
          if (favs.isEmpty) {
            return const Center(child: Text('No favorites yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favs.length,
            itemBuilder: (context, i) {
              final p = favs[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Card(
                  child: ListTile(
                    title: Text(p.title),
                    subtitle: Text(p.displayName),
                    trailing: IconButton(
                      icon: Icon(
                          p.liked ? Icons.favorite : Icons.favorite_border,
                          color: p.liked
                              ? Theme.of(context).colorScheme.secondary
                              : null),
                      onPressed: () {
                        // toggle like via repo
                        repo.toggleLike(p.id);
                      },
                    ),
                    onTap: () async {
                      // Open a simple detail view that reads the post from the repository
                      final repo = context.read<PostRepository>();
                      final post = repo.getPostById(p.id);
                      if (post == null) return;

                      if (!context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ChangeNotifierProvider<PostRepository>.value(
                            value: repo,
                            child: Scaffold(
                              appBar: AppBar(title: const Text('Post')),
                              body: Builder(
                                builder: (context) {
                                  return Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(post.title,
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text(post.displayName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text(post.body),
                                          const SizedBox(height: 16),
                                          Consumer<PostRepository>(
                                            builder: (context, localRepo, _) {
                                              final updatedPost = localRepo
                                                      .getPostById(post.id) ??
                                                  post;
                                              return Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () =>
                                                        localRepo.toggleLike(
                                                            updatedPost.id),
                                                    icon: Icon(
                                                        updatedPost.liked
                                                            ? Icons.favorite
                                                            : Icons
                                                                .favorite_border,
                                                        color: updatedPost.liked
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .secondary
                                                            : null),
                                                  ),
                                                  Text('${updatedPost.likes}'),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
