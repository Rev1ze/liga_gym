import '../entities/daily_step_count.dart';
import '../repositories/step_repository.dart';

class LoadStepCountsUseCase {
  const LoadStepCountsUseCase(this._stepRepository);

  final StepRepository _stepRepository;

  Future<List<DailyStepCount>> call({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) {
    return _stepRepository.loadStepCounts(userId: userId, from: from, to: to);
  }
}
