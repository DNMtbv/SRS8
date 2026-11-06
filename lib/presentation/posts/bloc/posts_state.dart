part of 'posts_bloc.dart';

/// Состояние первой страницы / экрана целиком.
enum PostsStatus {
  initial,
  loading,
  success,

  /// Показаны данные из кэша (ещё не обновились или сервер недоступен).
  cached,

  /// Сервер вернул пустой список.
  empty,
  error,
}

/// Отдельное состояние подгрузки следующих страниц.
enum PageLoadStatus { idle, loading, error }

class PostsState extends Equatable {
  const PostsState({
    this.status = PostsStatus.initial,
    this.pageStatus = PageLoadStatus.idle,
    this.isRefreshing = false,
    this.posts = const [],
    this.localPosts = const [],
    this.users = const [],
    this.query = const PostsQuery(),
    this.search = '',
    this.page = 0,
    this.hasMore = true,
    this.error,
    this.pageError,
  });

  final PostsStatus status;
  final PageLoadStatus pageStatus;

  /// Идёт обновление первой страницы поверх уже показанных данных.
  final bool isRefreshing;

  /// Посты с сервера (или из кэша) в порядке загрузки.
  final List<Post> posts;

  /// Посты, созданные в приложении.
  final List<Post> localPosts;
  final List<User> users;
  final PostsQuery query;
  final String search;

  /// Номер последней загруженной страницы.
  final int page;
  final bool hasMore;

  /// Ошибка первой страницы (для status == error или cached).
  final AppException? error;

  /// Ошибка подгрузки следующей страницы.
  final AppException? pageError;

  /// Что реально видно в списке: локальные посты сверху, затем серверные,
  /// и всё это отфильтровано поиском по загруженному.
  List<Post> get visiblePosts {
    final userId = query.userId;
    final locals = userId == null
        ? localPosts
        : localPosts.where((p) => p.userId == userId).toList();
    return filterPostsByTitle([...locals, ...posts], search);
  }

  /// Сколько постов загружено (по ним идёт поиск).
  int get loadedCount => posts.length + localPosts.length;

  bool get hasActiveFilters =>
      search.isNotEmpty || query != const PostsQuery();

  User? userById(int id) {
    for (final u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  PostsState copyWith({
    PostsStatus? status,
    PageLoadStatus? pageStatus,
    bool? isRefreshing,
    List<Post>? posts,
    List<Post>? localPosts,
    List<User>? users,
    PostsQuery? query,
    String? search,
    int? page,
    bool? hasMore,
    AppException? Function()? error,
    AppException? Function()? pageError,
  }) =>
      PostsState(
        status: status ?? this.status,
        pageStatus: pageStatus ?? this.pageStatus,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        posts: posts ?? this.posts,
        localPosts: localPosts ?? this.localPosts,
        users: users ?? this.users,
        query: query ?? this.query,
        search: search ?? this.search,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        error: error != null ? error() : this.error,
        pageError: pageError != null ? pageError() : this.pageError,
      );

  @override
  List<Object?> get props => [
        status,
        pageStatus,
        isRefreshing,
        posts,
        localPosts,
        users,
        query,
        search,
        page,
        hasMore,
        error,
        pageError,
      ];
}
