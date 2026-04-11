import '../repositories/social_repository.dart';

class UpdateLeaderboardStepsUseCase {
  const UpdateLeaderboardStepsUseCase(this._repository);

  final SocialRepository _repository;

  Future<void> call({
    required String userId,
    required int stepsCount,
  }) {
    return _repository.updateLeaderboardSteps(
      userId: userId,
      stepsCount: stepsCount,
    );
  }
}
