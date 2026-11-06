abstract final class PostValidators {
  static const titleMin = 5;
  static const titleMax = 100;
  static const bodyMin = 10;
  static const bodyMax = 1000;

  static String? title(String? value) =>
      _length(value, titleMin, titleMax, 'Заголовок');

  static String? body(String? value) =>
      _length(value, bodyMin, bodyMax, 'Текст');

  static String? userId(int? value) =>
      value == null ? 'Выберите автора' : null;

  static String? _length(String? value, int min, int max, String field) {
    final length = (value ?? '').trim().length;
    if (length == 0) return '$field обязателен';
    if (length < min) return '$field: минимум $min символов (сейчас $length)';
    if (length > max) return '$field: максимум $max символов (сейчас $length)';
    return null;
  }
}
