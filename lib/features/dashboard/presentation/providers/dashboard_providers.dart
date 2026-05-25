import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/domain/entities/weight_history_entry.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../nutrition/domain/entities/daily_food_diary.dart';
import '../../../nutrition/presentation/providers/nutrition_providers.dart';
import '../../../steps/domain/entities/daily_step_count.dart';
import '../../../steps/presentation/providers/step_providers.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/domain/entities/workout_type.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/daily_profile_metrics.dart';
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

final dailyProfileMetricsProvider =
    FutureProvider.family<DailyProfileMetrics, DateTime>((ref, date) async {
      final user = ref.watch(firebaseWorkoutUserProvider);
      final normalizedDate = DateUtils.dateOnly(date);
      final calculator = ref.watch(dashboardAnalyticsCalculatorProvider);

      if (user == null) {
        final progress = calculator.calculateProgress(
          steps: 0,
          calories: 0,
          stepGoal: calculator.defaultDailyStepGoal,
          calorieGoal: calculator.defaultDailyCalorieGoal,
        );

        return DailyProfileMetrics(
          date: normalizedDate,
          steps: 0,
          hasRecordedSteps: false,
          caloriesConsumed: 0,
          caloriesBurned: 0,
          proteins: 0,
          fats: 0,
          carbs: 0,
          foodEntriesCount: 0,
          workouts: const <Workout>[],
          stepGoal: calculator.defaultDailyStepGoal,
          calorieGoal: calculator.defaultDailyCalorieGoal,
          progress: progress,
        );
      }

      final loadUserWorkouts = ref.watch(loadUserWorkoutsUseCaseProvider);
      final loadDailyFoodEntries = ref.watch(
        loadDailyFoodEntriesUseCaseProvider,
      );
      final loadStepCounts = ref.watch(loadStepCountsUseCaseProvider);
      final loadUserProfile = ref.watch(loadUserProfileUseCaseProvider);
      final firebaseBootstrap = ref.watch(firebaseBootstrapProvider);
      final firestore = firebaseBootstrap.isConfigured
          ? ref.watch(firebaseFirestoreProvider)
          : null;

      final results = await Future.wait<Object>([
        loadUserWorkouts.call(user.uid),
        loadDailyFoodEntries.call(userId: user.uid, date: normalizedDate),
        loadStepCounts.call(
          userId: user.uid,
          from: normalizedDate,
          to: normalizedDate,
        ),
        loadUserProfile.call(user.uid),
      ]);
      final allWorkouts = results[0] as List<Workout>;
      final diary = results[1] as DailyFoodDiary;
      final stepCounts = results[2] as List<DailyStepCount>;
      final profile = results[3] as UserProfile;
      final dayWorkouts = allWorkouts
          .where(
            (workout) => DateUtils.isSameDay(workout.startedAt, normalizedDate),
          )
          .toList(growable: false);
      final macros = diary.totalMacros();
      final recordedSteps = stepCounts.isEmpty ? null : stepCounts.first.steps;
      final steps = recordedSteps ?? _estimateSteps(dayWorkouts);
      final burnedCalories = dayWorkouts.fold<double>(
        0,
        (total, workout) => total + workout.calories,
      );
      final progress = calculator.calculateProgress(
        steps: steps,
        calories: macros.calories,
        stepGoal: profile.dailyStepGoal,
        calorieGoal: profile.dailyCalorieGoal,
      );
      final metrics = DailyProfileMetrics(
        date: normalizedDate,
        steps: steps,
        hasRecordedSteps: recordedSteps != null,
        caloriesConsumed: macros.calories,
        caloriesBurned: burnedCalories,
        proteins: macros.proteins,
        fats: macros.fats,
        carbs: macros.carbs,
        foodEntriesCount: diary.entries.length,
        workouts: dayWorkouts,
        stepGoal: profile.dailyStepGoal,
        calorieGoal: profile.dailyCalorieGoal,
        progress: progress,
      );

      if (firestore != null) {
        unawaited(
          _saveDailyProfileMetricsSnapshot(
            firestore: firestore,
            userId: user.uid,
            metrics: metrics,
          ).catchError((_) {}),
        );
      }

      return metrics;
    });

int _estimateSteps(List<Workout> workouts) {
  return workouts.fold<int>(0, (total, workout) {
    final isStepBasedWorkout =
        workout.type == WorkoutType.running ||
        workout.type == WorkoutType.walking;
    if (!isStepBasedWorkout || workout.distanceMeters <= 0) {
      return total;
    }

    return total + (workout.distanceMeters / 0.78).round();
  });
}

Future<void> _saveDailyProfileMetricsSnapshot({
  required FirebaseFirestore firestore,
  required String userId,
  required DailyProfileMetrics metrics,
}) {
  final dateKey = _dailyMetricsDateKey(metrics.date);

  return firestore
      .collection('users')
      .doc(userId)
      .collection('daily_metrics')
      .doc(dateKey)
      .set(<String, Object?>{
        'dateKey': dateKey,
        'date': Timestamp.fromDate(metrics.date),
        'steps': metrics.steps,
        'hasRecordedSteps': metrics.hasRecordedSteps,
        'caloriesConsumed': metrics.caloriesConsumed,
        'caloriesBurned': metrics.caloriesBurned,
        'proteins': metrics.proteins,
        'fats': metrics.fats,
        'carbs': metrics.carbs,
        'foodEntriesCount': metrics.foodEntriesCount,
        'workoutsCount': metrics.workoutsCount,
        'workoutMinutes': metrics.totalWorkoutDuration.inMinutes,
        'workoutDistanceMeters': metrics.totalWorkoutDistanceMeters,
        'stepGoal': metrics.stepGoal,
        'calorieGoal': metrics.calorieGoal,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}

String _dailyMetricsDateKey(DateTime date) {
  final normalized = DateUtils.dateOnly(date);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}
