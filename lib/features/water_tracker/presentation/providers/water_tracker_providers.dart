import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/utils/date_key.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

const int defaultWaterGoalMl = 2000;

@immutable
class DailyWaterState {
  const DailyWaterState({
    required this.date,
    required this.userId,
    required this.consumedMl,
    required this.goalMl,
  });

  final DateTime date;
  final String? userId;
  final int consumedMl;
  final int goalMl;

  double get progress {
    if (goalMl <= 0) {
      return 0;
    }
    return (consumedMl / goalMl).clamp(0, 1).toDouble();
  }

  bool get isGoalReached => consumedMl >= goalMl;

  DailyWaterState copyWith({int? consumedMl, int? goalMl}) {
    return DailyWaterState(
      date: date,
      userId: userId,
      consumedMl: consumedMl ?? this.consumedMl,
      goalMl: goalMl ?? this.goalMl,
    );
  }
}

final waterTrackerControllerProvider =
    NotifierProvider.family<WaterTrackerController, DailyWaterState, DateTime>(
      WaterTrackerController.new,
    );

class WaterTrackerController extends Notifier<DailyWaterState> {
  WaterTrackerController(this._date);

  final DateTime _date;

  @override
  DailyWaterState build() {
    final date = DateUtils.dateOnly(_date);
    final userId = ref.watch(currentFirebaseUserProvider)?.uid;
    if (userId == null) {
      return DailyWaterState(
        date: date,
        userId: null,
        consumedMl: 0,
        goalMl: defaultWaterGoalMl,
      );
    }

    final prefs = ref.read(sharedPreferencesProvider);
    return DailyWaterState(
      date: date,
      userId: userId,
      consumedMl: prefs?.getInt(_entryKey(userId, date)) ?? 0,
      goalMl: prefs?.getInt(_goalKey(userId)) ?? defaultWaterGoalMl,
    );
  }

  Future<void> addWater(int amountMl) async {
    if (amountMl <= 0) {
      return;
    }
    state = state.copyWith(consumedMl: state.consumedMl + amountMl);
    await _saveEntry();
  }

  Future<void> removeWater(int amountMl) async {
    if (amountMl <= 0) {
      return;
    }
    state = state.copyWith(
      consumedMl: (state.consumedMl - amountMl).clamp(0, 100000),
    );
    await _saveEntry();
  }

  Future<void> setGoal(int goalMl) async {
    if (goalMl <= 0) {
      return;
    }
    state = state.copyWith(goalMl: goalMl);
    final prefs = ref.read(sharedPreferencesProvider);
    final userId = state.userId;
    if (prefs == null || userId == null) {
      return;
    }
    await prefs.setInt(_goalKey(userId), goalMl);
  }

  Future<void> _saveEntry() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final userId = state.userId;
    if (prefs == null || userId == null) {
      return;
    }
    await prefs.setInt(_entryKey(userId, state.date), state.consumedMl);
  }

  String _entryKey(String userId, DateTime date) {
    return 'water_tracker_${userId}_${LocalDateKey.fromDate(date)}';
  }

  String _goalKey(String userId) => 'water_tracker_goal_$userId';
}
