class DailyStepCount {
  const DailyStepCount({
    required this.userId,
    required this.date,
    required this.steps,
  });

  final String userId;
  final DateTime date;
  final int steps;
}
