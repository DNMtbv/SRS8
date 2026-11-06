part of 'posts_bloc.dart';

sealed class PostsEvent {
  const PostsEvent();
}

/// Открытие экрана: кэш → сервер.
class PostsStarted extends PostsEvent {
  const PostsStarted();
}

/// Доскролл до конца списка.
class PostsNextPageRequested extends PostsEvent {
  const PostsNextPageRequested();
}

/// Pull-to-refresh.
class PostsRefreshRequested extends PostsEvent {
  const PostsRefreshRequested();
}

/// «Повторить» на полноэкранной ошибке.
class PostsRetryRequested extends PostsEvent {
  const PostsRetryRequested();
}

class PostsAuthorFilterChanged extends PostsEvent {
  const PostsAuthorFilterChanged(this.userId);

  final int? userId;
}

class PostsSortChanged extends PostsEvent {
  const PostsSortChanged(this.order);

  final SortOrder order;
}

class PostsSearchChanged extends PostsEvent {
  const PostsSearchChanged(this.text);

  final String text;
}

class PostsFiltersReset extends PostsEvent {
  const PostsFiltersReset();
}

/// Пост создан через форму и добавляется в список локально.
class PostsLocalPostAdded extends PostsEvent {
  const PostsLocalPostAdded(this.post);

  final Post post;
}
