import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:practicevskodin/core/network/dio_client.dart';
import 'package:practicevskodin/data/api/posts_api.dart';
import 'package:practicevskodin/data/cache/posts_cache.dart';
import 'package:practicevskodin/data/repositories/posts_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef FakeHandler = Future<ResponseBody> Function(RequestOptions options);

/// Mock-адаптер Dio: подменяет сеть и запоминает все запросы.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  FakeHandler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}

  List<RequestOptions> requestsTo(String path) =>
      requests.where((r) => r.path == path).toList();
}

ResponseBody jsonResponse(Object? data, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody rawResponse(String body, {int status = 200}) =>
    ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> postJson(int id, {int userId = 1, String? title}) => {
      'id': id,
      'userId': userId,
      'title': title ?? 'Post title $id',
      'body': 'Body of post $id',
    };

Map<String, dynamic> userJson(int id, String name) => {
      'id': id,
      'name': name,
      'username': 'user$id',
      'email': 'user$id@mail.kz',
    };

Map<String, dynamic> commentJson(int id, int postId, String name) => {
      'postId': postId,
      'id': id,
      'name': name,
      'email': 'comment$id@mail.kz',
      'body': 'Comment body $id',
    };

/// Страница из [count] постов, начиная с id = (page - 1) * 10 + 1.
List<Map<String, dynamic>> pageJson(int page, {int count = 10, int userId = 1}) =>
    [
      for (var i = 0; i < count; i++)
        postJson((page - 1) * 10 + i + 1, userId: userId),
    ];

int queryInt(RequestOptions o, String key) =>
    int.parse(o.queryParameters[key].toString());

class TestEnv {
  TestEnv(this.repository, this.adapter, this.prefs);

  final PostsRepository repository;
  final FakeAdapter adapter;
  final SharedPreferences prefs;
}

Future<TestEnv> createEnv(
  FakeHandler handler, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final adapter = FakeAdapter(handler);
  final client = DioClient(
    adapter: adapter,
    retryDelay: Duration.zero,
    enableLogging: false,
  );
  final repository = PostsRepository(
    api: PostsApi(client.dio),
    cache: PostsCache(sp),
  );
  return TestEnv(repository, adapter, sp);
}
