import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/comment.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/posts_repository.dart';

sealed class PostDetailsState extends Equatable {
  const PostDetailsState();

  @override
  List<Object?> get props => [];
}

class PostDetailsLoading extends PostDetailsState {
  const PostDetailsLoading();
}

class PostDetailsLoaded extends PostDetailsState {
  const PostDetailsLoaded({
    required this.post,
    required this.comments,
    this.author,
  });

  final Post post;
  final User? author;
  final List<Comment> comments;

  @override
  List<Object?> get props => [post, author, comments];
}

class PostDetailsError extends PostDetailsState {
  const PostDetailsError(this.error);

  final AppException error;

  @override
  List<Object?> get props => [error];
}

class PostDetailsCubit extends Cubit<PostDetailsState> {
  PostDetailsCubit(this._repository, this._initialPost)
      : super(const PostDetailsLoading());

  final PostsRepository _repository;
  final Post _initialPost;

  Future<void> load() async {
    // Локальный пост на сервере не существует: показываем то, что есть.
    if (_initialPost.isLocal) {
      User? author;
      try {
        author = await _repository.fetchUser(_initialPost.userId);
      } on AppException {
        author = null;
      }
      emit(PostDetailsLoaded(
        post: _initialPost,
        author: author,
        comments: const [],
      ));
      return;
    }

    emit(const PostDetailsLoading());
    try {
      final post = await _repository.fetchPost(_initialPost.id);
      final comments = await _repository.fetchComments(post.id);
      User? author;
      try {
        author = await _repository.fetchUser(post.userId);
      } on AppException {
        author = null;
      }
      emit(PostDetailsLoaded(post: post, author: author, comments: comments));
    } on AppException catch (e) {
      emit(PostDetailsError(e));
    }
  }
}
