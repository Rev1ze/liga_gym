import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/core/constants/app_keys.dart';
import 'package:liga_gym_app/core/navigation/app_routes.dart';
import 'package:liga_gym_app/features/auth/presentation/screens/login_screen.dart';
import 'package:liga_gym_app/features/dashboard/presentation/providers/dashboard_providers.dart';

import '../support/fakes/in_memory_auth_repository.dart';
import '../support/test_app.dart';
import '../support/test_fixtures.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('shows validation errors for required fields', (tester) async {
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

    testWidgets('shows validation errors for email and password format', (
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

    testWidgets('navigates to dashboard after successful login', (
      tester,
    ) async {
      final repository = InMemoryAuthRepository()
        ..seedUser(
          email: 'alex@ligagym.dev',
          password: 'password123',
          hasProfile: true,
        );
      await tester.binding.setSurfaceSize(const Size(1440, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildRoutedTestApp(
          repository: repository,
          initialRoute: AppRoutes.login,
          overrides: [
            dashboardAnalyticsProvider.overrideWith(
              (ref) async => buildDashboardAnalyticsFixture(),
            ),
          ],
        ),
      );

      await tester.enterText(
        find.byKey(AppKeys.loginEmailField),
        'alex@ligagym.dev',
      );
      await tester.enterText(
        find.byKey(AppKeys.loginPasswordField),
        'password123',
      );
      await tester.tap(find.byKey(AppKeys.loginButton));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.textContaining('alex@ligagym.dev'), findsOneWidget);

      await repository.dispose();
    });
  });
}
