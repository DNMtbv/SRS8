import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/notifications/notification_service.dart';
import 'data/repositories/posts_repository.dart';
import 'data/repositories/registration_repository.dart';
import 'presentation/posts/bloc/posts_bloc.dart';
import 'presentation/posts/posts_page.dart';
import 'presentation/registration/registration_page.dart';

class PostsApp extends StatelessWidget {
  const PostsApp({
    super.key,
    required this.repository,
    required this.registrationRepository,
    required this.notifications,
  });

  final PostsRepository repository;
  final RegistrationRepository registrationRepository;
  final PushNotifications notifications;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5));

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: repository),
        RepositoryProvider.value(value: registrationRepository),
        RepositoryProvider.value(value: notifications),
      ],
      child: BlocProvider(
        create: (_) => PostsBloc(repository)..add(const PostsStarted()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Посты',
          theme: ThemeData(
            colorScheme: scheme,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Пока пользователь не зарегистрирован, первым открывается
          // экран регистрации.
          home: registrationRepository.isRegistered
              ? const PostsPage()
              : const RegistrationPage(isInitial: true),
        ),
      ),
    );
  }
}
