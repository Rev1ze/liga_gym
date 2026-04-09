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

class DashboardAnalytics {
  const DashboardAnalytics({
    required this.weeklyStats,
    required this.progress,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  final DashboardWeeklyStats weeklyStats;
  final DashboardGoalProgress progress;
  final double proteins;
  final double fats;
  final double carbs;
}
