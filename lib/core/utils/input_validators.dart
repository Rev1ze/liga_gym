import '../errors/app_exception.dart';

abstract final class InputValidators {
  static const int minPasswordLength = 8;

  static final RegExp _emailRegExp = RegExp(
    r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$",
    caseSensitive: false,
  );

  static AppErrorCode? validateEmail(String? value) {
    final normalizedValue = value?.trim() ?? '';

    if (normalizedValue.isEmpty) {
      return AppErrorCode.emptyEmail;
    }

    if (!_emailRegExp.hasMatch(normalizedValue)) {
      return AppErrorCode.invalidEmail;
    }

    return null;
  }

  static AppErrorCode? validatePassword(String? value) {
    final normalizedValue = value ?? '';

    if (normalizedValue.isEmpty) {
      return AppErrorCode.emptyPassword;
    }

    if (normalizedValue.length < minPasswordLength) {
      return AppErrorCode.passwordTooShort;
    }

    return null;
  }

  static AppErrorCode? validateConfirmPassword({
    required String? password,
    required String? confirmPassword,
  }) {
    final normalizedConfirmPassword = confirmPassword ?? '';

    if (normalizedConfirmPassword.isEmpty) {
      return AppErrorCode.emptyConfirmPassword;
    }

    if (password != normalizedConfirmPassword) {
      return AppErrorCode.passwordsDoNotMatch;
    }

    return null;
  }

  static AppErrorCode? validateName(String? value) {
    final normalizedValue = value?.trim() ?? '';

    if (normalizedValue.isEmpty) {
      return AppErrorCode.emptyName;
    }

    return null;
  }

  static AppErrorCode? validateBirthDate(DateTime? value) {
    if (value == null) {
      return AppErrorCode.emptyBirthDate;
    }

    return null;
  }
}
