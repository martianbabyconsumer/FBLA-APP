import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_3/main.dart';

void main() {
  test('add post and comment, notifications emitted', () {
    // reset services
  notificationService.clear();
  postRepository.clear();

  // create a post that belongs to the local user so notifications are relevant
  final p = Post(id: 't1', handle: '@you', displayName: 'You', dateLabel: 'Now', title: 'T', body: 'B', imageUrl: null);
    postRepository.addPost(p);
    expect(postRepository.getPosts().length, 1);

  // simulate another user liking the post so a notification is emitted
  postRepository.toggleLike('t1', actor: 'Other');
  expect(notificationService.items.isNotEmpty, true);

    notificationService.clear();
    final c = Comment(id: 'c1', author: 'X', text: 'nice', date: DateTime.now());
    postRepository.addComment('t1', c);
    final live = postRepository.getPostById('t1');
    expect(live, isNotNull);
    expect(live!.comments.length, 1);
    expect(notificationService.items.isNotEmpty, true);
  });
}
