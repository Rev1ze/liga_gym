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
  /// **'Go to Register'**
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

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

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

  /// No description provided for @productDetailsSave.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get productDetailsSave;

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
