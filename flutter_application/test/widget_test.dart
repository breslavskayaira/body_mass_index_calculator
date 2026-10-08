import 'package:flutter/material.dart';
import 'package:flutter_application/auth_screen.dart';
import 'package:flutter_application/bmi_calculator.dart';
import 'package:flutter_application/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BMI is rounded to 2 decimals', () {
    final result = assessBmi(heightText: '185', weightText: '77');
    expect(result.bmi, 22.50);
    expect(result.recommendation, contains('Норма'));
  });

  test('height in meters matches height in centimeters', () {
    final centimeters = assessBmi(heightText: '185', weightText: '77');
    final meters = assessBmi(heightText: '1,85', weightText: '77');
    expect(meters.bmi, centimeters.bmi);
  });

  test('category boundaries follow the specification', () {
    expect(recommendationFor(16), contains('Выраженный дефицит'));
    expect(recommendationFor(16.01), contains('Недостаточная'));
    expect(recommendationFor(18.49), contains('Недостаточная'));
    expect(recommendationFor(18.5), contains('Норма'));
    expect(recommendationFor(24.99), contains('Норма'));
    expect(recommendationFor(25), contains('Избыточная'));
    expect(recommendationFor(29.99), contains('Избыточная'));
    expect(recommendationFor(30), contains('Ожирение.'));
    expect(recommendationFor(35), contains('Ожирение резкое'));
    expect(recommendationFor(40), contains('Очень резкое ожирение'));
  });

  test('empty and invalid input is rejected', () {
    expect(
      () => assessBmi(heightText: '', weightText: '70'),
      throwsA(
        isA<BmiValidationException>().having(
          (error) => error.message,
          'message',
          'Заполните все поля',
        ),
      ),
    );
    expect(
      () => assessBmi(heightText: 'abc', weightText: '70'),
      throwsA(isA<BmiValidationException>()),
    );
    expect(
      () => assessBmi(heightText: '10', weightText: '70'),
      throwsA(isA<BmiValidationException>()),
    );
  });

  test('email and password validators', () {
    expect(validateEmail(''), 'Введите email');
    expect(validateEmail('user'), 'Введите корректный email');
    expect(validateEmail('user@mail.ru'), isNull);
    expect(validatePassword('123'), 'Пароль должен быть не менее 6 символов');
    expect(validatePassword('123456'), isNull);
  });

  testWidgets('login screen shows the required controls', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Вход в приложение'), findsOneWidget);
    expect(find.text('ВОЙТИ'), findsOneWidget);
    expect(find.text('Зарегистрироваться'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('registration screen opens from the login link', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pumpAndSettle();

    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.text('СОЗДАТЬ АККАУНТ'), findsOneWidget);
    expect(find.text('Вернуться к странице входа'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });
}
