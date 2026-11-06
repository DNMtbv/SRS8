import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/post.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/posts_repository.dart';
import '../posts_filter.dart';

part 'posts_event.dart';
part 'posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  PostsBloc(this._repository) : super(const PostsState()) {
    on<PostsStarted>(_onStarted);
    on<PostsNextPageRequested>(_onNextPage);
    on<PostsRefreshRequested>((_, emit) => _loadFirstPage(emit, refresh: true));
    on<PostsRetryRequested>((_, emit) => _loadFirstPage(emit));
    on<PostsAuthorFilterChanged>(_onAuthorChanged);
    on<PostsSortChanged>(_onSortChanged);
    on<PostsSearchChanged>((e, emit) => emit(state.copyWith(search: e.text)));
    on<PostsFiltersReset>(_onFiltersReset);
    on<PostsLocalPostAdded>(_onLocalPostAdded);
  }

  final PostsRepository _repository;

  /// Растёт при каждой перезагрузке первой страницы. Ответы со старым
  /// номером (например, после смены фильтра) отбрасываются.
  int _generation = 0;

  /// Страница, которая грузится прямо сейчас: защита от двойной загрузки.
  int? _loadingPage;

  Future<void> _onStarted(PostsStarted event, Emitter<PostsState> emit) async {
    emit(state.copyWith(
      localPosts: _repository.localPosts(),
      users: _repository.cachedUsers() ?? const [],
    ));
    await Future.wait([
      _loadFirstPage(emit),
      _loadUsers(emit),
    ]);
  }

  Future<void> _loadUsers(Emitter<PostsState> emit) async {
    try {
      final users = await _repository.fetchUsers();
      emit(state.copyWith(users: users));
    } on AppException {
      // Без списка авторов список постов всё равно работает.
    }
  }

  /// Загружает первую страницу. Новый [query] применяется в том же emit,
  /// что и сброс страниц, чтобы не было промежуточного состояния.
  Future<void> _loadFirstPage(
    Emitter<PostsState> emit, {
    bool refresh = false,
    PostsQuery? query,
    String? search,
  }) async {
    final generation = ++_generation;
    _loadingPage = null;
    query ??= state.query;

    // Что показать, если сервер не ответит: при pull-to-refresh — текущий
    // список, иначе — сохранённую первую страницу.
    final fallback = refresh && state.posts.isNotEmpty
        ? null
        : _repository.cachedFirstPage(query);

    if (refresh && state.posts.isNotEmpty) {
      emit(state.copyWith(isRefreshing: true));
    } else if (fallback != null && fallback.isNotEmpty) {
      emit(state.copyWith(
        query: query,
        search: search,
        status: PostsStatus.cached,
        posts: fallback,
        page: 1,
        hasMore: fallback.length == PostsRepository.pageSize,
        pageStatus: PageLoadStatus.idle,
        isRefreshing: true,
        error: () => null,
        pageError: () => null,
      ));
    } else {
      emit(state.copyWith(
        query: query,
        search: search,
        status: PostsStatus.loading,
        posts: const [],
        page: 0,
        hasMore: true,
        pageStatus: PageLoadStatus.idle,
        isRefreshing: false,
        error: () => null,
        pageError: () => null,
      ));
    }

    try {
      final posts = await _repository.fetchPosts(page: 1, query: query);
      if (generation != _generation) return;
      emit(state.copyWith(
        status: posts.isEmpty && state.localPosts.isEmpty
            ? PostsStatus.empty
            : PostsStatus.success,
        posts: posts,
        page: 1,
        hasMore: posts.length == PostsRepository.pageSize,
        pageStatus: PageLoadStatus.idle,
        isRefreshing: false,
        error: () => null,
        pageError: () => null,
      ));
    } on AppException catch (e) {
      if (generation != _generation) return;
      // Ошибка сети не стирает уже показанные данные.
      if (state.posts.isNotEmpty) {
        emit(state.copyWith(
          status: PostsStatus.cached,
          isRefreshing: false,
          error: () => e,
        ));
      } else {
        emit(state.copyWith(
          status: PostsStatus.error,
          isRefreshing: false,
          error: () => e,
        ));
      }
    }
  }

  Future<void> _onNextPage(
    PostsNextPageRequested event,
    Emitter<PostsState> emit,
  ) async {
    final canLoad = (state.status == PostsStatus.success ||
            state.status == PostsStatus.cached) &&
        state.hasMore &&
        !state.isRefreshing &&
        state.pageStatus != PageLoadStatus.loading &&
        _loadingPage == null;
    if (!canLoad) return;

    final generation = _generation;
    final nextPage = state.page + 1;
    _loadingPage = nextPage;
    emit(state.copyWith(
      pageStatus: PageLoadStatus.loading,
      pageError: () => null,
    ));

    try {
      final posts =
          await _repository.fetchPosts(page: nextPage, query: state.query);
      if (generation != _generation) return;
      final knownIds = state.posts.map((p) => p.id).toSet();
      emit(state.copyWith(
        posts: [...state.posts, ...posts.where((p) => !knownIds.contains(p.id))],
        page: nextPage,
        hasMore: posts.length == PostsRepository.pageSize,
        pageStatus: PageLoadStatus.idle,
      ));
    } on AppException catch (e) {
      if (generation != _generation) return;
      emit(state.copyWith(
        pageStatus: PageLoadStatus.error,
        pageError: () => e,
      ));
    } finally {
      if (generation == _generation) _loadingPage = null;
    }
  }

  Future<void> _onAuthorChanged(
    PostsAuthorFilterChanged event,
    Emitter<PostsState> emit,
  ) async {
    if (event.userId == state.query.userId) return;
    await _loadFirstPage(
      emit,
      query: PostsQuery(userId: event.userId, order: state.query.order),
    );
  }

  Future<void> _onSortChanged(
    PostsSortChanged event,
    Emitter<PostsState> emit,
  ) async {
    if (event.order == state.query.order) return;
    await _loadFirstPage(
      emit,
      query: PostsQuery(userId: state.query.userId, order: event.order),
    );
  }

  Future<void> _onFiltersReset(
    PostsFiltersReset event,
    Emitter<PostsState> emit,
  ) async {
    if (state.query == const PostsQuery()) {
      emit(state.copyWith(search: ''));
    } else {
      await _loadFirstPage(emit, query: const PostsQuery(), search: '');
    }
  }

  void _onLocalPostAdded(PostsLocalPostAdded event, Emitter<PostsState> emit) {
    emit(state.copyWith(
      localPosts: [event.post.copyWith(isLocal: true), ...state.localPosts],
      status: state.status == PostsStatus.empty ? PostsStatus.success : null,
    ));
  }
}
