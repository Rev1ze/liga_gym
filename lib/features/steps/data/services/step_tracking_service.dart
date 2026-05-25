import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../datasources/step_local_data_source.dart';
import '../models/daily_step_count_model.dart';

const String stepTrackingActiveUserIdKey = 'step_tracking_active_user_id';
const String stepTrackingUpdateEvent = 'steps_updated';
const String _stepTrackingSetUserEvent = 'set_tracking_user';
const String _stepTrackingStopEvent = 'stop_tracking';
const String _notificationTitle = 'Liga Gym Step Tracking';

class StepTrackingService {
  StepTrackingService({required SharedPreferences? sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  final SharedPreferences? _sharedPreferences;

  static bool _isConfigured = false;

  static Future<void> configureBackgroundTracking() async {
    if (_isConfigured || !isStepTrackingSupportedPlatform) {
      return;
    }

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: stepTrackingBackgroundEntrypoint,
        autoStart: false,
        autoStartOnBoot: true,
        isForegroundMode: true,
        initialNotificationTitle: _notificationTitle,
        initialNotificationContent: 'Preparing step counter',
        foregroundServiceTypes: [AndroidForegroundType.health],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: stepTrackingBackgroundEntrypoint,
      ),
    );

    _isConfigured = true;
  }

  Future<bool> ensureTracking({required String userId}) async {
    if (!isStepTrackingSupportedPlatform) {
      return false;
    }

    final permissionStatus = await Permission.activityRecognition.request();
    if (!permissionStatus.isGranted) {
      return false;
    }
    await Permission.notification.request();

    await _sharedPreferences?.setString(stepTrackingActiveUserIdKey, userId);

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }

    service.invoke(_stepTrackingSetUserEvent, <String, Object?>{
      'userId': userId,
    });
    return true;
  }

  Future<void> stopTracking() async {
    if (!isStepTrackingSupportedPlatform) {
      return;
    }

    await _sharedPreferences?.remove(stepTrackingActiveUserIdKey);
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke(_stepTrackingStopEvent);
    }
  }

  Future<bool> isRunning() {
    if (!isStepTrackingSupportedPlatform) {
      return Future<bool>.value(false);
    }

    return FlutterBackgroundService().isRunning();
  }

  Future<void> saveDailyGoal({
    required String userId,
    required int goal,
  }) async {
    await _sharedPreferences?.setInt(stepTrackingGoalKey(userId), goal);
  }

  Future<void> resetUserSession({
    required String? previousUserId,
    required String? nextUserId,
  }) async {
    if (_sharedPreferences == null) {
      return;
    }

    if (previousUserId != null && previousUserId.isNotEmpty) {
      await _sharedPreferences.remove(stepTrackingGoalKey(previousUserId));
      await _sharedPreferences.remove(
        stepGoalCelebrationPendingDateKey(previousUserId),
      );
      await _sharedPreferences.remove(
        stepGoalCelebratedDateKey(previousUserId),
      );
    }

    if (nextUserId == null || nextUserId.isEmpty) {
      await _sharedPreferences.remove(stepTrackingActiveUserIdKey);
      return;
    }

    await _sharedPreferences.setString(stepTrackingActiveUserIdKey, nextUserId);
  }
}

String stepTrackingGoalKey(String userId) => 'step_tracking_daily_goal_$userId';

String stepGoalCelebrationPendingDateKey(String userId) =>
    'step_goal_celebration_pending_date_$userId';

String stepGoalCelebratedDateKey(String userId) =>
    'step_goal_celebrated_date_$userId';

bool get isStepTrackingSupportedPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

@pragma('vm:entry-point')
void stepTrackingBackgroundEntrypoint(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final localDataSource = SqfliteStepLocalDataSource();
  final sharedPreferences = await SharedPreferences.getInstance();
  StreamSubscription<StepCount>? stepSubscription;
  var trackedUserId = sharedPreferences.getString(stepTrackingActiveUserIdKey);

  Future<void> updateForegroundNotification() async {
    final userId = trackedUserId;
    if (userId == null ||
        userId.isEmpty ||
        service is! AndroidServiceInstance) {
      return;
    }

    final todaySteps = await localDataSource.loadStepsForDate(
      userId: userId,
      date: DateTime.now(),
    );

    service.setForegroundNotificationInfo(
      title: _notificationTitle,
      content: 'Today: $todaySteps steps',
    );
  }

  Future<void> handleStepEvent(StepCount event) async {
    final userId = trackedUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    await localDataSource.recordSensorReading(
      userId: userId,
      sensorSteps: event.steps,
      recordedAt: event.timeStamp,
    );
    await updateForegroundNotification();

    final todaySteps = await localDataSource.loadStepsForDate(
      userId: userId,
      date: event.timeStamp,
    );
    final goalReachedNow = await _handleGoalReached(
      sharedPreferences: sharedPreferences,
      userId: userId,
      todaySteps: todaySteps,
    );
    service.invoke(stepTrackingUpdateEvent, <String, Object?>{
      'userId': userId,
      'steps': todaySteps,
      'dateKey': buildStepDateKey(event.timeStamp),
      'goalReachedNow': goalReachedNow,
    });
  }

  Future<void> startTracking() async {
    final userId = trackedUserId;
    if (userId == null || userId.isEmpty) {
      service.stopSelf();
      return;
    }

    await stepSubscription?.cancel();
    stepSubscription = Pedometer.stepCountStream.listen(handleStepEvent);
    stepSubscription!.onError((Object error) async {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: _notificationTitle,
          content: 'Step sensor unavailable',
        );
      }
      debugPrint('Step tracking error: $error');
    });

    await updateForegroundNotification();
  }

  service.on(_stepTrackingSetUserEvent).listen((payload) async {
    final userId = payload?['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      return;
    }

    trackedUserId = userId;
    await sharedPreferences.setString(stepTrackingActiveUserIdKey, userId);
    await startTracking();
  });

  service.on(_stepTrackingStopEvent).listen((_) async {
    trackedUserId = null;
    await sharedPreferences.remove(stepTrackingActiveUserIdKey);
    await stepSubscription?.cancel();
    service.stopSelf();
  });

  await startTracking();
}

Future<bool> _handleGoalReached({
  required SharedPreferences sharedPreferences,
  required String userId,
  required int todaySteps,
}) async {
  final stepGoal =
      sharedPreferences.getInt(stepTrackingGoalKey(userId)) ?? 10000;
  if (todaySteps < stepGoal) {
    return false;
  }

  final todayKey = buildStepDateKey(DateTime.now());
  final lastCelebratedDate = sharedPreferences.getString(
    stepGoalCelebratedDateKey(userId),
  );
  if (lastCelebratedDate == todayKey) {
    return false;
  }

  await sharedPreferences.setString(
    stepGoalCelebratedDateKey(userId),
    todayKey,
  );
  await sharedPreferences.setString(
    stepGoalCelebrationPendingDateKey(userId),
    todayKey,
  );
  return true;
}
