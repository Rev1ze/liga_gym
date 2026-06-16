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
  static const String waterReminderChannelId = 'water_reminder_channel';
  static const String waterReminderChannelName = 'Water reminders';
  static const String waterReminderChannelDescription =
      'Daily hydration reminders';
  static const String dailySummaryChannelId = 'daily_summary_channel';
  static const String dailySummaryChannelName = 'Daily summary';
  static const String dailySummaryChannelDescription =
      'Notifications to review the day summary';
  static const String friendRequestChannelId = 'friend_request_channel';
  static const String friendRequestChannelName = 'Friend requests';
  static const String friendRequestChannelDescription =
      'Notifications when a friend request arrives';
  static const int friendRequestNotificationId = 3001;
  static const int dailyWorkoutReminderNotificationId = 4001;
  static const int dailyWaterReminderNotificationId = 4002;
  static const int dailySummaryReminderNotificationId = 4003;
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
      () => androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          waterReminderChannelId,
          waterReminderChannelName,
          description: waterReminderChannelDescription,
          importance: Importance.defaultImportance,
        ),
      ),
    );
    await _ignoreMissingPlugin(
      () => androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          dailySummaryChannelId,
          dailySummaryChannelName,
          description: dailySummaryChannelDescription,
          importance: Importance.defaultImportance,
        ),
      ),
    );
    await _ignoreMissingPlugin(
      () => androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          friendRequestChannelId,
          friendRequestChannelName,
          description: friendRequestChannelDescription,
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

  static Future<void> showFriendRequestReceived({
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(
      friendRequestNotificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          friendRequestChannelId,
          friendRequestChannelName,
          channelDescription: friendRequestChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      payload: 'friends:requests',
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

  static Future<void> scheduleDailyWorkoutReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _scheduleDailyReminder(
      notificationId: dailyWorkoutReminderNotificationId,
      channelId: workoutReminderChannelId,
      channelName: workoutReminderChannelName,
      channelDescription: workoutReminderChannelDescription,
      hour: hour,
      minute: minute,
      title: title,
      body: body,
      payload: 'daily:workout',
    );
  }

  static Future<void> scheduleDailyWaterReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _scheduleDailyReminder(
      notificationId: dailyWaterReminderNotificationId,
      channelId: waterReminderChannelId,
      channelName: waterReminderChannelName,
      channelDescription: waterReminderChannelDescription,
      hour: hour,
      minute: minute,
      title: title,
      body: body,
      payload: 'daily:water',
    );
  }

  static Future<void> scheduleDailySummaryReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _scheduleDailyReminder(
      notificationId: dailySummaryReminderNotificationId,
      channelId: dailySummaryChannelId,
      channelName: dailySummaryChannelName,
      channelDescription: dailySummaryChannelDescription,
      hour: hour,
      minute: minute,
      title: title,
      body: body,
      payload: 'daily:summary',
    );
  }

  static Future<void> cancelDailyWorkoutReminder() async {
    await _cancel(dailyWorkoutReminderNotificationId);
  }

  static Future<void> cancelDailyWaterReminder() async {
    await _cancel(dailyWaterReminderNotificationId);
  }

  static Future<void> cancelDailySummaryReminder() async {
    await _cancel(dailySummaryReminderNotificationId);
  }

  static Future<void> cancelDailyReminders() async {
    await cancelDailyWorkoutReminder();
    await cancelDailyWaterReminder();
    await cancelDailySummaryReminder();
  }

  static Future<void> _scheduleDailyReminder({
    required int notificationId,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    await _ignoreMissingPlugin(() async {
      await initialize();
      await _configureLocalTimeZone();
      await _plugin.cancel(notificationId);
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        _nextDailyTime(hour: hour, minute: minute),
        _dailyReminderDetails(
          channelId: channelId,
          channelName: channelName,
          channelDescription: channelDescription,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    });
  }

  static Future<void> _cancel(int notificationId) async {
    await _ignoreMissingPlugin(() async {
      await initialize();
      await _plugin.cancel(notificationId);
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

  static NotificationDetails _dailyReminderDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
  }

  static tz.TZDateTime _nextDailyTime({
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour.clamp(0, 23),
      minute.clamp(0, 59),
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
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
    } on UnsupportedError {
      return null;
    }
  }
}
