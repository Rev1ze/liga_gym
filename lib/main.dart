import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Firebase до старта приложения, чтобы Splash сразу видел auth-состояние.
  final firebaseBootstrap = await FirebaseBootstrapResult.initialize();
  final sharedPreferences = await SharedPreferences.getInstance();
  final initialLocale = parseSavedLocale(
    sharedPreferences.getString('app_locale'),
  );

  runApp(
    ProviderScope(
      overrides: [
        firebaseBootstrapProvider.overrideWithValue(firebaseBootstrap),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        initialAppLocaleProvider.overrideWithValue(initialLocale),
      ],
      child: const LigaGymApp(),
    ),
  );
}
