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
  String get commonConfirmPassword => 'Подтверждение пароля';

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
  String get loginSubtitle => 'Войдите, чтобы продолжить тренировки.';

  @override
  String get loginButton => 'Войти';

  @override
  String get googleSignInButton => 'Войти через Google';

  @override
  String get goToRegisterButton => 'Перейти к регистрации';

  @override
  String get registerTitle => 'Создание аккаунта';

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
  String get dashboardHeadline => 'Вход выполнен';

  @override
  String get dashboardSubtitle => 'Аккаунт готов к следующей тренировке.';

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
  String get errorTooManyRequests => 'Слишком много попыток. Повторите позже.';

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
  String get errorFirebaseConfigurationMissing =>
      'Конфигурация Firebase отсутствует или настроена не полностью.';

  @override
  String get errorUnknown => 'Что-то пошло не так. Попробуйте ещё раз.';
}
