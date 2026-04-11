import '../../domain/entities/daily_step_count.dart';
import '../../domain/repositories/step_repository.dart';
import '../datasources/step_local_data_source.dart';

class StepRepositoryImpl implements StepRepository {
  const StepRepositoryImpl({required StepLocalDataSource stepLocalDataSource})
    : _stepLocalDataSource = stepLocalDataSource;

  final StepLocalDataSource _stepLocalDataSource;

  @override
  Future<List<DailyStepCount>> loadStepCounts({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) {
    return _stepLocalDataSource.loadStepCounts(
      userId: userId,
      from: from,
      to: to,
    );
  }

  @override
  Future<int> loadStepsForDate({
    required String userId,
    required DateTime date,
  }) {
    return _stepLocalDataSource.loadStepsForDate(userId: userId, date: date);
  }
}
