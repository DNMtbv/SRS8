import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practicevskodin/core/error/app_exception.dart';
import 'package:practicevskodin/core/notifications/notification_service.dart';
import 'package:practicevskodin/data/firebase/users_remote_data_source.dart';
import 'package:practicevskodin/data/models/registered_user.dart';
import 'package:practicevskodin/data/repositories/registration_repository.dart';
import 'package:practicevskodin/presentation/registration/registration_cubit.dart';
import 'package:practicevskodin/presentation/registration/registration_validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Вместо Realtime Database: запоминает сохранённые данные.
class FakeUsersRemote implements UsersRemoteDataSource {
  FakeUsersRemote({this.error, this.completer});

  Object? error;
  Completer<String>? completer;
  final saved = <Map<String, dynamic>>[];

  @override
  Future<String> saveUser(Map<String, dynamic> data) async {
    final e = error;
    if (e != null) throw e;
    saved.add(data);
    return completer?.future ?? Future.value('-Nkey${saved.length}');
  }
}

class FakePush implements PushNotifications {
  final shownFor = <String>[];

  @override
  String? get token => 'fcm-token-123';

  @override
  Future<void> showRegistrationSuccess(String name) async => shownFor.add(name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakeUsersRemote remote;
  late FakePush push;
  late RegistrationRepository repository;
  late RegistrationCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    remote = FakeUsersRemote();
    push = FakePush();
    repository = RegistrationRepository(remote: remote, prefs: prefs);
    cubit = RegistrationCubit(repository, push);
  });

  tearDown(() => cubit.close());

  Future<void> submit() => cubit.submit(
        name: '  Динмухаммед ',
        email: 'Test@Mail.KZ',
        phone: '+7 700 123 45 67',
        city: ' ',
      );

  test('RegisteredUser → JSON без пустых полей', () {
    const user = RegisteredUser(name: 'A', email: 'a@b.c', phone: '1234567890');
    expect(user.toJson(), {'name': 'A', 'email': 'a@b.c', 'phone': '1234567890'});
  });

  test('успешная регистрация: запись в базу, push и отметка на устройстве',
      () async {
    expect(repository.isRegistered, isFalse);

    await submit();

    expect(cubit.state.status, RegistrationStatus.success);
    expect(cubit.state.userKey, '-Nkey1');
    expect(remote.saved.single, {
      'name': 'Динмухаммед',
      'email': 'test@mail.kz',
      'phone': '+7 700 123 45 67',
      'fcmToken': 'fcm-token-123',
    });
    expect(push.shownFor, ['Динмухаммед']);
    expect(repository.isRegistered, isTrue);
    expect(repository.registeredName, 'Динмухаммед');
  });

  test('нет доступа к базе → понятная ошибка, push не отправляется', () async {
    remote.error = FirebaseException(
      plugin: 'firebase_database',
      code: 'permission-denied',
    );

    await submit();

    expect(cubit.state.status, RegistrationStatus.failure);
    expect(cubit.state.error, isA<BackendException>());
    expect(cubit.state.error!.message, contains('режим Test'));
    expect(push.shownFor, isEmpty);
    expect(repository.isRegistered, isFalse);
  });

  test('нет ответа от Firebase → TimeoutAppException', () async {
    remote.error = TimeoutException('set() timeout');

    await submit();

    expect(cubit.state.error, isA<TimeoutAppException>());
  });

  test('Firebase не настроен → BackendException', () async {
    cubit = RegistrationCubit(
      RegistrationRepository(
        remote: const UnavailableUsersDataSource(),
        prefs: prefs,
      ),
      push,
    );

    await submit();

    expect(cubit.state.error, isA<BackendException>());
    expect(cubit.state.error!.message, contains('google-services.json'));
  });

  test('повторное нажатие во время отправки не создаёт дубликат', () async {
    remote.completer = Completer<String>();

    final first = submit();
    final second = submit();
    expect(cubit.state.isSubmitting, isTrue);
    remote.completer!.complete('-Nonly');
    await Future.wait([first, second]);

    expect(remote.saved, hasLength(1));
    expect(push.shownFor, hasLength(1));
    expect(cubit.state.userKey, '-Nonly');
  });

  group('валидация регистрации', () {
    test('имя и email', () {
      expect(RegistrationValidators.name(' '), isNotNull);
      expect(RegistrationValidators.name('Ан'), isNull);
      expect(RegistrationValidators.email('user@'), isNotNull);
      expect(RegistrationValidators.email('user@mail.kz'), isNull);
    });

    test('телефон и город', () {
      expect(RegistrationValidators.phone('12345'), isNotNull);
      expect(RegistrationValidators.phone('+7 (700) 123-45-67'), isNull);
      expect(RegistrationValidators.phone('+7 700 abc'), isNotNull);
      expect(RegistrationValidators.city(''), isNull);
      expect(RegistrationValidators.city('a' * 51), isNotNull);
    });
  });
}
