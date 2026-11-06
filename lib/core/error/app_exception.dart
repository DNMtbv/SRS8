/// Ошибки приложения. Слой UI видит только их, а не DioException.
///
/// [message] — понятный пользователю текст, технические детали уходят в лог.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Нет подключения к сети / сервер недоступен.
class NoInternetException extends AppException {
  const NoInternetException()
      : super('Нет подключения к интернету. Проверьте сеть и попробуйте снова.');
}

/// Сервер не ответил за отведённое время.
class TimeoutAppException extends AppException {
  const TimeoutAppException()
      : super('Сервер слишком долго не отвечает. Попробуйте позже.');
}

/// Ответ 4xx: запрос некорректен или ресурс не найден.
class ClientErrorException extends AppException {
  ClientErrorException(this.statusCode)
      : super(statusCode == 404
            ? 'Данные не найдены (ошибка 404).'
            : 'Некорректный запрос (ошибка $statusCode).');

  final int statusCode;
}

/// Ответ 5xx: проблема на стороне сервера.
class ServerErrorException extends AppException {
  ServerErrorException(this.statusCode)
      : super('Ошибка на сервере ($statusCode). Попробуйте позже.');

  final int statusCode;
}

/// Сервер прислал данные, которые не удалось разобрать.
class ParseException extends AppException {
  const ParseException()
      : super('Сервер прислал некорректные данные.');
}

/// Ошибка Firebase (нет доступа к базе, проект не настроен и т. п.).
class BackendException extends AppException {
  const BackendException(super.message);
}

/// Всё остальное.
class UnknownAppException extends AppException {
  const UnknownAppException()
      : super('Что-то пошло не так. Попробуйте ещё раз.');
}
