import '../../features/auth/domain/entities/gender.dart';
import '../../l10n/app_localizations.dart';
import '../errors/app_exception.dart';

extension AppErrorCodeLocalization on AppErrorCode {
  String localize(AppLocalizations l10n) {
    return switch (this) {
      AppErrorCode.emptyEmail => l10n.validationEmptyEmail,
      AppErrorCode.invalidEmail => l10n.validationInvalidEmail,
      AppErrorCode.emptyPassword => l10n.validationEmptyPassword,
      AppErrorCode.passwordTooShort => l10n.validationPasswordTooShort,
      AppErrorCode.emptyConfirmPassword => l10n.validationEmptyConfirmPassword,
      AppErrorCode.passwordsDoNotMatch => l10n.validationPasswordsDoNotMatch,
      AppErrorCode.emptyName => l10n.validationEmptyName,
      AppErrorCode.emptyGender => l10n.validationEmptyGender,
      AppErrorCode.emptyBirthDate => l10n.validationEmptyBirthDate,
      AppErrorCode.userNotFound => l10n.errorUserNotFound,
      AppErrorCode.wrongPassword => l10n.errorWrongPassword,
      AppErrorCode.invalidCredential => l10n.errorInvalidCredential,
      AppErrorCode.emailAlreadyInUse => l10n.errorEmailAlreadyInUse,
      AppErrorCode.networkRequestFailed => l10n.errorNetworkRequestFailed,
      AppErrorCode.tooManyRequests => l10n.errorTooManyRequests,
      AppErrorCode.googleSignInCancelled => l10n.errorGoogleSignInCancelled,
      AppErrorCode.googleSignInNotSupported =>
        l10n.errorGoogleSignInNotSupported,
      AppErrorCode.googleSignInConfigurationError =>
        l10n.errorGoogleSignInConfiguration,
      AppErrorCode.googleSignInFailed => l10n.errorGoogleSignInFailed,
      AppErrorCode.unauthorized => l10n.errorUnauthorized,
      AppErrorCode.profileSaveFailed => l10n.errorProfileSaveFailed,
      AppErrorCode.firebaseConfigurationMissing =>
        l10n.errorFirebaseConfigurationMissing,
      AppErrorCode.unknown => l10n.errorUnknown,
    };
  }
}

extension GenderLocalization on Gender {
  String localize(AppLocalizations l10n) {
    return switch (this) {
      Gender.male => l10n.genderMale,
      Gender.female => l10n.genderFemale,
      Gender.other => l10n.genderOther,
    };
  }
}
