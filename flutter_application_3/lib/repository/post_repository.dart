import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'notification_repository.dart';
import '../services/firebase_user_service.dart';

const String _savedKey = 'saved_posts';
const String _firstPostKey = 'user_first_post_ids';

// Poll option for posts
class PollOption {
  PollOption({
    required this.id,
    required this.text,
    Set<String>? voterIds,
  }) : voterIds = voterIds ?? {};

  final String id;
  final String text;
  final Set<String> voterIds; // User IDs who voted for this option

  int get voteCount => voterIds.length;
  
  PollOption copy() => PollOption(
    id: id,
    text: text,
    voterIds: Set.from(voterIds),
  );
}

// Poll for posts
class Poll {
  Poll({
    required this.question,
    required this.options,
  });

  final String question;
  final List<PollOption> options;
  
  int get totalVotes => options.fold(0, (sum, opt) => sum + opt.voteCount);
  
  Poll copy() => Poll(
    question: question,
    options: options.map((opt) => opt.copy()).toList(),
  );
}

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
    this.userId, // Add userId to track post author
    this.profileImagePath, // User's profile picture path
    this.poll, // Optional poll
    List<String>? tags, // Tags/categories like "Nationals", "Community Service"
    List<String>? crossPostedTo, // Platforms this post was cross-posted to
    int? likes,
    bool? liked,
    bool? saved,
    List<Comment>? comments,
  })  : likes = likes ?? 0,
        liked = liked ?? false,
        saved = saved ?? false,
        tags = tags ?? [],
        crossPostedTo = crossPostedTo ?? [],
        comments = comments ?? <Comment>[];
  bool saved;

  final String id;
  final String handle;
  final String displayName;
  final String dateLabel;
  final String title;
  final String body;
  final String? imageUrl;
  final String? userId; // Firebase Auth UID of the post author
  final String? profileImagePath; // User's profile picture path
  final Poll? poll; // Optional poll
  final List<String> tags; // Tags for categorization
  final List<String> crossPostedTo; // Platforms this post was cross-posted to (e.g., ['Facebook', 'X', 'Instagram'])

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
        userId: userId,
        profileImagePath: profileImagePath,
        poll: poll?.copy(),
        tags: List.from(tags),
        crossPostedTo: List.from(crossPostedTo),
        likes: likes,
        liked: liked,
        saved: saved,
        comments: comments.map((c) => c.copy()).toList(),
      );
}

class Comment {
  Comment({
    String? id,
    required this.authorHandle,
    required this.authorName,
    required this.text,
    required this.dateLabel,
    this.userId, // Add userId to track comment author
    this.profileImagePath, // User's profile picture path
    List<Comment>? replies,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + (DateTime.now().microsecond % 1000).toString(),
       replies = replies ?? [];

  final String id;
  final String authorHandle;
  final String authorName;
  final String text;
  final String dateLabel;
  final String? userId; // Firebase Auth UID of the comment author
  final String? profileImagePath; // User's profile picture path
  final List<Comment> replies;

  Comment copy() => Comment(
        id: id,
        authorHandle: authorHandle,
        authorName: authorName,
        text: text,
        dateLabel: dateLabel,
        userId: userId,
        profileImagePath: profileImagePath,
        replies: List<Comment>.from(replies),
      );
}

abstract class PostRepository extends ChangeNotifier {
  List<Post> getPosts();
  Post? getPostById(String id);
  void updatePost(Post updated);
  void toggleLike(String postId, {bool autoSave = false, String? currentUserId, String? currentUserName, String? currentUserHandle});
  void addComment(String postId, Comment comment, {String? currentUserId});
  void addPost(Post post);
  List<Post> getFavorites();
  void toggleSave(String postId);
  List<Post> getSavedPosts();

  /// Initialize repository (loads persisted saved posts)
  Future<void> initialize();
  
  /// Update all posts and comments by a user with new handle, display name, and profile image
  void updateUserInfo(String userId, String newHandle, String newDisplayName, String? profileImagePath);
  
  /// Delete a post by ID
  bool deletePost(String postId);
  
  /// Delete a comment from a post
  bool deleteComment(String postId, Comment comment);
  
  /// Check if a user has posted before (to determine if welcome comment should be added)
  Future<bool> hasUserPostedBefore(String userId);
  
  /// Mark that a user has posted (so they don't get welcome comment again)
  Future<void> markUserHasPosted(String userId);
  
  /// Vote on a poll option
  void voteOnPoll(String postId, String optionId, String userId);
  
  /// Get posts by tag
  List<Post> getPostsByTag(String tag);
  
  /// Get all available tags
  List<String> getAllTags();
  
  /// Report a post
  Future<bool> reportPost(String postId, String reason, String reporterId);
  
  /// Hide a reported post for the user
  void hidePost(String postId, String userId);
  
  /// Check if a post is hidden for the user
  bool isPostHidden(String postId, String userId);
}

class InMemoryPostRepository extends PostRepository {
  final List<Post> _posts;
  final Set<String> _hiddenPostIds = {}; // Posts hidden by current user
  final Map<String, List<String>> _reportedPosts = {}; // postId -> list of reporter user IDs
  NotificationRepository? _notificationRepo;

  // Lists for generating diverse bot names
  static const List<String> _firstNames = [
    'Alex', 'Jordan', 'Taylor', 'Morgan', 'Casey',
    'Riley', 'Avery', 'Quinn', 'Jamie', 'Dakota',
    'Emma', 'Liam', 'Olivia', 'Noah', 'Sophia',
    'Mason', 'Isabella', 'William', 'Ava', 'James',
    'Charlotte', 'Benjamin', 'Mia', 'Lucas', 'Amelia',
    'Michael', 'Harper', 'Elijah', 'Evelyn', 'Alexander',
    'Abigail', 'Daniel', 'Emily', 'Matthew', 'Elizabeth',
    'Jackson', 'Sofia', 'Sebastian', 'Avery', 'David',
    'Ella', 'Joseph', 'Madison', 'Samuel', 'Scarlett',
    'Henry', 'Victoria', 'Owen', 'Aria', 'Wyatt',
  ];
  
  static const List<String> _lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones',
    'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
    'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson',
    'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
    'Lee', 'Perez', 'Thompson', 'White', 'Harris',
    'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson',
    'Walker', 'Young', 'Allen', 'King', 'Wright',
    'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores',
    'Green', 'Adams', 'Nelson', 'Baker', 'Hall',
    'Rivera', 'Campbell', 'Mitchell', 'Carter', 'Roberts',
  ];
  
  // Cache for generated bot names to maintain consistency
  final Map<int, String> _botNameCache = {};
  final Map<int, String> _botHandleCache = {};
  
  // Generate a bot name by combining random first and last names
  String _generateBotName(int seed) {
    if (_botNameCache.containsKey(seed)) {
      return _botNameCache[seed]!;
    }
    
    final random = math.Random(seed);
    final firstName = _firstNames[random.nextInt(_firstNames.length)];
    final lastName = _lastNames[random.nextInt(_lastNames.length)];
    final fullName = '$firstName $lastName';
    
    _botNameCache[seed] = fullName;
    return fullName;
  }
  
  // Generate a bot handle from the name
  String _generateBotHandle(int seed) {
    if (_botHandleCache.containsKey(seed)) {
      return _botHandleCache[seed]!;
    }
    
    final name = _generateBotName(seed);
    final parts = name.split(' ');
    final firstName = parts[0].toLowerCase();
    final lastInitial = parts[1][0].toLowerCase();
    final handle = '@${firstName}_$lastInitial';
    
    _botHandleCache[seed] = handle;
    return handle;
  }

  InMemoryPostRepository()
      : _posts = [
          // Posts from our chapter
          Post(
            id: '1',
            handle: '@fbla_president',
            displayName: 'Sarah Johnson',
            userId: 'bot_sarah_johnson',
            dateLabel: 'Nov 1',
            title: 'Nationals Prep Meeting Tomorrow!',
            body:
                'Don\'t forget we have our FBLA Nationals prep meeting tomorrow at 3pm in room 204. We\'ll be going over competition categories and practice rounds. Bring your materials!',
            imageUrl: null,
            likes: 24,
            tags: ['Nationals', 'Meetings', 'Competitions'],
            comments: [
              Comment(
                authorHandle: '@marketing_lead',
                authorName: 'Alex Chen',
                text: 'Will there be pizza? 🍕',
                dateLabel: 'Nov 1',
                replies: [],
              ),
              Comment(
                authorHandle: '@finance_officer',
                authorName: 'Marcus Davis',
                text: 'See you there! I\'ll bring my accounting project drafts.',
                dateLabel: 'Nov 1',
                replies: [],
              ),
            ],
          ),
          // Post from California chapter
          Post(
            id: 'ca_1',
            handle: '@sfhs_fbla',
            displayName: 'San Francisco HS FBLA',
            userId: 'bot_sfhs_fbla',
            dateLabel: 'Nov 3',
            title: 'We Won Best Chapter Award! 🏆',
            body:
                'Huge congratulations to our chapter for winning the Best Chapter Award at the Northern California Regional Conference! Thank you to everyone who contributed to this achievement. Let\'s keep up the momentum!',
            imageUrl: null,
            likes: 156,
            tags: ['Awards', 'Regional', 'Chapter News'],
            comments: [],
          ),
          Post(
            id: '2',
            handle: '@community_service',
            displayName: 'Emily Rodriguez',
            userId: 'bot_emily_rodriguez',
            dateLabel: 'Oct 28',
            title: 'Community Service Hours Update',
            body:
                'Great job everyone! Our chapter has logged 350 community service hours this semester. Keep up the amazing work - we\'re on track to exceed our goal of 500 hours!',
            imageUrl: null,
            likes: 18,
            tags: ['Community Service', 'Chapter News'],
            comments: [],
          ),
          // Post from Texas chapter
          Post(
            id: 'tx_1',
            handle: '@austin_fbla',
            displayName: 'Austin West FBLA',
            userId: 'bot_austin_fbla',
            dateLabel: 'Nov 2',
            title: 'Entrepreneurship Workshop This Weekend',
            body:
                'Excited to announce that we\'re hosting a free entrepreneurship workshop featuring guest speakers from local startups! Saturday 10 AM at the library. Open to all FBLA members in the Austin area. RSVP in comments!',
            imageUrl: null,
            likes: 89,
            tags: ['Workshop', 'Entrepreneurship', 'Regional Event'],
            comments: [],
          ),
          Post(
            id: '3',
            handle: '@events_coordinator',
            displayName: 'Jordan Miller',
            userId: 'bot_jordan_miller',
            dateLabel: 'Oct 30',
            title: 'Which fundraiser should we do next?',
            body:
                'Help us choose our next chapter fundraiser! Vote below and let\'s make it a success! 🎯',
            imageUrl: null,
            likes: 32,
            tags: ['Fundraising', 'Chapter Events', 'Poll'],
            poll: Poll(
              question: 'Which fundraiser would you prefer?',
              options: [
                PollOption(id: '1', text: 'Bake Sale', voterIds: {'user1', 'user2', 'user3'}),
                PollOption(id: '2', text: 'Car Wash', voterIds: {'user4', 'user5'}),
                PollOption(id: '3', text: 'Silent Auction', voterIds: {'user6'}),
                PollOption(id: '4', text: 'T-Shirt Sales', voterIds: {'user7', 'user8', 'user9', 'user10'}),
              ],
            ),
            comments: [
              Comment(
                authorHandle: '@marketing_lead',
                authorName: 'Alex Chen',
                text: 'T-shirts would be great for chapter visibility!',
                dateLabel: 'Oct 30',
                replies: [],
              ),
            ],
          ),
          // Post from New York chapter
          Post(
            id: 'ny_1',
            handle: '@nychs_fbla',
            displayName: 'NYC Central HS FBLA',
            dateLabel: 'Oct 29',
            title: 'Finance Competition Tips Thread',
            body:
                'For everyone preparing for finance competitions, here are my top tips: 1) Know your ratios cold 2) Practice time management 3) Read WSJ daily 4) Form study groups. What other tips do you have?',
            imageUrl: null,
            likes: 203,
            tags: ['Competitions', 'Finance', 'Study Tips'],
            comments: [],
          ),
          Post(
            id: '4',
            handle: '@competition_team',
            displayName: 'Ryan Thompson',
            dateLabel: 'Oct 25',
            title: 'Business Ethics Competition Prep',
            body:
                'Anyone interested in competing in Business Ethics at State? We\'re starting practice sessions next week. DM me if you want to join! 💼',
            imageUrl: null,
            likes: 15,
            tags: ['Competitions', 'Business Ethics', 'State'],
            comments: [],
          ),
          // Post from Florida chapter
          Post(
            id: 'fl_1',
            handle: '@miami_fbla',
            displayName: 'Miami Lakes FBLA',
            dateLabel: 'Oct 27',
            title: 'Thank You To Our Sponsors! 💙',
            body:
                'A huge thank you to local businesses who sponsored our chapter this year: TechStart Inc, Miami Business Solutions, and Garcia & Associates. Your support makes everything we do possible!',
            imageUrl: null,
            likes: 67,
            tags: ['Sponsors', 'Thank You', 'Chapter News'],
            comments: [],
          ),
          // Post from Illinois chapter
          Post(
            id: 'il_1',
            handle: '@chicago_fbla',
            displayName: 'Chicago North FBLA',
            dateLabel: 'Oct 26',
            title: 'Networking Event Success! 🤝',
            body:
                'Last night\'s networking event with local business professionals was incredible! Over 50 professionals attended and our members made amazing connections. Already planning the next one!',
            imageUrl: null,
            likes: 142,
            tags: ['Networking', 'Professional Development', 'Events'],
            comments: [],
          ),
          // Cross-posted from Instagram
          Post(
            id: 'social_ig_1',
            handle: '@newyork_fbla_ig',
            displayName: 'NYC FBLA Chapter 📸',
            userId: 'bot_nyc_fbla_ig',
            dateLabel: 'Nov 5',
            title: 'First Place at State Competition! 🥇',
            body:
                'We did it! Our team just won FIRST PLACE in Business Plan at the New York State FBLA Competition! Couldn\'t be prouder of everyone who worked so hard on this project. Next stop: Nationals! 🎯✨\n\n#fbla25-26 #StateChampions #BusinessPlan #FutureLeaders',
            imageUrl: null,
            likes: 287,
            tags: ['Competitions', 'State', 'Awards', 'Nationals'],
            crossPostedTo: ['Facebook', 'X', 'Instagram', 'LinkedIn'], // Posted to all platforms
            comments: [
              Comment(
                authorHandle: '@sfhs_fbla',
                authorName: 'San Francisco HS FBLA',
                text: 'Congratulations! See you at Nationals! 🎉',
                dateLabel: 'Nov 5',
                replies: [],
              ),
              Comment(
                authorHandle: '@chicago_fbla',
                authorName: 'Chicago North FBLA',
                text: 'Amazing work NYC! Best of luck at Nationals!',
                dateLabel: 'Nov 5',
                replies: [],
              ),
            ],
          ),
          // Cross-posted from X (Twitter)
          Post(
            id: 'social_x_1',
            handle: '@seattle_fbla_x',
            displayName: 'Seattle Tech FBLA 🐦',
            userId: 'bot_seattle_fbla_x',
            dateLabel: 'Nov 4',
            title: 'Breaking: Partnership Announcement 🚀',
            body:
                'HUGE NEWS: We\'re excited to announce our new partnership with @Microsoft for this year\'s coding competition! They\'ll be providing mentorship, resources, and internship opportunities for our members. This is what #fbla25-26 is all about! 💻🌟\n\n#FBLA #TechPartnership #StudentSuccess',
            imageUrl: null,
            likes: 412,
            tags: ['Partnerships', 'Technology', 'Opportunities', 'Coding'],
            crossPostedTo: ['X'], // Posted to X only
            comments: [
              Comment(
                authorHandle: '@austin_fbla',
                authorName: 'Austin West FBLA',
                text: 'This is incredible! Congrats Seattle! 🎊',
                dateLabel: 'Nov 4',
                replies: [],
              ),
            ],
          ),
        ];

  // Set notification repository (called from app initialization)
  void setNotificationRepository(NotificationRepository repo) {
    _notificationRepo = repo;
  }

  @override
  void addPost(Post post) async {
    // Check if this is user's first post and add welcome comment
    if (post.userId != null) {
      final hasPosted = await hasUserPostedBefore(post.userId!);
      if (!hasPosted) {
        _addWelcomeComment(post);
        await markUserHasPosted(post.userId!);
      }
    }
    
    // Add random generic bot comments
    _addRandomBotComments(post);
    
    // Add random bot likes to the post with delays (run in background)
    _addRandomBotLikes(post);
    
    // Guaranteed like and comment after 40 seconds
    _addGuaranteedBotActivity(post);
    
    _posts.insert(0, post);
    notifyListeners();
  }

  @override
  List<Post> getPosts() {
    // Filter out hidden posts
    return List<Post>.unmodifiable(
      _posts.where((p) => !_hiddenPostIds.contains(p.id)).map((p) => p.copy())
    );
  }

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
  void toggleLike(String postId, {bool autoSave = false, String? currentUserId, String? currentUserName, String? currentUserHandle}) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final p = _posts[idx];
    final wasLiked = p.liked;
    if (p.liked) {
      p.liked = false;
      p.likes = (p.likes - 1).clamp(0, 999999);
      // If unliking, unsave as well if it was auto-saved
      if (autoSave && p.saved) {
        p.saved = false;
        _persistSavedIds();
      }
    } else {
      p.liked = true;
      p.likes++;
      // Auto-save if enabled
      if (autoSave && !p.saved) {
        p.saved = true;
        _persistSavedIds();
      }
      
      // Create notification for new likes (only if not liking own post)
      if (!wasLiked && currentUserId != null && 
          currentUserName != null && currentUserHandle != null && p.userId != null &&
          currentUserId != p.userId) { // Don't notify if user likes their own post
        final postPreview = p.title.isNotEmpty ? p.title : p.body;
        final postTitle = postPreview.length > 50 ? '${postPreview.substring(0, 50)}...' : postPreview;
        print('DEBUG: Creating like notification for user ${p.userId} from $currentUserName');
        _notificationRepo?.addNotification(
          AppNotification(
            id: '${DateTime.now().millisecondsSinceEpoch}_like_$postId',
            type: NotificationType.like,
            postId: postId,
            postTitle: postTitle,
            actorName: currentUserName,
            actorHandle: currentUserHandle,
            timestamp: DateTime.now(),
            isRead: false,
          ),
          p.userId!, // Notify the post owner
        );
        print('DEBUG: Notification created and added');
      } else {
        print('DEBUG: Like notification NOT created - wasLiked:$wasLiked, currentUserId:$currentUserId, postUserId:${p.userId}');
      }
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
  List<Post> getFavorites() => List<Post>.unmodifiable(
      _posts.where((p) => p.liked).map((p) => p.copy()).toList());

  @override
  List<Post> getSavedPosts() => List<Post>.unmodifiable(
      _posts.where((p) => p.saved).map((p) => p.copy()).toList());

  @override
  void addComment(String postId, Comment comment, {String? currentUserId}) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final p = _posts[idx];
    p.comments.add(comment);
    
    // Create notification for comments (only if not commenting on own post)
    if (currentUserId != null && p.userId != null && currentUserId != p.userId) {
      final postPreview = p.title.isNotEmpty ? p.title : p.body;
      final postTitle = postPreview.length > 50 ? '${postPreview.substring(0, 50)}...' : postPreview;
      print('DEBUG: Creating comment notification for user ${p.userId} from ${comment.authorName}');
      _notificationRepo?.addNotification(
        AppNotification(
          id: '${DateTime.now().millisecondsSinceEpoch}_comment_$postId',
          type: NotificationType.comment,
          postId: postId,
          postTitle: postTitle,
          actorName: comment.authorName,
          actorHandle: comment.authorHandle,
          timestamp: DateTime.now(),
          commentText: comment.text.length > 100 ? '${comment.text.substring(0, 100)}...' : comment.text,
          isRead: false,
        ),
        p.userId!, // Notify the post owner
      );
      print('DEBUG: Comment notification created');
    } else {
      print('DEBUG: Comment notification NOT created - currentUserId:$currentUserId, postUserId:${p.userId}');
    }
    
    notifyListeners();
  }

  @override
  void updateUserInfo(String userId, String newHandle, String newDisplayName, String? profileImagePath) {
    print('DEBUG PostRepo: updateUserInfo called');
    print('DEBUG PostRepo: userId: $userId');
    print('DEBUG PostRepo: newHandle: $newHandle');
    print('DEBUG PostRepo: newDisplayName: $newDisplayName');
    print('DEBUG PostRepo: profileImagePath: $profileImagePath');
    
    int updatedPostCount = 0;
    // Update all posts by this user
    for (final post in _posts) {
      if (post.userId == userId) {
        print('DEBUG PostRepo: Found post by user: ${post.id}');
        // Create a new post with updated info
        final updatedPost = Post(
          id: post.id,
          handle: newHandle,
          displayName: newDisplayName,
          dateLabel: post.dateLabel,
          title: post.title,
          body: post.body,
          imageUrl: post.imageUrl,
          userId: post.userId,
          profileImagePath: profileImagePath,
          poll: post.poll,
          tags: post.tags,
          likes: post.likes,
          liked: post.liked,
          saved: post.saved,
          comments: post.comments,
        );
        final idx = _posts.indexWhere((p) => p.id == post.id);
        if (idx != -1) {
          _posts[idx] = updatedPost;
          updatedPostCount++;
          print('DEBUG PostRepo: Updated post at index $idx with profileImagePath: ${updatedPost.profileImagePath}');
        }
      }
      
      // Update all comments and replies by this user in all posts
      _updateCommentsRecursively(post.comments, userId, newHandle, newDisplayName, profileImagePath);
    }
    print('DEBUG PostRepo: Updated $updatedPostCount posts total');
    notifyListeners();
  }

  void _updateCommentsRecursively(List<Comment> comments, String userId, String newHandle, String newDisplayName, String? profileImagePath) {
    for (int i = 0; i < comments.length; i++) {
      final comment = comments[i];
      if (comment.userId == userId) {
        // Replace the comment with updated info, preserving the ID
        comments[i] = Comment(
          id: comment.id,
          authorHandle: newHandle,
          authorName: newDisplayName,
          text: comment.text,
          dateLabel: comment.dateLabel,
          userId: comment.userId,
          profileImagePath: profileImagePath,
          replies: comment.replies,
        );
      }
      // Recursively update replies
      if (comment.replies.isNotEmpty) {
        _updateCommentsRecursively(comment.replies, userId, newHandle, newDisplayName, profileImagePath);
      }
    }
  }

  @override
  bool deletePost(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return false;
    _posts.removeAt(idx);
    notifyListeners();
    return true;
  }

  @override
  bool deleteComment(String postId, Comment comment) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return false;
    
    final post = _posts[idx];
    final removed = _removeCommentRecursively(post.comments, comment);
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  bool _removeCommentRecursively(List<Comment> comments, Comment targetComment) {
    // Try to find and remove the comment at this level by ID
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == targetComment.id) {
        comments.removeAt(i);
        return true;
      }
      // Check replies recursively
      if (_removeCommentRecursively(comments[i].replies, targetComment)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<bool> hasUserPostedBefore(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersList = prefs.getStringList(_firstPostKey) ?? [];
      return usersList.contains(userId);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markUserHasPosted(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersList = prefs.getStringList(_firstPostKey) ?? [];
      if (!usersList.contains(userId)) {
        usersList.add(userId);
        await prefs.setStringList(_firstPostKey, usersList);
      }
    } catch (_) {
      // Silently fail
    }
  }

  /// Add a welcome comment from FBLA Bot to a first-time poster
  void _addWelcomeComment(Post post) {
    final welcomeMessages = [
      'Welcome to FBLA HIVE! 🐝 Great to see your first post!',
      'Awesome first post! 🎉 Welcome to the community!',
      'Welcome to FBLA HIVE! 🐝 Can\'t wait to see more from you!',
      'Great to have you here! 🌟 Looking forward to more posts!',
    ];
    
    final random = math.Random();
    final message = welcomeMessages[random.nextInt(welcomeMessages.length)];
    
    final welcomeComment = Comment(
      authorHandle: '@fbla_bot',
      authorName: 'FBLA Bot',
      text: message,
      dateLabel: 'Just now',
      userId: 'fbla_bot_system',
    );
    
    post.comments.insert(0, welcomeComment);
  }

  /// Add random generic bot comments to posts with delays
  Future<void> _addRandomBotComments(Post post) async {
    final random = math.Random();
    
    // 85% chance to add 2-4 bot comments (increased from 60%)
    if (random.nextDouble() < 0.85) {
      final genericComments = [
        'Great post!',
        'Thanks for sharing!',
        'This is helpful!',
        'Interesting perspective!',
        'Well said!',
        'Love this!',
        'Totally agree!',
        'Good point!',
        'Nice work!',
        'Appreciate the insight!',
        'This is awesome!',
        'Keep it up!',
        'Very informative!',
        'Thanks!',
        'Really useful info!',
        'Great idea!',
        'I learned something new!',
        'Super helpful!',
        'Agreed!',
        'Well done!',
        'This makes sense!',
        'Good to know!',
        'Thank you for this!',
        'Fantastic post!',
        'Couldn\'t have said it better!',
      ];
      
      final numComments = 2 + random.nextInt(3); // 2, 3, or 4 comments
      
      for (int i = 0; i < numComments; i++) {
        // Random delay between 5-30 seconds
        final delaySeconds = 5 + random.nextInt(26);
        await Future.delayed(Duration(seconds: delaySeconds));
        
        final commentIndex = random.nextInt(genericComments.length);
        final botSeed = random.nextInt(100000);
        final botName = _generateBotName(botSeed);
        final botHandle = _generateBotHandle(botSeed);
        
        final comment = Comment(
          authorHandle: botHandle,
          authorName: botName,
          text: genericComments[commentIndex],
          dateLabel: 'Just now',
          userId: 'bot_user_$botSeed',
        );
        
        // Find the post in the list and add the comment
        final idx = _posts.indexWhere((p) => p.id == post.id);
        if (idx == -1) return; // Post was deleted
        
        _posts[idx].comments.add(comment);
        
        // Create notification for bot comment
        if (_posts[idx].userId != null && _notificationRepo != null) {
          final postPreview = _posts[idx].title.isNotEmpty ? _posts[idx].title : _posts[idx].body;
          final postTitle = postPreview.length > 50 ? '${postPreview.substring(0, 50)}...' : postPreview;
          
          _notificationRepo!.addNotification(
            AppNotification(
              id: '${DateTime.now().millisecondsSinceEpoch}_botcomment_${_posts[idx].id}_$i',
              type: NotificationType.comment,
              postId: _posts[idx].id,
              postTitle: postTitle,
              actorName: botName,
              actorHandle: botHandle,
              timestamp: DateTime.now(),
              commentText: genericComments[commentIndex],
              isRead: false,
            ),
            _posts[idx].userId!,
          );
        }
        
        notifyListeners(); // Update UI after each comment
      }
    }
  }

  /// Add random bot likes to posts with delays
  Future<void> _addRandomBotLikes(Post post) async {
    final random = math.Random();
    // 90% chance to add 3-6 bot likes (increased from 70%)
    if (random.nextDouble() < 0.9) {
      final botLikes = 3 + random.nextInt(4); // 3, 4, 5, or 6 likes
      
      // Add likes with random delays (5-30 seconds between each)
      for (int i = 0; i < botLikes; i++) {
        // Random delay between 5-30 seconds
        final delaySeconds = 5 + random.nextInt(26);
        await Future.delayed(Duration(seconds: delaySeconds));
        
        // Find the post in the list
        final idx = _posts.indexWhere((p) => p.id == post.id);
        if (idx == -1) return; // Post was deleted
        
        // Increment likes BEFORE creating notification
        _posts[idx].likes++;
        notifyListeners(); // Update UI immediately
        
        // Create notification for bot like
        if (_posts[idx].userId != null && _notificationRepo != null) {
          final botSeed = random.nextInt(100000);
          final botName = _generateBotName(botSeed);
          final botHandle = _generateBotHandle(botSeed);
          final postPreview = _posts[idx].title.isNotEmpty ? _posts[idx].title : _posts[idx].body;
          final postTitle = postPreview.length > 50 ? '${postPreview.substring(0, 50)}...' : postPreview;
          
          _notificationRepo!.addNotification(
            AppNotification(
              id: '${DateTime.now().millisecondsSinceEpoch}_botlike_${_posts[idx].id}_$i',
              type: NotificationType.like,
              postId: _posts[idx].id,
              postTitle: postTitle,
              actorName: botName,
              actorHandle: botHandle,
              timestamp: DateTime.now(),
              isRead: false,
            ),
            _posts[idx].userId!,
          );
        }
      }
    }
  }

  /// Guaranteed bot like and comment after 40 seconds
  Future<void> _addGuaranteedBotActivity(Post post) async {
    final random = math.Random();
    
    // Wait 40 seconds
    await Future.delayed(const Duration(seconds: 40));
    
    // Find the post in the list and add guaranteed like
    final idx = _posts.indexWhere((p) => p.id == post.id);
    if (idx == -1) return; // Post was deleted
    
    // Increment likes BEFORE creating notification
    _posts[idx].likes++;
    notifyListeners(); // Update UI immediately
    
    final botSeed = random.nextInt(100000);
    final botName = _generateBotName(botSeed);
    final botHandle = _generateBotHandle(botSeed);
    
    // Create notification for guaranteed like
    if (_posts[idx].userId != null && _notificationRepo != null) {
      final postPreview = _posts[idx].title.isNotEmpty ? _posts[idx].title : _posts[idx].body;
      final postTitle = postPreview.length > 50 ? '${postPreview.substring(0, 50)}...' : postPreview;
      
      _notificationRepo!.addNotification(
        AppNotification(
          id: '${DateTime.now().millisecondsSinceEpoch}_guaranteed_like_${_posts[idx].id}',
          type: NotificationType.like,
          postId: _posts[idx].id,
          postTitle: postTitle,
          actorName: botName,
          actorHandle: botHandle,
          timestamp: DateTime.now(),
          isRead: false,
        ),
        _posts[idx].userId!,
      );
    }
    
    notifyListeners();
    
    // Add guaranteed comment
    final genericComments = [
      'Great post!',
      'Thanks for sharing!',
      'This is helpful!',
      'Interesting perspective!',
      'Well said!',
      'Love this!',
      'Totally agree!',
      'Good point!',
      'Nice work!',
      'Appreciate the insight!',
    ];
    
    final commentIndex = random.nextInt(genericComments.length);
    final commentBotSeed = random.nextInt(100000);
    final commentBotName = _generateBotName(commentBotSeed);
    final commentBotHandle = _generateBotHandle(commentBotSeed);
    
    final comment = Comment(
      authorHandle: commentBotHandle,
      authorName: commentBotName,
      text: genericComments[commentIndex],
      dateLabel: 'Just now',
      userId: 'bot_user_$commentBotSeed',
    );
    
    // Add comment to the post in the list
    final commentIdx = _posts.indexWhere((p) => p.id == post.id);
    if (commentIdx == -1) return; // Post was deleted
    
    _posts[commentIdx].comments.add(comment);
    
    // Create notification for guaranteed comment
    if (_posts[commentIdx].userId != null && _notificationRepo != null) {
      final postPreview = _posts[commentIdx].title.isNotEmpty ? _posts[commentIdx].title : _posts[commentIdx].body;
      final postTitle = postPreview.length > 50 ? '${postPreview.substring(0, 50)}...' : postPreview;
      
      _notificationRepo!.addNotification(
        AppNotification(
          id: '${DateTime.now().millisecondsSinceEpoch}_guaranteed_comment_${_posts[commentIdx].id}',
          type: NotificationType.comment,
          postId: _posts[commentIdx].id,
          postTitle: postTitle,
          actorName: commentBotName,
          actorHandle: commentBotHandle,
          timestamp: DateTime.now(),
          commentText: genericComments[commentIndex],
          isRead: false,
        ),
        _posts[commentIdx].userId!,
      );
    }
    
    notifyListeners();
  }

  @override
  void voteOnPoll(String postId, String optionId, String userId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    
    final post = _posts[idx];
    if (post.poll == null) return;
    
    // Remove user's vote from all options first (single vote per user)
    for (final option in post.poll!.options) {
      option.voterIds.remove(userId);
    }
    
    // Add vote to selected option
    final option = post.poll!.options.firstWhere(
      (opt) => opt.id == optionId,
      orElse: () => post.poll!.options.first,
    );
    option.voterIds.add(userId);
    
    notifyListeners();
  }

  @override
  List<Post> getPostsByTag(String tag) {
    return _posts
        .where((post) => post.tags.any((t) => t.toLowerCase() == tag.toLowerCase()))
        .map((p) => p.copy())
        .toList();
  }

  @override
  List<String> getAllTags() {
    final tagsSet = <String>{};
    for (final post in _posts) {
      tagsSet.addAll(post.tags);
    }
    return tagsSet.toList()..sort();
  }

  @override
  Future<bool> reportPost(String postId, String reason, String reporterId) async {
    // In a real app, this would send the report to a backend/moderation system
    if (!_reportedPosts.containsKey(postId)) {
      _reportedPosts[postId] = [];
    }
    
    if (!_reportedPosts[postId]!.contains(reporterId)) {
      _reportedPosts[postId]!.add(reporterId);
      // Simulate successful report
      return true;
    }
    return false; // Already reported by this user
  }

  @override
  void hidePost(String postId, String userId) {
    _hiddenPostIds.add(postId);
    notifyListeners();
  }

  @override
  bool isPostHidden(String postId, String userId) {
    return _hiddenPostIds.contains(postId);
  }

  // Static bot profiles data for quick access
  static final Map<String, Map<String, String>> _botProfiles = {
      // Jersey Village HS bots (our chapter)
      'bot_sarah_johnson': {
        'displayName': 'Sarah Johnson',
        'username': 'fbla_president',
        'bio': 'FBLA President | Passionate about leadership and business education | Nationals bound! 🏆',
        'event': 'Business Presentation',
        'chapter': 'Jersey Village HS',
        'grade': '12',
      },
      'bot_alex_chen': {
        'displayName': 'Alex Chen',
        'username': 'marketing_lead',
        'bio': 'Marketing enthusiast | Love creating campaigns that make a difference | Coffee addict ☕',
        'event': 'Marketing',
        'chapter': 'Jersey Village HS',
        'grade': '11',
      },
      'bot_marcus_davis': {
        'displayName': 'Marcus Davis',
        'username': 'finance_officer',
        'bio': 'Numbers never lie! Finance Officer passionate about accounting and financial literacy',
        'event': 'Accounting',
        'chapter': 'Jersey Village HS',
        'grade': '12',
      },
      'bot_emily_rodriguez': {
        'displayName': 'Emily Rodriguez',
        'username': 'community_service',
        'bio': 'Community Service Chair | Believe in giving back | Making our community better one project at a time',
        'event': 'Community Service Project',
        'chapter': 'Jersey Village HS',
        'grade': '10',
      },
      'bot_jordan_miller': {
        'displayName': 'Jordan Miller',
        'username': 'events_coordinator',
        'bio': 'Events Coordinator | Planning the best FBLA activities | Making memories together',
        'event': 'Event Planning',
        'chapter': 'Jersey Village HS',
        'grade': '11',
      },
      
      // California chapter bots
      'bot_sfhs_fbla': {
        'displayName': 'San Francisco HS FBLA',
        'username': 'sfhs_fbla',
        'bio': 'Official SFHS FBLA account | Best Chapter Award winners | Representing the Bay Area 🌉',
        'event': 'Chapter Activities',
        'chapter': 'San Francisco HS',
        'grade': 'Grad',
      },
      'bot_jessica_wong': {
        'displayName': 'Jessica Wong',
        'username': 'jessica_wong_ca',
        'bio': 'Tech enthusiast from SF | Building the future one line of code at a time | Future entrepreneur 💻',
        'event': 'Website Design',
        'chapter': 'San Francisco HS',
        'grade': '11',
      },
      
      // Texas chapter bots
      'bot_austin_fbla': {
        'displayName': 'Austin West FBLA',
        'username': 'austin_fbla',
        'bio': 'Official Austin West FBLA | Connecting Texas entrepreneurs | Keep Austin entrepreneurial! 🤠',
        'event': 'Entrepreneurship',
        'chapter': 'Austin West HS',
        'grade': 'Grad',
      },
      'bot_tyler_brooks': {
        'displayName': 'Tyler Brooks',
        'username': 'tyler_b_texas',
        'bio': 'Business management major in the making | Texas FBLA proud | Longhorns fan 🤘',
        'event': 'Business Management',
        'chapter': 'Austin West HS',
        'grade': '12',
      },
      
      // New York chapter bots
      'bot_madison_taylor': {
        'displayName': 'Madison Taylor',
        'username': 'madison_t_ny',
        'bio': 'NYC FBLA member | Economics nerd | Wall Street dreamer | Columbia bound 📈',
        'event': 'Economics',
        'chapter': 'Manhattan High',
        'grade': '12',
      },
      'bot_nyc_fbla_ig': {
        'displayName': 'NYC FBLA Chapter 📸',
        'username': 'newyork_fbla_ig',
        'bio': 'Official NYC FBLA Instagram | State Champions | #fbla25-26 | Posting from the Big Apple 🗽',
        'event': 'Business Plan',
        'chapter': 'New York FBLA',
        'grade': 'Grad',
      },
      
      // Seattle chapter bots
      'bot_seattle_fbla_x': {
        'displayName': 'Seattle Tech FBLA 🐦',
        'username': 'seattle_fbla_x',
        'bio': 'Seattle Tech FBLA on X | Microsoft Partnership | Coding & Innovation | #fbla25-26 ☕💻',
        'event': 'Coding & Programming',
        'chapter': 'Seattle Tech HS',
        'grade': 'Grad',
      },
      
      // System bot
      'fbla_bot_system': {
        'displayName': 'FBLA Helper Bot',
        'username': 'fbla_helper',
        'bio': 'Official FBLA community assistant | Here to help you succeed | Future Business Leaders! 🤖',
        'event': 'Chapter Activities',
        'chapter': 'National FBLA',
        'grade': 'Grad',
      },
    };
  
  /// Get bot profile data by userId
  static Map<String, String>? getBotProfile(String userId) {
    return _botProfiles[userId];
  }

  /// Seed bot profile data to Firebase (optional - for persistence)
  Future<void> seedBotProfiles() async {
    final firebaseService = FirebaseUserService();

    // Save each bot profile to Firebase
    for (final entry in _botProfiles.entries) {
      final userId = entry.key;
      final data = entry.value;
      
      try {
        await firebaseService.saveUserProfile(
          userId: userId,
          displayName: data['displayName']!,
          email: '$userId@fbla-bot.local',
          username: data['username'],
          bio: data['bio'],
          event: data['event'],
          chapter: data['chapter'],
          grade: data['grade'],
        );
        print('✓ Seeded profile for ${data['displayName']}');
      } catch (e) {
        print('✗ Error seeding ${data['displayName']}: $e');
      }
    }
  }
}
