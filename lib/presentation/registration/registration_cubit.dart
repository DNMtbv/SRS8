import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../core/logger.dart';
import '../../core/notifications/notification_service.dart';
import '../../data/models/registered_user.dart';
import '../../data/repositories/registration_repository.dart';

enum RegistrationStatus { idle, submitting, success, failure }

class RegistrationState extends Equatable {
  const RegistrationState({
    this.status = RegistrationStatus.idle,
    this.userKey,
    this.error,
  });

  final RegistrationStatus status;

  /// Ключ записи в /users после успешной регистрации.
  final String? userKey;
  final AppException? error;

  bool get isSubmitting => status == RegistrationStatus.submitting;

  @override
  List<Object?> get props => [status, userKey, error];
}

class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit(this._repository, this._push)
      : super(const RegistrationState());

  final RegistrationRepository _repository;
  final PushNotifications _push;

  Future<void> submit({
    required String name,
    required String email,
    required String phone,
    String? city,
  }) async {
    if (state.isSubmitting) return;
    emit(const RegistrationState(status: RegistrationStatus.submitting));

    final trimmedCity = city?.trim();
    final user = RegisteredUser(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      city: (trimmedCity?.isEmpty ?? true) ? null : trimmedCity,
      fcmToken: _push.token,
    );

    try {
      final key = await _repository.register(user);
      try {
        await _push.showRegistrationSuccess(user.name);
      } catch (e, s) {
        // Данные уже сохранены — сбой уведомления регистрацию не отменяет.
        AppLogger.error('Не удалось показать уведомление', error: e, stackTrace: s);
      }
      emit(RegistrationState(status: RegistrationStatus.success, userKey: key));
    } on AppException catch (e) {
      emit(RegistrationState(status: RegistrationStatus.failure, error: e));
    }
  }
}
