import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AppNotificationService {
  AppNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String goalChannelId = 'step_goal_channel';
  static const String goalChannelName = 'Step Goal Achievements';
  static const String goalChannelDescription =
      'Notifications when the step goal is achieved';
  static const int stepGoalNotificationId = 1001;
  static const String workoutReminderChannelId = 'workout_reminder_channel';
  static const String workoutReminderChannelName = 'Workout reminders';
  static const String workoutReminderChannelDescription =
      'Notifications before planned workouts';
  static const Duration workoutReminderLeadTime = Duration(hours: 1);
  static bool _timeZoneConfigured = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _ignoreMissingPlugin(() => _plugin.initialize(settings));

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await _ignoreMissingPlugin(
      () => androidPlugin?.requestNotificationsPermission(),
    );
    await _ignoreMissingPlugin(
      () => androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          goalChannelId,
          goalChannelName,
          description: goalChannelDescription,
          importance: Importance.high,
        ),
      ),
    );
    await _ignoreMissingPlugin(
      () => androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          workoutReminderChannelId,
          workoutReminderChannelName,
          description: workoutReminderChannelDescription,
          importance: Importance.high,
        ),
      ),
    );
    await _ignoreMissingPlugin(
      () => _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true),
    );
    await _ignoreMissingPlugin(
      () => _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true),
    );

    _initialized = true;
  }

  static Future<void> showStepGoalReached({
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(
      stepGoalNotificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          goalChannelId,
          goalChannelName,
          channelDescription: goalChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> scheduleWorkoutReminder({
    required String workoutId,
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    if (!scheduledAt.isAfter(DateTime.now())) {
      return;
    }

    await _ignoreMissingPlugin(() async {
      await initialize();
      await _configureLocalTimeZone();

      final reminderAt = scheduledAt.subtract(workoutReminderLeadTime);
      if (!reminderAt.isAfter(DateTime.now())) {
        await _plugin.show(
          _workoutReminderNotificationId(workoutId),
          title,
          body,
          _workoutReminderDetails(),
          payload: 'workout:$workoutId',
        );
        return;
      }

      await _plugin.zonedSchedule(
        _workoutReminderNotificationId(workoutId),
        title,
        body,
        tz.TZDateTime.from(reminderAt, tz.local),
        _workoutReminderDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'workout:$workoutId',
      );
    });
  }

  static Future<void> cancelWorkoutReminder(String workoutId) async {
    await _ignoreMissingPlugin(() async {
      await initialize();
      await _plugin.cancel(_workoutReminderNotificationId(workoutId));
    });
  }

  static NotificationDetails _workoutReminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        workoutReminderChannelId,
        workoutReminderChannelName,
        channelDescription: workoutReminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }

  static Future<void> _configureLocalTimeZone() async {
    if (_timeZoneConfigured) {
      return;
    }

    tz.initializeTimeZones();
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    _timeZoneConfigured = true;
  }

  static int _workoutReminderNotificationId(String workoutId) {
    return 2000 +
        workoutId.codeUnits.fold<int>(
          0,
          (hash, codeUnit) => ((hash * 31) + codeUnit) & 0x3fffffff,
        );
  }

  static Future<T?> _ignoreMissingPlugin<T>(
    Future<T?>? Function() action,
  ) async {
    try {
      return await action();
    } on MissingPluginException {
      return null;
    } on UnimplementedError {
      return null;
    }
  }
}
