import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Firebase до старта приложения, чтобы Splash сразу видел auth-состояние.
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: LigaGymApp()));
}
