import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:json_annotation/json_annotation.dart';

import '../logger.dart';
import 'app_exception.dart';

/// Единая точка превращения любых ошибок в [AppException].
///
/// Используется и в [ErrorInterceptor] (сетевые ошибки), и в репозитории
/// (ошибки разбора JSON, которые возникают уже после ответа Dio).
abstract final class ErrorMapper {
  static AppException map(Object error, [StackTrace? stackTrace]) {
    // Уже преобразованную ошибку не логируем повторно.
    if (error is AppException) return error;
    if (error is DioException && error.error is AppException) {
      return error.error as AppException;
    }

    final result = _map(error);
    AppLogger.error(
      'Ошибка: ${result.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
    return result;
  }

  static AppException _map(Object error) {
    if (error is DioException) {
      final inner = error.error;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          return const TimeoutAppException();
        case DioExceptionType.connectionError:
          return const NoInternetException();
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode ?? 0;
          if (code >= 500) return ServerErrorException(code);
          if (code >= 400) return ClientErrorException(code);
          return const UnknownAppException();
        case DioExceptionType.badCertificate:
        case DioExceptionType.cancel:
          return const UnknownAppException();
        case DioExceptionType.unknown:
          if (inner != null) {
            if (_isParseError(inner)) return const ParseException();
            // SocketException/HandshakeException без импорта dart:io.
            final text = inner.toString();
            if (text.contains('SocketException') ||
                text.contains('Failed host lookup') ||
                text.contains('Connection refused')) {
              return const NoInternetException();
            }
          }
          return const UnknownAppException();
      }
    }

    if (error is TimeoutException) return const TimeoutAppException();

    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => const BackendException(
            'Нет доступа к базе данных. Проверьте правила Realtime Database '
            '(режим Test).',
          ),
        'network-error' || 'disconnected' => const NoInternetException(),
        _ => const BackendException('Не удалось сохранить данные в Firebase.'),
      };
    }

    if (_isParseError(error)) return const ParseException();
    return const UnknownAppException();
  }

  static bool _isParseError(Object error) =>
      error is FormatException ||
      error is CheckedFromJsonException ||
      error is TypeError;
}
