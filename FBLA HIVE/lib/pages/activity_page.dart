import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../repository/post_repository.dart';
import 'post_detail_page.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: Consumer<PostRepository>(builder: (context, repo, child) {
        final posts = repo.getPosts();
        // Use a watched UserProvider so the activity page updates when the
        // username changes in settings.
        final up = context.watch<UserProvider>();
        final String userHandle = (up.username != null && up.username!.isNotEmpty)
            ? '@${up.username}'
            : '@you';

    // Build sections separately
        final List<Post> liked = repo.getFavorites();
        final List<Post> saved = repo.getSavedPosts();
    final List<Post> yourPosts =
      posts.where((p) => p.handle == userHandle).toList();

        final List<Widget> commentTiles = [];
        final List<Widget> replyTiles = [];
        for (final p in posts) {
          for (final c in p.comments) {
            if (c.authorHandle == userHandle) {
              commentTiles.add(ListTile(
                leading: const Icon(Icons.comment),
                title: Text('You commented on "${p.title}"'),
                subtitle: Text(c.text),
                onTap: () {
                  final repo = context.read<PostRepository>();
                  final post = repo.getPostById(p.id);
                  if (post != null)
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PostDetailPage(post: post)));
                },
              ));
            }
            for (final r in c.replies) {
              if (r.authorHandle == userHandle) {
                replyTiles.add(ListTile(
                  leading: const Icon(Icons.reply),
                  title: Text('You replied to ${c.authorName} on "${p.title}"'),
                  subtitle: Text(r.text),
                  onTap: () {
                    final repo = context.read<PostRepository>();
                    final post = repo.getPostById(p.id);
                    if (post != null)
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PostDetailPage(post: post)));
                  },
                ));
              }
            }
          }
        }

        Widget section(String title, List<Widget> items) {
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
              ...items,
              const Divider(),
            ],
          );
        }

        final hasAny = liked.isNotEmpty || saved.isNotEmpty ||
            yourPosts.isNotEmpty || replyTiles.isNotEmpty || commentTiles.isNotEmpty;

        if (!hasAny) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No activity yet. When you like, comment, or post, activity will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(0),
          children: [
            section(
                'Your Posts',
                yourPosts
                    .map((p) => ListTile(
                          leading: const Icon(Icons.upload_file),
                          title: Text('You posted "${p.title}"'),
                          subtitle: Text(p.displayName),
                          onTap: () {
                            final post = repo.getPostById(p.id);
                            if (post != null)
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => PostDetailPage(post: post)));
                          },
                        ))
                    .toList()),
            section(
                'Likes',
                liked
                  .map((p) => ListTile(
                      leading: Icon(Icons.favorite,
                        color: Theme.of(context).colorScheme.primary),
                      title: Text('You liked "${p.title}"'),
                      subtitle: Text(p.displayName),
                          onTap: () {
                            final post = repo.getPostById(p.id);
                            if (post != null)
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => PostDetailPage(post: post)));
                          },
                        ))
                    .toList()),
            section('Replies', replyTiles),
            section('Comments', commentTiles),
            section(
                'Saves',
                saved
            .map((p) => ListTile(
                  leading: Icon(Icons.bookmark,
                    color: Theme.of(context).colorScheme.primary),
                  title: Text('You saved "${p.title}"'),
                  subtitle: Text(p.displayName),
                          onTap: () {
                            final post = repo.getPostById(p.id);
                            if (post != null)
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => PostDetailPage(post: post)));
                          },
                        ))
                    .toList()),
          ],
        );
      }),
    );
  }
}
