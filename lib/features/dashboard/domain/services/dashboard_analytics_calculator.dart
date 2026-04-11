import 'package:flutter/material.dart';

import '../../../nutrition/domain/entities/daily_food_diary.dart';
import '../../../steps/domain/entities/daily_step_count.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/domain/entities/workout_type.dart';
import '../entities/dashboard_analytics.dart';

class DashboardAnalyticsCalculator {
  const DashboardAnalyticsCalculator({
    this.dailyStepGoal = 10000,
    this.dailyCalorieGoal = 2200,
    this.metersPerStep = 0.78,
  });

  final int dailyStepGoal;
  final double dailyCalorieGoal;
  final double metersPerStep;

  DashboardWeeklyStats calculateWeeklyStats({
    required List<Workout> workouts,
    required List<DailyFoodDiary> diaries,
    List<DailyStepCount> stepCounts = const <DailyStepCount>[],
    DateTime? now,
  }) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final startDate = today.subtract(const Duration(days: 6));
    final diaryByDay = <String, DailyFoodDiary>{
      for (final diary in diaries) _dateKey(diary.date): diary,
    };
    final stepsByDay = <String, DailyStepCount>{
      for (final stepCount in stepCounts) _dateKey(stepCount.date): stepCount,
    };
    final workoutsByDay = <String, List<Workout>>{};

    for (final workout in workouts) {
      final workoutDate = DateUtils.dateOnly(workout.startedAt);
      final startsBeforeWindow = workoutDate.isBefore(startDate);
      final startsAfterWindow = workoutDate.isAfter(today);
      if (startsBeforeWindow || startsAfterWindow) {
        continue;
      }

      workoutsByDay
          .putIfAbsent(_dateKey(workoutDate), () => <Workout>[])
          .add(workout);
    }

    final days = List<DashboardDaySummary>.generate(7, (index) {
      final date = startDate.add(Duration(days: index));
      final dayWorkouts = workoutsByDay[_dateKey(date)] ?? const <Workout>[];
      final diary = diaryByDay[_dateKey(date)];
      final macros = diary?.totalMacros();
      final recordedSteps = stepsByDay[_dateKey(date)]?.steps;
      final steps =
          recordedSteps ??
          dayWorkouts.fold<int>(
            0,
            (total, workout) => total + _estimateSteps(workout),
          );
      final calories = macros?.calories ?? 0;

      return DashboardDaySummary(
        date: date,
        steps: steps,
        calories: calories,
        progress: calculateProgress(steps: steps, calories: calories),
      );
    }, growable: false);

    return DashboardWeeklyStats(days: days);
  }

  DashboardGoalProgress calculateProgress({
    required int steps,
    required double calories,
  }) {
    final stepsProgress = _clamp01(steps / dailyStepGoal);
    final caloriesProgress = _clamp01(calories / dailyCalorieGoal);

    return DashboardGoalProgress(
      steps: stepsProgress,
      calories: caloriesProgress,
      overall: (stepsProgress + caloriesProgress) / 2,
    );
  }

  DashboardAnalytics buildAnalytics({
    required List<Workout> workouts,
    required List<DailyFoodDiary> diaries,
    List<DailyStepCount> stepCounts = const <DailyStepCount>[],
    DateTime? now,
  }) {
    final targetDate = DateUtils.dateOnly(now ?? DateTime.now());
    final weeklyStats = calculateWeeklyStats(
      workouts: workouts,
      diaries: diaries,
      stepCounts: stepCounts,
      now: now,
    );
    final todayDiary = diaries.cast<DailyFoodDiary?>().firstWhere(
      (diary) => diary != null && DateUtils.isSameDay(diary.date, targetDate),
      orElse: () => DailyFoodDiary(date: targetDate, entries: const []),
    )!;
    final macros = todayDiary.totalMacros();

    return DashboardAnalytics(
      weeklyStats: weeklyStats,
      progress: weeklyStats.today.progress,
      proteins: macros.proteins,
      fats: macros.fats,
      carbs: macros.carbs,
    );
  }

  int _estimateSteps(Workout workout) {
    final isStepBasedWorkout =
        workout.type == WorkoutType.running ||
        workout.type == WorkoutType.walking;
    if (!isStepBasedWorkout || workout.distanceMeters <= 0) {
      return 0;
    }

    return (workout.distanceMeters / metersPerStep).round();
  }

  String _dateKey(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    return '${normalized.year}-${normalized.month}-${normalized.day}';
  }

  double _clamp01(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }
}
