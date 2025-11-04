
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/user_provider.dart';
import 'providers/auth_service.dart';
import 'repository/post_repository.dart';
import 'widgets/app_scaffold.dart';
import 'pages/settings_page.dart';
import 'pages/chapter_page.dart';
import 'pages/calendar_page.dart';
import 'pages/activity_page.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create and initialize providers
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  final postRepo = InMemoryPostRepository();
  await postRepo.initialize();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeProvider),
      ChangeNotifierProvider<AuthService>(
        create: (_) => AuthService(),
      ),
      ChangeNotifierProvider<PostRepository>.value(value: postRepo),
      ChangeNotifierProvider<CalendarProvider>(
        create: (_) => CalendarProvider(),
      ),
      ChangeNotifierProvider<UserProvider>(
        create: (_) => UserProvider(),
      ),
    ],
    child: const FBLAApp(),
  ));
}

class FBLAApp extends StatelessWidget {
  const FBLAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FBLA CONNECT',
      theme: context.watch<ThemeProvider>().currentTheme,
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          // Show login page if not authenticated
          if (!authService.isAuthenticated) {
            return const LoginPage();
          }
          // Show main app if authenticated
          return const AppScaffold();
        },
      ),
    );
  }
}



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}



class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              if (_titleController.text.trim().isEmpty || 
                  _bodyController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields'))
                );
                return;
              }
              final newPost = Post(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                handle: '@you',
                displayName: 'You',
                dateLabel: '${DateTime.now().month}/${DateTime.now().day}',
                title: _titleController.text.trim(),
                body: _bodyController.text.trim(),
                comments: [],
              );
              if (mounted) {
                Navigator.of(context).pop(newPost);
              }
            },
            child: const Text('Post', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  hintText: 'What do you want to share?',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Default to home tab

  Future<void> _createNewPost() async {
    if (!mounted) return;
    final newPost = await Navigator.of(context).push<Post>(
      MaterialPageRoute(builder: (_) => CreatePostScreen()),
    );
    if (!mounted) return;
    if (newPost != null) {
      // use provided repository
      context.read<PostRepository>().addPost(newPost);
    }
  }

  // Toggle like on post id
  void _toggleLike(String postId) {
    context.read<PostRepository>().toggleLike(postId);
  }

  // Open post detail to view/add comments
  Future<void> _openComments(String postId) async {
    if (!mounted) return;
    final post = context.read<PostRepository>().getPostById(postId);
    if (post == null) return;
    if (!mounted) return;
    final updated = await Navigator.of(context).push<Post>(
      MaterialPageRoute(
        builder: (context) => Consumer<PostRepository>(
          builder: (context, repo, _) => PostDetailPage(post: post),
        ),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      context.read<PostRepository>().updatePost(updated);
    }
  }

  void _onMenuSelected(String value, String postId) {
    if (value == 'Save') {
      // toggle saved state via repository
      final repo = context.read<PostRepository>();
      repo.toggleSave(postId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved post')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$value on post $postId')),
    );
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const SettingsPage();
      case 1:
        return const ChapterPage();
      case 2:
        return Consumer<PostRepository>(
          builder: (context, repo, child) {
            final posts = repo.getPosts();
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final p = posts[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: PostCard(
                    post: p,
                    onLike: () => _toggleLike(p.id),
                    onComments: () => _openComments(p.id),
                    onMenuSelected: (value) => _onMenuSelected(value, p.id),
                  ),
                );
              },
            );
          },
        );
      case 3:
        return const CalendarPage();
      // case 4 (Favorites) removed — Favorites moved to Activity accessible from top-right
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FBLA',
              style: TextStyle(
                color: theme.primaryColor,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'CONNECT',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                // open Activity page
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActivityPage()));
              },
              child: const CircleAvatar(child: Icon(Icons.person)),
            ),
          )
        ],
        bottom: _selectedIndex == 2 ? PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
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
              onTap: _createNewPost,
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
        ) : null,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigationItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.unselectedWidgetColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Your Chapter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
        ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(102) : Colors.black.withAlpha(13),
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
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
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
                           style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                         ),
                       ],
                     ),
                     const SizedBox(height: 2),
                     Text(
                       post.handle,
                       style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                     ),
                   ],
                 ),
               ),
               // three-dot popup menu
               PopupMenuButton<String>(
                 onSelected: onMenuSelected,
                 itemBuilder: (context) => const [
                       PopupMenuItem(value: 'Report', child: Text('Report')),
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
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
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
  Comment? _replyingTo; // Track which comment we're replying to

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
    // In this demo the commenter is always 'You'. Replace with auth in real app.
    final newComment = Comment(
      authorHandle: '@you',
      authorName: 'You',
      text: text,
      dateLabel: dateLabel,
      replies: []
    );

    setState(() {
      if (parentComment != null) {
        // Add reply to the parent comment
        parentComment.replies.add(newComment);
      } else {
        // Add top-level comment
        _post.comments.add(newComment);
      }
      _replyingTo = null; // Clear reply state
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

  void _startReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
    });
    _controller.clear();
    FocusScope.of(context).requestFocus(FocusNode());
    // Optionally scroll to the input field
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
                Container(
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
                          Text(_post.handle, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14)),
                          const SizedBox(width: 8),
                          Text(_post.dateLabel, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14)),
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
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // Use repository as single source of truth for likes
                    final repo = context.read<PostRepository>();
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
                                  Text(c.authorHandle, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                  const SizedBox(width: 8),
                                  Text(c.dateLabel, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
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
                            // Show replies with indentation
                            if (c.replies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: Column(
                                  children: c.replies.map((reply) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.subdirectory_arrow_right, size: 20),
                                    title: Row(
                                      children: [
                                        Text(reply.authorName, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 8),
                                        Text(reply.dateLabel, 
                                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
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
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
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
