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
