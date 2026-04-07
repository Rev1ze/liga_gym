import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/core/errors/app_exception.dart';
import 'package:liga_gym_app/features/auth/domain/entities/auth_status.dart';
import 'package:liga_gym_app/features/auth/domain/usecases/login_with_email_use_case.dart';

import '../support/fakes/in_memory_auth_repository.dart';

void main() {
  group('LoginWithEmailUseCase', () {
    test('успешно авторизует пользователя с готовым профилем', () async {
      final repository = InMemoryAuthRepository()
        ..seedUser(
          email: 'member@ligagym.dev',
          password: 'password123',
          hasProfile: true,
        );
      final useCase = LoginWithEmailUseCase(repository);

      final result = await useCase(
        email: 'member@ligagym.dev',
        password: 'password123',
      );

      expect(result, AuthStatus.authenticated);
      await repository.dispose();
    });

    test('бросает ValidationException для некорректного email', () async {
      final repository = InMemoryAuthRepository();
      final useCase = LoginWithEmailUseCase(repository);

      await expectLater(
        () => useCase(email: 'wrong-email', password: 'password123'),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.invalidEmail,
          ),
        ),
      );

      await repository.dispose();
    });

    test('пробрасывает ошибку user not found из репозитория', () async {
      final repository = InMemoryAuthRepository();
      final useCase = LoginWithEmailUseCase(repository);

      await expectLater(
        () => useCase(email: 'missing@ligagym.dev', password: 'password123'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.userNotFound,
          ),
        ),
      );

      await repository.dispose();
    });
  });
}
