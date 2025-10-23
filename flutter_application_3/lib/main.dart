import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/chats.dart';
import 'screens/settings.dart';
import 'screens/calendar.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initRepository();
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(),
    );
  }
}

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
  })  : likes = likes ?? 0,
        liked = liked ?? false;

  final String id;
  final String handle;
  final String displayName;
  final String dateLabel;
  final String title;
  final String body;
  final String? imageUrl;

  // comments
  final List<Comment> comments = [];

  int likes;
  bool liked;

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
      );
  // deep-copy including comments
  Post deepCopy() {
    final p = copy();
    p.comments.clear();
    for (final c in comments) {
      p.comments.add(c.copy());
    }
    return p;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'handle': handle,
        'displayName': displayName,
        'dateLabel': dateLabel,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'likes': likes,
        'liked': liked,
        'comments': comments.map((c) => c.toJson()).toList(),
      };

  static Post fromJson(Map<String, dynamic> j) {
    final p = Post(
      id: j['id'] as String,
      handle: j['handle'] as String,
      displayName: j['displayName'] as String,
      dateLabel: j['dateLabel'] as String,
      title: j['title'] as String,
      body: j['body'] as String,
      imageUrl: j['imageUrl'] as String?,
      likes: (j['likes'] as num?)?.toInt() ?? 0,
      liked: j['liked'] as bool? ?? false,
    );
    final cm = j['comments'] as List<dynamic>? ?? [];
    for (final c in cm) {
      p.comments.add(Comment.fromJson(Map<String, dynamic>.from(c as Map)));
    }
    return p;
  }
}

class Comment {
  Comment({required this.id, required this.author, required this.text, required this.date, int? likes, bool? liked})
      : likes = likes ?? 0,
        liked = liked ?? false;
  final String id;
  final String author;
  final String text;
  final DateTime date;
  int likes = 0;
  bool liked = false;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'text': text,
        'date': date.toIso8601String(),
        'likes': likes,
        'liked': liked,
      };

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
      id: j['id'] as String,
      author: j['author'] as String,
      text: j['text'] as String,
      date: DateTime.parse(j['date'] as String),
      likes: (j['likes'] as num?)?.toInt() ?? 0,
      liked: j['liked'] as bool? ?? false);

  Comment copy() => Comment(id: id, author: author, text: text, date: date, likes: likes, liked: liked);
}

class NotificationItem {
  NotificationItem({required this.id, required this.message, required this.date});
  final String id;
  final String message;
  final DateTime date;
}

class NotificationService extends ChangeNotifier {
  final List<NotificationItem> _items = [];

  List<NotificationItem> get items => List.unmodifiable(_items);

  void add(NotificationItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

final notificationService = NotificationService();

final postRepository = InMemoryPostRepository();

class InMemoryPostRepository extends ChangeNotifier {
  static const _prefsKey = 'fbla_posts_v1';
  String? _lastAddedPostId;

  String? get lastAddedPostId => _lastAddedPostId;

  Future<void> initRepository() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final arr = jsonDecode(raw) as List<dynamic>;
      _posts.clear();
      for (final e in arr) {
        _posts.add(Post.fromJson(Map<String, dynamic>.from(e as Map)));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_posts.map((p) => p.toJson()).toList());
      await prefs.setString(_prefsKey, raw);
    } catch (_) {}
  }
  final List<Post> _posts = [
    Post(
      id: '1',
      handle: '@skibidiwinner189',
      displayName: 'John Adams',
      dateLabel: 'Sep 11',
      title: 'My dog is pregnant',
      body:
          'I found out today that my dog is pregnant. We\'re excited and a little nervous. Any tips for first-time dog parents? Here\'s a photo from the vet appointment.',
      imageUrl: null,
      likes: 12,
      liked: false,
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
      liked: false,
    ),
  ];

  // expose live posts so UI can reflect comment/like changes immediately
  List<Post> getPosts() => List.unmodifiable(_posts);

  /// Returns the live Post instance stored in the repository (or null if not found).
  Post? getPostById(String id) {
    final idx = _posts.indexWhere((p) => p.id == id);
    if (idx == -1) return null;
    return _posts[idx];
  }

  void addPost(Post p) {
    _posts.insert(0, p);
    _lastAddedPostId = p.id;
    notifyListeners();
    _save();
  }

  void clear() {
    _posts.clear();
    notifyListeners();
  }

  void addComment(String postId, Comment c) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].comments.insert(0, c);
    notifyListeners();
    // don't notify for local user's own comments
    if (c.author != 'You') {
      notificationService.add(NotificationItem(id: DateTime.now().toString(), message: '${c.author} commented: ${c.text}', date: DateTime.now()));
    }
    _save();
  }

  // Replies/nested comments removed for simplicity

  void toggleCommentLike(String postId, String commentId) {
    final pIdx = _posts.indexWhere((p) => p.id == postId);
    if (pIdx == -1) return;
    // Find the comment among top-level comments only (no nested replies)
    final list = _posts[pIdx].comments;
    final cIdx = list.indexWhere((c) => c.id == commentId);
    if (cIdx == -1) return;
    final c = list[cIdx];
    if (c.liked) {
      c.liked = false;
      c.likes = (c.likes - 1).clamp(0, 999999);
    } else {
      c.liked = true;
      c.likes++;
    }
    notifyListeners();
    _save();
  }

  void toggleLike(String postId, {String actor = 'You'}) {
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
    // Only notify the local user when someone else (actor != 'You') likes their post
    if (actor != 'You' && p.handle == '@you') {
      notificationService.add(NotificationItem(id: DateTime.now().millisecondsSinceEpoch.toString(), message: '$actor liked "${p.title}"', date: DateTime.now()));
    }
    _save();
  }
}

// initialize repository before app starts
Future<void> initRepository() async {
  await postRepository.initRepository();
}

// Top-level helper: safely animate a ScrollController to a position.
// Uses a small retry loop with delays and catches AssertionError/Errors to
// avoid the "Viewport assertion: !_doingMountOrUpdate is not true" race when
// scrolling immediately after list changes.
void _safeAnimateTo(ScrollController controller, double offset, Duration duration, {bool Function()? mountedGetter}) {
  final isMounted = mountedGetter ?? () => true;
  // fire-and-forget async retries
  Future<void> _attempt() async {
    if (!isMounted()) return;
    // Try up to 6 attempts with short backoff
    const attempts = 6;
    var delayMs = 8;
    for (var i = 0; i < attempts; i++) {
      if (!isMounted()) return;
      if (!controller.hasClients) {
        // wait for next frame and try again
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
        continue;
      }
      try {
        // Use addPostFrameCallback to avoid doing layout work synchronously
        final completer = Completer<void>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            controller.animateTo(offset, duration: duration, curve: Curves.easeOut).whenComplete(() => completer.complete());
          } catch (e) {
            // capture errors and complete so we can retry
            completer.completeError(e);
          }
        });
        await completer.future;
        // success
        return;
      } catch (e) {
        // If there's an AssertionError or other timing error, retry after a short delay
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
        continue;
      }
    }
    // give up after attempts
  }

  unawaited(_attempt());
}

// Small helper to allow launching an async without awaiting and without analyzer lint
void unawaited(Future<void> f) {}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // use the global repository so composer and other parts of the app share the same data
  final repo = postRepository;
  int _index = 0;
  int? _hoverIndex;
  final ScrollController _feedScrollController = ScrollController();
  String? _observedLastAddedPostId;

  @override
  void initState() {
    super.initState();
    repo.addListener(_onRepoChanged);
    // listen for notifications so the AppBar badge updates
    notificationService.addListener(_onNotifications);
  }

  @override
  void dispose() {
    // remove only the listeners we added; do not dispose global singletons
    repo.removeListener(_onRepoChanged);
    notificationService.removeListener(_onNotifications);
    _feedScrollController.dispose();
    super.dispose();
  }

  void _onNotifications() => setState(() {});

  void _onRepoChanged() {
    // Update UI
    setState(() {});
    final last = repo.lastAddedPostId;
    if (last != null && last != _observedLastAddedPostId) {
      _observedLastAddedPostId = last;
      // safe animate to top (guarded to avoid viewport mount/update assertion)
  WidgetsBinding.instance.addPostFrameCallback((_) => _safeAnimateTo(_feedScrollController, 0.0, const Duration(milliseconds: 400), mountedGetter: () => mounted));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHome(),
      const CalendarScreen(),
      const ChatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          key: const Key('composer_button'),
          icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 28),
          onPressed: _openComposer,
          tooltip: 'New post',
        ),
        title: const Text('[FBLA APP]', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              key: const Key('bell_button'),
              onTap: _openNotifications,
              child: Stack(alignment: Alignment.topRight, children: [
                const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.notifications_none, color: Colors.black, size: 26)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: notificationService.items.isNotEmpty
                      ? Container(
                          key: ValueKey('badge_${notificationService.items.length}'),
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Center(child: Text('${notificationService.items.length}', style: const TextStyle(color: Colors.white, fontSize: 10))),
                        )
                      : const SizedBox.shrink(),
                ),
              ]),
            ),
          )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_index],
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      ),
      bottomNavigationBar: Container(
        height: 64,
        color: Colors.blue,
        child: Row(
          children: [
            _navItem(icon: Icons.home, label: 'Home', index: 0),
            _navItem(icon: Icons.calendar_today, label: 'Calendar', index: 1),
            _navItem(icon: Icons.chat_bubble_outline, label: 'Chats', index: 2),
            _navItem(icon: Icons.settings, label: 'Settings', index: 3),
          ],
        ),
      ),
    );
  }

  void _openComposer() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const ComposerSheet());
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SizedBox(
        height: 320,
        child: Column(
          children: [
            ListTile(title: const Text('Notifications'), trailing: TextButton(onPressed: () => setState(() => notificationService.clear()), child: const Text('Clear'))),
            const Divider(height: 1),
            Expanded(
              child: notificationService.items.isEmpty
                  ? const Center(child: Text('No notifications'))
                  : ListView.separated(
                      itemCount: notificationService.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final n = notificationService.items[i];
                        return ListTile(title: Text(n.message), subtitle: Text('${n.date}'));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final bool active = _index == index;
      return Expanded(
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoverIndex = index),
          onExit: (_) => setState(() => _hoverIndex = null),
          child: GestureDetector(
            onTap: () => setState(() => _index = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              color: active ? Colors.blue.shade800 : (_hoverIndex == index ? Colors.blue.shade700 : Colors.blue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(height: 6),
                  AnimatedOpacity(opacity: active ? 1 : 0, duration: const Duration(milliseconds: 150), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildHome() {
    final posts = repo.getPosts();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            decoration: InputDecoration(hintText: 'Search', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _feedScrollController,
            padding: const EdgeInsets.only(bottom: 80, top: 0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final p = posts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _PostCard(
                  post: p,
                  onLike: () => repo.toggleLike(p.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({Key? key, required this.post, required this.onLike}) : super(key: key);

  final Post post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text(post.displayName, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), Text(post.dateLabel, style: TextStyle(color: Colors.grey[600]))]),
                const SizedBox(height: 2),
                Text(post.handle, style: TextStyle(color: Colors.grey[700])),
              ]),
            ),
            PopupMenuButton<String>(onSelected: (v) {
              // basic visual feedback
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$v selected')));
            }, itemBuilder: (_) => const [PopupMenuItem(value: 'Report', child: Text('Report')), PopupMenuItem(value: 'Save', child: Text('Save'))])
          ]),
          const SizedBox(height: 12),
          Text(post.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          Text(post.body, style: const TextStyle(fontSize: 14)),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            SizedBox(height: 160, width: double.infinity, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(post.imageUrl!, fit: BoxFit.cover))),
          ],
          const SizedBox(height: 12),
          Row(children: [
            IconButton(onPressed: onLike, icon: Icon(post.liked ? Icons.favorite : Icons.favorite_border, color: post.liked ? Colors.pink : null)),
            Text('${post.likes}'),
            const SizedBox(width: 16),
            IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailPage(post: post))), icon: const Icon(Icons.mode_comment_outlined)),
            Text('${post.comments.length}'),
            const Spacer(),
            IconButton(onPressed: () {}, icon: const Icon(Icons.share))
          ])
        ]),
      ),
    );
  }
}

// open detail page to view/add comments
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post});
  final Post post;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _ctrl = TextEditingController();
  final _authorCtrl = TextEditingController(text: 'You');
  final _scrollController = ScrollController();
  String? _justAddedCommentId;
  late Post? livePost;
  final FocusNode _commentFocusNode = FocusNode();
  

  @override
  void initState() {
    super.initState();
    livePost = postRepository.getPostById(widget.post.id) ?? widget.post;
    postRepository.addListener(_onRepoChanged);
  }

  // Replies removed for simplicity.

  @override
  void dispose() {
    postRepository.removeListener(_onRepoChanged);
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) {
    // Only handle down events
    if (event is! RawKeyDownEvent) return;
    // Check Enter key
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final keysPressed = RawKeyboard.instance.keysPressed;
      final shiftPressed = keysPressed.contains(LogicalKeyboardKey.shiftLeft) || keysPressed.contains(LogicalKeyboardKey.shiftRight);
      if (shiftPressed) {
        // insert newline at cursor
        final sel = _ctrl.selection;
        final text = _ctrl.text;
        final start = sel.start >= 0 ? sel.start : text.length;
        final end = sel.end >= 0 ? sel.end : text.length;
        final before = text.substring(0, start);
        final after = text.substring(end);
        final newText = '$before\n$after';
        final newOffset = before.length + 1;
        _ctrl.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newOffset));
      } else {
        _addComment();
      }
    }
  }

  void _onRepoChanged() {
    setState(() {
      livePost = postRepository.getPostById(widget.post.id) ?? widget.post;
    });
  }

  void _addComment() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    // Use author from input
    final author = _authorCtrl.text.trim().isEmpty ? 'You' : _authorCtrl.text.trim();
    final newComment = Comment(id: DateTime.now().toString(), author: author, text: text, date: DateTime.now());
    // Always add top-level comments (no nested replies)
    postRepository.addComment(widget.post.id, newComment);
  _ctrl.clear();
    setState(() {
      _justAddedCommentId = newComment.id;
    });
    // scroll to top to reveal the new comment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeAnimateTo(_scrollController, 0.0, const Duration(milliseconds: 300), mountedGetter: () => mounted);
    });
  }

  

  @override
  Widget build(BuildContext context) {
    final p = livePost ?? widget.post;
    return Scaffold(
      appBar: AppBar(title: Text(p.title)),
      body: Column(children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: 1 + p.comments.length,
                  itemBuilder: (ctx, idx) {
                    if (idx == 0) {
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.body),
                        if (p.imageUrl != null) Image.network(p.imageUrl!),
                        const Divider(),
                        const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                      ]);
                    }
                        final c = p.comments[idx - 1];
                        return CommentTile(postId: p.id, comment: c, animate: c.id == _justAddedCommentId, onAnimated: () {
                          if (_justAddedCommentId == c.id) {
                            setState(() => _justAddedCommentId = null);
                          }
                        });
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: [
            TextField(key: const Key('comment_author'), controller: _authorCtrl, decoration: const InputDecoration(hintText: 'Your name', prefixIcon: Icon(Icons.person))),
            // Replies removed; no reply preview UI
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: RawKeyboardListener(
                  focusNode: _commentFocusNode,
                  onKey: _handleKey,
                  child: TextField(key: const Key('comment_textfield'), controller: _ctrl, decoration: const InputDecoration(hintText: 'Write a comment')),
                ),
              ),
              IconButton(key: const Key('send_comment'), onPressed: _addComment, icon: const Icon(Icons.send))
            ]),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Enter = send · Shift+Enter = newline', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ),
          ]),
        )
      ]),
    );
  }
}

class CommentTile extends StatefulWidget {
  const CommentTile({super.key, required this.postId, required this.comment, this.animate = false, this.onAnimated, this.onReply});
  final String postId;
  final Comment comment;
  final bool animate;
  final VoidCallback? onAnimated;
  final VoidCallback? onReply;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  late final AnimationController _likeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), lowerBound: 0.8, upperBound: 1.15)
    ..value = 1.0;
  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _ctrl.forward().whenComplete(() => widget.onAnimated?.call());
    } else {
      _ctrl.value = 1.0;
    }
    // initialize like animation state
    if (widget.comment.liked) {
      _likeCtrl.value = 1.0;
    } else {
      _likeCtrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant CommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctrl.isAnimating && _ctrl.value == 0.0) {
      _ctrl.forward().whenComplete(() => widget.onAnimated?.call());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _likeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: FadeTransition(
        opacity: _ctrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                ListTile(
              // simple single-level comment tile
              tileColor: null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              title: Text(widget.comment.author, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(widget.comment.text),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                ScaleTransition(
                  scale: CurvedAnimation(parent: _likeCtrl, curve: Curves.elasticOut),
                  child: InkWell(
                    onTap: () {
                      postRepository.toggleCommentLike(widget.postId, widget.comment.id);
                      // play like animation
                      _likeCtrl.forward(from: 0.8);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(children: [
                        Icon(widget.comment.liked ? Icons.favorite : Icons.favorite_border, color: widget.comment.liked ? Colors.pink : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text('${widget.comment.likes}')
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Reply action removed
              ]),
            ),
            // nested replies removed
          ],
        ),
      ),
    );
  }

  
}
