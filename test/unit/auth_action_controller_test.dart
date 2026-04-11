import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/core/navigation/app_routes.dart';
import 'package:liga_gym_app/features/auth/presentation/controllers/auth_action_controller.dart';
import 'package:liga_gym_app/features/auth/presentation/providers/auth_providers.dart';

import '../support/fakes/in_memory_auth_repository.dart';

void main() {
  group('AuthActionController', () {
    test(
      'returns dashboard route for a successful login with completed profile',
      () async {
        final repository = InMemoryAuthRepository()
          ..seedUser(
            email: 'alex@ligagym.dev',
            password: 'password123',
            hasProfile: true,
          );
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);
        addTearDown(repository.dispose);

        final route = await container
            .read(authActionControllerProvider.notifier)
            .loginWithEmail(email: 'alex@ligagym.dev', password: 'password123');

        expect(route, AppRoutes.dashboard);
        expect(container.read(authActionControllerProvider).hasError, isFalse);
      },
    );

    test('returns profile setup route after registering a new user', () async {
      final repository = InMemoryAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      addTearDown(repository.dispose);

      final route = await container
          .read(authActionControllerProvider.notifier)
          .registerUser(email: 'newuser@ligagym.dev', password: 'password123');

      expect(route, AppRoutes.profileSetup);
      expect(container.read(authActionControllerProvider).hasError, isFalse);
    });
  });
}
