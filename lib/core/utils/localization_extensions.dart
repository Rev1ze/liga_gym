import '../../features/auth/domain/entities/gender.dart';
import '../../features/nutrition/domain/entities/meal_type.dart';
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
      AppErrorCode.emptyFoodName => l10n.validationEmptyFoodName,
      AppErrorCode.emptyBarcode => l10n.validationEmptyBarcode,
      AppErrorCode.emptyChatMessage => l10n.validationEmptyChatMessage,
      AppErrorCode.invalidFoodWeight => l10n.validationInvalidFoodWeight,
      AppErrorCode.invalidCalories => l10n.validationInvalidCalories,
      AppErrorCode.invalidProteins => l10n.validationInvalidProteins,
      AppErrorCode.invalidFats => l10n.validationInvalidFats,
      AppErrorCode.invalidCarbs => l10n.validationInvalidCarbs,
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
      AppErrorCode.workoutSaveFailed => l10n.errorWorkoutSaveFailed,
      AppErrorCode.chatSendFailed => l10n.errorChatSendFailed,
      AppErrorCode.chatLoadFailed => l10n.errorChatLoadFailed,
      AppErrorCode.leaderboardLoadFailed => l10n.errorLeaderboardLoadFailed,
      AppErrorCode.nutritionDiaryLoadFailed =>
        l10n.errorNutritionDiaryLoadFailed,
      AppErrorCode.nutritionEntrySaveFailed =>
        l10n.errorNutritionEntrySaveFailed,
      AppErrorCode.foodProductNotFound => l10n.errorFoodProductNotFound,
      AppErrorCode.firebaseConfigurationMissing =>
        l10n.errorFirebaseConfigurationMissing,
      AppErrorCode.unknown => l10n.errorUnknown,
    };
  }
}

extension MealTypeLocalization on MealType {
  String localize(AppLocalizations l10n) {
    return switch (this) {
      MealType.breakfast => l10n.mealTypeBreakfast,
      MealType.lunch => l10n.mealTypeLunch,
      MealType.dinner => l10n.mealTypeDinner,
      MealType.snack => l10n.mealTypeSnack,
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
