import '../entities/daily_step_count.dart';

abstract interface class StepRepository {
  Future<List<DailyStepCount>> loadStepCounts({
    required String userId,
    required DateTime from,
    required DateTime to,
  });

  Future<int> loadStepsForDate({
    required String userId,
    required DateTime date,
  });
}
