# Посты (JSONPlaceholder)

Flutter-приложение для работы с `https://jsonplaceholder.typicode.com`:
список постов с пагинацией, поиск и фильтры, кэш, детали поста с комментариями
и форма создания поста.

## Запуск

```bash
flutter pub get
dart run build_runner build   # генерация *.g.dart (json_serializable, retrofit)
flutter run
flutter test
```

## Архитектура

```
UI (presentation/*_page.dart)
  → State (Bloc / Cubit)
    → Repository (data/repositories)
      → Retrofit API (data/api)
        → Dio (core/network/dio_client.dart)
```

UI не обращается к Dio напрямую: страницы общаются только с Bloc/Cubit,
а те — только с `PostsRepository`.

```
lib/
  core/
    error/        AppException (6 видов ошибок) и ErrorMapper
    network/      DioClient и interceptor'ы (заголовки, retry, ошибки)
    logger.dart   технический лог
  data/
    models/       Post, Comment, User (json_serializable)
    api/          PostsApi (retrofit)
    cache/        PostsCache (SharedPreferences)
    repositories/ PostsRepository
  presentation/
    posts/        список: PostsBloc, фильтры, карточка
    post_details/ пост + автор + комментарии
    create_post/  форма, валидаторы, CreatePostCubit
    widgets/      общие состояния (загрузка, ошибка, пусто)
```

## Где что реализовано

| Требование | Где |
|---|---|
| 1. Запросы Retrofit: `GET /posts?_page&_limit`, `GET /posts/{id}`, `GET /posts?userId=`, `GET /posts/{id}/comments`, `POST /posts`, `GET /users`, `GET /users/{id}` | `data/api/posts_api.dart` |
| A. Модели на json_serializable, битый JSON → `ParseException`, а не падение | `data/models/`, `core/error/error_mapper.dart` |
| B. Один DioClient: baseUrl, таймауты, LogInterceptor, HeadersInterceptor, ErrorInterceptor | `core/network/` (создаётся один раз в `main.dart`) |
| C. Пагинация по 10, индикатор внизу, защита от повторной загрузки страницы, «Повторить», сброс страниц при смене фильтра | `presentation/posts/bloc/posts_bloc.dart`, `posts_page.dart` |
| D. Поиск по заголовку (только по загруженным, это написано в UI), фильтр по автору, сортировка по ID, сброс | `presentation/posts/widgets/filters_panel.dart`, `posts_filter.dart` |
| E. Кэш SharedPreferences: сначала кэш, потом сервер; при ошибке кэш не стирается; плашка «Показаны сохранённые данные»; pull-to-refresh | `data/cache/posts_cache.dart`, `PostsBloc._loadFirstPage` |
| F. Форма: title 5–100, body 10–1000, автор из списка, кнопка заблокирована во время запроса, ответ сервера в диалоге, пост с пометкой «создан локально» | `presentation/create_post/` |
| 4. Состояния `initial / loading / success / cached / empty / error`, отдельно `PageLoadStatus` для подгрузки и `isRefreshing` | `posts_state.dart`, `post_details_cubit.dart`, `create_post_cubit.dart` |
| 5. Ошибки: нет сети, таймаут, 4xx, 5xx, JSON, неизвестная. Пользователю — текст, детали — в `AppLogger` | `core/error/` |
| 6. Тесты | `test/` |
| 7. Доп. задание: **retry policy** — GET повторяется до 2 раз с экспоненциальной задержкой при таймауте, обрыве сети и 5xx; POST не повторяется | `core/network/interceptors.dart` (`RetryInterceptor`) |

Также ответы на устаревший запрос (например, после смены фильтра во время
загрузки) отбрасываются по счётчику поколений в `PostsBloc`.

## Тесты

- `models_test.dart` — JSON → Post, Post → JSON, битый JSON, Comment, User
- `posts_repository_test.dart` — успешная загрузка, 500 с повторами, 404, нет
  сети, таймаут, битый JSON без потери кэша, POST через mock-адаптер Dio
- `posts_bloc_test.dart` — фильтрация и поиск, сброс страниц при смене автора,
  защита от повторной загрузки страницы, «Повторить» после ошибки страницы,
  кэш → сервер при отсутствии сети, валидация формы

- `registration_test.dart` — регистрация: запись в базу + push, отказ в
  доступе, таймаут, Firebase не настроен, защита от двойной отправки, валидация
- `validators_test.dart` — unit-тесты валидаторов: границы длины, некорректный
  ввод, тексты ошибок
- `create_post_page_test.dart` — widget-тесты формы: поля, ошибки, блокировка
  кнопки при отправке, диалог с ответом сервера, «Повторить»
- `posts_page_test.dart` — widget-тесты списка: поиск, переход на экран поста и
  обратно, создание поста через форму, «Повторить»

Сеть в тестах подменяется `FakeAdapter` (`test/helpers/fake_adapter.dart`),
Firebase — фейковыми `UsersRemoteDataSource` и `PushNotifications`.

## Иконка приложения

Исходники лежат в `assets/icon/`, настройки — в разделе
`flutter_launcher_icons` файла `pubspec.yaml`. После замены картинки:

```bash
dart run flutter_launcher_icons
```

## Firebase: регистрация и push-уведомления

### Что делает приложение

1. При первом запуске открывается экран регистрации
   (`presentation/registration/registration_page.dart`): имя, email, телефон,
   город. Позже его можно открыть кнопкой в AppBar списка постов.
2. При отправке формы пользователь сохраняется в Firebase Realtime Database
   в узел `/users/{pushKey}` вместе с FCM-токеном устройства и `createdAt`.
3. `firebase_messaging` получает push-уведомления. В фоне их показывает
   система, а когда приложение открыто — `flutter_local_notifications`.
4. После успешной регистрации приходит уведомление «Регистрация завершена».

### Архитектура Flutter ↔ Firebase

```
RegistrationPage → RegistrationCubit → RegistrationRepository
                                         → UsersRemoteDataSource → FirebaseDatabase  (/users)
                 → PushNotifications (NotificationService)
                                         → FirebaseMessaging (FCM: токен, входящие пуши)
                                         → flutter_local_notifications (показ уведомлений)
```

Уведомление после регистрации показывает само приложение. Отправить
FCM-пуш прямо с устройства можно только с секретным ключом сервисного
аккаунта, а хранить его в приложении небезопасно; в реальном проекте это
делает сервер (например, Cloud Function на запись в `/users`).

### Настройка (один раз)

1. [Firebase Console](https://console.firebase.google.com) → **Add project**.
2. **Add app → Android**, package name: `com.example.practicevskodin`.
   Скачайте `google-services.json` и положите в `android/app/`.
3. **Build → Realtime Database → Create database** → режим **Test**.
   Если база создана *после* скачивания `google-services.json`, скачайте файл
   заново или впишите URL базы в `lib/core/firebase/firebase_config.dart`.
4. **Cloud Messaging** включён по умолчанию.
5. `flutter run`.

### Как проверить

- Зарегистрируйтесь: в Realtime Database → **Data** появится `/users/-N…`,
  на устройстве — уведомление.
- Тестовый пуш: скопируйте FCM-токен внизу экрана регистрации →
  Firebase Console → **Messaging → New campaign → Notifications →
  Send test message** → вставьте токен. Попробуйте с открытым и со свёрнутым
  приложением.

Без `google-services.json` Android-сборка не запустится (этого требует
плагин google-services).

Старые учебные примеры (счётчик, жесты и т. п.) перенесены в `_old_examples/`.
