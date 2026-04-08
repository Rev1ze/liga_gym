import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Firebase до старта приложения, чтобы Splash сразу видел auth-состояние.
  final firebaseBootstrap = await FirebaseBootstrapResult.initialize();

  runApp(
    ProviderScope(
      overrides: [
        firebaseBootstrapProvider.overrideWithValue(firebaseBootstrap),
      ],
      child: const LigaGymApp(),
    ),
  );
}
