import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

enum FirebaseRuntimeMode { configured, emulator, unavailable }

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({required this.isConfigured, this.error});

  final bool isConfigured;
  final Object? error;
  FirebaseRuntimeMode get mode => isConfigured
      ? FirebaseRuntimeMode.configured
      : FirebaseRuntimeMode.unavailable;
  bool get usesEmulator => false;
  bool get supportsGoogleSignIn => isConfigured && !usesEmulator;

  static Future<FirebaseBootstrapResult> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return const FirebaseBootstrapResult(isConfigured: true);
    } catch (error) {
      debugPrint('Firebase initialization skipped: $error');

      return FirebaseUnavailableBootstrapResult(error: error);
    }
  }
}

class FirebaseUnavailableBootstrapResult extends FirebaseBootstrapResult {
  const FirebaseUnavailableBootstrapResult({super.error})
    : super(isConfigured: false);
}

final firebaseBootstrapProvider = Provider<FirebaseBootstrapResult>(
  (ref) =>
      throw UnimplementedError('firebaseBootstrapProvider is not overridden'),
);
