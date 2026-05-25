import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/providers/app_theme_provider.dart';
import 'core/notifications/app_notification_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/steps/data/services/step_tracking_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Firebase до старта приложения, чтобы Splash сразу видел auth-состояние.
  final firebaseBootstrap = await FirebaseBootstrapResult.initialize();
  final sharedPreferences = await SharedPreferences.getInstance();
  await AppNotificationService.initialize();
  await StepTrackingService.configureBackgroundTracking();
  final initialLocale = parseSavedLocale(
    sharedPreferences.getString('app_locale'),
  );
  final initialTheme = AppThemePalettes.byId(
    sharedPreferences.getString(appThemePreferenceKey),
  );

  runApp(
    ProviderScope(
      overrides: [
        firebaseBootstrapProvider.overrideWithValue(firebaseBootstrap),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        initialAppLocaleProvider.overrideWithValue(initialLocale),
        initialAppThemeProvider.overrideWithValue(initialTheme),
      ],
      child: const LigaGymApp(),
    ),
  );
}
