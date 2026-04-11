import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/offline/offline_sync_providers.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/dashboard/presentation/providers/dashboard_providers.dart';
import 'features/steps/data/services/step_tracking_service.dart';
import 'features/steps/presentation/providers/step_providers.dart';
import 'l10n/app_localizations.dart';

class LigaGymApp extends ConsumerStatefulWidget {
  const LigaGymApp({super.key, this.locale});

  final Locale? locale;

  @override
  ConsumerState<LigaGymApp> createState() => _LigaGymAppState();
}

class _LigaGymAppState extends ConsumerState<LigaGymApp>
    with WidgetsBindingObserver {
  StreamSubscription<Object?>? _authSubscription;
  StreamSubscription<Map<String, dynamic>?>? _stepUpdateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(firebaseAuthProvider).currentUser;
      if (currentUser == null) {
        unawaited(ref.read(stepTrackingServiceProvider).stopTracking());
        return;
      }

      unawaited(
        ref
            .read(stepTrackingServiceProvider)
            .ensureTracking(userId: currentUser.uid),
      );
      unawaited(
        ref
            .read(appOfflineSyncCoordinatorProvider)
            .syncDataWithServer(userId: currentUser.uid),
      );
    });

    _authSubscription = ref
        .read(firebaseAuthProvider)
        .authStateChanges()
        .listen((user) {
          if (user == null) {
            unawaited(ref.read(stepTrackingServiceProvider).stopTracking());
            return;
          }

          unawaited(
            ref
                .read(stepTrackingServiceProvider)
                .ensureTracking(userId: user.uid),
          );
          unawaited(
            ref
                .read(appOfflineSyncCoordinatorProvider)
                .syncDataWithServer(userId: user.uid),
          );
        });

    if (isStepTrackingSupportedPlatform) {
      _stepUpdateSubscription = FlutterBackgroundService()
          .on(stepTrackingUpdateEvent)
          .listen((_) {
            ref.invalidate(dashboardAnalyticsProvider);
          });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _stepUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(dashboardAnalyticsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider) ?? widget.locale;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
