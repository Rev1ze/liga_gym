import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/input_validators.dart';
import '../entities/auth_status.dart';
import '../repositories/auth_repository.dart';

class RegisterUserUseCase {
  const RegisterUserUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AuthStatus> call({
    required String email,
    required String password,
  }) async {
    // Проверяем данные до запроса в Firebase, чтобы сократить лишние сетевые обращения.
    final emailError = InputValidators.validateEmail(email);
    if (emailError != null) {
      throw ValidationException(emailError);
    }

    final passwordError = InputValidators.validatePassword(password);
    if (passwordError != null) {
      throw ValidationException(passwordError);
    }

    return _authRepository.registerUser(
      email: email.trim(),
      password: password,
    );
  }
}
