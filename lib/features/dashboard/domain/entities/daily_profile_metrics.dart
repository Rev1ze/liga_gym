import '../../../workout/domain/entities/workout.dart';
import 'dashboard_analytics.dart';

class DailyProfileMetrics {
  const DailyProfileMetrics({
    required this.date,
    required this.steps,
    required this.hasRecordedSteps,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.proteins,
    required this.fats,
    required this.carbs,
    required this.foodEntriesCount,
    required this.workouts,
    required this.stepGoal,
    required this.calorieGoal,
    required this.progress,
  });

  final DateTime date;
  final int steps;
  final bool hasRecordedSteps;
  final double caloriesConsumed;
  final double caloriesBurned;
  final double proteins;
  final double fats;
  final double carbs;
  final int foodEntriesCount;
  final List<Workout> workouts;
  final int stepGoal;
  final double calorieGoal;
  final DashboardGoalProgress progress;

  int get workoutsCount => workouts.length;

  Duration get totalWorkoutDuration {
    return workouts.fold(
      Duration.zero,
      (total, workout) => total + workout.duration,
    );
  }

  double get totalWorkoutDistanceMeters {
    return workouts.fold(0, (total, workout) => total + workout.distanceMeters);
  }
}
