// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Liga Gym';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Пароль';

  @override
  String get commonConfirmPassword => 'Подтвердите пароль';

  @override
  String get commonName => 'Имя';

  @override
  String get commonGender => 'Пол';

  @override
  String get commonBirthDate => 'Дата рождения';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get splashTitle => 'Liga Gym';

  @override
  String get splashSubtitle =>
      'Подготавливаем пространство для тренировок и проверяем ваш аккаунт.';

  @override
  String get splashErrorMessage =>
      'Не удалось проверить сессию. Попробуйте ещё раз.';

  @override
  String get loginTitle => 'С возвращением';

  @override
  String get loginSubtitle => 'Войдите, чтобы продолжить путь к тренировкам.';

  @override
  String get loginButton => 'Войти';

  @override
  String get googleSignInButton => 'Продолжить через Google';

  @override
  String get goToRegisterButton => 'К регистрации';

  @override
  String get registerTitle => 'Создать аккаунт';

  @override
  String get registerSubtitle =>
      'Зарегистрируйтесь, чтобы настроить профиль и начать тренировки.';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get goToLoginButton => 'Назад ко входу';

  @override
  String get profileSetupTitle => 'Настройка профиля';

  @override
  String get profileSetupSubtitle =>
      'Расскажите немного о себе, чтобы мы персонализировали приложение.';

  @override
  String get profileSetupButton => 'Сохранить профиль';

  @override
  String get profileBirthDatePickerHelp => 'Выберите дату рождения';

  @override
  String get dashboardTitle => 'Главная';

  @override
  String get dashboardHeadline => 'Вы вошли';

  @override
  String get dashboardSubtitle => 'Ваш аккаунт готов к следующей тренировке.';

  @override
  String get dashboardStartWorkout => 'Начать тренировку';

  @override
  String get dashboardWorkoutHistory => 'История тренировок';

  @override
  String get dashboardNutritionDiary => 'Дневник питания';

  @override
  String get dashboardNutritionTitle => 'Питание за сегодня';

  @override
  String dashboardNutritionCalories(Object value) {
    return 'Калории: $value';
  }

  @override
  String dashboardNutritionProteins(Object value) {
    return 'Белки: $value';
  }

  @override
  String dashboardNutritionFats(Object value) {
    return 'Жиры: $value';
  }

  @override
  String dashboardNutritionCarbs(Object value) {
    return 'Углеводы: $value';
  }

  @override
  String get dashboardSignOut => 'Выйти';

  @override
  String dashboardSignedInAs(Object email) {
    return 'Вы вошли как $email';
  }

  @override
  String get genderMale => 'Мужской';

  @override
  String get genderFemale => 'Женский';

  @override
  String get genderOther => 'Другой';

  @override
  String get workoutTypeRunning => 'Бег';

  @override
  String get workoutTypeCycling => 'Велосипед';

  @override
  String get workoutTypeWalking => 'Ходьба';

  @override
  String get workoutTypeStrength => 'Силовая';

  @override
  String get workoutTypeCardio => 'Кардио';

  @override
  String get workoutListTitle => 'Тренировки';

  @override
  String get workoutListEmpty =>
      'Тренировок пока нет. Начните первую тренировку с главного экрана.';

  @override
  String get workoutFilterDate => 'Выбрать дату';

  @override
  String get workoutFilterType => 'Тип';

  @override
  String get workoutFilterAllTypes => 'Все типы';

  @override
  String get workoutFilterClear => 'Сбросить фильтры';

  @override
  String get workoutStartTitle => 'Старт тренировки';

  @override
  String get workoutStartSubtitle =>
      'Выберите тип тренировки и начните отслеживание сессии.';

  @override
  String get workoutStartButton => 'Старт';

  @override
  String get workoutTypeLabel => 'Тип тренировки';

  @override
  String get workoutActiveTitle => 'Активная тренировка';

  @override
  String get workoutActivePause => 'Пауза';

  @override
  String get workoutActiveResume => 'Продолжить';

  @override
  String get workoutActiveStop => 'Остановить';

  @override
  String get workoutMetricDuration => 'Длительность';

  @override
  String get workoutMetricCalories => 'Калории';

  @override
  String get workoutMetricDistance => 'Дистанция';

  @override
  String get workoutGpsUnavailable =>
      'GPS недоступен. Длительность и калории будут считаться, но маршрут и дистанция могут быть неполными.';

  @override
  String get workoutNoActiveSession =>
      'Нет активной тренировки. Запустите новую с главного экрана.';

  @override
  String get workoutResultTitle => 'Результат тренировки';

  @override
  String get workoutResultSubtitle =>
      'Проверьте результат и сохраните тренировку в историю.';

  @override
  String get workoutResultSave => 'Сохранить тренировку';

  @override
  String get workoutNoResult => 'Нет данных о результате тренировки.';

  @override
  String get workoutSavedSynced =>
      'Тренировка сохранена локально и синхронизирована с Firestore.';

  @override
  String get workoutSavedLocalOnly =>
      'Тренировка сохранена локально. Синхронизация с Firestore выполнится позже.';

  @override
  String get mealTypeBreakfast => 'Завтрак';

  @override
  String get mealTypeLunch => 'Обед';

  @override
  String get mealTypeDinner => 'Ужин';

  @override
  String get mealTypeSnack => 'Перекус';

  @override
  String get foodDiaryTitle => 'Дневник питания';

  @override
  String get foodDiaryPickDate => 'Выберите дату дневника';

  @override
  String get foodDiaryAddFood => 'Добавить еду';

  @override
  String get foodDiaryMealType => 'Приём пищи';

  @override
  String get foodDiaryEmptySection => 'Для этого приёма пищи записей пока нет.';

  @override
  String foodDiaryEntrySubtitle(Object grams, Object calories) {
    return '$grams г • $calories ккал';
  }

  @override
  String foodDiaryInlineMacros(Object proteins, Object fats, Object carbs) {
    return 'Б $proteins • Ж $fats • У $carbs';
  }

  @override
  String get addFoodTitle => 'Добавление еды';

  @override
  String get addFoodManual => 'Вручную';

  @override
  String get addFoodBarcode => 'Штрихкод';

  @override
  String get addFoodName => 'Название продукта';

  @override
  String get addFoodBarcodeLabel => 'Штрихкод';

  @override
  String get addFoodGrams => 'Порция, г';

  @override
  String get productDetailsTitle => 'Информация о продукте';

  @override
  String productDetailsMeal(Object meal) {
    return 'Приём пищи: $meal';
  }

  @override
  String productDetailsPortion(Object grams) {
    return 'Порция: $grams г';
  }

  @override
  String get productDetailsPer100 => 'На 100 г';

  @override
  String get productDetailsPortionMacros => 'Для выбранной порции';

  @override
  String get productDetailsSave => 'Сохранить запись';

  @override
  String get foodCalories => 'Калории';

  @override
  String get foodProteins => 'Белки';

  @override
  String get foodFats => 'Жиры';

  @override
  String get foodCarbs => 'Углеводы';

  @override
  String get foodCaloriesPer100 => 'Калории на 100 г';

  @override
  String get foodProteinsPer100 => 'Белки на 100 г';

  @override
  String get foodFatsPer100 => 'Жиры на 100 г';

  @override
  String get foodCarbsPer100 => 'Углеводы на 100 г';

  @override
  String get validationEmptyEmail => 'Введите email.';

  @override
  String get validationInvalidEmail => 'Введите корректный email.';

  @override
  String get validationEmptyPassword => 'Введите пароль.';

  @override
  String get validationPasswordTooShort =>
      'Пароль должен содержать минимум 8 символов.';

  @override
  String get validationEmptyConfirmPassword => 'Подтвердите пароль.';

  @override
  String get validationPasswordsDoNotMatch => 'Пароли не совпадают.';

  @override
  String get validationEmptyName => 'Введите имя.';

  @override
  String get validationEmptyGender => 'Выберите пол.';

  @override
  String get validationEmptyBirthDate => 'Выберите дату рождения.';

  @override
  String get validationEmptyFoodName => 'Введите название продукта.';

  @override
  String get validationEmptyBarcode => 'Введите штрихкод.';

  @override
  String get validationInvalidFoodWeight =>
      'Введите корректный вес порции в граммах.';

  @override
  String get validationInvalidCalories =>
      'Введите корректные калории на 100 г.';

  @override
  String get validationInvalidProteins => 'Введите корректные белки на 100 г.';

  @override
  String get validationInvalidFats => 'Введите корректные жиры на 100 г.';

  @override
  String get validationInvalidCarbs => 'Введите корректные углеводы на 100 г.';

  @override
  String get errorUserNotFound => 'Пользователь с таким email не найден.';

  @override
  String get errorWrongPassword => 'Введён неверный пароль.';

  @override
  String get errorInvalidCredential => 'Неверный email или пароль.';

  @override
  String get errorEmailAlreadyInUse => 'Аккаунт с таким email уже существует.';

  @override
  String get errorNetworkRequestFailed =>
      'Сетевая ошибка. Проверьте соединение и попробуйте снова.';

  @override
  String get errorTooManyRequests => 'Слишком много попыток. Попробуйте позже.';

  @override
  String get errorGoogleSignInCancelled => 'Вход через Google был отменён.';

  @override
  String get errorGoogleSignInNotSupported =>
      'Вход через Google не поддерживается на этой платформе.';

  @override
  String get errorGoogleSignInConfiguration =>
      'Вход через Google настроен некорректно.';

  @override
  String get errorGoogleSignInFailed =>
      'Не удалось выполнить вход через Google. Попробуйте снова.';

  @override
  String get errorUnauthorized => 'Пожалуйста, войдите снова.';

  @override
  String get errorProfileSaveFailed => 'Не удалось сохранить профиль.';

  @override
  String get errorWorkoutSaveFailed => 'Не удалось сохранить тренировку.';

  @override
  String get errorNutritionDiaryLoadFailed =>
      'Не удалось загрузить дневник питания.';

  @override
  String get errorNutritionEntrySaveFailed =>
      'Не удалось сохранить запись о еде.';

  @override
  String get errorFoodProductNotFound =>
      'Продукт с таким штрихкодом не найден.';

  @override
  String get errorFirebaseConfigurationMissing =>
      'Конфигурация Firebase отсутствует или настроена не полностью.';

  @override
  String get errorUnknown => 'Что-то пошло не так. Попробуйте ещё раз.';
}
