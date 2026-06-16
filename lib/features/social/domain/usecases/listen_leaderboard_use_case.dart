import '../entities/leaderboard_user.dart';
import '../repositories/social_repository.dart';

class ListenLeaderboardUseCase {
  const ListenLeaderboardUseCase(this._repository);

  final SocialRepository _repository;

  Stream<List<LeaderboardUser>> call({int limit = 20, String? city}) {
    return _repository.listenLeaderboard(limit: limit, city: city);
  }
}
