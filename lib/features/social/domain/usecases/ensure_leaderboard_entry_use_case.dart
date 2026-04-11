import '../repositories/social_repository.dart';

class EnsureLeaderboardEntryUseCase {
  const EnsureLeaderboardEntryUseCase(this._repository);

  final SocialRepository _repository;

  Future<void> call({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) {
    return _repository.ensureLeaderboardEntry(
      userId: userId,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
    );
  }
}
