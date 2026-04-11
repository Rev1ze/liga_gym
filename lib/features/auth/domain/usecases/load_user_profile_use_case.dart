import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class LoadUserProfileUseCase {
  const LoadUserProfileUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<UserProfile> call(String userId) {
    return _authRepository.getUserProfile(userId);
  }
}
