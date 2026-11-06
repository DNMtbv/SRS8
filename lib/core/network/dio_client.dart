import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../logger.dart';
import 'interceptors.dart';

/// Единственный Dio на всё приложение. Создаётся один раз в main()
/// и передаётся дальше через DI; UI к нему не обращается.
class DioClient {
  DioClient({
    String baseUrl = defaultBaseUrl,
    HttpClientAdapter? adapter,
    Duration retryDelay = const Duration(milliseconds: 500),
    bool enableLogging = kDebugMode,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 10),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
          ),
        ) {
    if (adapter != null) dio.httpClientAdapter = adapter;

    dio.interceptors.addAll([
      HeadersInterceptor(),
      if (enableLogging)
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          logPrint: (o) => AppLogger.info(o.toString()),
        ),
      RetryInterceptor(dio: dio, baseDelay: retryDelay),
      ErrorInterceptor(),
    ]);
  }

  static const defaultBaseUrl = 'https://jsonplaceholder.typicode.com';

  final Dio dio;
}
