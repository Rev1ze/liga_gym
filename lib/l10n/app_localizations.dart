import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Liga Gym'**
  String get appTitle;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get commonConfirmPassword;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @commonGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get commonGender;

  /// No description provided for @commonBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get commonBirthDate;

  /// No description provided for @commonDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get commonDate;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Liga Gym'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing your training space and checking your account.'**
  String get splashSubtitle;

  /// No description provided for @splashErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t check your session. You can try again.'**
  String get splashErrorMessage;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your training journey.'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @googleSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleSignInButton;

  /// No description provided for @goToRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'No account? Sign up'**
  String get goToRegisterButton;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register to start building your profile and workouts.'**
  String get registerSubtitle;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @goToLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get goToLoginButton;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile setup'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself so we can personalize the experience.'**
  String get profileSetupSubtitle;

  /// No description provided for @profileSetupButton.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get profileSetupButton;

  /// No description provided for @profileBirthDatePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Select birth date'**
  String get profileBirthDatePickerHelp;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile & goals'**
  String get dashboardProfile;

  /// No description provided for @todayOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s overview'**
  String get todayOverviewTitle;

  /// No description provided for @todayOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily goals, progress, and nutrition in one place.'**
  String get todayOverviewSubtitle;

  /// No description provided for @dashboardHeadline.
  ///
  /// In en, this message translates to:
  /// **'You\'re in'**
  String get dashboardHeadline;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready for the next workout.'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get dashboardGoalsTitle;

  /// No description provided for @dashboardGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your daily targets and target weight to personalize the dashboard.'**
  String get dashboardGoalsSubtitle;

  /// No description provided for @dashboardGoalsSummary.
  ///
  /// In en, this message translates to:
  /// **'{goal} • {steps} steps • {calories} kcal'**
  String dashboardGoalsSummary(Object goal, Object steps, Object calories);

  /// No description provided for @dashboardGoalsAction.
  ///
  /// In en, this message translates to:
  /// **'Edit goals'**
  String get dashboardGoalsAction;

  /// No description provided for @dashboardCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get dashboardCommunityTitle;

  /// No description provided for @dashboardCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jump into the live chat and see who is leading this week.'**
  String get dashboardCommunitySubtitle;

  /// No description provided for @dashboardCommunityChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get dashboardCommunityChat;

  /// No description provided for @dashboardCommunityLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get dashboardCommunityLeaderboard;

  /// No description provided for @dashboardStartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get dashboardStartWorkout;

  /// No description provided for @dashboardWorkoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Workout history'**
  String get dashboardWorkoutHistory;

  /// No description provided for @dashboardStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step counter'**
  String get dashboardStepCounter;

  /// No description provided for @dashboardNutritionDiary.
  ///
  /// In en, this message translates to:
  /// **'Food diary'**
  String get dashboardNutritionDiary;

  /// No description provided for @dashboardNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s nutrition'**
  String get dashboardNutritionTitle;

  /// No description provided for @dashboardNutritionCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories: {value}'**
  String dashboardNutritionCalories(Object value);

  /// No description provided for @dashboardNutritionProteins.
  ///
  /// In en, this message translates to:
  /// **'Proteins: {value}'**
  String dashboardNutritionProteins(Object value);

  /// No description provided for @dashboardNutritionFats.
  ///
  /// In en, this message translates to:
  /// **'Fats: {value}'**
  String dashboardNutritionFats(Object value);

  /// No description provided for @dashboardNutritionCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs: {value}'**
  String dashboardNutritionCarbs(Object value);

  /// No description provided for @dashboardAnalyticsOverview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s overview'**
  String get dashboardAnalyticsOverview;

  /// No description provided for @dashboardAnalyticsSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get dashboardAnalyticsSteps;

  /// No description provided for @dashboardAnalyticsCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get dashboardAnalyticsCalories;

  /// No description provided for @dashboardAnalyticsProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get dashboardAnalyticsProgress;

  /// No description provided for @dashboardAnalyticsStepGoal.
  ///
  /// In en, this message translates to:
  /// **'{value} step goal'**
  String dashboardAnalyticsStepGoal(Object value);

  /// No description provided for @dashboardAnalyticsCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal goal'**
  String dashboardAnalyticsCalorieGoal(Object value);

  /// No description provided for @dashboardAnalyticsOverallGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily balance'**
  String get dashboardAnalyticsOverallGoal;

  /// No description provided for @dashboardAnalyticsWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly analytics'**
  String get dashboardAnalyticsWeeklyTitle;

  /// No description provided for @dashboardAnalyticsWeeklySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get dashboardAnalyticsWeeklySubtitle;

  /// No description provided for @dashboardAnalyticsOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Detailed report'**
  String get dashboardAnalyticsOpenDetails;

  /// No description provided for @dashboardAnalyticsRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Results analytics'**
  String get dashboardAnalyticsRangeTitle;

  /// No description provided for @dashboardAnalyticsRangeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose any period up to 31 days and review your results.'**
  String get dashboardAnalyticsRangeSubtitle;

  /// No description provided for @dashboardAnalyticsFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get dashboardAnalyticsFrom;

  /// No description provided for @dashboardAnalyticsTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get dashboardAnalyticsTo;

  /// No description provided for @dashboardAnalyticsMaxRangeHint.
  ///
  /// In en, this message translates to:
  /// **'The selected range cannot be longer than 31 days.'**
  String get dashboardAnalyticsMaxRangeHint;

  /// No description provided for @dashboardAnalyticsAverageSteps.
  ///
  /// In en, this message translates to:
  /// **'Average {value} steps per day'**
  String dashboardAnalyticsAverageSteps(Object value);

  /// No description provided for @dashboardAnalyticsAverageCalories.
  ///
  /// In en, this message translates to:
  /// **'Average {value} kcal per day'**
  String dashboardAnalyticsAverageCalories(Object value);

  /// No description provided for @dashboardAnalyticsWorkoutCalories.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal burned in workouts'**
  String dashboardAnalyticsWorkoutCalories(Object value);

  /// No description provided for @dashboardAnalyticsWorkoutsCount.
  ///
  /// In en, this message translates to:
  /// **'{value} workouts completed'**
  String dashboardAnalyticsWorkoutsCount(Object value);

  /// No description provided for @dashboardAnalyticsResultsByDay.
  ///
  /// In en, this message translates to:
  /// **'Daily results'**
  String get dashboardAnalyticsResultsByDay;

  /// No description provided for @dashboardAnalyticsNoWeightData.
  ///
  /// In en, this message translates to:
  /// **'No weight data for the selected period yet.'**
  String get dashboardAnalyticsNoWeightData;

  /// No description provided for @dashboardAnalyticsWeightChange.
  ///
  /// In en, this message translates to:
  /// **'Weight progress {value} kg'**
  String dashboardAnalyticsWeightChange(Object value);

  /// No description provided for @dashboardAnalyticsExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Save as PDF'**
  String get dashboardAnalyticsExportPdf;

  /// No description provided for @dashboardAnalyticsPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Liga Gym analytics report'**
  String get dashboardAnalyticsPdfTitle;

  /// No description provided for @dashboardAnalyticsPdfRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get dashboardAnalyticsPdfRangeLabel;

  /// No description provided for @dashboardAnalyticsPdfSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get dashboardAnalyticsPdfSummaryTitle;

  /// No description provided for @dashboardAnalyticsPdfSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved to: {path}'**
  String dashboardAnalyticsPdfSaved(Object path);

  /// No description provided for @dashboardAnalyticsStepsLegend.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get dashboardAnalyticsStepsLegend;

  /// No description provided for @dashboardAnalyticsCaloriesLegend.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get dashboardAnalyticsCaloriesLegend;

  /// No description provided for @dashboardAnalyticsWeeklySteps.
  ///
  /// In en, this message translates to:
  /// **'{value} steps this week'**
  String dashboardAnalyticsWeeklySteps(Object value);

  /// No description provided for @dashboardAnalyticsWeeklyCalories.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal this week'**
  String dashboardAnalyticsWeeklyCalories(Object value);

  /// No description provided for @dashboardSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get dashboardSignOut;

  /// No description provided for @dashboardSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String dashboardSignedInAs(Object email);

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @goalLoseWeight.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get goalLoseWeight;

  /// No description provided for @goalMaintainWeight.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get goalMaintainWeight;

  /// No description provided for @goalGainWeight.
  ///
  /// In en, this message translates to:
  /// **'Gain weight'**
  String get goalGainWeight;

  /// No description provided for @profileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & goals'**
  String get profileScreenTitle;

  /// No description provided for @profileScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile, personal data, and body metrics.'**
  String get profileScreenSubtitle;

  /// No description provided for @profilePersonalSection.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get profilePersonalSection;

  /// No description provided for @profileBodySection.
  ///
  /// In en, this message translates to:
  /// **'Body metrics'**
  String get profileBodySection;

  /// No description provided for @profileGoalsSection.
  ///
  /// In en, this message translates to:
  /// **'Goal settings'**
  String get profileGoalsSection;

  /// No description provided for @profileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height, cm'**
  String get profileHeight;

  /// No description provided for @profileCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current weight, kg'**
  String get profileCurrentWeight;

  /// No description provided for @profileStartWeight.
  ///
  /// In en, this message translates to:
  /// **'Starting weight, kg'**
  String get profileStartWeight;

  /// No description provided for @profileTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target weight, kg'**
  String get profileTargetWeight;

  /// No description provided for @profileGoalType.
  ///
  /// In en, this message translates to:
  /// **'Main goal'**
  String get profileGoalType;

  /// No description provided for @profileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCity;

  /// No description provided for @profileCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Please choose your city'**
  String get profileCityRequired;

  /// No description provided for @profileCityDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your city'**
  String get profileCityDialogTitle;

  /// No description provided for @profileCityDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'To participate in the city leaderboard, select the city where you live.'**
  String get profileCityDialogMessage;

  /// No description provided for @profileDailyStepGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily step goal'**
  String get profileDailyStepGoal;

  /// No description provided for @profileDailyCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily calorie goal, kcal'**
  String get profileDailyCalorieGoal;

  /// No description provided for @profileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveButton;

  /// No description provided for @profileSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileSavedMessage;

  /// No description provided for @profileHeightShort.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeightShort;

  /// No description provided for @profileCurrentWeightShort.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get profileCurrentWeightShort;

  /// No description provided for @profileStartWeightShort.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get profileStartWeightShort;

  /// No description provided for @profileTargetWeightShort.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get profileTargetWeightShort;

  /// No description provided for @profileKgUnit.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get profileKgUnit;

  /// No description provided for @profileCmUnit.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get profileCmUnit;

  /// No description provided for @profileCaloriesUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get profileCaloriesUnit;

  /// No description provided for @dashboardWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight loss analytics'**
  String get dashboardWeightTitle;

  /// No description provided for @dashboardWeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your current dynamics based on the saved weight history.'**
  String get dashboardWeightSubtitle;

  /// No description provided for @dashboardWeightCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current weight {value} kg'**
  String dashboardWeightCurrent(Object value);

  /// No description provided for @dashboardWeightTarget.
  ///
  /// In en, this message translates to:
  /// **'Target {value} kg'**
  String dashboardWeightTarget(Object value);

  /// No description provided for @dashboardWeightLost.
  ///
  /// In en, this message translates to:
  /// **'Progress {value} kg'**
  String dashboardWeightLost(Object value);

  /// No description provided for @dashboardWeightWeekly.
  ///
  /// In en, this message translates to:
  /// **'For the selected week {value} kg'**
  String dashboardWeightWeekly(Object value);

  /// No description provided for @dashboardWeightRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining {value} kg'**
  String dashboardWeightRemaining(Object value);

  /// No description provided for @dashboardWeightEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your current and target weight'**
  String get dashboardWeightEmptyTitle;

  /// No description provided for @dashboardWeightEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Once you do that, the dashboard will show weight-loss analytics.'**
  String get dashboardWeightEmptySubtitle;

  /// No description provided for @dashboardWeekStartWeight.
  ///
  /// In en, this message translates to:
  /// **'Week start {value} kg'**
  String dashboardWeekStartWeight(Object value);

  /// No description provided for @dashboardWeekEndWeight.
  ///
  /// In en, this message translates to:
  /// **'Week end {value} kg'**
  String dashboardWeekEndWeight(Object value);

  /// No description provided for @goalSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal settings'**
  String get goalSettingsTitle;

  /// No description provided for @goalSettingsStepsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust the daily step goal from the Today\'s Overview card.'**
  String get goalSettingsStepsSubtitle;

  /// No description provided for @goalSettingsCaloriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust the daily calorie goal from the Today\'s Overview card.'**
  String get goalSettingsCaloriesSubtitle;

  /// No description provided for @goalSettingsProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your main goal and weight targets for progress tracking.'**
  String get goalSettingsProgressSubtitle;

  /// No description provided for @workoutTypeRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get workoutTypeRunning;

  /// No description provided for @workoutTypeCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get workoutTypeCycling;

  /// No description provided for @workoutTypeWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get workoutTypeWalking;

  /// No description provided for @workoutTypeStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get workoutTypeStrength;

  /// No description provided for @workoutTypeCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get workoutTypeCardio;

  /// No description provided for @workoutListTitle.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutListTitle;

  /// No description provided for @workoutListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet. Start your first workout from the dashboard.'**
  String get workoutListEmpty;

  /// No description provided for @workoutFilterDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get workoutFilterDate;

  /// No description provided for @workoutFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get workoutFilterType;

  /// No description provided for @workoutFilterAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get workoutFilterAllTypes;

  /// No description provided for @workoutFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get workoutFilterClear;

  /// No description provided for @workoutStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get workoutStartTitle;

  /// No description provided for @workoutStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a workout type and start tracking your session.'**
  String get workoutStartSubtitle;

  /// No description provided for @workoutStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get workoutStartButton;

  /// No description provided for @workoutTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout type'**
  String get workoutTypeLabel;

  /// No description provided for @workoutActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active workout'**
  String get workoutActiveTitle;

  /// No description provided for @workoutActivePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get workoutActivePause;

  /// No description provided for @workoutActiveResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get workoutActiveResume;

  /// No description provided for @workoutActiveStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get workoutActiveStop;

  /// No description provided for @workoutMetricDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get workoutMetricDuration;

  /// No description provided for @workoutMetricCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get workoutMetricCalories;

  /// No description provided for @workoutMetricDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get workoutMetricDistance;

  /// No description provided for @workoutGpsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'GPS is unavailable. Duration and calories will continue, but route and distance may be incomplete.'**
  String get workoutGpsUnavailable;

  /// No description provided for @workoutNoActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active workout. Start a new one from the dashboard.'**
  String get workoutNoActiveSession;

  /// No description provided for @workoutResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout result'**
  String get workoutResultTitle;

  /// No description provided for @workoutResultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your workout and save it to history.'**
  String get workoutResultSubtitle;

  /// No description provided for @workoutResultSave.
  ///
  /// In en, this message translates to:
  /// **'Save workout'**
  String get workoutResultSave;

  /// No description provided for @workoutNoResult.
  ///
  /// In en, this message translates to:
  /// **'No workout result available.'**
  String get workoutNoResult;

  /// No description provided for @workoutSavedSynced.
  ///
  /// In en, this message translates to:
  /// **'Workout saved locally and synced to Firestore.'**
  String get workoutSavedSynced;

  /// No description provided for @workoutSavedLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Workout saved locally. Firestore sync will complete later.'**
  String get workoutSavedLocalOnly;

  /// No description provided for @mealTypeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealTypeBreakfast;

  /// No description provided for @mealTypeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealTypeLunch;

  /// No description provided for @mealTypeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealTypeDinner;

  /// No description provided for @mealTypeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealTypeSnack;

  /// No description provided for @foodDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Food diary'**
  String get foodDiaryTitle;

  /// No description provided for @foodDiaryPickDate.
  ///
  /// In en, this message translates to:
  /// **'Select diary date'**
  String get foodDiaryPickDate;

  /// No description provided for @foodDiaryAddFood.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get foodDiaryAddFood;

  /// No description provided for @foodDiaryTodayWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s weight'**
  String get foodDiaryTodayWeightTitle;

  /// No description provided for @foodDiaryTodayWeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save today\'s weight so it appears in your profile and analytics.'**
  String get foodDiaryTodayWeightSubtitle;

  /// No description provided for @foodDiaryWeightSaved.
  ///
  /// In en, this message translates to:
  /// **'Today\'s weight saved.'**
  String get foodDiaryWeightSaved;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Community chat'**
  String get chatTitle;

  /// No description provided for @chatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time messages from Liga Gym members.'**
  String get chatSubtitle;

  /// No description provided for @chatDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Interest chats'**
  String get chatDirectoryTitle;

  /// No description provided for @chatDirectorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your own communities, join any chat, and find like-minded people.'**
  String get chatDirectorySubtitle;

  /// No description provided for @chatDirectoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no chats yet. Create the first interest chat.'**
  String get chatDirectoryEmpty;

  /// No description provided for @chatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by interest'**
  String get chatSearchHint;

  /// No description provided for @chatSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chats found for your search.'**
  String get chatSearchEmpty;

  /// No description provided for @chatCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create chat'**
  String get chatCreateAction;

  /// No description provided for @chatCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatCreateTitle;

  /// No description provided for @chatInterestName.
  ///
  /// In en, this message translates to:
  /// **'Interest name'**
  String get chatInterestName;

  /// No description provided for @chatInterestDescription.
  ///
  /// In en, this message translates to:
  /// **'Chat description'**
  String get chatInterestDescription;

  /// No description provided for @chatMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{value} members'**
  String chatMembersCount(Object value);

  /// No description provided for @chatJoinPrompt.
  ///
  /// In en, this message translates to:
  /// **'You have not joined this chat yet. Join to read and send messages.'**
  String get chatJoinPrompt;

  /// No description provided for @chatJoinAction.
  ///
  /// In en, this message translates to:
  /// **'Join chat'**
  String get chatJoinAction;

  /// No description provided for @chatRoomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Chat was not found or has been removed.'**
  String get chatRoomNotFound;

  /// No description provided for @chatManageParticipantTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage: {name}'**
  String chatManageParticipantTitle(Object name);

  /// No description provided for @chatRemoveParticipantTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove user {name}'**
  String chatRemoveParticipantTitle(Object name);

  /// No description provided for @chatRemoveParticipantAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chatRemoveParticipantAction;

  /// No description provided for @chatRemoveReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Removal reason, optional'**
  String get chatRemoveReasonOptional;

  /// No description provided for @chatRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get chatRoleLabel;

  /// No description provided for @chatRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get chatRoleAdmin;

  /// No description provided for @chatRoleModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get chatRoleModerator;

  /// No description provided for @chatRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get chatRoleMember;

  /// No description provided for @chatCanDeleteMessages.
  ///
  /// In en, this message translates to:
  /// **'Can delete messages'**
  String get chatCanDeleteMessages;

  /// No description provided for @chatCanDeleteUsers.
  ///
  /// In en, this message translates to:
  /// **'Can delete users'**
  String get chatCanDeleteUsers;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Start the conversation.'**
  String get chatEmpty;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get chatInputHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatYou;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top athletes by social score.'**
  String get leaderboardSubtitle;

  /// No description provided for @leaderboardRussiaTab.
  ///
  /// In en, this message translates to:
  /// **'Russia'**
  String get leaderboardRussiaTab;

  /// No description provided for @leaderboardCityTab.
  ///
  /// In en, this message translates to:
  /// **'My city'**
  String get leaderboardCityTab;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard is still empty. Save a workout to claim the first spot.'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardCityEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no participants in {city} yet.'**
  String leaderboardCityEmpty(Object city);

  /// No description provided for @leaderboardPoints.
  ///
  /// In en, this message translates to:
  /// **'{value} pts'**
  String leaderboardPoints(Object value);

  /// No description provided for @leaderboardWorkouts.
  ///
  /// In en, this message translates to:
  /// **'{value} workouts'**
  String leaderboardWorkouts(Object value);

  /// No description provided for @leaderboardSteps.
  ///
  /// In en, this message translates to:
  /// **'{value} steps'**
  String leaderboardSteps(Object value);

  /// No description provided for @leaderboardYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardYou;

  /// No description provided for @foodDiaryMealType.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get foodDiaryMealType;

  /// No description provided for @foodDiaryEmptySection.
  ///
  /// In en, this message translates to:
  /// **'No entries for this meal yet.'**
  String get foodDiaryEmptySection;

  /// No description provided for @foodDiaryEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{grams} g • {calories} kcal'**
  String foodDiaryEntrySubtitle(Object grams, Object calories);

  /// No description provided for @foodDiaryInlineMacros.
  ///
  /// In en, this message translates to:
  /// **'P {proteins} • F {fats} • C {carbs}'**
  String foodDiaryInlineMacros(Object proteins, Object fats, Object carbs);

  /// No description provided for @addFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get addFoodTitle;

  /// No description provided for @addFoodManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get addFoodManual;

  /// No description provided for @addFoodBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get addFoodBarcode;

  /// No description provided for @addFoodQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get addFoodQuickAccess;

  /// No description provided for @addFoodName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get addFoodName;

  /// No description provided for @addFoodBarcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get addFoodBarcodeLabel;

  /// No description provided for @addFoodGrams.
  ///
  /// In en, this message translates to:
  /// **'Portion, g'**
  String get addFoodGrams;

  /// No description provided for @addFoodQuickAccessChooseProduct.
  ///
  /// In en, this message translates to:
  /// **'Select a product from quick access first.'**
  String get addFoodQuickAccessChooseProduct;

  /// No description provided for @addFoodQuickAccessChooseProducts.
  ///
  /// In en, this message translates to:
  /// **'Select at least one product from quick access.'**
  String get addFoodQuickAccessChooseProducts;

  /// No description provided for @addFoodQuickAccessEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no saved products yet. Add a new one manually or by barcode and it will appear here.'**
  String get addFoodQuickAccessEmpty;

  /// No description provided for @addFoodQuickAccessEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get addFoodQuickAccessEdit;

  /// No description provided for @addFoodQuickAccessSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected products: {count}'**
  String addFoodQuickAccessSelectedCount(Object count);

  /// No description provided for @addFoodEditingProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Editing saved product'**
  String get addFoodEditingProductTitle;

  /// No description provided for @addFoodCreateNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Create new product'**
  String get addFoodCreateNewProduct;

  /// No description provided for @productDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get productDetailsTitle;

  /// No description provided for @productDetailsMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal: {meal}'**
  String productDetailsMeal(Object meal);

  /// No description provided for @productDetailsPortion.
  ///
  /// In en, this message translates to:
  /// **'Portion: {grams} g'**
  String productDetailsPortion(Object grams);

  /// No description provided for @productDetailsPer100.
  ///
  /// In en, this message translates to:
  /// **'Per 100 g'**
  String get productDetailsPer100;

  /// No description provided for @productDetailsPortionMacros.
  ///
  /// In en, this message translates to:
  /// **'For selected portion'**
  String get productDetailsPortionMacros;

  /// No description provided for @productDetailsSelectedProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected products'**
  String get productDetailsSelectedProductsTitle;

  /// No description provided for @productDetailsSelectedProductsCount.
  ///
  /// In en, this message translates to:
  /// **'Selected products: {count}'**
  String productDetailsSelectedProductsCount(Object count);

  /// No description provided for @productDetailsTotalMacros.
  ///
  /// In en, this message translates to:
  /// **'Total for selected portions'**
  String get productDetailsTotalMacros;

  /// No description provided for @productDetailsSave.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get productDetailsSave;

  /// No description provided for @stepCounterTitle.
  ///
  /// In en, this message translates to:
  /// **'Step counter'**
  String get stepCounterTitle;

  /// No description provided for @stepCounterSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Step settings'**
  String get stepCounterSettingsTitle;

  /// No description provided for @stepCounterToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s steps'**
  String get stepCounterToday;

  /// No description provided for @stepCounterTodayHint.
  ///
  /// In en, this message translates to:
  /// **'The value is read from the local database and updates while the tracking service is running.'**
  String get stepCounterTodayHint;

  /// No description provided for @stepCounterGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal {value} steps'**
  String stepCounterGoal(Object value);

  /// No description provided for @stepCounterRemaining.
  ///
  /// In en, this message translates to:
  /// **'{value} steps left to the goal'**
  String stepCounterRemaining(Object value);

  /// No description provided for @stepCounterStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get stepCounterStatusTitle;

  /// No description provided for @stepCounterStatusPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get stepCounterStatusPlatform;

  /// No description provided for @stepCounterStatusPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get stepCounterStatusPermission;

  /// No description provided for @stepCounterStatusService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get stepCounterStatusService;

  /// No description provided for @stepCounterStatusAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get stepCounterStatusAccount;

  /// No description provided for @stepCounterStatusSupported.
  ///
  /// In en, this message translates to:
  /// **'Supported'**
  String get stepCounterStatusSupported;

  /// No description provided for @stepCounterStatusUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not supported'**
  String get stepCounterStatusUnsupported;

  /// No description provided for @stepCounterStatusGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get stepCounterStatusGranted;

  /// No description provided for @stepCounterStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get stepCounterStatusDenied;

  /// No description provided for @stepCounterStatusPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied in settings'**
  String get stepCounterStatusPermanentlyDenied;

  /// No description provided for @stepCounterStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get stepCounterStatusRunning;

  /// No description provided for @stepCounterStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stepCounterStatusStopped;

  /// No description provided for @stepCounterStatusLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to current account'**
  String get stepCounterStatusLinked;

  /// No description provided for @stepCounterStatusNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get stepCounterStatusNotLinked;

  /// No description provided for @stepCounterActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get stepCounterActionsTitle;

  /// No description provided for @stepCounterEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable step tracking'**
  String get stepCounterEnable;

  /// No description provided for @stepCounterOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get stepCounterOpenSettings;

  /// No description provided for @stepCounterGoalSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open goal settings'**
  String get stepCounterGoalSettingsAction;

  /// No description provided for @stepGoalReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Step goal achieved'**
  String get stepGoalReachedTitle;

  /// No description provided for @stepGoalReachedMessage.
  ///
  /// In en, this message translates to:
  /// **'You reached your daily step goal. Amazing work!'**
  String get stepGoalReachedMessage;

  /// No description provided for @stepGoalReachedInline.
  ///
  /// In en, this message translates to:
  /// **'Goal reached. Time to celebrate!'**
  String get stepGoalReachedInline;

  /// No description provided for @stepCounterUnsupportedHint.
  ///
  /// In en, this message translates to:
  /// **'Continuous step tracking is currently available only on Android devices with a step sensor.'**
  String get stepCounterUnsupportedHint;

  /// No description provided for @stepCounterPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Grant Activity Recognition permission to start continuous step counting.'**
  String get stepCounterPermissionHint;

  /// No description provided for @stepCounterSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Open app settings and allow Activity Recognition, then return here.'**
  String get stepCounterSettingsHint;

  /// No description provided for @stepCounterEnableHint.
  ///
  /// In en, this message translates to:
  /// **'Tracking is available, but the service is not fully active yet. Tap the enable button.'**
  String get stepCounterEnableHint;

  /// No description provided for @stepCounterRunningHint.
  ///
  /// In en, this message translates to:
  /// **'Tracking is active. Steps should continue updating while the app is minimized.'**
  String get stepCounterRunningHint;

  /// No description provided for @foodCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get foodCalories;

  /// No description provided for @foodProteins.
  ///
  /// In en, this message translates to:
  /// **'Proteins'**
  String get foodProteins;

  /// No description provided for @foodFats.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get foodFats;

  /// No description provided for @foodCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get foodCarbs;

  /// No description provided for @foodCaloriesPer100.
  ///
  /// In en, this message translates to:
  /// **'Calories per 100 g'**
  String get foodCaloriesPer100;

  /// No description provided for @foodProteinsPer100.
  ///
  /// In en, this message translates to:
  /// **'Proteins per 100 g'**
  String get foodProteinsPer100;

  /// No description provided for @foodFatsPer100.
  ///
  /// In en, this message translates to:
  /// **'Fats per 100 g'**
  String get foodFatsPer100;

  /// No description provided for @foodCarbsPer100.
  ///
  /// In en, this message translates to:
  /// **'Carbs per 100 g'**
  String get foodCarbsPer100;

  /// No description provided for @validationEmptyEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get validationEmptyEmail;

  /// No description provided for @validationInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get validationInvalidEmail;

  /// No description provided for @validationEmptyPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get validationEmptyPassword;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 8 characters.'**
  String get validationPasswordTooShort;

  /// No description provided for @validationEmptyConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password.'**
  String get validationEmptyConfirmPassword;

  /// No description provided for @validationPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get validationPasswordsDoNotMatch;

  /// No description provided for @validationEmptyName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get validationEmptyName;

  /// No description provided for @validationEmptyGender.
  ///
  /// In en, this message translates to:
  /// **'Select your gender.'**
  String get validationEmptyGender;

  /// No description provided for @validationEmptyBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select your birth date.'**
  String get validationEmptyBirthDate;

  /// No description provided for @validationInvalidHeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid height.'**
  String get validationInvalidHeight;

  /// No description provided for @validationInvalidCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid current weight.'**
  String get validationInvalidCurrentWeight;

  /// No description provided for @validationInvalidTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid target weight.'**
  String get validationInvalidTargetWeight;

  /// No description provided for @validationInvalidStepGoal.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid daily step goal.'**
  String get validationInvalidStepGoal;

  /// No description provided for @validationInvalidCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid daily calorie goal.'**
  String get validationInvalidCalorieGoal;

  /// No description provided for @validationEmptyChatMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a message.'**
  String get validationEmptyChatMessage;

  /// No description provided for @validationEmptyFoodName.
  ///
  /// In en, this message translates to:
  /// **'Enter the product name.'**
  String get validationEmptyFoodName;

  /// No description provided for @validationEmptyBarcode.
  ///
  /// In en, this message translates to:
  /// **'Enter a barcode.'**
  String get validationEmptyBarcode;

  /// No description provided for @validationInvalidFoodWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid portion in grams.'**
  String get validationInvalidFoodWeight;

  /// No description provided for @validationInvalidCalories.
  ///
  /// In en, this message translates to:
  /// **'Enter valid calories per 100 g.'**
  String get validationInvalidCalories;

  /// No description provided for @validationInvalidProteins.
  ///
  /// In en, this message translates to:
  /// **'Enter valid proteins per 100 g.'**
  String get validationInvalidProteins;

  /// No description provided for @validationInvalidFats.
  ///
  /// In en, this message translates to:
  /// **'Enter valid fats per 100 g.'**
  String get validationInvalidFats;

  /// No description provided for @validationInvalidCarbs.
  ///
  /// In en, this message translates to:
  /// **'Enter valid carbs per 100 g.'**
  String get validationInvalidCarbs;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User with this email was not found.'**
  String get errorUserNotFound;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is incorrect.'**
  String get errorWrongPassword;

  /// No description provided for @errorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'The email or password is invalid.'**
  String get errorInvalidCredential;

  /// No description provided for @errorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailAlreadyInUse;

  /// No description provided for @errorNetworkRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get errorNetworkRequestFailed;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get errorTooManyRequests;

  /// No description provided for @errorGoogleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get errorGoogleSignInCancelled;

  /// No description provided for @errorGoogleSignInNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not supported on this platform.'**
  String get errorGoogleSignInNotSupported;

  /// No description provided for @errorGoogleSignInConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not configured correctly.'**
  String get errorGoogleSignInConfiguration;

  /// No description provided for @errorGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get errorGoogleSignInFailed;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Please log in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorProfileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile could not be saved.'**
  String get errorProfileSaveFailed;

  /// No description provided for @errorWorkoutSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Workout could not be saved.'**
  String get errorWorkoutSaveFailed;

  /// No description provided for @errorChatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Message could not be sent.'**
  String get errorChatSendFailed;

  /// No description provided for @errorChatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Chat could not be loaded.'**
  String get errorChatLoadFailed;

  /// No description provided for @errorLeaderboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard could not be loaded.'**
  String get errorLeaderboardLoadFailed;

  /// No description provided for @errorNutritionDiaryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Food diary could not be loaded.'**
  String get errorNutritionDiaryLoadFailed;

  /// No description provided for @errorNutritionEntrySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Food entry could not be saved.'**
  String get errorNutritionEntrySaveFailed;

  /// No description provided for @errorFoodProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product with this barcode was not found.'**
  String get errorFoodProductNotFound;

  /// No description provided for @errorFirebaseConfigurationMissing.
  ///
  /// In en, this message translates to:
  /// **'Firebase configuration is missing or incomplete.'**
  String get errorFirebaseConfigurationMissing;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
