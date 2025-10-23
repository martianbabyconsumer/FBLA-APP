import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_3/main.dart';

void main() {
  setUp(() {
    notificationService.clear();
    postRepository.clear();
  });

  test('add comment and like top-level comment', () {
    final p = Post(id: 'p1', handle: '@a', displayName: 'A', dateLabel: 'Now', title: 'T', body: 'B', imageUrl: null);
    postRepository.addPost(p);
    final c = Comment(id: 'c1', author: 'B', text: 'First', date: DateTime.now());
    postRepository.addComment('p1', c);
    final live = postRepository.getPostById('p1')!;
    expect(live.comments.length, 1);

    // like the comment
    postRepository.toggleCommentLike('p1', 'c1');
    expect(live.comments.first.likes, 1);
    expect(live.comments.first.liked, true);

    // unlike
    postRepository.toggleCommentLike('p1', 'c1');
    expect(live.comments.first.likes, 0);
    expect(live.comments.first.liked, false);
  });
}
