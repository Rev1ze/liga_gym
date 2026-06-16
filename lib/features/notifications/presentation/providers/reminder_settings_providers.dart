import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/app_notification_service.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

@immutable
class ReminderSettingsState {
  const ReminderSettingsState({
    required this.userId,
    this.enabled = true,
    this.workoutEnabled = true,
    this.waterEnabled = true,
    this.dailySummaryEnabled = true,
    this.workoutTime = const TimeOfDay(hour: 10, minute: 0),
    this.waterTime = const TimeOfDay(hour: 12, minute: 30),
    this.dailySummaryTime = const TimeOfDay(hour: 20, minute: 30),
  });

  final String? userId;
  final bool enabled;
  final bool workoutEnabled;
  final bool waterEnabled;
  final bool dailySummaryEnabled;
  final TimeOfDay workoutTime;
  final TimeOfDay waterTime;
  final TimeOfDay dailySummaryTime;

  ReminderSettingsState copyWith({
    bool? enabled,
    bool? workoutEnabled,
    bool? waterEnabled,
    bool? dailySummaryEnabled,
    TimeOfDay? workoutTime,
    TimeOfDay? waterTime,
    TimeOfDay? dailySummaryTime,
  }) {
    return ReminderSettingsState(
      userId: userId,
      enabled: enabled ?? this.enabled,
      workoutEnabled: workoutEnabled ?? this.workoutEnabled,
      waterEnabled: waterEnabled ?? this.waterEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      workoutTime: workoutTime ?? this.workoutTime,
      waterTime: waterTime ?? this.waterTime,
      dailySummaryTime: dailySummaryTime ?? this.dailySummaryTime,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'enabled': enabled,
      'workoutEnabled': workoutEnabled,
      'waterEnabled': waterEnabled,
      'dailySummaryEnabled': dailySummaryEnabled,
      'workoutHour': workoutTime.hour,
      'workoutMinute': workoutTime.minute,
      'waterHour': waterTime.hour,
      'waterMinute': waterTime.minute,
      'dailySummaryHour': dailySummaryTime.hour,
      'dailySummaryMinute': dailySummaryTime.minute,
    };
  }

  factory ReminderSettingsState.fromJson({
    required String? userId,
    required Map<String, Object?> json,
  }) {
    return ReminderSettingsState(
      userId: userId,
      enabled: json['enabled'] as bool? ?? true,
      workoutEnabled: json['workoutEnabled'] as bool? ?? true,
      waterEnabled: json['waterEnabled'] as bool? ?? true,
      dailySummaryEnabled: json['dailySummaryEnabled'] as bool? ?? true,
      workoutTime: _timeFromJson(json, 'workoutHour', 'workoutMinute', 10, 0),
      waterTime: _timeFromJson(json, 'waterHour', 'waterMinute', 12, 30),
      dailySummaryTime: _timeFromJson(
        json,
        'dailySummaryHour',
        'dailySummaryMinute',
        20,
        30,
      ),
    );
  }

  static TimeOfDay _timeFromJson(
    Map<String, Object?> json,
    String hourKey,
    String minuteKey,
    int fallbackHour,
    int fallbackMinute,
  ) {
    final hour = (json[hourKey] as num?)?.toInt() ?? fallbackHour;
    final minute = (json[minuteKey] as num?)?.toInt() ?? fallbackMinute;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }
}

final reminderSettingsControllerProvider =
    NotifierProvider<ReminderSettingsController, ReminderSettingsState>(
      ReminderSettingsController.new,
    );

class ReminderSettingsController extends Notifier<ReminderSettingsState> {
  @override
  ReminderSettingsState build() {
    final userId = ref.watch(currentFirebaseUserProvider)?.uid;
    final prefs = ref.read(sharedPreferencesProvider);
    final payload = userId == null ? null : prefs?.getString(_key(userId));
    if (payload == null || payload.isEmpty) {
      return ReminderSettingsState(userId: userId);
    }

    try {
      return ReminderSettingsState.fromJson(
        userId: userId,
        json: Map<String, Object?>.from(jsonDecode(payload) as Map),
      );
    } on Object {
      return ReminderSettingsState(userId: userId);
    }
  }

  Future<void> setMasterEnabled(bool value) async {
    await _update(state.copyWith(enabled: value));
  }

  Future<void> setWorkoutEnabled(bool value) async {
    await _update(state.copyWith(workoutEnabled: value));
  }

  Future<void> setWaterEnabled(bool value) async {
    await _update(state.copyWith(waterEnabled: value));
  }

  Future<void> setDailySummaryEnabled(bool value) async {
    await _update(state.copyWith(dailySummaryEnabled: value));
  }

  Future<void> setWorkoutTime(TimeOfDay value) async {
    await _update(state.copyWith(workoutTime: value));
  }

  Future<void> setWaterTime(TimeOfDay value) async {
    await _update(state.copyWith(waterTime: value));
  }

  Future<void> setDailySummaryTime(TimeOfDay value) async {
    await _update(state.copyWith(dailySummaryTime: value));
  }

  Future<void> reschedule() async {
    await _applySchedules(state);
  }

  Future<void> _update(ReminderSettingsState nextState) async {
    state = nextState;
    final prefs = ref.read(sharedPreferencesProvider);
    final userId = state.userId;
    if (prefs != null && userId != null) {
      await prefs.setString(_key(userId), jsonEncode(state.toJson()));
    }
    await _applySchedules(state);
  }

  Future<void> _applySchedules(ReminderSettingsState settings) async {
    if (!settings.enabled) {
      await AppNotificationService.cancelDailyReminders();
      return;
    }

    if (settings.workoutEnabled) {
      await AppNotificationService.scheduleDailyWorkoutReminder(
        hour: settings.workoutTime.hour,
        minute: settings.workoutTime.minute,
        title: 'Liga Gym',
        body: 'Не забудь выполнить тренировку сегодня',
      );
    } else {
      await AppNotificationService.cancelDailyWorkoutReminder();
    }

    if (settings.waterEnabled) {
      await AppNotificationService.scheduleDailyWaterReminder(
        hour: settings.waterTime.hour,
        minute: settings.waterTime.minute,
        title: 'Liga Gym',
        body: 'Выпей воды, организм скажет спасибо',
      );
    } else {
      await AppNotificationService.cancelDailyWaterReminder();
    }

    if (settings.dailySummaryEnabled) {
      await AppNotificationService.scheduleDailySummaryReminder(
        hour: settings.dailySummaryTime.hour,
        minute: settings.dailySummaryTime.minute,
        title: 'Liga Gym',
        body: 'Посмотри свой итог дня',
      );
    } else {
      await AppNotificationService.cancelDailySummaryReminder();
    }
  }

  String _key(String userId) => 'liga_reminder_settings_$userId';
}
