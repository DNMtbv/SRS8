import 'dart:developer' as developer;

/// Технический лог. Пользователь эти сообщения не видит.
abstract final class AppLogger {
  static void info(String message) =>
      developer.log(message, name: 'posts_app');

  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      developer.log(
        message,
        name: 'posts_app',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
}
