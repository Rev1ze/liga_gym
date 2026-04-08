import 'package:flutter/widgets.dart';

abstract final class AppKeys {
  static const splashLogo = ValueKey<String>('splashLogo');
  static const loginEmailField = ValueKey<String>('loginEmailField');
  static const loginPasswordField = ValueKey<String>('loginPasswordField');
  static const loginButton = ValueKey<String>('loginButton');
  static const googleSignInButton = ValueKey<String>('googleSignInButton');
  static const goToRegisterButton = ValueKey<String>('goToRegisterButton');
  static const registerEmailField = ValueKey<String>('registerEmailField');
  static const registerPasswordField = ValueKey<String>(
    'registerPasswordField',
  );
  static const registerConfirmPasswordField = ValueKey<String>(
    'registerConfirmPasswordField',
  );
  static const registerButton = ValueKey<String>('registerButton');
  static const goToLoginButton = ValueKey<String>('goToLoginButton');
  static const profileNameField = ValueKey<String>('profileNameField');
  static const profileGenderField = ValueKey<String>('profileGenderField');
  static const profileBirthDateField = ValueKey<String>(
    'profileBirthDateField',
  );
  static const saveProfileButton = ValueKey<String>('saveProfileButton');
  static const signOutButton = ValueKey<String>('signOutButton');
  static const dashboardStartWorkoutButton = ValueKey<String>(
    'dashboardStartWorkoutButton',
  );
  static const dashboardWorkoutHistoryButton = ValueKey<String>(
    'dashboardWorkoutHistoryButton',
  );
  static const workoutStartButton = ValueKey<String>('workoutStartButton');
  static const workoutPauseButton = ValueKey<String>('workoutPauseButton');
  static const workoutStopButton = ValueKey<String>('workoutStopButton');
  static const workoutResultSaveButton = ValueKey<String>(
    'workoutResultSaveButton',
  );
  static const dashboardNutritionDiaryButton = ValueKey<String>(
    'dashboardNutritionDiaryButton',
  );
  static const foodDiaryAddButton = ValueKey<String>('foodDiaryAddButton');
  static const foodDiaryDateButton = ValueKey<String>('foodDiaryDateButton');
  static const addFoodManualTab = ValueKey<String>('addFoodManualTab');
  static const addFoodBarcodeTab = ValueKey<String>('addFoodBarcodeTab');
  static const addFoodMealTypeField = ValueKey<String>('addFoodMealTypeField');
  static const addFoodNameField = ValueKey<String>('addFoodNameField');
  static const addFoodBarcodeField = ValueKey<String>('addFoodBarcodeField');
  static const addFoodCaloriesField = ValueKey<String>('addFoodCaloriesField');
  static const addFoodProteinsField = ValueKey<String>('addFoodProteinsField');
  static const addFoodFatsField = ValueKey<String>('addFoodFatsField');
  static const addFoodCarbsField = ValueKey<String>('addFoodCarbsField');
  static const addFoodGramsField = ValueKey<String>('addFoodGramsField');
  static const addFoodContinueButton = ValueKey<String>(
    'addFoodContinueButton',
  );
  static const productDetailsSaveButton = ValueKey<String>(
    'productDetailsSaveButton',
  );
}
