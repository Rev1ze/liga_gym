enum AppErrorCode {
  emptyEmail,
  invalidEmail,
  emptyPassword,
  passwordTooShort,
  emptyConfirmPassword,
  passwordsDoNotMatch,
  emptyName,
  emptyGender,
  emptyBirthDate,
  emptyFoodName,
  emptyBarcode,
  emptyChatMessage,
  invalidFoodWeight,
  invalidCalories,
  invalidProteins,
  invalidFats,
  invalidCarbs,
  userNotFound,
  wrongPassword,
  invalidCredential,
  emailAlreadyInUse,
  networkRequestFailed,
  tooManyRequests,
  googleSignInCancelled,
  googleSignInNotSupported,
  googleSignInConfigurationError,
  googleSignInFailed,
  unauthorized,
  profileSaveFailed,
  workoutSaveFailed,
  chatSendFailed,
  chatLoadFailed,
  leaderboardLoadFailed,
  nutritionDiaryLoadFailed,
  nutritionEntrySaveFailed,
  foodProductNotFound,
  firestoreConfigurationError,
  firebaseConfigurationMissing,
  unknown,
}

sealed class AppException implements Exception {
  const AppException(this.code);

  final AppErrorCode code;
}

final class ValidationException extends AppException {
  const ValidationException(super.code);
}

final class AuthException extends AppException {
  const AuthException(super.code);
}

final class ProfileException extends AppException {
  const ProfileException(super.code);
}

final class WorkoutException extends AppException {
  const WorkoutException(super.code);
}

final class NutritionException extends AppException {
  const NutritionException(super.code);
}

final class SocialException extends AppException {
  const SocialException(super.code);
}
