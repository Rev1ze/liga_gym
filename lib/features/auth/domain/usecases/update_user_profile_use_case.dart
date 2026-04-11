import '../entities/user_profile_update_data.dart';
import '../repositories/auth_repository.dart';

class UpdateUserProfileUseCase {
  const UpdateUserProfileUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call(UserProfileUpdateData profile) {
    return _authRepository.updateUserProfile(profile);
  }
}
