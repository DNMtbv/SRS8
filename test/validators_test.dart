import 'package:flutter_test/flutter_test.dart';
import 'package:practicevskodin/presentation/create_post/post_validators.dart';
import 'package:practicevskodin/presentation/registration/registration_validators.dart';

void main() {
  group('RegistrationValidators.name', () {
    test('пустое значение, null и одни пробелы → просит ввести имя', () {
      for (final value in [null, '', '     ']) {
        expect(RegistrationValidators.name(value), 'Введите имя');
      }
    });

    test('границы длины: 1 — ошибка, 2 и 50 — можно, 51 — ошибка', () {
      expect(RegistrationValidators.name('А'), 'Имя: минимум 2 символа');
      expect(RegistrationValidators.name('Ан'), isNull);
      expect(RegistrationValidators.name('а' * 50), isNull);
      expect(RegistrationValidators.name('а' * 51), 'Имя: максимум 50 символов');
    });

    test('пробелы по краям в длину не считаются', () {
      expect(RegistrationValidators.name('   А   '), 'Имя: минимум 2 символа');
    });
  });

  group('RegistrationValidators.email', () {
    test('принимает корректные адреса', () {
      for (final value in [
        'user@mail.kz',
        'first.last+tag@sub.domain.com',
        '  user@mail.kz  ',
      ]) {
        expect(RegistrationValidators.email(value), isNull, reason: value);
      }
    });

    test('отклоняет адреса без @, домена или с пробелом', () {
      for (final value in [
        'user',
        'user@',
        '@mail.kz',
        'user@mail',
        'user mail@mail.kz',
        'user@mail..kz',
      ]) {
        expect(
          RegistrationValidators.email(value),
          'Некорректный email',
          reason: value,
        );
      }
    });

    test('пустое значение → просит ввести email', () {
      expect(RegistrationValidators.email('   '), 'Введите email');
    });
  });

  group('RegistrationValidators.phone', () {
    const lengthError = 'В номере должно быть 10–15 цифр';
    const charsError = 'Только цифры, +, пробелы, скобки и дефисы';

    test('разделители разрешены и в подсчёте цифр не участвуют', () {
      expect(RegistrationValidators.phone('+7 (700) 123-45-67'), isNull);
      expect(RegistrationValidators.phone('87001234567'), isNull);
    });

    test('границы количества цифр: 9 и 16 — ошибка, 10 и 15 — можно', () {
      expect(RegistrationValidators.phone('1' * 9), lengthError);
      expect(RegistrationValidators.phone('1' * 10), isNull);
      expect(RegistrationValidators.phone('1' * 15), isNull);
      expect(RegistrationValidators.phone('1' * 16), lengthError);
    });

    test('только разделители без цифр → ошибка количества цифр', () {
      expect(RegistrationValidators.phone('(---)'), lengthError);
    });

    test('буквы и + не в начале номера запрещены', () {
      expect(RegistrationValidators.phone('+7 700 abc 45 67'), charsError);
      expect(RegistrationValidators.phone('8700+1234567'), charsError);
    });
  });

  group('RegistrationValidators.city', () {
    test('поле необязательное: null, пусто и пробелы — можно', () {
      for (final value in [null, '', '   ']) {
        expect(RegistrationValidators.city(value), isNull);
      }
    });

    test('граница длины: 50 — можно, 51 — ошибка', () {
      expect(RegistrationValidators.city('а' * 50), isNull);
      expect(
        RegistrationValidators.city('а' * 51),
        'Город: максимум 50 символов',
      );
    });
  });

  group('PostValidators', () {
    test('заголовок из одних пробелов считается пустым', () {
      expect(PostValidators.title('     '), 'Заголовок обязателен');
      expect(PostValidators.title(null), 'Заголовок обязателен');
    });

    test('сообщение называет текущую длину без учёта пробелов по краям', () {
      expect(
        PostValidators.title('  abc  '),
        'Заголовок: минимум 5 символов (сейчас 3)',
      );
      expect(
        PostValidators.body('a' * 1001),
        'Текст: максимум 1000 символов (сейчас 1001)',
      );
    });

    test('верхняя граница включена в допустимый диапазон', () {
      expect(PostValidators.title('a' * PostValidators.titleMax), isNull);
      expect(PostValidators.body('a' * PostValidators.bodyMax), isNull);
    });
  });
}
