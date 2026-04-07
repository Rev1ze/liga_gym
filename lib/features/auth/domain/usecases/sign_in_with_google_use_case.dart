import '../entities/auth_status.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AuthStatus> call() {
    return _authRepository.signInWithGoogle();
  }
}
