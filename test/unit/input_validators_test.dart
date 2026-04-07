import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/core/errors/app_exception.dart';
import 'package:liga_gym_app/core/utils/input_validators.dart';

void main() {
  group('InputValidators', () {
    test('возвращает ошибку для некорректного email', () {
      expect(
        InputValidators.validateEmail('invalid-email'),
        AppErrorCode.invalidEmail,
      );
    });

    test('возвращает ошибку для короткого пароля', () {
      expect(
        InputValidators.validatePassword('12345'),
        AppErrorCode.passwordTooShort,
      );
    });

    test('возвращает ошибку при несовпадении паролей', () {
      expect(
        InputValidators.validateConfirmPassword(
          password: 'password123',
          confirmPassword: 'password124',
        ),
        AppErrorCode.passwordsDoNotMatch,
      );
    });
  });
}
