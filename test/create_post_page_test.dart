import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practicevskodin/presentation/create_post/create_post_page.dart';

import 'helpers/fake_adapter.dart';

/// Отвечает списком авторов; POST /posts возвращает тело запроса с id = 101.
Future<ResponseBody> _handler(RequestOptions o) async {
  if (o.path == '/users') {
    return jsonResponse([userJson(1, 'Анна Ким'), userJson(2, 'Борис Ли')]);
  }
  return jsonResponse(
    {...o.data as Map<String, dynamic>, 'id': 101},
    status: 201,
  );
}

Future<TestEnv> _pumpPage(WidgetTester tester, FakeHandler handler) async {
  // Высокий экран: иначе нижние элементы ListView не будут построены.
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);

  final env = await createEnv(handler);
  await tester.pumpWidget(
    RepositoryProvider.value(
      value: env.repository,
      child: const MaterialApp(home: CreatePostPage()),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _selectAuthor(WidgetTester tester, String name) async {
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

ButtonStyleButton _button(WidgetTester tester, String label) =>
    tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );

void main() {
  testWidgets('показывает заголовок экрана, поля формы и кнопку', (tester) async {
    await _pumpPage(tester, _handler);

    expect(find.text('Новый пост'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(_field('Заголовок'), findsOneWidget);
    expect(_field('Текст'), findsOneWidget);
    expect(find.text('Опубликовать'), findsOneWidget);
  });

  testWidgets('пустая форма: показаны все ошибки, POST не отправляется',
      (tester) async {
    final env = await _pumpPage(tester, _handler);

    await tester.tap(find.text('Опубликовать'));
    await tester.pumpAndSettle();

    expect(find.text('Выберите автора'), findsOneWidget);
    expect(find.text('Заголовок обязателен'), findsOneWidget);
    expect(find.text('Текст обязателен'), findsOneWidget);
    expect(env.adapter.requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('выбор автора из GET /users убирает ошибку поля', (tester) async {
    await _pumpPage(tester, _handler);

    await tester.tap(find.text('Опубликовать'));
    await tester.pumpAndSettle();
    expect(find.text('Выберите автора'), findsOneWidget);

    await _selectAuthor(tester, 'Борис Ли');

    expect(find.text('Выберите автора'), findsNothing);
  });

  testWidgets('ошибка исчезает, когда значение поля исправлено', (tester) async {
    await _pumpPage(tester, _handler);

    await tester.enterText(_field('Заголовок'), 'abc');
    await tester.pumpAndSettle();
    expect(
      find.text('Заголовок: минимум 5 символов (сейчас 3)'),
      findsOneWidget,
    );

    await tester.enterText(_field('Заголовок'), 'Новый заголовок');
    await tester.pumpAndSettle();
    expect(find.textContaining('минимум 5 символов'), findsNothing);
  });

  testWidgets('отправка: кнопка заблокирована, затем диалог с ответом сервера',
      (tester) async {
    final response = Completer<void>();
    final env = await _pumpPage(tester, (o) async {
      if (o.method == 'POST') await response.future;
      return _handler(o);
    });

    await _selectAuthor(tester, 'Анна Ким');
    await tester.enterText(_field('Заголовок'), '  Мой заголовок  ');
    await tester.enterText(_field('Текст'), 'Текст моего поста');
    await tester.tap(find.text('Опубликовать'));
    await tester.pump();

    expect(find.text('Отправка…'), findsOneWidget);
    expect(_button(tester, 'Отправка…').onPressed, isNull);

    response.complete();
    await tester.pumpAndSettle();

    expect(find.text('Пост отправлен'), findsOneWidget);
    expect(find.textContaining('"id": 101'), findsOneWidget);
    expect(env.adapter.requests.last.data, {
      'userId': 1,
      'title': 'Мой заголовок',
      'body': 'Текст моего поста',
    });
  });

  testWidgets('авторы не загрузились: «Повторить» открывает форму',
      (tester) async {
    var fail = true;
    await _pumpPage(tester, (o) async {
      if (fail) return jsonResponse({'error': 'not found'}, status: 404);
      return _handler(o);
    });

    expect(find.text('Не удалось загрузить список авторов'), findsOneWidget);
    expect(find.text('Опубликовать'), findsNothing);

    fail = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('Опубликовать'), findsOneWidget);
    expect(find.text('Не удалось загрузить список авторов'), findsNothing);
  });
}
