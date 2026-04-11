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
  String get commonDate => 'Дата';

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
  String get goToRegisterButton => 'Нет аккаунта? Зарегистрируйтесь';

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
  String get dashboardProfile => 'Профиль и цели';

  @override
  String get todayOverviewTitle => 'Обзор за сегодня';

  @override
  String get todayOverviewSubtitle =>
      'Дневные цели, прогресс и питание в одном месте.';

  @override
  String get dashboardHeadline => 'Вы вошли';

  @override
  String get dashboardSubtitle => 'Ваш аккаунт готов к следующей тренировке.';

  @override
  String get dashboardGoalsTitle => 'Цели';

  @override
  String get dashboardGoalsSubtitle =>
      'Настройте дневные цели и целевой вес, чтобы персонализировать дашборд.';

  @override
  String dashboardGoalsSummary(Object goal, Object steps, Object calories) {
    return '$goal • $steps шагов • $calories ккал';
  }

  @override
  String get dashboardGoalsAction => 'Настроить цели';

  @override
  String get dashboardCommunityTitle => 'Сообщество';

  @override
  String get dashboardCommunitySubtitle =>
      'Общайтесь в реальном времени и смотрите, кто лидирует на этой неделе.';

  @override
  String get dashboardCommunityChat => 'Чат';

  @override
  String get dashboardCommunityLeaderboard => 'Лидерборд';

  @override
  String get dashboardStartWorkout => 'Начать тренировку';

  @override
  String get dashboardWorkoutHistory => 'История тренировок';

  @override
  String get dashboardStepCounter => 'Шагомер';

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
  String get dashboardAnalyticsOverview => 'Обзор за сегодня';

  @override
  String get dashboardAnalyticsSteps => 'Шаги';

  @override
  String get dashboardAnalyticsCalories => 'Калории';

  @override
  String get dashboardAnalyticsProgress => 'Прогресс';

  @override
  String dashboardAnalyticsStepGoal(Object value) {
    return 'Цель $value шагов';
  }

  @override
  String dashboardAnalyticsCalorieGoal(Object value) {
    return 'Цель $value ккал';
  }

  @override
  String get dashboardAnalyticsOverallGoal => 'Дневной баланс';

  @override
  String get dashboardAnalyticsWeeklyTitle => 'Аналитика за неделю';

  @override
  String get dashboardAnalyticsWeeklySubtitle => 'Последние 7 дней';

  @override
  String get dashboardAnalyticsOpenDetails => 'Подробный отчёт';

  @override
  String get dashboardAnalyticsRangeTitle => 'Аналитика результатов';

  @override
  String get dashboardAnalyticsRangeSubtitle =>
      'Выберите любой период до 31 дня и посмотрите свои результаты.';

  @override
  String get dashboardAnalyticsFrom => 'С';

  @override
  String get dashboardAnalyticsTo => 'По';

  @override
  String get dashboardAnalyticsMaxRangeHint =>
      'Выбранный период не должен превышать 31 день.';

  @override
  String dashboardAnalyticsAverageSteps(Object value) {
    return 'В среднем $value шагов в день';
  }

  @override
  String dashboardAnalyticsAverageCalories(Object value) {
    return 'В среднем $value ккал в день';
  }

  @override
  String dashboardAnalyticsWorkoutCalories(Object value) {
    return 'На тренировках сожжено $value ккал';
  }

  @override
  String dashboardAnalyticsWorkoutsCount(Object value) {
    return 'Выполнено тренировок: $value';
  }

  @override
  String get dashboardAnalyticsResultsByDay => 'Результаты по дням';

  @override
  String get dashboardAnalyticsNoWeightData =>
      'За выбранный период пока нет данных о весе.';

  @override
  String dashboardAnalyticsWeightChange(Object value) {
    return 'Прогресс по весу $value кг';
  }

  @override
  String get dashboardAnalyticsExportPdf => 'Сохранить в PDF';

  @override
  String get dashboardAnalyticsPdfTitle => 'Liga Gym — отчёт по аналитике';

  @override
  String get dashboardAnalyticsPdfRangeLabel => 'Период';

  @override
  String get dashboardAnalyticsPdfSummaryTitle => 'Сводка';

  @override
  String dashboardAnalyticsPdfSaved(Object path) {
    return 'PDF сохранён: $path';
  }

  @override
  String get dashboardAnalyticsStepsLegend => 'Шаги';

  @override
  String get dashboardAnalyticsCaloriesLegend => 'Калории';

  @override
  String dashboardAnalyticsWeeklySteps(Object value) {
    return 'За неделю $value шагов';
  }

  @override
  String dashboardAnalyticsWeeklyCalories(Object value) {
    return 'За неделю $value ккал';
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
  String get goalLoseWeight => 'Снизить вес';

  @override
  String get goalMaintainWeight => 'Удерживать вес';

  @override
  String get goalGainWeight => 'Набрать вес';

  @override
  String get profileScreenTitle => 'Профиль и цели';

  @override
  String get profileScreenSubtitle =>
      'Управляйте профилем, личными данными и параметрами тела.';

  @override
  String get profilePersonalSection => 'Личные данные';

  @override
  String get profileBodySection => 'Параметры тела';

  @override
  String get profileGoalsSection => 'Настройка целей';

  @override
  String get profileHeight => 'Рост, см';

  @override
  String get profileCurrentWeight => 'Текущий вес, кг';

  @override
  String get profileStartWeight => 'Начальный вес, кг';

  @override
  String get profileTargetWeight => 'Целевой вес, кг';

  @override
  String get profileGoalType => 'Основная цель';

  @override
  String get profileCity => 'Город';

  @override
  String get profileCityRequired => 'Пожалуйста, выберите город';

  @override
  String get profileCityDialogTitle => 'Укажите ваш город';

  @override
  String get profileCityDialogMessage =>
      'Чтобы участвовать в городском лидерборде, выберите город проживания.';

  @override
  String get profileDailyStepGoal => 'Дневная цель по шагам';

  @override
  String get profileDailyCalorieGoal => 'Дневная цель по калориям, ккал';

  @override
  String get profileSaveButton => 'Сохранить изменения';

  @override
  String get profileSavedMessage => 'Профиль обновлён.';

  @override
  String get profileHeightShort => 'Рост';

  @override
  String get profileCurrentWeightShort => 'Текущий';

  @override
  String get profileStartWeightShort => 'Старт';

  @override
  String get profileTargetWeightShort => 'Цель';

  @override
  String get profileKgUnit => 'кг';

  @override
  String get profileCmUnit => 'см';

  @override
  String get profileCaloriesUnit => 'ккал';

  @override
  String get dashboardWeightTitle => 'Аналитика снижения веса';

  @override
  String get dashboardWeightSubtitle =>
      'Текущая динамика по сохранённой истории веса.';

  @override
  String dashboardWeightCurrent(Object value) {
    return 'Текущий вес $value кг';
  }

  @override
  String dashboardWeightTarget(Object value) {
    return 'Цель $value кг';
  }

  @override
  String dashboardWeightLost(Object value) {
    return 'Прогресс $value кг';
  }

  @override
  String dashboardWeightWeekly(Object value) {
    return 'За выбранную неделю $value кг';
  }

  @override
  String dashboardWeightRemaining(Object value) {
    return 'Осталось $value кг';
  }

  @override
  String get dashboardWeightEmptyTitle => 'Добавьте текущий и целевой вес';

  @override
  String get dashboardWeightEmptySubtitle =>
      'Тогда дашборд начнёт показывать аналитику снижения веса.';

  @override
  String dashboardWeekStartWeight(Object value) {
    return 'Вес в начале недели $value кг';
  }

  @override
  String dashboardWeekEndWeight(Object value) {
    return 'Вес в конце недели $value кг';
  }

  @override
  String get goalSettingsTitle => 'Настройка целей';

  @override
  String get goalSettingsStepsSubtitle =>
      'Измените дневную цель по шагам прямо из карточки «Обзор за сегодня».';

  @override
  String get goalSettingsCaloriesSubtitle =>
      'Измените дневную цель по калориям прямо из карточки «Обзор за сегодня».';

  @override
  String get goalSettingsProgressSubtitle =>
      'Настройте основную цель и целевые значения веса для отслеживания прогресса.';

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
  String get foodDiaryTodayWeightTitle => 'Вес сегодня';

  @override
  String get foodDiaryTodayWeightSubtitle =>
      'Сохраните сегодняшний вес, чтобы он попал в профиль и аналитику.';

  @override
  String get foodDiaryWeightSaved => 'Вес за сегодня сохранён.';

  @override
  String get chatTitle => 'Чат сообщества';

  @override
  String get chatSubtitle =>
      'Сообщения участников Liga Gym в реальном времени.';

  @override
  String get chatDirectoryTitle => 'Чаты по интересам';

  @override
  String get chatDirectorySubtitle =>
      'Создавайте свои сообщества, вступайте в любые чаты и находите единомышленников.';

  @override
  String get chatDirectoryEmpty =>
      'Пока нет ни одного чата. Создайте первый чат по интересам.';

  @override
  String get chatSearchHint => 'Поиск по интересу';

  @override
  String get chatSearchEmpty => 'По вашему запросу чаты не найдены.';

  @override
  String get chatCreateAction => 'Создать чат';

  @override
  String get chatCreateTitle => 'Новый чат';

  @override
  String get chatInterestName => 'Название интереса';

  @override
  String get chatInterestDescription => 'Описание чата';

  @override
  String chatMembersCount(Object value) {
    return '$value участников';
  }

  @override
  String get chatJoinPrompt =>
      'Вы ещё не вступили в этот чат. Вступите, чтобы читать сообщения и писать в беседу.';

  @override
  String get chatJoinAction => 'Вступить в чат';

  @override
  String get chatRoomNotFound => 'Чат не найден или был удалён.';

  @override
  String chatManageParticipantTitle(Object name) {
    return 'Управление: $name';
  }

  @override
  String chatRemoveParticipantTitle(Object name) {
    return 'Исключить пользователя $name';
  }

  @override
  String get chatRemoveParticipantAction => 'Исключить';

  @override
  String get chatRemoveReasonOptional => 'Причина исключения, необязательно';

  @override
  String get chatRoleLabel => 'Роль';

  @override
  String get chatRoleAdmin => 'Администратор';

  @override
  String get chatRoleModerator => 'Модератор';

  @override
  String get chatRoleMember => 'Участник';

  @override
  String get chatCanDeleteMessages => 'Может удалять сообщения';

  @override
  String get chatCanDeleteUsers => 'Может удалять пользователей';

  @override
  String get chatEmpty => 'Сообщений пока нет. Начните разговор первым.';

  @override
  String get chatInputHint => 'Напишите сообщение';

  @override
  String get chatSend => 'Отправить';

  @override
  String get chatYou => 'Вы';

  @override
  String get leaderboardTitle => 'Лидерборд';

  @override
  String get leaderboardSubtitle => 'Топ спортсменов по social score.';

  @override
  String get leaderboardRussiaTab => 'Россия';

  @override
  String get leaderboardCityTab => 'Мой город';

  @override
  String get leaderboardEmpty =>
      'Лидерборд пока пуст. Сохраните тренировку, чтобы занять первое место.';

  @override
  String leaderboardCityEmpty(Object city) {
    return 'В городе $city пока нет участников.';
  }

  @override
  String leaderboardPoints(Object value) {
    return '$value очков';
  }

  @override
  String leaderboardWorkouts(Object value) {
    return '$value тренировок';
  }

  @override
  String leaderboardSteps(Object value) {
    return '$value шагов';
  }

  @override
  String get leaderboardYou => 'Вы';

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
  String get addFoodQuickAccess => 'Быстрый доступ';

  @override
  String get addFoodName => 'Название продукта';

  @override
  String get addFoodBarcodeLabel => 'Штрихкод';

  @override
  String get addFoodGrams => 'Порция, г';

  @override
  String get addFoodQuickAccessChooseProduct =>
      'Сначала выберите продукт из быстрого доступа.';

  @override
  String get addFoodQuickAccessChooseProducts =>
      'Выберите хотя бы один продукт из быстрого доступа.';

  @override
  String get addFoodQuickAccessEmpty =>
      'Пока нет сохранённых продуктов. Добавьте новый продукт вручную или по штрихкоду, и он появится здесь.';

  @override
  String get addFoodQuickAccessEdit => 'Изменить продукт';

  @override
  String addFoodQuickAccessSelectedCount(Object count) {
    return 'Выбрано продуктов: $count';
  }

  @override
  String get addFoodEditingProductTitle =>
      'Редактирование сохранённого продукта';

  @override
  String get addFoodCreateNewProduct => 'Создать новый продукт';

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
  String get productDetailsSelectedProductsTitle => 'Выбранные продукты';

  @override
  String productDetailsSelectedProductsCount(Object count) {
    return 'Продуктов выбрано: $count';
  }

  @override
  String get productDetailsTotalMacros => 'Итого по выбранным порциям';

  @override
  String get productDetailsSave => 'Сохранить запись';

  @override
  String get stepCounterTitle => 'Шагомер';

  @override
  String get stepCounterSettingsTitle => 'Настройки шагомера';

  @override
  String get stepCounterToday => 'Шаги за сегодня';

  @override
  String get stepCounterTodayHint =>
      'Значение читается из локальной базы и обновляется, пока работает сервис отслеживания.';

  @override
  String stepCounterGoal(Object value) {
    return 'Цель $value шагов';
  }

  @override
  String stepCounterRemaining(Object value) {
    return 'До цели осталось $value шагов';
  }

  @override
  String get stepCounterStatusTitle => 'Статус';

  @override
  String get stepCounterStatusPlatform => 'Платформа';

  @override
  String get stepCounterStatusPermission => 'Разрешение';

  @override
  String get stepCounterStatusService => 'Сервис';

  @override
  String get stepCounterStatusAccount => 'Аккаунт';

  @override
  String get stepCounterStatusSupported => 'Поддерживается';

  @override
  String get stepCounterStatusUnsupported => 'Не поддерживается';

  @override
  String get stepCounterStatusGranted => 'Выдано';

  @override
  String get stepCounterStatusDenied => 'Не выдано';

  @override
  String get stepCounterStatusPermanentlyDenied => 'Запрещено в настройках';

  @override
  String get stepCounterStatusRunning => 'Работает';

  @override
  String get stepCounterStatusStopped => 'Остановлен';

  @override
  String get stepCounterStatusLinked => 'Привязан к текущему аккаунту';

  @override
  String get stepCounterStatusNotLinked => 'Не привязан';

  @override
  String get stepCounterActionsTitle => 'Действия';

  @override
  String get stepCounterEnable => 'Включить шагомер';

  @override
  String get stepCounterOpenSettings => 'Открыть настройки приложения';

  @override
  String get stepCounterGoalSettingsAction => 'Открыть настройки цели';

  @override
  String get stepGoalReachedTitle => 'Цель по шагам достигнута';

  @override
  String get stepGoalReachedMessage =>
      'Вы достигли дневной цели по шагам. Отличная работа!';

  @override
  String get stepGoalReachedInline => 'Цель выполнена. Можно праздновать!';

  @override
  String get stepCounterUnsupportedHint =>
      'Непрерывный подсчёт шагов сейчас доступен только на Android-устройствах с шаговым сенсором.';

  @override
  String get stepCounterPermissionHint =>
      'Выдайте разрешение на физическую активность, чтобы запустить постоянный подсчёт шагов.';

  @override
  String get stepCounterSettingsHint =>
      'Откройте настройки приложения, разрешите физическую активность и вернитесь сюда.';

  @override
  String get stepCounterEnableHint =>
      'Отслеживание доступно, но сервис ещё не полностью активен. Нажмите кнопку включения.';

  @override
  String get stepCounterRunningHint =>
      'Отслеживание активно. Шаги должны продолжать обновляться, пока приложение свернуто.';

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
  String get validationInvalidHeight => 'Введите корректный рост.';

  @override
  String get validationInvalidCurrentWeight =>
      'Введите корректный текущий вес.';

  @override
  String get validationInvalidTargetWeight => 'Введите корректный целевой вес.';

  @override
  String get validationInvalidStepGoal =>
      'Введите корректную дневную цель по шагам.';

  @override
  String get validationInvalidCalorieGoal =>
      'Введите корректную дневную цель по калориям.';

  @override
  String get validationEmptyChatMessage => 'Введите сообщение.';

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
  String get errorChatSendFailed => 'Не удалось отправить сообщение.';

  @override
  String get errorChatLoadFailed => 'Не удалось загрузить чат.';

  @override
  String get errorLeaderboardLoadFailed => 'Не удалось загрузить лидерборд.';

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
