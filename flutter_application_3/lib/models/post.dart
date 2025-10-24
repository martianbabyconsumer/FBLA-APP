class Post {
  final String id;
  final String handle;
  final String displayName;
  final String dateLabel;
  final String title;
  final String body;
  final bool liked;
  final int likes;
  final List<Comment> comments;
  final String? imageUrl;

  Post({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.dateLabel,
    required this.title,
    required this.body,
    this.liked = false,
    this.likes = 0,
    List<Comment>? comments,
    this.imageUrl,
  }) : comments = comments ?? [];

  Post copy({
    String? id,
    String? handle,
    String? displayName,
    String? dateLabel,
    String? title,
    String? body,
    bool? liked,
    int? likes,
    List<Comment>? comments,
    String? imageUrl,
  }) {
    return Post(
      id: id ?? this.id,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      dateLabel: dateLabel ?? this.dateLabel,
      title: title ?? this.title,
      body: body ?? this.body,
      liked: liked ?? this.liked,
      likes: likes ?? this.likes,
      comments: comments ?? List.from(this.comments),
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class Comment {
  final String authorHandle;
  final String authorName;
  final String text;
  final String dateLabel;
  final List<Comment> replies;

  Comment({
    required this.authorHandle,
    required this.authorName,
    required this.text,
    required this.dateLabel,
    List<Comment>? replies,
  }) : replies = replies ?? [];
}