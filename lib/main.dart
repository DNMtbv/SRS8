import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/firebase_config.dart';
import 'core/logger.dart';
import 'core/network/dio_client.dart';
import 'core/notifications/notification_service.dart';
import 'data/api/posts_api.dart';
import 'data/cache/posts_cache.dart';
import 'data/firebase/users_remote_data_source.dart';
import 'data/repositories/posts_repository.dart';
import 'data/repositories/registration_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Firebase берёт настройки из android/app/google-services.json.
  // Если его нет, приложение работает, но регистрация сообщит об ошибке.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e, s) {
    AppLogger.error('Firebase не инициализирован', error: e, stackTrace: s);
  }

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  final notifications = NotificationService(
    messaging: firebaseReady ? FirebaseMessaging.instance : null,
  );
  try {
    await notifications.init();
  } catch (e, s) {
    AppLogger.error('Уведомления не инициализированы', error: e, stackTrace: s);
  }

  // Сборка зависимостей: Dio → Retrofit API → Repository → Bloc → UI.
  final dioClient = DioClient();
  final postsRepository = PostsRepository(
    api: PostsApi(dioClient.dio),
    cache: PostsCache(prefs),
  );

  final UsersRemoteDataSource usersRemote;
  if (firebaseReady) {
    final database = realtimeDatabaseUrl == null
        ? FirebaseDatabase.instance
        : FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: realtimeDatabaseUrl,
          );
    usersRemote = FirebaseUsersDataSource(database);
  } else {
    usersRemote = const UnavailableUsersDataSource();
  }
  final registrationRepository = RegistrationRepository(
    remote: usersRemote,
    prefs: prefs,
  );

  runApp(PostsApp(
    repository: postsRepository,
    registrationRepository: registrationRepository,
    notifications: notifications,
  ));
}
