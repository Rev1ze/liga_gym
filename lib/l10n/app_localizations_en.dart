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
  String get commonDate => 'Date';

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
  String get goToRegisterButton => 'No account? Sign up';

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
  String get dashboardProfile => 'Profile & goals';

  @override
  String get todayOverviewTitle => 'Today\'s overview';

  @override
  String get todayOverviewSubtitle =>
      'Daily goals, progress, and nutrition in one place.';

  @override
  String get dashboardHeadline => 'You\'re in';

  @override
  String get dashboardSubtitle => 'Your account is ready for the next workout.';

  @override
  String get dashboardGoalsTitle => 'Goals';

  @override
  String get dashboardGoalsSubtitle =>
      'Set your daily targets and target weight to personalize the dashboard.';

  @override
  String dashboardGoalsSummary(Object goal, Object steps, Object calories) {
    return '$goal • $steps steps • $calories kcal';
  }

  @override
  String get dashboardGoalsAction => 'Edit goals';

  @override
  String get dashboardCommunityTitle => 'Community';

  @override
  String get dashboardCommunitySubtitle =>
      'Chat with friends and share personal results.';

  @override
  String get dashboardCommunityChat => 'Chats';

  @override
  String get dashboardCommunityLeaderboard => 'Leaderboard';

  @override
  String get dashboardStartWorkout => 'Start workout';

  @override
  String get dashboardWorkoutHistory => 'Workout history';

  @override
  String get dashboardStepCounter => 'Step counter';

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
  String get dashboardAnalyticsOverview => 'Today\'s overview';

  @override
  String get dashboardAnalyticsSteps => 'Steps';

  @override
  String get dashboardAnalyticsCalories => 'Calories';

  @override
  String get dashboardAnalyticsProgress => 'Progress';

  @override
  String dashboardAnalyticsStepGoal(Object value) {
    return '$value step goal';
  }

  @override
  String dashboardAnalyticsCalorieGoal(Object value) {
    return '$value kcal goal';
  }

  @override
  String get dashboardAnalyticsOverallGoal => 'Daily balance';

  @override
  String get dashboardAnalyticsWeeklyTitle => 'Weekly analytics';

  @override
  String get dashboardAnalyticsWeeklySubtitle => 'Last 7 days';

  @override
  String get dashboardAnalyticsOpenDetails => 'Detailed report';

  @override
  String get dashboardAnalyticsRangeTitle => 'Results analytics';

  @override
  String get dashboardAnalyticsRangeSubtitle =>
      'Choose any period up to 31 days and review your results.';

  @override
  String get dashboardAnalyticsFrom => 'From';

  @override
  String get dashboardAnalyticsTo => 'To';

  @override
  String get dashboardAnalyticsMaxRangeHint =>
      'The selected range cannot be longer than 31 days.';

  @override
  String dashboardAnalyticsAverageSteps(Object value) {
    return 'Average $value steps per day';
  }

  @override
  String dashboardAnalyticsAverageCalories(Object value) {
    return 'Average $value kcal per day';
  }

  @override
  String dashboardAnalyticsWorkoutCalories(Object value) {
    return '$value kcal burned in workouts';
  }

  @override
  String dashboardAnalyticsWorkoutsCount(Object value) {
    return '$value workouts completed';
  }

  @override
  String get dashboardAnalyticsResultsByDay => 'Daily results';

  @override
  String get dashboardAnalyticsNoWeightData =>
      'No weight data for the selected period yet.';

  @override
  String dashboardAnalyticsWeightChange(Object value) {
    return 'Weight progress $value kg';
  }

  @override
  String get dashboardAnalyticsExportPdf => 'Save as PDF';

  @override
  String get dashboardAnalyticsPdfTitle => 'Liga Gym analytics report';

  @override
  String get dashboardAnalyticsPdfRangeLabel => 'Period';

  @override
  String get dashboardAnalyticsPdfSummaryTitle => 'Summary';

  @override
  String dashboardAnalyticsPdfSaved(Object path) {
    return 'PDF saved to: $path';
  }

  @override
  String get dashboardAnalyticsStepsLegend => 'Steps';

  @override
  String get dashboardAnalyticsCaloriesLegend => 'Calories';

  @override
  String dashboardAnalyticsWeeklySteps(Object value) {
    return '$value steps this week';
  }

  @override
  String dashboardAnalyticsWeeklyCalories(Object value) {
    return '$value kcal this week';
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
  String get goalLoseWeight => 'Lose weight';

  @override
  String get goalMaintainWeight => 'Maintain weight';

  @override
  String get goalGainWeight => 'Gain weight';

  @override
  String get profileScreenTitle => 'Profile & goals';

  @override
  String get profileScreenSubtitle =>
      'Manage your profile, personal data, and body metrics.';

  @override
  String get profilePersonalSection => 'Personal data';

  @override
  String get profileBodySection => 'Body metrics';

  @override
  String get profileGoalsSection => 'Goal settings';

  @override
  String get profileHeight => 'Height, cm';

  @override
  String get profileCurrentWeight => 'Current weight, kg';

  @override
  String get profileStartWeight => 'Starting weight, kg';

  @override
  String get profileTargetWeight => 'Target weight, kg';

  @override
  String get profileGoalType => 'Main goal';

  @override
  String get profileCity => 'City';

  @override
  String get profileCityRequired => 'Please choose your city';

  @override
  String get profileCityDialogTitle => 'Choose your city';

  @override
  String get profileCityDialogMessage =>
      'To participate in the city leaderboard, select the city where you live.';

  @override
  String get profileDailyStepGoal => 'Daily step goal';

  @override
  String get profileDailyCalorieGoal => 'Daily calorie goal, kcal';

  @override
  String get profileSaveButton => 'Save changes';

  @override
  String get profileSavedMessage => 'Profile updated.';

  @override
  String get profileHeightShort => 'Height';

  @override
  String get profileCurrentWeightShort => 'Current';

  @override
  String get profileStartWeightShort => 'Start';

  @override
  String get profileTargetWeightShort => 'Target';

  @override
  String get profileKgUnit => 'kg';

  @override
  String get profileCmUnit => 'cm';

  @override
  String get profileCaloriesUnit => 'kcal';

  @override
  String get dashboardWeightTitle => 'Weight loss analytics';

  @override
  String get dashboardWeightSubtitle =>
      'Your current dynamics based on the saved weight history.';

  @override
  String dashboardWeightCurrent(Object value) {
    return 'Current weight $value kg';
  }

  @override
  String dashboardWeightTarget(Object value) {
    return 'Target $value kg';
  }

  @override
  String dashboardWeightLost(Object value) {
    return 'Progress $value kg';
  }

  @override
  String dashboardWeightWeekly(Object value) {
    return 'For the selected week $value kg';
  }

  @override
  String dashboardWeightRemaining(Object value) {
    return 'Remaining $value kg';
  }

  @override
  String get dashboardWeightEmptyTitle => 'Add your current and target weight';

  @override
  String get dashboardWeightEmptySubtitle =>
      'Once you do that, the dashboard will show weight-loss analytics.';

  @override
  String dashboardWeekStartWeight(Object value) {
    return 'Week start $value kg';
  }

  @override
  String dashboardWeekEndWeight(Object value) {
    return 'Week end $value kg';
  }

  @override
  String get goalSettingsTitle => 'Goal settings';

  @override
  String get goalSettingsStepsSubtitle =>
      'Adjust the daily step goal from the Today\'s Overview card.';

  @override
  String get goalSettingsCaloriesSubtitle =>
      'Adjust the daily calorie goal from the Today\'s Overview card.';

  @override
  String get goalSettingsProgressSubtitle =>
      'Set your main goal and weight targets for progress tracking.';

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
  String get workoutRouteMapTitle => 'Workout route';

  @override
  String get workoutRouteWaitingForSignal =>
      'Waiting for GPS signal. The route will appear here during the workout.';

  @override
  String get workoutRouteMissing => 'No workout route';

  @override
  String get workoutRouteShare => 'Share route';

  @override
  String get workoutRouteShareSubject => 'Liga Gym workout route';

  @override
  String get workoutRouteFullscreen => 'Open route fullscreen';

  @override
  String get workoutRouteView => 'View route';

  @override
  String get workoutRoutePromptTitle => 'Do you need a route map?';

  @override
  String get workoutRoutePromptMessage =>
      'Location is off, so the workout can continue without a route. Turn it on if you want a live map and saved route.';

  @override
  String get workoutRoutePromptNeedMap => 'Need map';

  @override
  String get workoutRoutePromptSkip => 'Without map';

  @override
  String get workoutRouteEnableLocationTitle => 'Enable location';

  @override
  String get workoutRouteEnableLocationMessage =>
      'Turn on location access to record the route map for this workout.';

  @override
  String get workoutRouteOpenLocationSettings => 'Open location settings';

  @override
  String get workoutRouteCheckAgain => 'Check again';

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
  String get foodDiaryTodayWeightTitle => 'Today\'s weight';

  @override
  String get foodDiaryTodayWeightSubtitle =>
      'Save today\'s weight so it appears in your profile and analytics.';

  @override
  String get foodDiaryWeightSaved => 'Today\'s weight saved.';

  @override
  String get chatTitle => 'Friend chat';

  @override
  String get chatSubtitle => 'Private messages with Liga Gym friends.';

  @override
  String get chatDirectoryTitle => 'Friend chats';

  @override
  String get chatDirectorySubtitle =>
      'Choose a friend to message privately or share a result.';

  @override
  String get chatDirectoryEmpty =>
      'There are no friends for private chats yet. Add a friend by code, link, or QR code.';

  @override
  String get chatSearchHint => 'Search friends';

  @override
  String get chatSearchEmpty => 'No friends found for your search.';

  @override
  String get chatCreateAction => 'Create chat';

  @override
  String get chatCreateTitle => 'New chat';

  @override
  String get chatInterestName => 'Interest name';

  @override
  String get chatInterestDescription => 'Chat description';

  @override
  String chatMembersCount(Object value) {
    return '$value members';
  }

  @override
  String get chatJoinPrompt =>
      'You have not joined this chat yet. Join to read and send messages.';

  @override
  String get chatJoinAction => 'Join chat';

  @override
  String get chatRoomNotFound => 'Chat was not found or has been removed.';

  @override
  String chatManageParticipantTitle(Object name) {
    return 'Manage: $name';
  }

  @override
  String chatRemoveParticipantTitle(Object name) {
    return 'Remove user $name';
  }

  @override
  String get chatRemoveParticipantAction => 'Remove';

  @override
  String get chatRemoveReasonOptional => 'Removal reason, optional';

  @override
  String get chatRoleLabel => 'Role';

  @override
  String get chatRoleAdmin => 'Administrator';

  @override
  String get chatRoleModerator => 'Moderator';

  @override
  String get chatRoleMember => 'Member';

  @override
  String get chatCanDeleteMessages => 'Can delete messages';

  @override
  String get chatCanDeleteUsers => 'Can delete users';

  @override
  String get chatEmpty => 'No messages yet. Start the conversation.';

  @override
  String get chatInputHint => 'Write a message';

  @override
  String get chatSend => 'Send';

  @override
  String get chatYou => 'You';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardSubtitle => 'Top athletes by social score.';

  @override
  String get leaderboardRussiaTab => 'Russia';

  @override
  String get leaderboardCityTab => 'My city';

  @override
  String get leaderboardEmpty =>
      'Leaderboard is still empty. Save a workout to claim the first spot.';

  @override
  String leaderboardCityEmpty(Object city) {
    return 'There are no participants in $city yet.';
  }

  @override
  String leaderboardPoints(Object value) {
    return '$value pts';
  }

  @override
  String leaderboardWorkouts(Object value) {
    return '$value workouts';
  }

  @override
  String leaderboardSteps(Object value) {
    return '$value steps';
  }

  @override
  String get leaderboardYou => 'You';

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
  String get addFoodQuickAccess => 'Quick access';

  @override
  String get addFoodName => 'Product name';

  @override
  String get addFoodBarcodeLabel => 'Barcode';

  @override
  String get addFoodGrams => 'Portion, g';

  @override
  String get addFoodQuickAccessChooseProduct =>
      'Select a product from quick access first.';

  @override
  String get addFoodQuickAccessChooseProducts =>
      'Select at least one product from quick access.';

  @override
  String get addFoodQuickAccessEmpty =>
      'There are no saved products yet. Add a new one manually or by barcode and it will appear here.';

  @override
  String get addFoodQuickAccessEdit => 'Edit product';

  @override
  String addFoodQuickAccessSelectedCount(Object count) {
    return 'Selected products: $count';
  }

  @override
  String get addFoodEditingProductTitle => 'Editing saved product';

  @override
  String get addFoodCreateNewProduct => 'Create new product';

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
  String get productDetailsSelectedProductsTitle => 'Selected products';

  @override
  String productDetailsSelectedProductsCount(Object count) {
    return 'Selected products: $count';
  }

  @override
  String get productDetailsTotalMacros => 'Total for selected portions';

  @override
  String get productDetailsSave => 'Save entry';

  @override
  String get stepCounterTitle => 'Step counter';

  @override
  String get stepCounterSettingsTitle => 'Step settings';

  @override
  String get stepCounterToday => 'Today\'s steps';

  @override
  String get stepCounterTodayHint =>
      'The value is read from the local database and updates while the tracking service is running.';

  @override
  String stepCounterGoal(Object value) {
    return 'Goal $value steps';
  }

  @override
  String stepCounterRemaining(Object value) {
    return '$value steps left to the goal';
  }

  @override
  String get stepCounterStatusTitle => 'Status';

  @override
  String get stepCounterStatusPlatform => 'Platform';

  @override
  String get stepCounterStatusPermission => 'Permission';

  @override
  String get stepCounterStatusService => 'Service';

  @override
  String get stepCounterStatusAccount => 'Account';

  @override
  String get stepCounterStatusSupported => 'Supported';

  @override
  String get stepCounterStatusUnsupported => 'Not supported';

  @override
  String get stepCounterStatusGranted => 'Granted';

  @override
  String get stepCounterStatusDenied => 'Not granted';

  @override
  String get stepCounterStatusPermanentlyDenied => 'Denied in settings';

  @override
  String get stepCounterStatusRunning => 'Running';

  @override
  String get stepCounterStatusStopped => 'Stopped';

  @override
  String get stepCounterStatusLinked => 'Linked to current account';

  @override
  String get stepCounterStatusNotLinked => 'Not linked';

  @override
  String get stepCounterActionsTitle => 'Actions';

  @override
  String get stepCounterEnable => 'Enable step tracking';

  @override
  String get stepCounterOpenSettings => 'Open app settings';

  @override
  String get stepCounterGoalSettingsAction => 'Open goal settings';

  @override
  String get stepGoalReachedTitle => 'Step goal achieved';

  @override
  String get stepGoalReachedMessage =>
      'You reached your daily step goal. Amazing work!';

  @override
  String get stepGoalReachedInline => 'Goal reached. Time to celebrate!';

  @override
  String get stepCounterUnsupportedHint =>
      'Continuous step tracking is currently available only on Android devices with a step sensor.';

  @override
  String get stepCounterPermissionHint =>
      'Grant Activity Recognition permission to start continuous step counting.';

  @override
  String get stepCounterSettingsHint =>
      'Open app settings and allow Activity Recognition, then return here.';

  @override
  String get stepCounterEnableHint =>
      'Tracking is available, but the service is not fully active yet. Tap the enable button.';

  @override
  String get stepCounterRunningHint =>
      'Tracking is active. Steps should continue updating while the app is minimized.';

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
  String get validationInvalidHeight => 'Enter a valid height.';

  @override
  String get validationInvalidCurrentWeight => 'Enter a valid current weight.';

  @override
  String get validationInvalidTargetWeight => 'Enter a valid target weight.';

  @override
  String get validationInvalidStepGoal => 'Enter a valid daily step goal.';

  @override
  String get validationInvalidCalorieGoal =>
      'Enter a valid daily calorie goal.';

  @override
  String get validationEmptyChatMessage => 'Enter a message.';

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
  String get errorGoogleSignInCancelled =>
      'Google sign-in was cancelled or rejected by app configuration. Check the SHA-1 in Firebase.';

  @override
  String get errorGoogleSignInNotSupported =>
      'Google sign-in is not supported on this platform.';

  @override
  String get errorGoogleSignInConfiguration =>
      'Google sign-in is not enabled in Firebase Authentication or is configured incorrectly.';

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
  String get errorChatSendFailed => 'Message could not be sent.';

  @override
  String get errorChatLoadFailed => 'Chat could not be loaded.';

  @override
  String get errorLeaderboardLoadFailed => 'Leaderboard could not be loaded.';

  @override
  String get errorNutritionDiaryLoadFailed => 'Food diary could not be loaded.';

  @override
  String get errorNutritionEntrySaveFailed => 'Food entry could not be saved.';

  @override
  String get errorFoodProductNotFound =>
      'Product with this barcode was not found.';

  @override
  String get errorFirestoreConfiguration =>
      'Firestore is not created, enabled, or its access rules are not published.';

  @override
  String get errorFirebaseConfigurationMissing =>
      'Firebase configuration is missing or incomplete.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';
}
