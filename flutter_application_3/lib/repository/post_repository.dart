import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _savedKey = 'saved_posts';

// Models and repository for posts
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
  bool? saved,
    List<Comment>? comments,
  })  : likes = likes ?? 0,
    liked = liked ?? false,
    saved = saved ?? false,
        comments = comments ?? <Comment>[];
  bool saved;

  final String id;
  final String handle;
  final String displayName;
  final String dateLabel;
  final String title;
  final String body;
  final String? imageUrl;

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
        saved: saved,
        comments: comments.map((c) => c.copy()).toList(),
      );
}

class Comment {
  Comment({
    required this.authorHandle,
    required this.authorName,
    required this.text,
    required this.dateLabel,
    List<Comment>? replies,
  }) : replies = replies ?? [];

  final String authorHandle;
  final String authorName;
  final String text;
  final String dateLabel;
  final List<Comment> replies;

  Comment copy() => Comment(
        authorHandle: authorHandle,
        authorName: authorName,
        text: text,
        dateLabel: dateLabel,
        replies: List<Comment>.from(replies),
      );
}

abstract class PostRepository extends ChangeNotifier {
  List<Post> getPosts();
  Post? getPostById(String id);
  void updatePost(Post updated);
  void toggleLike(String postId);
  void addComment(String postId, Comment comment);
  void addPost(Post post);
  List<Post> getFavorites();
  void toggleSave(String postId);
  List<Post> getSavedPosts();
  /// Initialize repository (loads persisted saved posts)
  Future<void> initialize();
}

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
                'I found out today that my dog is pregnant. We\'re excited and a little nervous. Any tips for first-time dog parents?',
            imageUrl: null,
            likes: 12,
            comments: [
              Comment(
                authorHandle: '@fan1',
                authorName: 'A Fan',
                text: 'Congrats!',
                dateLabel: 'Sep 11',
                replies: [],
              ),
              Comment(
                authorHandle: '@friend2',
                authorName: 'Friend Two',
                text: 'So happy for you',
                dateLabel: 'Sep 11',
                replies: [],
              ),
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
  void addPost(Post post) {
    _posts.insert(0, post);
    notifyListeners();
  }

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
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_savedKey) ?? <String>[];
      for (final p in _posts) {
        p.saved = saved.contains(p.id);
      }
      notifyListeners();
    } catch (_) {}
  }

  @override
  void toggleSave(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final p = _posts[idx];
    p.saved = !p.saved;
    _persistSavedIds();
    notifyListeners();
  }

  Future<void> _persistSavedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = _posts.where((p) => p.saved).map((p) => p.id).toList();
      await prefs.setStringList(_savedKey, savedIds);
    } catch (_) {}
  }

  @override
  List<Post> getFavorites() => List<Post>.unmodifiable(_posts.where((p) => p.liked).map((p) => p.copy()).toList());

  @override
  List<Post> getSavedPosts() => List<Post>.unmodifiable(_posts.where((p) => p.saved).map((p) => p.copy()).toList());

  @override
  void addComment(String postId, Comment comment) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].comments.add(comment);
    notifyListeners();
  }
}
