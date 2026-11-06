import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practicevskodin/presentation/posts/bloc/posts_bloc.dart';
import 'package:practicevskodin/presentation/posts/posts_page.dart';
import 'package:practicevskodin/presentation/posts/widgets/post_card.dart';

import 'helpers/fake_adapter.dart';

/// Сервер с тремя постами двух авторов.
Future<ResponseBody> _handler(RequestOptions o) async {
  final path = o.path;
  if (path == '/users') {
    return jsonResponse([userJson(1, 'Анна Ким'), userJson(2, 'Борис Ли')]);
  }
  if (path == '/posts' && o.method == 'POST') {
    return jsonResponse(
      {...o.data as Map<String, dynamic>, 'id': 101},
      status: 201,
    );
  }
  if (path == '/posts') {
    if (queryInt(o, '_page') > 1) return jsonResponse(<Object>[]);
    return jsonResponse([
      postJson(1, title: 'Flutter и Dart'),
      postJson(2, title: 'Всё про Retrofit'),
      postJson(3, userId: 2, title: 'Dart на практике'),
    ]);
  }
  if (path == '/posts/3') {
    return jsonResponse(postJson(3, userId: 2, title: 'Dart на практике'));
  }
  if (path == '/posts/3/comments') {
    return jsonResponse([commentJson(1, 3, 'Хороший пост')]);
  }
  if (path == '/users/2') return jsonResponse(userJson(2, 'Борис Ли'));
  return jsonResponse({'error': 'not found'}, status: 404);
}

Future<void> _pumpPage(WidgetTester tester, FakeHandler handler) async {
  // Высокий экран: иначе нижние элементы ListView не будут построены.
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);

  final env = await createEnv(handler);
  await tester.pumpWidget(
    RepositoryProvider.value(
      value: env.repository,
      child: BlocProvider(
        create: (_) => PostsBloc(env.repository)..add(const PostsStarted()),
        child: const MaterialApp(home: PostsPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('показывает заголовок, поиск, кнопку и карточки постов',
      (tester) async {
    await _pumpPage(tester, _handler);

    expect(find.widgetWithText(AppBar, 'Посты'), findsOneWidget);
    expect(find.text('Поиск по загруженным постам'), findsOneWidget);
    expect(find.text('Новый пост'), findsOneWidget);
    expect(find.byType(PostCard), findsNWidgets(3));
    expect(find.text('Flutter и Dart'), findsOneWidget);
    // Имя автора берётся из /users, а не «Автор #2».
    expect(
      find.descendant(
        of: find.byType(PostCard),
        matching: find.text('Борис Ли'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('поиск сужает список, а «Очистить» возвращает его', (tester) async {
    await _pumpPage(tester, _handler);

    await tester.enterText(find.byType(TextField).first, 'dart');
    await tester.pumpAndSettle();

    expect(find.byType(PostCard), findsNWidgets(2));
    expect(find.text('Всё про Retrofit'), findsNothing);

    await tester.tap(find.byTooltip('Очистить'));
    await tester.pumpAndSettle();

    expect(find.byType(PostCard), findsNWidgets(3));
    expect(find.text('Всё про Retrofit'), findsOneWidget);
  });

  testWidgets('нажатие на карточку открывает экран поста, «Назад» возвращает',
      (tester) async {
    await _pumpPage(tester, _handler);

    await tester.tap(find.text('Dart на практике'));
    await tester.pumpAndSettle();

    expect(find.text('Пост #3'), findsOneWidget);
    expect(find.text('Борис Ли'), findsOneWidget);
    expect(find.text('Комментарии (1)'), findsOneWidget);
    expect(find.text('Хороший пост'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Пост #3'), findsNothing);
    expect(find.byType(PostCard), findsNWidgets(3));
  });

  testWidgets('новый пост: форма → диалог → пост в списке с пометкой',
      (tester) async {
    await _pumpPage(tester, _handler);

    await tester.tap(find.text('Новый пост'));
    await tester.pumpAndSettle();
    expect(find.text('Опубликовать'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Анна Ким').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Заголовок'),
      'Мой первый пост',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Текст'),
      'Текст моего первого поста',
    );
    await tester.tap(find.text('Опубликовать'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('К списку'));
    await tester.pumpAndSettle();

    expect(find.byType(PostCard), findsNWidgets(4));
    expect(find.text('Мой первый пост'), findsOneWidget);
    expect(find.text('создан локально'), findsOneWidget);
  });

  testWidgets('ошибка загрузки: «Повторить» показывает посты', (tester) async {
    var fail = true;
    await _pumpPage(tester, (o) async {
      if (fail) return jsonResponse({'error': 'not found'}, status: 404);
      return _handler(o);
    });

    expect(find.text('Не удалось загрузить посты'), findsOneWidget);
    expect(find.byType(PostCard), findsNothing);

    fail = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить посты'), findsNothing);
    expect(find.byType(PostCard), findsNWidgets(3));
  });
}
