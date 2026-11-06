import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practicevskodin/core/error/app_exception.dart';
import 'package:practicevskodin/data/repositories/posts_repository.dart';

import 'helpers/fake_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('успешная загрузка страницы через репозиторий', () async {
    final env = await createEnv((o) async => jsonResponse(pageJson(1)));

    final posts = await env.repository.fetchPosts(page: 1);

    expect(posts, hasLength(10));
    expect(posts.first.id, 1);

    final request = env.adapter.requests.single;
    expect(request.path, '/posts');
    expect(request.queryParameters['_page'], 1);
    expect(request.queryParameters['_limit'], 10);
    expect(request.headers['X-Client'], 'posts-app/1.0');

    // Первая страница сохранена в кэш.
    expect(env.repository.cachedFirstPage(const PostsQuery()), posts);
  });

  test('фильтр по автору идёт запросом /posts?userId=', () async {
    final env = await createEnv(
      (o) async => jsonResponse(pageJson(1, count: 3, userId: 4)),
    );

    final posts = await env.repository
        .fetchPosts(page: 1, query: const PostsQuery(userId: 4));

    expect(posts.every((p) => p.userId == 4), isTrue);
    expect(env.adapter.requests.single.queryParameters['userId'], 4);
  });

  test('ошибка сервера 500 → ServerErrorException после повторов', () async {
    final env = await createEnv((o) async => jsonResponse({}, status: 500));

    await expectLater(
      env.repository.fetchPosts(page: 1),
      throwsA(isA<ServerErrorException>()
          .having((e) => e.statusCode, 'statusCode', 500)),
    );
    // Retry policy: исходный запрос + 2 повтора.
    expect(env.adapter.requests, hasLength(3));
  });

  test('ошибка 404 → ClientErrorException без повторов', () async {
    final env = await createEnv((o) async => jsonResponse({}, status: 404));

    await expectLater(
      env.repository.fetchPost(999),
      throwsA(isA<ClientErrorException>()),
    );
    expect(env.adapter.requests, hasLength(1));
  });

  test('нет сети → NoInternetException', () async {
    final env = await createEnv(
      (o) async => throw DioException.connectionError(
        requestOptions: o,
        reason: 'SocketException: Failed host lookup',
      ),
    );

    await expectLater(
      env.repository.fetchPosts(page: 1),
      throwsA(isA<NoInternetException>()),
    );
  });

  test('таймаут → TimeoutAppException', () async {
    final env = await createEnv(
      (o) async => throw DioException.receiveTimeout(
        requestOptions: o,
        timeout: const Duration(seconds: 15),
      ),
    );

    await expectLater(
      env.repository.fetchPosts(page: 1),
      throwsA(isA<TimeoutAppException>()),
    );
  });

  test('битый JSON → ParseException, кэш не стирается', () async {
    final env = await createEnv((o) async => jsonResponse(pageJson(1)));
    await env.repository.fetchPosts(page: 1);

    env.adapter.handler = (o) async => jsonResponse([
          {'id': 'oops', 'title': null},
        ]);
    await expectLater(
      env.repository.fetchPosts(page: 1),
      throwsA(isA<ParseException>()),
    );

    env.adapter.handler = (o) async => rawResponse('{not json');
    await expectLater(
      env.repository.fetchPosts(page: 1),
      throwsA(isA<ParseException>()),
    );

    expect(env.repository.cachedFirstPage(const PostsQuery()), hasLength(10));
  });

  test('POST /posts через mock-адаптер', () async {
    final env = await createEnv((o) async {
      final sent = o.data is String ? jsonDecode(o.data as String) : o.data;
      return jsonResponse({...sent as Map<String, dynamic>, 'id': 101},
          status: 201);
    });

    final created = await env.repository.createPost(
      userId: 2,
      title: 'Новый пост',
      body: 'Текст нового поста',
    );

    final request = env.adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/posts');
    expect(request.data, {
      'userId': 2,
      'title': 'Новый пост',
      'body': 'Текст нового поста',
    });
    expect(created.id, 101);
    expect(created.title, 'Новый пост');

    // POST не повторяется retry policy и сохраняется локально.
    final local = env.repository.localPosts();
    expect(local.single.isLocal, isTrue);
    expect(local.single.title, 'Новый пост');
  });
}
