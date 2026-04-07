import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liga_gym_app/app.dart';
import 'package:liga_gym_app/core/constants/app_keys.dart';
import 'package:liga_gym_app/features/auth/presentation/providers/auth_providers.dart';

import '../test/support/fakes/in_memory_auth_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('проходит полный auth flow от Splash до Dashboard', (
    tester,
  ) async {
    final repository = InMemoryAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const LigaGymApp(locale: Locale('en')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.loginButton), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.goToRegisterButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(AppKeys.registerEmailField),
      'newuser@ligagym.dev',
    );
    await tester.enterText(
      find.byKey(AppKeys.registerPasswordField),
      'password123',
    );
    await tester.enterText(
      find.byKey(AppKeys.registerConfirmPasswordField),
      'password123',
    );
    await tester.tap(find.byKey(AppKeys.registerButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.profileNameField), findsOneWidget);

    await tester.enterText(find.byKey(AppKeys.profileNameField), 'Alex');
    await tester.tap(find.byKey(AppKeys.profileGenderField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.profileBirthDateField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppKeys.saveProfileButton));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.textContaining('newuser@ligagym.dev'), findsOneWidget);

    await repository.dispose();
  });
}
