import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/input_validators.dart';
import '../entities/auth_status.dart';
import '../repositories/auth_repository.dart';

class LoginWithEmailUseCase {
  const LoginWithEmailUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AuthStatus> call({
    required String email,
    required String password,
  }) async {
    // Валидируем входные данные повторно на уровне use case, чтобы не зависеть только от UI.
    final emailError = InputValidators.validateEmail(email);
    if (emailError != null) {
      throw ValidationException(emailError);
    }

    final passwordError = InputValidators.validatePassword(password);
    if (passwordError != null) {
      throw ValidationException(passwordError);
    }

    return _authRepository.loginWithEmail(
      email: email.trim(),
      password: password,
    );
  }
}
