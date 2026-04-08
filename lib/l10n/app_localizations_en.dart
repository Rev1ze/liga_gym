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
  String get commonContinue => 'Continue';

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
  String get dashboardStartWorkout => 'Start workout';

  @override
  String get dashboardWorkoutHistory => 'Workout history';

  @override
  String get dashboardNutritionDiary => 'Food diary';

  @override
  String get dashboardNutritionTitle => 'Today\'s nutrition';

  @override
  String dashboardNutritionCalories(Object value) {
    return 'Calories: $value';
  }

  @override
  String dashboardNutritionProteins(Object value) {
    return 'Proteins: $value';
  }

  @override
  String dashboardNutritionFats(Object value) {
    return 'Fats: $value';
  }

  @override
  String dashboardNutritionCarbs(Object value) {
    return 'Carbs: $value';
  }

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
  String get workoutTypeRunning => 'Running';

  @override
  String get workoutTypeCycling => 'Cycling';

  @override
  String get workoutTypeWalking => 'Walking';

  @override
  String get workoutTypeStrength => 'Strength';

  @override
  String get workoutTypeCardio => 'Cardio';

  @override
  String get workoutListTitle => 'Workouts';

  @override
  String get workoutListEmpty =>
      'No workouts yet. Start your first workout from the dashboard.';

  @override
  String get workoutFilterDate => 'Select date';

  @override
  String get workoutFilterType => 'Type';

  @override
  String get workoutFilterAllTypes => 'All types';

  @override
  String get workoutFilterClear => 'Clear filters';

  @override
  String get workoutStartTitle => 'Start workout';

  @override
  String get workoutStartSubtitle =>
      'Choose a workout type and start tracking your session.';

  @override
  String get workoutStartButton => 'Start';

  @override
  String get workoutTypeLabel => 'Workout type';

  @override
  String get workoutActiveTitle => 'Active workout';

  @override
  String get workoutActivePause => 'Pause';

  @override
  String get workoutActiveResume => 'Resume';

  @override
  String get workoutActiveStop => 'Stop';

  @override
  String get workoutMetricDuration => 'Duration';

  @override
  String get workoutMetricCalories => 'Calories';

  @override
  String get workoutMetricDistance => 'Distance';

  @override
  String get workoutGpsUnavailable =>
      'GPS is unavailable. Duration and calories will continue, but route and distance may be incomplete.';

  @override
  String get workoutNoActiveSession =>
      'No active workout. Start a new one from the dashboard.';

  @override
  String get workoutResultTitle => 'Workout result';

  @override
  String get workoutResultSubtitle =>
      'Review your workout and save it to history.';

  @override
  String get workoutResultSave => 'Save workout';

  @override
  String get workoutNoResult => 'No workout result available.';

  @override
  String get workoutSavedSynced =>
      'Workout saved locally and synced to Firestore.';

  @override
  String get workoutSavedLocalOnly =>
      'Workout saved locally. Firestore sync will complete later.';

  @override
  String get mealTypeBreakfast => 'Breakfast';

  @override
  String get mealTypeLunch => 'Lunch';

  @override
  String get mealTypeDinner => 'Dinner';

  @override
  String get mealTypeSnack => 'Snack';

  @override
  String get foodDiaryTitle => 'Food diary';

  @override
  String get foodDiaryPickDate => 'Select diary date';

  @override
  String get foodDiaryAddFood => 'Add food';

  @override
  String get foodDiaryMealType => 'Meal';

  @override
  String get foodDiaryEmptySection => 'No entries for this meal yet.';

  @override
  String foodDiaryEntrySubtitle(Object grams, Object calories) {
    return '$grams g • $calories kcal';
  }

  @override
  String foodDiaryInlineMacros(Object proteins, Object fats, Object carbs) {
    return 'P $proteins • F $fats • C $carbs';
  }

  @override
  String get addFoodTitle => 'Add food';

  @override
  String get addFoodManual => 'Manual';

  @override
  String get addFoodBarcode => 'Barcode';

  @override
  String get addFoodName => 'Product name';

  @override
  String get addFoodBarcodeLabel => 'Barcode';

  @override
  String get addFoodGrams => 'Portion, g';

  @override
  String get productDetailsTitle => 'Product details';

  @override
  String productDetailsMeal(Object meal) {
    return 'Meal: $meal';
  }

  @override
  String productDetailsPortion(Object grams) {
    return 'Portion: $grams g';
  }

  @override
  String get productDetailsPer100 => 'Per 100 g';

  @override
  String get productDetailsPortionMacros => 'For selected portion';

  @override
  String get productDetailsSave => 'Save entry';

  @override
  String get foodCalories => 'Calories';

  @override
  String get foodProteins => 'Proteins';

  @override
  String get foodFats => 'Fats';

  @override
  String get foodCarbs => 'Carbs';

  @override
  String get foodCaloriesPer100 => 'Calories per 100 g';

  @override
  String get foodProteinsPer100 => 'Proteins per 100 g';

  @override
  String get foodFatsPer100 => 'Fats per 100 g';

  @override
  String get foodCarbsPer100 => 'Carbs per 100 g';

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
  String get validationEmptyFoodName => 'Enter the product name.';

  @override
  String get validationEmptyBarcode => 'Enter a barcode.';

  @override
  String get validationInvalidFoodWeight => 'Enter a valid portion in grams.';

  @override
  String get validationInvalidCalories => 'Enter valid calories per 100 g.';

  @override
  String get validationInvalidProteins => 'Enter valid proteins per 100 g.';

  @override
  String get validationInvalidFats => 'Enter valid fats per 100 g.';

  @override
  String get validationInvalidCarbs => 'Enter valid carbs per 100 g.';

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
  String get errorWorkoutSaveFailed => 'Workout could not be saved.';

  @override
  String get errorNutritionDiaryLoadFailed => 'Food diary could not be loaded.';

  @override
  String get errorNutritionEntrySaveFailed => 'Food entry could not be saved.';

  @override
  String get errorFoodProductNotFound =>
      'Product with this barcode was not found.';

  @override
  String get errorFirebaseConfigurationMissing =>
      'Firebase configuration is missing or incomplete.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';
}
