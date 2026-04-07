// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Liga Gym';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonConfirmPassword => 'Confirm password';

  @override
  String get commonName => 'Name';

  @override
  String get commonGender => 'Gender';

  @override
  String get commonBirthDate => 'Birth date';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get splashTitle => 'Liga Gym';

  @override
  String get splashSubtitle =>
      'Preparing your training space and checking your account.';

  @override
  String get splashErrorMessage =>
      'We couldn\'t check your session. You can try again.';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue your training journey.';

  @override
  String get loginButton => 'Log in';

  @override
  String get googleSignInButton => 'Continue with Google';

  @override
  String get goToRegisterButton => 'Go to Register';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle =>
      'Register to start building your profile and workouts.';

  @override
  String get registerButton => 'Register';

  @override
  String get goToLoginButton => 'Back to Login';

  @override
  String get profileSetupTitle => 'Profile setup';

  @override
  String get profileSetupSubtitle =>
      'Tell us a bit about yourself so we can personalize the experience.';

  @override
  String get profileSetupButton => 'Save profile';

  @override
  String get profileBirthDatePickerHelp => 'Select birth date';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardHeadline => 'You\'re in';

  @override
  String get dashboardSubtitle => 'Your account is ready for the next workout.';

  @override
  String get dashboardSignOut => 'Sign out';

  @override
  String dashboardSignedInAs(Object email) {
    return 'Signed in as $email';
  }

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get validationEmptyEmail => 'Enter your email.';

  @override
  String get validationInvalidEmail => 'Enter a valid email.';

  @override
  String get validationEmptyPassword => 'Enter your password.';

  @override
  String get validationPasswordTooShort =>
      'Password must contain at least 8 characters.';

  @override
  String get validationEmptyConfirmPassword => 'Confirm your password.';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get validationEmptyName => 'Enter your name.';

  @override
  String get validationEmptyGender => 'Select your gender.';

  @override
  String get validationEmptyBirthDate => 'Select your birth date.';

  @override
  String get errorUserNotFound => 'User with this email was not found.';

  @override
  String get errorWrongPassword => 'The password is incorrect.';

  @override
  String get errorInvalidCredential => 'The email or password is invalid.';

  @override
  String get errorEmailAlreadyInUse =>
      'An account with this email already exists.';

  @override
  String get errorNetworkRequestFailed =>
      'Network error. Check your connection and try again.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get errorGoogleSignInCancelled => 'Google sign-in was cancelled.';

  @override
  String get errorGoogleSignInNotSupported =>
      'Google sign-in is not supported on this platform.';

  @override
  String get errorGoogleSignInConfiguration =>
      'Google sign-in is not configured correctly.';

  @override
  String get errorGoogleSignInFailed =>
      'Google sign-in failed. Please try again.';

  @override
  String get errorUnauthorized => 'Please log in again.';

  @override
  String get errorProfileSaveFailed => 'Profile could not be saved.';

  @override
  String get errorFirebaseConfigurationMissing =>
      'Firebase configuration is missing or incomplete.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';
}
