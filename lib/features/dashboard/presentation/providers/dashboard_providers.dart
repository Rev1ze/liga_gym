import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nutrition/domain/entities/daily_food_diary.dart';
import '../../../nutrition/presentation/providers/nutrition_providers.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/services/dashboard_analytics_calculator.dart';

final dashboardAnalyticsCalculatorProvider = Provider(
  (ref) => const DashboardAnalyticsCalculator(),
);

final dashboardAnalyticsProvider = FutureProvider<DashboardAnalytics>((
  ref,
) async {
  final user = ref.watch(firebaseWorkoutUserProvider);
  final today = DateUtils.dateOnly(DateTime.now());

  if (user == null) {
    return ref
        .watch(dashboardAnalyticsCalculatorProvider)
        .buildAnalytics(
          workouts: const <Workout>[],
          diaries: <DailyFoodDiary>[
            DailyFoodDiary(date: today, entries: const []),
          ],
          now: today,
        );
  }

  final loadUserWorkouts = ref.watch(loadUserWorkoutsUseCaseProvider);
  final loadDailyFoodEntries = ref.watch(loadDailyFoodEntriesUseCaseProvider);
  final workoutsFuture = loadUserWorkouts.call(user.uid);
  final dates = List<DateTime>.generate(
    7,
    (index) => today.subtract(Duration(days: 6 - index)),
    growable: false,
  );
  final diariesFuture = Future.wait(
    dates.map(
      (date) => loadDailyFoodEntries.call(userId: user.uid, date: date),
    ),
  );
  final results = await Future.wait<Object>([workoutsFuture, diariesFuture])
      .timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Dashboard analytics timed out'),
      );
  final workouts = results.first as List<Workout>;
  final diaries = results.last as List<DailyFoodDiary>;

  return ref
      .watch(dashboardAnalyticsCalculatorProvider)
      .buildAnalytics(workouts: workouts, diaries: diaries, now: today);
});
