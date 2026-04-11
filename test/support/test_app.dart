import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liga_gym_app/core/firebase/firebase_bootstrap.dart';
import 'package:liga_gym_app/core/navigation/app_router.dart';
import 'package:liga_gym_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:liga_gym_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:liga_gym_app/l10n/app_localizations.dart';

Widget buildTestApp({
  required AuthRepository repository,
  required Widget home,
  List overrides = const [],
  RouteFactory? onGenerateRoute,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      firebaseBootstrapProvider.overrideWithValue(
        const FirebaseBootstrapResult(isConfigured: true),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      locale: locale,
      onGenerateRoute: onGenerateRoute,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

Widget buildRoutedTestApp({
  required AuthRepository repository,
  String initialRoute = '/',
  List overrides = const [],
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      firebaseBootstrapProvider.overrideWithValue(
        const FirebaseBootstrapResult(isConfigured: true),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      locale: locale,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onGenerateInitialRoutes: (routeName) {
        return [
          AppRouter.onGenerateRoute(
            RouteSettings(name: initialRoute.isEmpty ? '/' : initialRoute),
          ),
        ];
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}
