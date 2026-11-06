import '../../core/error/app_exception.dart';
import '../../core/error/error_mapper.dart';
import '../api/posts_api.dart';
import '../cache/posts_cache.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';

enum SortOrder {
  asc('asc'),
  desc('desc');

  const SortOrder(this.apiValue);

  final String apiValue;
}

/// Параметры серверного запроса списка. При их смене пагинация сбрасывается.
class PostsQuery {
  const PostsQuery({this.userId, this.order = SortOrder.asc});

  final int? userId;
  final SortOrder order;

  /// Ключ для кэша: у каждого набора фильтров своя первая страница.
  String get cacheKey => 'user=${userId ?? 'all'};order=${order.apiValue}';

  @override
  bool operator ==(Object other) =>
      other is PostsQuery && other.userId == userId && other.order == order;

  @override
  int get hashCode => Object.hash(userId, order);
}

/// Единственная точка доступа к данным для слоя состояния.
/// Все ошибки наружу выходят только как [AppException].
class PostsRepository {
  PostsRepository({required this._api, required this._cache});

  final PostsApi _api;
  final PostsCache _cache;

  static const pageSize = 10;

  /// Первая страница из кэша для данного запроса (или null).
  List<Post>? cachedFirstPage(PostsQuery query) =>
      _cache.readPosts(query.cacheKey);

  /// Загрузка страницы с сервера. Первая страница сохраняется в кэш;
  /// при ошибке кэш не трогаем.
  Future<List<Post>> fetchPosts({
    required int page,
    PostsQuery query = const PostsQuery(),
  }) =>
      _guard(() async {
        final userId = query.userId;
        final posts = userId == null
            ? await _api.getPosts(
                page: page,
                limit: pageSize,
                order: query.order.apiValue,
              )
            : await _api.getPostsByUser(
                userId: userId,
                page: page,
                limit: pageSize,
                order: query.order.apiValue,
              );
        if (page == 1) await _cache.savePosts(query.cacheKey, posts);
        return posts;
      });

  Future<Post> fetchPost(int id) => _guard(() => _api.getPost(id));

  Future<List<Comment>> fetchComments(int postId) =>
      _guard(() => _api.getComments(postId));

  Future<User> fetchUser(int id) => _guard(() async {
        final cached = _cache.readUsers()?.where((u) => u.id == id);
        try {
          return await _api.getUser(id);
        } catch (_) {
          if (cached != null && cached.isNotEmpty) return cached.first;
          rethrow;
        }
      });

  /// Авторы нужны для фильтра и формы: при ошибке сети отдаём кэш.
  Future<List<User>> fetchUsers() => _guard(() async {
        try {
          final users = await _api.getUsers();
          await _cache.saveUsers(users);
          return users;
        } catch (_) {
          final cached = _cache.readUsers();
          if (cached != null && cached.isNotEmpty) return cached;
          rethrow;
        }
      });

  List<User>? cachedUsers() => _cache.readUsers();

  /// POST /posts. Возвращает ответ сервера как есть; в локальный список
  /// пост попадает с флагом isLocal, так как API его не сохраняет.
  Future<Post> createPost({
    required int userId,
    required String title,
    required String body,
  }) =>
      _guard(() async {
        final created = await _api.createPost(
          CreatePostRequest(userId: userId, title: title, body: body),
        );
        final local = created.copyWith(isLocal: true);
        await _cache.saveLocalPosts([local, ..._cache.readLocalPosts()]);
        return created;
      });

  List<Post> localPosts() => _cache.readLocalPosts();

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, s) {
      throw ErrorMapper.map(e, s);
    }
  }
}
