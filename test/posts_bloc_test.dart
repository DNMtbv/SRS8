import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practicevskodin/data/models/post.dart';
import 'package:practicevskodin/data/repositories/posts_repository.dart';
import 'package:practicevskodin/presentation/create_post/post_validators.dart';
import 'package:practicevskodin/presentation/posts/bloc/posts_bloc.dart';
import 'package:practicevskodin/presentation/posts/posts_filter.dart';

import 'helpers/fake_adapter.dart';

/// Отвечает на /posts страницами из 10 постов, на /users — пустым списком.
FakeHandler pagedHandler({int totalPages = 10}) => (o) async {
      if (o.path == '/users') return jsonResponse(<Object>[]);
      final page = queryInt(o, '_page');
      if (page > totalPages) return jsonResponse(<Object>[]);
      return jsonResponse(pageJson(page));
    };

Future<PostsState> waitFor(
  PostsBloc bloc,
  bool Function(PostsState) predicate,
) async {
  if (predicate(bloc.state)) return bloc.state;
  return bloc.stream
      .firstWhere(predicate)
      .timeout(const Duration(seconds: 5));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('фильтрация', () {
    const posts = [
      Post(id: 1, userId: 1, title: 'Flutter и Dart', body: 'b'),
      Post(id: 2, userId: 1, title: 'Retrofit', body: 'b'),
      Post(id: 3, userId: 2, title: 'Всё про DART', body: 'b'),
    ];

    test('поиск по заголовку без учёта регистра', () {
      final result = filterPostsByTitle(posts, '  dart ');
      expect(result.map((p) => p.id), [1, 3]);
    });

    test('пустой запрос возвращает всё', () {
      expect(filterPostsByTitle(posts, ''), posts);
    });

    test('смена автора сбрасывает пагинацию и грузит /posts?userId=',
        () async {
      final env = await createEnv((o) async {
        if (o.path == '/users') return jsonResponse(<Object>[]);
        final userId = o.queryParameters['userId'];
        final page = queryInt(o, '_page');
        if (userId != null) {
          return jsonResponse(pageJson(page, count: 4, userId: 3));
        }
        return jsonResponse(pageJson(page));
      });
      final bloc = PostsBloc(env.repository)..add(const PostsStarted());
      await waitFor(bloc, (s) => s.status == PostsStatus.success);

      bloc.add(const PostsNextPageRequested());
      await waitFor(bloc, (s) => s.page == 2);
      expect(bloc.state.posts, hasLength(20));

      bloc.add(const PostsAuthorFilterChanged(3));
      final state = await waitFor(
        bloc,
        (s) => s.status == PostsStatus.success && s.query.userId == 3,
      );

      expect(state.page, 1);
      expect(state.posts, hasLength(4));
      expect(state.posts.every((p) => p.userId == 3), isTrue);
      expect(state.hasMore, isFalse);
      final last = env.adapter.requestsTo('/posts').last;
      expect(last.queryParameters['userId'], 3);
      expect(last.queryParameters['_page'], 1);
      await bloc.close();
    });

    test('поиск фильтрует только загруженные посты', () async {
      final env = await createEnv(pagedHandler());
      final bloc = PostsBloc(env.repository)..add(const PostsStarted());
      await waitFor(bloc, (s) => s.status == PostsStatus.success);

      bloc.add(const PostsSearchChanged('title 1'));
      final state = await waitFor(bloc, (s) => s.search == 'title 1');

      // Загружены 1..10: подходят «Post title 1» и «Post title 10».
      expect(state.visiblePosts.map((p) => p.id), [1, 10]);
      // Поиск не делает запросов к серверу.
      expect(env.adapter.requestsTo('/posts'), hasLength(1));
      await bloc.close();
    });
  });

  test('одна страница не грузится дважды', () async {
    final page2 = Completer<ResponseBody>();
    final env = await createEnv((o) async {
      if (o.path == '/users') return jsonResponse(<Object>[]);
      final page = queryInt(o, '_page');
      if (page == 2) return page2.future;
      return jsonResponse(pageJson(page));
    });
    final bloc = PostsBloc(env.repository)..add(const PostsStarted());
    await waitFor(bloc, (s) => s.status == PostsStatus.success);

    // Пользователь дёргает скролл несколько раз подряд.
    bloc
      ..add(const PostsNextPageRequested())
      ..add(const PostsNextPageRequested())
      ..add(const PostsNextPageRequested());
    await waitFor(bloc, (s) => s.pageStatus == PageLoadStatus.loading);
    bloc.add(const PostsNextPageRequested());

    page2.complete(jsonResponse(pageJson(2)));
    final state = await waitFor(
      bloc,
      (s) => s.page == 2 && s.pageStatus == PageLoadStatus.idle,
    );

    final page2Requests = env.adapter
        .requestsTo('/posts')
        .where((r) => queryInt(r, '_page') == 2);
    expect(page2Requests, hasLength(1));
    expect(state.posts, hasLength(20));
    expect(state.posts.map((p) => p.id).toSet(), hasLength(20));
    await bloc.close();
  });

  test('ошибка подгрузки страницы → «Повторить» грузит её снова', () async {
    var failPage2 = true;
    final env = await createEnv((o) async {
      if (o.path == '/users') return jsonResponse(<Object>[]);
      final page = queryInt(o, '_page');
      if (page == 2 && failPage2) return jsonResponse({}, status: 503);
      return jsonResponse(pageJson(page));
    });
    final bloc = PostsBloc(env.repository)..add(const PostsStarted());
    await waitFor(bloc, (s) => s.status == PostsStatus.success);

    bloc.add(const PostsNextPageRequested());
    await waitFor(bloc, (s) => s.pageStatus == PageLoadStatus.error);
    expect(bloc.state.posts, hasLength(10));

    failPage2 = false;
    bloc.add(const PostsNextPageRequested());
    final state = await waitFor(bloc, (s) => s.page == 2);
    expect(state.posts, hasLength(20));
    await bloc.close();
  });

  test('сначала кэш, затем сервер; ошибка сети кэш не стирает', () async {
    final cached = jsonEncode(pageJson(1, count: 10));
    final env = await createEnv(
      (o) async => throw DioException.connectionError(
        requestOptions: o,
        reason: 'offline',
      ),
      prefs: {'cache.posts.user=all;order=asc': cached},
    );

    final bloc = PostsBloc(env.repository);
    final states = <PostsState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const PostsStarted());

    final state = await waitFor(
      bloc,
      (s) => s.status == PostsStatus.cached && !s.isRefreshing,
    );

    expect(
      states.any((s) => s.status == PostsStatus.cached && s.isRefreshing),
      isTrue,
      reason: 'кэш показан до ответа сервера',
    );
    expect(state.posts, hasLength(10));
    expect(state.error, isNotNull);
    expect(env.repository.cachedFirstPage(const PostsQuery()), hasLength(10));
    await sub.cancel();
    await bloc.close();
  });

  group('валидация формы', () {
    test('title от 5 до 100 символов', () {
      expect(PostValidators.title('abcd'), isNotNull);
      expect(PostValidators.title('abcde'), isNull);
      expect(PostValidators.title('a' * 101), isNotNull);
    });

    test('body от 10 до 1000 символов, автор обязателен', () {
      expect(PostValidators.body('123456789'), isNotNull);
      expect(PostValidators.body('1234567890'), isNull);
      expect(PostValidators.body('a' * 1001), isNotNull);
      expect(PostValidators.userId(null), isNotNull);
      expect(PostValidators.userId(1), isNull);
    });
  });
}
