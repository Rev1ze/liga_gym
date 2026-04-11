import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/domain/entities/weight_history_entry.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../nutrition/domain/entities/daily_food_diary.dart';
import '../../../nutrition/presentation/providers/nutrition_providers.dart';
import '../../../steps/domain/entities/daily_step_count.dart';
import '../../../steps/presentation/providers/step_providers.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/services/dashboard_analytics_calculator.dart';
import '../utils/analytics_range_query.dart';

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
          profile: null,
          now: today,
        );
  }

  final loadUserWorkouts = ref.watch(loadUserWorkoutsUseCaseProvider);
  final loadDailyFoodEntries = ref.watch(loadDailyFoodEntriesUseCaseProvider);
  final loadStepCounts = ref.watch(loadStepCountsUseCaseProvider);
  final loadUserProfile = ref.watch(loadUserProfileUseCaseProvider);
  final loadWeightHistory = ref.watch(loadWeightHistoryUseCaseProvider);
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
  final stepCountsFuture = loadStepCounts.call(
    userId: user.uid,
    from: dates.first,
    to: today,
  );
  final profileFuture = loadUserProfile.call(user.uid);
  final weightHistoryFuture = loadWeightHistory.call(
    userId: user.uid,
    from: dates.first,
    to: today,
  );
  final results =
      await Future.wait<Object>([
        workoutsFuture,
        diariesFuture,
        stepCountsFuture,
        profileFuture,
        weightHistoryFuture,
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Dashboard analytics timed out'),
      );
  final workouts = results.first as List<Workout>;
  final diaries = results[1] as List<DailyFoodDiary>;
  final stepCounts = results[2] as List<DailyStepCount>;
  final profile = results[3] as UserProfile;
  final weightHistory = results[4] as List<WeightHistoryEntry>;

  return ref
      .watch(dashboardAnalyticsCalculatorProvider)
      .buildAnalytics(
        workouts: workouts,
        diaries: diaries,
        stepCounts: stepCounts,
        profile: profile,
        weightHistory: weightHistory,
        now: today,
      );
});

final dashboardRangeAnalyticsProvider =
    FutureProvider.family<DashboardRangeAnalytics, AnalyticsRangeQuery>((
      ref,
      query,
    ) async {
      final user = ref.watch(firebaseWorkoutUserProvider);
      final normalizedQuery = query.normalized();

      if (user == null) {
        return ref
            .watch(dashboardAnalyticsCalculatorProvider)
            .buildRangeAnalytics(
              workouts: const <Workout>[],
              diaries: List<DailyFoodDiary>.generate(
                normalizedQuery.to.difference(normalizedQuery.from).inDays + 1,
                (index) => DailyFoodDiary(
                  date: normalizedQuery.from.add(Duration(days: index)),
                  entries: const [],
                ),
                growable: false,
              ),
              from: normalizedQuery.from,
              to: normalizedQuery.to,
            );
      }

      final loadUserWorkouts = ref.watch(loadUserWorkoutsUseCaseProvider);
      final loadDailyFoodEntries = ref.watch(
        loadDailyFoodEntriesUseCaseProvider,
      );
      final loadStepCounts = ref.watch(loadStepCountsUseCaseProvider);
      final loadUserProfile = ref.watch(loadUserProfileUseCaseProvider);
      final loadWeightHistory = ref.watch(loadWeightHistoryUseCaseProvider);
      final workoutsFuture = loadUserWorkouts.call(user.uid);
      final dates = List<DateTime>.generate(
        normalizedQuery.to.difference(normalizedQuery.from).inDays + 1,
        (index) => normalizedQuery.from.add(Duration(days: index)),
        growable: false,
      );
      final diariesFuture = Future.wait(
        dates.map(
          (date) => loadDailyFoodEntries.call(userId: user.uid, date: date),
        ),
      );
      final stepCountsFuture = loadStepCounts.call(
        userId: user.uid,
        from: normalizedQuery.from,
        to: normalizedQuery.to,
      );
      final profileFuture = loadUserProfile.call(user.uid);
      final weightHistoryFuture = loadWeightHistory.call(
        userId: user.uid,
        from: normalizedQuery.from,
        to: normalizedQuery.to,
      );
      final results =
          await Future.wait<Object>([
            workoutsFuture,
            diariesFuture,
            stepCountsFuture,
            profileFuture,
            weightHistoryFuture,
          ]).timeout(
            const Duration(seconds: 5),
            onTimeout: () =>
                throw TimeoutException('Dashboard range analytics timed out'),
          );
      final workouts = results.first as List<Workout>;
      final diaries = results[1] as List<DailyFoodDiary>;
      final stepCounts = results[2] as List<DailyStepCount>;
      final profile = results[3] as UserProfile;
      final weightHistory = results[4] as List<WeightHistoryEntry>;

      return ref
          .watch(dashboardAnalyticsCalculatorProvider)
          .buildRangeAnalytics(
            workouts: workouts,
            diaries: diaries,
            stepCounts: stepCounts,
            profile: profile,
            weightHistory: weightHistory,
            from: normalizedQuery.from,
            to: normalizedQuery.to,
          );
    });
