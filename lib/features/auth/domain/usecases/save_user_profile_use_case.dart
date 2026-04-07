import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/input_validators.dart';
import '../entities/auth_status.dart';
import '../entities/gender.dart';
import '../entities/profile_setup_data.dart';
import '../repositories/auth_repository.dart';

class SaveUserProfileUseCase {
  const SaveUserProfileUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AuthStatus> call({
    required String name,
    required Gender? gender,
    required DateTime? birthDate,
  }) async {
    // Проверяем обязательные поля анкеты, прежде чем сохранять их в Firestore.
    final nameError = InputValidators.validateName(name);
    if (nameError != null) {
      throw ValidationException(nameError);
    }

    if (gender == null) {
      throw const ValidationException(AppErrorCode.emptyGender);
    }

    final birthDateError = InputValidators.validateBirthDate(birthDate);
    if (birthDateError != null) {
      throw ValidationException(birthDateError);
    }

    return _authRepository.saveUserProfile(
      ProfileSetupData(
        name: name.trim(),
        gender: gender,
        birthDate: birthDate!,
      ),
    );
  }
}
