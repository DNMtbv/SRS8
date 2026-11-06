import 'package:dio/dio.dart';

import '../error/error_mapper.dart';
import '../logger.dart';

/// Добавляет общие заголовки к каждому запросу.
class HeadersInterceptor extends Interceptor {
  int _counter = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll({
      Headers.acceptHeader: Headers.jsonContentType,
      'X-Client': 'posts-app/1.0',
      'X-Request-Id': '${DateTime.now().millisecondsSinceEpoch}-${_counter++}',
    });
    handler.next(options);
  }
}

/// Retry policy: повторяет GET-запросы при таймауте, обрыве сети и 5xx
/// с экспоненциальной задержкой. POST не повторяется, чтобы не создать
/// дубликат.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  static const _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxRetries) {
      return handler.next(err);
    }

    final delay = baseDelay * (1 << attempt);
    AppLogger.info(
      'Повтор ${attempt + 1}/$maxRetries для ${options.uri} через '
      '${delay.inMilliseconds} мс',
    );
    await Future<void>.delayed(delay);

    options.extra[_attemptKey] = attempt + 1;
    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        return (err.response?.statusCode ?? 0) >= 500;
      default:
        return false;
    }
  }
}

/// Централизованная обработка ошибок: кладёт в DioException уже
/// преобразованную [AppException], чтобы выше по стеку разбирать её одинаково.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: ErrorMapper.map(err, err.stackTrace)));
  }
}
