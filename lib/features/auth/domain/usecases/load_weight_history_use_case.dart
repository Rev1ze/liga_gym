import '../entities/weight_history_entry.dart';
import '../repositories/auth_repository.dart';

class LoadWeightHistoryUseCase {
  const LoadWeightHistoryUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<List<WeightHistoryEntry>> call({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) {
    return _authRepository.loadWeightHistory(
      userId: userId,
      from: from,
      to: to,
    );
  }
}
