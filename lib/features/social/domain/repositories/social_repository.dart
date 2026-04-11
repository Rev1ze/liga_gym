import '../entities/chat_message.dart';
import '../entities/leaderboard_user.dart';

abstract interface class SocialRepository {
  Future<void> ensureLeaderboardEntry({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  });

  Future<void> sendMessage({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String message,
  });

  Stream<List<ChatMessage>> listenMessages({int limit = 50});

  Stream<List<LeaderboardUser>> listenLeaderboard({int limit = 20});
}
