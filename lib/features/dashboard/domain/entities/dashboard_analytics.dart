import '../../../auth/domain/entities/user_goal.dart';

class DashboardGoalProgress {
  const DashboardGoalProgress({
    required this.steps,
    required this.calories,
    required this.overall,
  });

  final double steps;
  final double calories;
  final double overall;
}

class DashboardDaySummary {
  const DashboardDaySummary({
    required this.date,
    required this.steps,
    required this.calories,
    required this.progress,
  });

  final DateTime date;
  final int steps;
  final double calories;
  final DashboardGoalProgress progress;
}

class DashboardWeeklyStats {
  const DashboardWeeklyStats({required this.days});

  final List<DashboardDaySummary> days;

  DashboardDaySummary get today => days.last;

  int get totalSteps => days.fold(0, (total, day) => total + day.steps);

  double get totalCalories =>
      days.fold(0.0, (total, day) => total + day.calories);

  int get maxSteps => days.fold(0, (maxValue, day) {
    return day.steps > maxValue ? day.steps : maxValue;
  });

  double get maxCalories => days.fold(0.0, (maxValue, day) {
    return day.calories > maxValue ? day.calories : maxValue;
  });
}

class DashboardUserGoals {
  const DashboardUserGoals({
    required this.stepGoal,
    required this.calorieGoal,
    required this.goalType,
    this.currentWeightKg,
    this.targetWeightKg,
  });

  final int stepGoal;
  final double calorieGoal;
  final UserGoalType goalType;
  final double? currentWeightKg;
  final double? targetWeightKg;
}

class DashboardWeightAnalytics {
  const DashboardWeightAnalytics({
    required this.goalType,
    this.startWeightKg,
    this.currentWeightKg,
    this.targetWeightKg,
    this.periodStartWeightKg,
    this.periodEndWeightKg,
    this.weeklyChangeKg,
    this.totalChangeKg,
    this.remainingToGoalKg,
    this.goalProgress,
  });

  final UserGoalType goalType;
  final double? startWeightKg;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final double? periodStartWeightKg;
  final double? periodEndWeightKg;
  final double? weeklyChangeKg;
  final double? totalChangeKg;
  final double? remainingToGoalKg;
  final double? goalProgress;

  bool get hasData =>
      currentWeightKg != null &&
      (targetWeightKg != null ||
          totalChangeKg != null ||
          weeklyChangeKg != null);
}

class DashboardAnalytics {
  const DashboardAnalytics({
    required this.weeklyStats,
    required this.progress,
    required this.goals,
    required this.weightAnalytics,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  final DashboardWeeklyStats weeklyStats;
  final DashboardGoalProgress progress;
  final DashboardUserGoals goals;
  final DashboardWeightAnalytics weightAnalytics;
  final double proteins;
  final double fats;
  final double carbs;
}

class DashboardRangeAnalytics {
  const DashboardRangeAnalytics({
    required this.from,
    required this.to,
    required this.stats,
    required this.weightAnalytics,
    required this.totalWorkoutCalories,
    required this.totalWorkouts,
    required this.averageDailySteps,
    required this.averageDailyCalories,
  });

  final DateTime from;
  final DateTime to;
  final DashboardWeeklyStats stats;
  final DashboardWeightAnalytics weightAnalytics;
  final double totalWorkoutCalories;
  final int totalWorkouts;
  final double averageDailySteps;
  final double averageDailyCalories;
}
