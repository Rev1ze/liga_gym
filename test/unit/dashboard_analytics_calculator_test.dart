import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/features/dashboard/domain/services/dashboard_analytics_calculator.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/daily_food_diary.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_entry.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_input_method.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_macros.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/meal_type.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_type.dart';

void main() {
  group('DashboardAnalyticsCalculator', () {
    const calculator = DashboardAnalyticsCalculator(
      dailyStepGoal: 10000,
      dailyCalorieGoal: 2200,
      metersPerStep: 0.8,
    );

    test('calculateWeeklyStats aggregates steps and nutrition by day', () {
      final now = DateTime(2026, 4, 9);
      final workouts = [
        Workout(
          id: 'w1',
          userId: 'user-1',
          type: WorkoutType.walking,
          startedAt: DateTime(2026, 4, 9, 8),
          endedAt: DateTime(2026, 4, 9, 9),
          duration: const Duration(hours: 1),
          calories: 210,
          distanceMeters: 3200,
          route: const [],
          isSynced: true,
        ),
        Workout(
          id: 'w2',
          userId: 'user-1',
          type: WorkoutType.cycling,
          startedAt: DateTime(2026, 4, 8, 7),
          endedAt: DateTime(2026, 4, 8, 8),
          duration: const Duration(hours: 1),
          calories: 330,
          distanceMeters: 11000,
          route: const [],
          isSynced: true,
        ),
        Workout(
          id: 'w3',
          userId: 'user-1',
          type: WorkoutType.running,
          startedAt: DateTime(2026, 4, 7, 18),
          endedAt: DateTime(2026, 4, 7, 19),
          duration: const Duration(hours: 1),
          calories: 420,
          distanceMeters: 4000,
          route: const [],
          isSynced: true,
        ),
      ];
      final diaries = [
        DailyFoodDiary(
          date: DateTime(2026, 4, 7),
          entries: [
            _entry(
              calories: 1600,
              proteins: 110,
              fats: 50,
              carbs: 180,
              loggedAt: DateTime(2026, 4, 7, 13),
            ),
          ],
        ),
        DailyFoodDiary(date: DateTime(2026, 4, 8), entries: const []),
        DailyFoodDiary(
          date: DateTime(2026, 4, 9),
          entries: [
            _entry(
              calories: 1800,
              proteins: 125,
              fats: 60,
              carbs: 210,
              loggedAt: DateTime(2026, 4, 9, 9),
            ),
          ],
        ),
      ];

      final stats = calculator.calculateWeeklyStats(
        workouts: workouts,
        diaries: diaries,
        now: now,
      );

      expect(stats.days, hasLength(7));
      expect(stats.today.steps, 4000);
      expect(stats.today.calories, 1800);
      expect(stats.days[5].steps, 0);
      expect(stats.days[4].steps, 5000);
      expect(stats.totalSteps, 9000);
      expect(stats.totalCalories, 3400);
      expect(stats.today.progress.steps, closeTo(0.4, 0.001));
      expect(stats.today.progress.calories, closeTo(1800 / 2200, 0.001));
    });

    test('calculateProgress clamps values to goal completion', () {
      final progress = calculator.calculateProgress(
        steps: 15000,
        calories: 2700,
      );

      expect(progress.steps, 1);
      expect(progress.calories, 1);
      expect(progress.overall, 1);
    });
  });
}

FoodEntry _entry({
  required double calories,
  required double proteins,
  required double fats,
  required double carbs,
  required DateTime loggedAt,
}) {
  return FoodEntry(
    id: 'entry-${loggedAt.microsecondsSinceEpoch}',
    userId: 'user-1',
    mealType: MealType.breakfast,
    productNameEn: 'Oatmeal',
    productNameRu: 'Oatmeal',
    grams: 100,
    macros: FoodMacros(
      calories: calories,
      proteins: proteins,
      fats: fats,
      carbs: carbs,
    ),
    loggedAt: loggedAt,
    inputMethod: FoodInputMethod.manual,
  );
}
