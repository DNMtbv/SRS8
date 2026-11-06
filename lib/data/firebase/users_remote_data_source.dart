import 'package:firebase_database/firebase_database.dart';

import '../../core/error/app_exception.dart';

/// Удалённое хранилище пользователей.
abstract interface class UsersRemoteDataSource {
  /// Сохраняет пользователя и возвращает его ключ в базе.
  Future<String> saveUser(Map<String, dynamic> data);
}

/// Firebase Realtime Database: каждый пользователь — узел /users/{pushKey}.
class FirebaseUsersDataSource implements UsersRemoteDataSource {
  FirebaseUsersDataSource(this._database);

  final FirebaseDatabase _database;

  @override
  Future<String> saveUser(Map<String, dynamic> data) async {
    final ref = _database.ref('users').push();
    // Без сети set() не завершается (запись ждёт в очереди SDK),
    // поэтому ограничиваем ожидание.
    await ref.set({
      ...data,
      'createdAt': ServerValue.timestamp,
    }).timeout(const Duration(seconds: 15));
    return ref.key!;
  }
}

/// Используется, если Firebase не удалось инициализировать.
class UnavailableUsersDataSource implements UsersRemoteDataSource {
  const UnavailableUsersDataSource();

  @override
  Future<String> saveUser(Map<String, dynamic> data) async =>
      throw const BackendException(
        'Firebase не настроен: добавьте android/app/google-services.json '
        'и перезапустите приложение.',
      );
}
