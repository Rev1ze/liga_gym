import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/notifications/app_notification_service.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/offline/offline_sync_providers.dart';
import 'core/providers/app_theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/entities/user_profile.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/dashboard/presentation/providers/dashboard_providers.dart';
import 'features/social/presentation/providers/social_providers.dart';
import 'features/steps/data/datasources/step_local_data_source.dart';
import 'features/steps/data/models/daily_step_count_model.dart';
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Object?>? _authSubscription;
  StreamSubscription<Map<String, dynamic>?>? _stepUpdateSubscription;
  StreamSubscription<StepCount>? _foregroundPedometerSubscription;
  ProviderSubscription<AsyncValue<UserProfile?>>? _profileSubscription;
  late final ConfettiController _confettiController;
  final StepLocalDataSource _stepLocalDataSource = SqfliteStepLocalDataSource();
  bool _isCelebrationOpen = false;
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    WidgetsBinding.instance.addObserver(this);

    if (ref.read(firebaseBootstrapProvider).isConfigured) {
      _authSubscription = ref
          .read(firebaseAuthProvider)
          .authStateChanges()
          .listen((user) async {
            final previousUserId = _activeUserId;
            _activeUserId = user?.uid;
            await ref
                .read(stepTrackingServiceProvider)
                .resetUserSession(
                  previousUserId: previousUserId,
                  nextUserId: user?.uid,
                );
            ref.invalidate(currentAuthUserProvider);
            ref.invalidate(currentUserProfileProvider);
            ref.invalidate(dashboardAnalyticsProvider);
            ref.invalidate(todayStepCountProvider);
            ref.invalidate(stepGoalProvider);
            ref.invalidate(stepGoalCelebrationPendingProvider);
            ref.invalidate(stepTrackingStatusProvider);

            if (user == null) {
              unawaited(ref.read(stepTrackingServiceProvider).stopTracking());
              unawaited(_stopForegroundStepSync());
              return;
            }

            unawaited(
              ref
                  .read(stepTrackingServiceProvider)
                  .ensureTracking(userId: user.uid),
            );
            final email = user.email ?? '';
            unawaited(
              ref
                  .read(ensureLeaderboardEntryUseCaseProvider)
                  .call(
                    userId: user.uid,
                    fallbackName: user.displayName ?? email.split('@').first,
                    fallbackEmail: email,
                  ),
            );
            unawaited(_startForegroundStepSync(user.uid));
            unawaited(
              ref
                  .read(appOfflineSyncCoordinatorProvider)
                  .syncDataWithServer(userId: user.uid),
            );
            unawaited(_refreshUserScopedState(userId: user.uid));
          });
    }

    _profileSubscription = ref.listenManual<AsyncValue<UserProfile?>>(
      currentUserProfileProvider,
      (_, next) {
        next.whenData((profile) {
          if (profile == null) {
            return;
          }

          unawaited(
            ref
                .read(stepTrackingServiceProvider)
                .saveDailyGoal(
                  userId: profile.userId,
                  goal: profile.dailyStepGoal,
                ),
          );
        });
      },
    );

    if (isStepTrackingSupportedPlatform) {
      _stepUpdateSubscription = FlutterBackgroundService()
          .on(stepTrackingUpdateEvent)
          .listen((payload) {
            ref.invalidate(dashboardAnalyticsProvider);
            ref.invalidate(todayStepCountProvider);
            ref.invalidate(stepGoalCelebrationPendingProvider);
            final goalReachedNow = payload?['goalReachedNow'] == true;
            if (goalReachedNow) {
              final l10n = _navigatorKey.currentContext == null
                  ? null
                  : AppLocalizations.of(_navigatorKey.currentContext!);
              if (l10n != null) {
                unawaited(
                  AppNotificationService.showStepGoalReached(
                    title: 'Liga Gym',
                    body: l10n.stepGoalReachedMessage,
                  ),
                );
              }
            }
            unawaited(_showPendingStepCelebration());
          });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _stepUpdateSubscription?.cancel();
    _foregroundPedometerSubscription?.cancel();
    _profileSubscription?.close();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(dashboardAnalyticsProvider);
      ref.invalidate(stepGoalCelebrationPendingProvider);
      unawaited(_showPendingStepCelebration());
    }
  }

  Future<void> _showPendingStepCelebration() async {
    if (_isCelebrationOpen) {
      return;
    }

    final sharedPreferences = ref.read(sharedPreferencesProvider);
    final userId = _activeUserId;
    if (userId == null) {
      return;
    }
    final pendingDate = sharedPreferences?.getString(
      stepGoalCelebrationPendingDateKey(userId),
    );
    final todayKey = buildStepDateKey(DateTime.now());
    if (pendingDate != todayKey) {
      return;
    }

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) {
      return;
    }

    _isCelebrationOpen = true;
    _confettiController.play();
    final l10n = AppLocalizations.of(dialogContext)!;

    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: true,
      builder: (context) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            AlertDialog(
              title: Text(l10n.stepGoalReachedTitle),
              content: Text(l10n.stepGoalReachedMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.commonContinue),
                ),
              ],
            ),
            IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2,
                emissionFrequency: 0.05,
                numberOfParticles: 24,
                maxBlastForce: 18,
                minBlastForce: 8,
                gravity: 0.3,
                shouldLoop: false,
              ),
            ),
          ],
        );
      },
    );

    await ref
        .read(stepScreenControllerProvider.notifier)
        .markGoalCelebrationSeen();
    _isCelebrationOpen = false;
  }

  Future<void> _startForegroundStepSync(String userId) async {
    if (!isStepTrackingSupportedPlatform) {
      return;
    }

    final permission = await Permission.activityRecognition.status;
    if (!permission.isGranted) {
      return;
    }

    final todaySteps = await _stepLocalDataSource.loadStepsForDate(
      userId: userId,
      date: DateTime.now(),
    );
    await _syncFriendSteps(userId: userId, stepsCount: todaySteps);

    await _foregroundPedometerSubscription?.cancel();
    _foregroundPedometerSubscription = Pedometer.stepCountStream.listen((
      event,
    ) async {
      await _stepLocalDataSource.recordSensorReading(
        userId: userId,
        sensorSteps: event.steps,
        recordedAt: event.timeStamp,
      );

      final todaySteps = await _stepLocalDataSource.loadStepsForDate(
        userId: userId,
        date: event.timeStamp,
      );
      await _syncFriendSteps(userId: userId, stepsCount: todaySteps);
      await _handleGoalReachedOnMain(todaySteps);

      ref.invalidate(todayStepCountProvider);
      ref.invalidate(dashboardAnalyticsProvider);
    });
  }

  Future<void> _syncFriendSteps({
    required String userId,
    required int stepsCount,
  }) async {
    try {
      await ref
          .read(updateLeaderboardStepsUseCaseProvider)
          .call(userId: userId, stepsCount: stepsCount);
    } on Object {
      // Social step sharing should not interrupt local step tracking.
    }
  }

  Future<void> _stopForegroundStepSync() async {
    await _foregroundPedometerSubscription?.cancel();
    _foregroundPedometerSubscription = null;
  }

  Future<void> _handleGoalReachedOnMain(int todaySteps) async {
    final sharedPreferences = ref.read(sharedPreferencesProvider);
    final userId = _activeUserId;
    if (sharedPreferences == null || userId == null) {
      return;
    }

    final stepGoal =
        sharedPreferences.getInt(stepTrackingGoalKey(userId)) ?? 10000;
    if (todaySteps < stepGoal) {
      return;
    }

    final todayKey = buildStepDateKey(DateTime.now());
    final lastCelebratedDate = sharedPreferences.getString(
      stepGoalCelebratedDateKey(userId),
    );
    if (lastCelebratedDate == todayKey) {
      return;
    }

    await sharedPreferences.setString(
      stepGoalCelebratedDateKey(userId),
      todayKey,
    );
    await sharedPreferences.setString(
      stepGoalCelebrationPendingDateKey(userId),
      todayKey,
    );
    final l10n = _navigatorKey.currentContext == null
        ? null
        : AppLocalizations.of(_navigatorKey.currentContext!);
    if (l10n != null) {
      await AppNotificationService.showStepGoalReached(
        title: 'Liga Gym',
        body: l10n.stepGoalReachedMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider) ?? widget.locale;
    final appPalette = ref.watch(appThemeProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: buildLigaGymTheme(appPalette),
      themeAnimationDuration: const Duration(milliseconds: 450),
      themeAnimationCurve: Curves.easeOutCubic,
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

  Future<void> _refreshUserScopedState({required String userId}) async {
    ref.invalidate(currentAuthUserProvider);
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(dashboardAnalyticsProvider);
    ref.invalidate(todayStepCountProvider);
    ref.invalidate(stepGoalProvider);
    ref.invalidate(stepGoalCelebrationPendingProvider);
    ref.invalidate(stepTrackingStatusProvider);

    final profile = await ref.read(loadUserProfileUseCaseProvider).call(userId);
    await ref
        .read(stepTrackingServiceProvider)
        .saveDailyGoal(userId: profile.userId, goal: profile.dailyStepGoal);

    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser != null) {
      final email = currentUser.email ?? '';
      await ref
          .read(ensureLeaderboardEntryUseCaseProvider)
          .call(
            userId: currentUser.uid,
            fallbackName: currentUser.displayName ?? email.split('@').first,
            fallbackEmail: email,
          );
    }
  }
}
