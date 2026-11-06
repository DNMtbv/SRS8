abstract final class RegistrationValidators {
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Введите имя';
    if (v.length < 2) return 'Имя: минимум 2 символа';
    if (v.length > 50) return 'Имя: максимум 50 символов';
    return null;
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Введите email';
    if (!_email.hasMatch(v)) return 'Некорректный email';
    return null;
  }

  /// Допускаются +, пробелы, скобки и дефисы; цифр — от 10 до 15.
  static String? phone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Введите телефон';
    if (!RegExp(r'^\+?[\d\s()-]+$').hasMatch(v)) {
      return 'Только цифры, +, пробелы, скобки и дефисы';
    }
    final digits = v.replaceAll(RegExp(r'\D'), '').length;
    if (digits < 10 || digits > 15) return 'В номере должно быть 10–15 цифр';
    return null;
  }

  static String? city(String? value) {
    final v = (value ?? '').trim();
    if (v.length > 50) return 'Город: максимум 50 символов';
    return null;
  }
}
