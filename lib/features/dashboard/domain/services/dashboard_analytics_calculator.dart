import 'package:flutter/material.dart';

import '../../../auth/domain/entities/user_goal.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/domain/entities/weight_history_entry.dart';
import '../../../nutrition/domain/entities/daily_food_diary.dart';
import '../../../steps/domain/entities/daily_step_count.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/domain/entities/workout_type.dart';
import '../entities/dashboard_analytics.dart';

class DashboardAnalyticsCalculator {
  const DashboardAnalyticsCalculator({
    this.defaultDailyStepGoal = 10000,
    this.defaultDailyCalorieGoal = 2200,
    this.metersPerStep = 0.78,
  });

  final int defaultDailyStepGoal;
  final double defaultDailyCalorieGoal;
  final double metersPerStep;

  DashboardWeeklyStats calculateWeeklyStats({
    required List<Workout> workouts,
    required List<DailyFoodDiary> diaries,
    List<DailyStepCount> stepCounts = const <DailyStepCount>[],
    int? dailyStepGoal,
    double? dailyCalorieGoal,
    DateTime? now,
    DateTime? from,
    DateTime? to,
  }) {
    final endDate = DateUtils.dateOnly(to ?? now ?? DateTime.now());
    final startDate = from != null
        ? DateUtils.dateOnly(from)
        : endDate.subtract(const Duration(days: 6));
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
      final startsAfterWindow = workoutDate.isAfter(endDate);
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
      final resolvedStepGoal = dailyStepGoal ?? defaultDailyStepGoal;
      final resolvedCalorieGoal = dailyCalorieGoal ?? defaultDailyCalorieGoal;

      return DashboardDaySummary(
        date: date,
        steps: steps,
        calories: calories,
        progress: calculateProgress(
          steps: steps,
          calories: calories,
          stepGoal: resolvedStepGoal,
          calorieGoal: resolvedCalorieGoal,
        ),
      );
    }, growable: false);

    return DashboardWeeklyStats(days: days);
  }

  DashboardGoalProgress calculateProgress({
    required int steps,
    required double calories,
    required int stepGoal,
    required double calorieGoal,
  }) {
    final safeStepGoal = stepGoal <= 0 ? defaultDailyStepGoal : stepGoal;
    final safeCalorieGoal = calorieGoal <= 0
        ? defaultDailyCalorieGoal
        : calorieGoal;
    final stepsProgress = _clamp01(steps / safeStepGoal);
    final caloriesProgress = _clamp01(calories / safeCalorieGoal);

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
    UserProfile? profile,
    List<WeightHistoryEntry> weightHistory = const <WeightHistoryEntry>[],
    DateTime? now,
  }) {
    final targetDate = DateUtils.dateOnly(now ?? DateTime.now());
    final goals = DashboardUserGoals(
      stepGoal: profile?.dailyStepGoal ?? defaultDailyStepGoal,
      calorieGoal: profile?.dailyCalorieGoal ?? defaultDailyCalorieGoal,
      goalType: profile?.goalType ?? UserGoalType.maintainWeight,
      currentWeightKg: profile?.currentWeightKg,
      targetWeightKg: profile?.targetWeightKg,
    );
    final weeklyStats = calculateWeeklyStats(
      workouts: workouts,
      diaries: diaries,
      stepCounts: stepCounts,
      dailyStepGoal: goals.stepGoal,
      dailyCalorieGoal: goals.calorieGoal,
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
      goals: goals,
      weightAnalytics: buildWeightAnalytics(
        profile: profile,
        weightHistory: weightHistory,
      ),
      proteins: macros.proteins,
      fats: macros.fats,
      carbs: macros.carbs,
    );
  }

  DashboardRangeAnalytics buildRangeAnalytics({
    required List<Workout> workouts,
    required List<DailyFoodDiary> diaries,
    required DateTime from,
    required DateTime to,
    List<DailyStepCount> stepCounts = const <DailyStepCount>[],
    UserProfile? profile,
    List<WeightHistoryEntry> weightHistory = const <WeightHistoryEntry>[],
  }) {
    final normalizedFrom = DateUtils.dateOnly(from);
    final normalizedTo = DateUtils.dateOnly(to);
    final stats = calculateWeeklyStats(
      workouts: workouts,
      diaries: diaries,
      stepCounts: stepCounts,
      dailyStepGoal: profile?.dailyStepGoal ?? defaultDailyStepGoal,
      dailyCalorieGoal: profile?.dailyCalorieGoal ?? defaultDailyCalorieGoal,
      from: normalizedFrom,
      to: normalizedTo,
    );
    final rangeWorkouts = workouts
        .where((workout) {
          final workoutDate = DateUtils.dateOnly(workout.startedAt);
          return !workoutDate.isBefore(normalizedFrom) &&
              !workoutDate.isAfter(normalizedTo);
        })
        .toList(growable: false);
    final totalWorkoutCalories = rangeWorkouts.fold<double>(
      0,
      (total, workout) => total + workout.calories,
    );
    final numberOfDays = normalizedTo.difference(normalizedFrom).inDays + 1;

    return DashboardRangeAnalytics(
      from: normalizedFrom,
      to: normalizedTo,
      stats: stats,
      weightAnalytics: buildWeightAnalytics(
        profile: profile,
        weightHistory: weightHistory,
      ),
      totalWorkoutCalories: totalWorkoutCalories,
      totalWorkouts: rangeWorkouts.length,
      averageDailySteps: stats.totalSteps / numberOfDays,
      averageDailyCalories: stats.totalCalories / numberOfDays,
    );
  }

  DashboardWeightAnalytics buildWeightAnalytics({
    UserProfile? profile,
    List<WeightHistoryEntry> weightHistory = const <WeightHistoryEntry>[],
  }) {
    final sortedHistory = List<WeightHistoryEntry>.from(weightHistory)
      ..sort((left, right) => left.recordedAt.compareTo(right.recordedAt));
    final latestWeight = sortedHistory.isNotEmpty
        ? sortedHistory.last.weightKg
        : profile?.currentWeightKg;
    final firstWeightInPeriod = sortedHistory.isNotEmpty
        ? sortedHistory.first.weightKg
        : latestWeight;
    final lastWeightInPeriod = sortedHistory.isNotEmpty
        ? sortedHistory.last.weightKg
        : latestWeight;
    final startWeight = profile?.startWeightKg ?? firstWeightInPeriod;
    final targetWeight = profile?.targetWeightKg;
    final goalType = profile?.goalType ?? UserGoalType.maintainWeight;
    final weeklyChange = firstWeightInPeriod != null && latestWeight != null
        ? _goalAdjustedChange(
            start: firstWeightInPeriod,
            end: latestWeight,
            goalType: goalType,
          )
        : null;
    final totalChange = startWeight != null && latestWeight != null
        ? _goalAdjustedChange(
            start: startWeight,
            end: latestWeight,
            goalType: goalType,
          )
        : null;
    final remainingToGoal = latestWeight != null && targetWeight != null
        ? _remainingToGoal(
            currentWeight: latestWeight,
            targetWeight: targetWeight,
            goalType: goalType,
          )
        : null;
    final goalProgress =
        startWeight != null &&
            latestWeight != null &&
            targetWeight != null &&
            !_nearlyEqual(startWeight, targetWeight)
        ? _clamp01(
            _goalAdjustedChange(
                  start: startWeight,
                  end: latestWeight,
                  goalType: goalType,
                ) /
                _goalAdjustedChange(
                  start: startWeight,
                  end: targetWeight,
                  goalType: goalType,
                ).abs(),
          )
        : null;

    return DashboardWeightAnalytics(
      goalType: goalType,
      startWeightKg: startWeight,
      currentWeightKg: latestWeight,
      targetWeightKg: targetWeight,
      periodStartWeightKg: firstWeightInPeriod,
      periodEndWeightKg: lastWeightInPeriod,
      weeklyChangeKg: weeklyChange,
      totalChangeKg: totalChange,
      remainingToGoalKg: remainingToGoal,
      goalProgress: goalProgress,
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

  double _goalAdjustedChange({
    required double start,
    required double end,
    required UserGoalType goalType,
  }) {
    return switch (goalType) {
      UserGoalType.loseWeight => start - end,
      UserGoalType.gainWeight => end - start,
      UserGoalType.maintainWeight => -(end - start).abs(),
    };
  }

  double _remainingToGoal({
    required double currentWeight,
    required double targetWeight,
    required UserGoalType goalType,
  }) {
    return switch (goalType) {
      UserGoalType.loseWeight => currentWeight - targetWeight,
      UserGoalType.gainWeight => targetWeight - currentWeight,
      UserGoalType.maintainWeight => (currentWeight - targetWeight).abs(),
    };
  }

  bool _nearlyEqual(double a, double b) {
    return (a - b).abs() < 0.001;
  }
}
