import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:practicevskodin/data/models/comment.dart';
import 'package:practicevskodin/data/models/post.dart';
import 'package:practicevskodin/data/models/user.dart';

void main() {
  group('Post', () {
    test('JSON → Post', () {
      final post = Post.fromJson({
        'userId': 3,
        'id': 21,
        'title': 'asperiores ea ipsam',
        'body': 'line 1\nline 2',
      });

      expect(post.id, 21);
      expect(post.userId, 3);
      expect(post.title, 'asperiores ea ipsam');
      expect(post.body, 'line 1\nline 2');
      expect(post.isLocal, isFalse);
    });

    test('Post → JSON (без служебного флага isLocal)', () {
      const post = Post(
        id: 7,
        userId: 2,
        title: 'Title',
        body: 'Body text',
        isLocal: true,
      );

      expect(post.toJson(), {
        'id': 7,
        'userId': 2,
        'title': 'Title',
        'body': 'Body text',
      });
    });

    test('JSON → Post → JSON без потерь', () {
      final json = {'id': 1, 'userId': 1, 'title': 't', 'body': 'b'};
      expect(Post.fromJson(json).toJson(), json);
    });

    test('битый JSON даёт CheckedFromJsonException, а не падение', () {
      expect(
        () => Post.fromJson({'id': 'not-a-number', 'userId': 1, 'title': 't'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });

  test('JSON → Comment', () {
    final comment = Comment.fromJson({
      'postId': 1,
      'id': 5,
      'name': 'vero eaque',
      'email': 'Hayden@althea.biz',
      'body': 'harum non quasi',
    });
    expect(comment.postId, 1);
    expect(comment.email, 'Hayden@althea.biz');
  });

  test('JSON → User игнорирует лишние поля', () {
    final user = User.fromJson({
      'id': 1,
      'name': 'Leanne Graham',
      'username': 'Bret',
      'email': 'Sincere@april.biz',
      'address': {'city': 'Gwenborough'},
      'website': 'hildegard.org',
    });
    expect(user.name, 'Leanne Graham');
    expect(user.website, 'hildegard.org');
  });
}
