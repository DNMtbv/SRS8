import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/posts_repository.dart';

enum UsersStatus { loading, success, error }

enum SubmitStatus { idle, submitting, success, failure }

class CreatePostState extends Equatable {
  const CreatePostState({
    this.usersStatus = UsersStatus.loading,
    this.users = const [],
    this.submitStatus = SubmitStatus.idle,
    this.created,
    this.error,
  });

  final UsersStatus usersStatus;
  final List<User> users;
  final SubmitStatus submitStatus;

  /// Ответ сервера на POST /posts.
  final Post? created;
  final AppException? error;

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  CreatePostState copyWith({
    UsersStatus? usersStatus,
    List<User>? users,
    SubmitStatus? submitStatus,
    Post? created,
    AppException? error,
  }) =>
      CreatePostState(
        usersStatus: usersStatus ?? this.usersStatus,
        users: users ?? this.users,
        submitStatus: submitStatus ?? this.submitStatus,
        created: created ?? this.created,
        error: error,
      );

  @override
  List<Object?> get props => [usersStatus, users, submitStatus, created, error];
}

class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit(this._repository) : super(const CreatePostState());

  final PostsRepository _repository;

  Future<void> loadUsers() async {
    final cached = _repository.cachedUsers();
    emit(state.copyWith(
      usersStatus: cached == null ? UsersStatus.loading : UsersStatus.success,
      users: cached,
    ));
    try {
      final users = await _repository.fetchUsers();
      emit(state.copyWith(usersStatus: UsersStatus.success, users: users));
    } on AppException catch (e) {
      if (state.users.isEmpty) {
        emit(state.copyWith(usersStatus: UsersStatus.error, error: e));
      }
    }
  }

  Future<void> submit({
    required int userId,
    required String title,
    required String body,
  }) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(submitStatus: SubmitStatus.submitting));
    try {
      final created = await _repository.createPost(
        userId: userId,
        title: title.trim(),
        body: body.trim(),
      );
      emit(state.copyWith(submitStatus: SubmitStatus.success, created: created));
    } on AppException catch (e) {
      emit(state.copyWith(submitStatus: SubmitStatus.failure, error: e));
    }
  }
}
