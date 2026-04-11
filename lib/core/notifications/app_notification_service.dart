import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        goalChannelId,
        goalChannelName,
        description: goalChannelDescription,
        importance: Importance.high,
      ),
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
}
