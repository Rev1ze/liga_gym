import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/core/constants/app_keys.dart';
import 'package:liga_gym_app/features/auth/presentation/screens/login_screen.dart';

import '../support/fakes/in_memory_auth_repository.dart';
import '../support/test_app.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('показывает ошибки обязательных полей', (tester) async {
      final repository = InMemoryAuthRepository();

      await tester.pumpWidget(
        buildTestApp(repository: repository, home: const LoginScreen()),
      );

      await tester.tap(find.byKey(AppKeys.loginButton));
      await tester.pump();

      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);

      await repository.dispose();
    });

    testWidgets('показывает ошибки формата email и длины пароля', (
      tester,
    ) async {
      final repository = InMemoryAuthRepository();

      await tester.pumpWidget(
        buildTestApp(repository: repository, home: const LoginScreen()),
      );

      await tester.enterText(
        find.byKey(AppKeys.loginEmailField),
        'wrong-email',
      );
      await tester.enterText(find.byKey(AppKeys.loginPasswordField), '12345');
      await tester.tap(find.byKey(AppKeys.loginButton));
      await tester.pump();

      expect(find.text('Enter a valid email.'), findsOneWidget);
      expect(
        find.text('Password must contain at least 8 characters.'),
        findsOneWidget,
      );

      await repository.dispose();
    });
  });
}
