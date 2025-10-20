import 'package:flutter/material.dart';

void main() {
  runApp(const FBLAApp());
}

class FBLAApp extends StatelessWidget {
  const FBLAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FBLA APP',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Sans-serif',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(),
    );
  }
}

// Minimal Post model matching the screenshot fields.
class Post {
  Post({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.dateLabel,
    required this.title,
    required this.body,
    this.imageUrl,
    int? likes,
    bool? liked,
    List<Comment>? comments,
  })  : likes = likes ?? 0,
        liked = liked ?? false,
        comments = comments ?? <Comment>[];

  final String id;
  final String handle; // e.g. @skibidiwinner189
  final String displayName; // e.g. John Adams
  final String dateLabel; // e.g. Sep 11
  final String title; // bold title
  final String body; // multiline body text
  final String? imageUrl; // optional image

  int likes;
  bool liked;
  List<Comment> comments;

  Post copy() => Post(
        id: id,
        handle: handle,
        displayName: displayName,
        dateLabel: dateLabel,
        title: title,
        body: body,
        imageUrl: imageUrl,
        likes: likes,
        liked: liked,
        comments: List<Comment>.from(comments),
      );
}

class Comment {
  Comment({
    required this.authorHandle,
    required this.authorName,
    required this.text,
    required this.dateLabel,
  });

  final String authorHandle; // e.g. @skibidiwinner189
  final String authorName; // e.g. John Adams
  final String text;
  final String dateLabel; // e.g. 'Oct 20'
}

// Repository abstraction so the data layer can be swapped out for a real
// backend later. Implementations should call notifyListeners() when data
// changes so UI can update.
abstract class PostRepository extends ChangeNotifier {
  List<Post> getPosts();
  Post? getPostById(String id);
  void updatePost(Post updated);
  void toggleLike(String postId);
  void addComment(String postId, Comment comment);
}

// Simple in-memory repository useful for local testing and for wiring up a
// network-backed implementation later.
class InMemoryPostRepository extends PostRepository {
  final List<Post> _posts;

  InMemoryPostRepository()
      : _posts = [
          Post(
            id: '1',
            handle: '@skibidiwinner189',
            displayName: 'John Adams',
            dateLabel: 'Sep 11',
            title: 'My dog is pregnant',
            body:
                'I found out today that my dog is pregnant. We\'re excited and a little nervous. Any tips for first-time dog parents? Here\'s a photo from the vet appointment.',
            imageUrl:
                'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=60',
            likes: 12,
            comments: [
              Comment(authorHandle: '@fan1', authorName: 'A Fan', text: 'Congrats!', dateLabel: 'Sep 11'),
              Comment(authorHandle: '@friend2', authorName: 'Friend Two', text: 'So happy for you', dateLabel: 'Sep 11'),
            ],
          ),
          Post(
            id: '2',
            handle: '@skibidiwinner167',
            displayName: 'Samuel Adams',
            dateLabel: 'Jul 11',
            title: 'Big news',
            body:
                'Working on a new project that I think will help students prepare for competitions. More details soon!',
            imageUrl: null,
            likes: 2,
            comments: [],
          ),
        ];

  @override
  List<Post> getPosts() => List<Post>.unmodifiable(_posts.map((p) => p.copy()));

  @override
  Post? getPostById(String id) {
    try {
      return _posts.firstWhere((p) => p.id == id).copy();
    } catch (_) {
      return null;
    }
  }

  @override
  void updatePost(Post updated) {
    final idx = _posts.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _posts[idx] = updated.copy();
      notifyListeners();
    }
  }

  @override
  void toggleLike(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final p = _posts[idx];
    if (p.liked) {
      p.liked = false;
      p.likes = (p.likes - 1).clamp(0, 999999);
    } else {
      p.liked = true;
      p.likes++;
    }
    notifyListeners();
  }

  @override
  void addComment(String postId, Comment comment) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].comments.add(comment);
    notifyListeners();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PostRepository repository;
  late List<Post> posts;

  @override
  void initState() {
    super.initState();
    repository = InMemoryPostRepository();
    posts = repository.getPosts();
    repository.addListener(() {
      setState(() {
        posts = repository.getPosts();
      });
    });
  }

  // Toggle like on post index
  void _toggleLike(int index) {
    repository.toggleLike(posts[index].id);
  }

  // Open post detail to view/add comments
  Future<void> _openComments(int index) async {
    final postId = posts[index].id;
    final post = repository.getPostById(postId);
    if (post == null) return;
    final updated = await Navigator.of(context).push<Post>(
      MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
    );
    if (updated != null) {
      repository.updatePost(updated);
    }
  }

  void _onMenuSelected(String value, int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$value on post ${posts[index].id}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '[FBLA APP]',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 8),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final p = posts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: PostCard(
              post: p,
              onLike: () => _toggleLike(index),
              onComments: () => _openComments(index),
              onMenuSelected: (value) => _onMenuSelected(value, index),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 64,
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Icon(Icons.settings, color: Colors.white),
            Icon(Icons.chat_bubble_outline, color: Colors.white),
            Icon(Icons.home, color: Colors.white),
            Icon(Icons.folder_open, color: Colors.white),
            Icon(Icons.favorite_border, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                // Gray circular avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                   shape: BoxShape.circle,
                 ),
               ),
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
                           style: TextStyle(color: Colors.grey[600]),
                         ),
                       ],
                     ),
                     const SizedBox(height: 2),
                     Text(
                       post.handle,
                       style: TextStyle(color: Colors.grey[700]),
                     ),
                   ],
                 ),
               ),
               // three-dot popup menu
               PopupMenuButton<String>(
                 onSelected: onMenuSelected,
                 itemBuilder: (context) => const [
                   PopupMenuItem(value: 'Report', child: Text('Report')),
                   PopupMenuItem(value: 'Save', child: Text('Save')),
                   PopupMenuItem(value: 'Share', child: Text('Share')),
                 ],
               ),
              ],
            ),
            const SizedBox(height: 12),
            // Bold title
            Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // Body text
            Text(
              post.body,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Optional image with red circle overlay
            if (post.imageUrl != null) ...[
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                    // Red circular highlight (example: roughly where person is)
                    Positioned(
                      right: 36,
                      top: 36,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Bottom action row (icons with counts)
            Row(
              children: [
                // Like button with count and pink when liked
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    post.liked ? Icons.favorite : Icons.favorite_border,
                    color: post.liked ? Colors.pink : null,
                  ),
                ),
                Text('${post.likes}'),
                const SizedBox(width: 16),
                // Comments button with count
                IconButton(
                  onPressed: onComments,
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                Text('${post.comments.length}'),
                const Spacer(),
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

  void _addComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      final now = DateTime.now();
      final dateLabel = '${now.month}/${now.day}';
      // In this demo the commenter is always 'You'. Replace with auth in real app.
      _post.comments.add(Comment(authorHandle: '@you', authorName: 'You', text: text, dateLabel: dateLabel));
    });
    _controller.clear();
    // Scroll to the bottom to show the new comment.
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return the modified post when the user navigates back.
        Navigator.of(context).pop(_post);
        return false; // we already popped
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop(_post);
            },
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
                Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_post.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_post.title),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                        return ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Row(
                            children: [
                              Text(c.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text(c.authorHandle, style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(width: 8),
                              Text(c.dateLabel, style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                          subtitle: Text(c.text),
                        );
                      },
                    ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Write a comment...'),
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                IconButton(onPressed: _addComment, icon: const Icon(Icons.send))
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
