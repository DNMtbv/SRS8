import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';

part 'posts_api.g.dart';

/// Описание REST API JSONPlaceholder. Реализацию генерирует retrofit_generator.
@RestApi()
abstract class PostsApi {
  factory PostsApi(Dio dio, {String? baseUrl}) = _PostsApi;

  /// GET /posts?_page=1&_limit=10 — список постов с пагинацией.
  @GET('/posts')
  Future<List<Post>> getPosts({
    @Query('_page') required int page,
    @Query('_limit') required int limit,
    @Query('_sort') String sort = 'id',
    @Query('_order') String order = 'asc',
  });

  /// GET /posts?userId={id} — посты одного автора (тоже с пагинацией).
  @GET('/posts')
  Future<List<Post>> getPostsByUser({
    @Query('userId') required int userId,
    @Query('_page') required int page,
    @Query('_limit') required int limit,
    @Query('_sort') String sort = 'id',
    @Query('_order') String order = 'asc',
  });

  /// GET /posts/{id} — один пост.
  @GET('/posts/{id}')
  Future<Post> getPost(@Path('id') int id);

  /// GET /posts/{id}/comments — комментарии к посту.
  @GET('/posts/{id}/comments')
  Future<List<Comment>> getComments(@Path('id') int postId);

  /// POST /posts — создание поста.
  @POST('/posts')
  Future<Post> createPost(@Body() CreatePostRequest request);

  /// GET /users — список авторов.
  @GET('/users')
  Future<List<User>> getUsers();

  /// GET /users/{id} — один автор.
  @GET('/users/{id}')
  Future<User> getUser(@Path('id') int id);
}
