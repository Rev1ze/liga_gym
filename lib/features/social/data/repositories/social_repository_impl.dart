import '../../domain/entities/chat_message.dart';
import '../../domain/entities/leaderboard_user.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_data_source.dart';

class SocialRepositoryImpl implements SocialRepository {
  const SocialRepositoryImpl({required SocialRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final SocialRemoteDataSource _remoteDataSource;

  @override
  Future<void> ensureLeaderboardEntry({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) {
    return _remoteDataSource.ensureLeaderboardEntry(
      userId: userId,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
    );
  }

  @override
  Stream<List<LeaderboardUser>> listenLeaderboard({int limit = 20}) {
    return _remoteDataSource.listenLeaderboard(limit: limit);
  }

  @override
  Stream<List<ChatMessage>> listenMessages({int limit = 50}) {
    return _remoteDataSource.listenMessages(limit: limit);
  }

  @override
  Future<void> sendMessage({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String message,
  }) {
    return _remoteDataSource.sendMessage(
      userId: userId,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
      message: message,
    );
  }
}
