import '../entities/chat_member_role.dart';
import '../entities/chat_message.dart';
import '../entities/chat_participant.dart';
import '../entities/friend_profile.dart';
import '../entities/friend_request.dart';
import '../entities/interest_chat_room.dart';
import '../entities/leaderboard_user.dart';
import '../entities/social_privacy.dart';

abstract interface class SocialRepository {
  Future<void> ensureSocialProfile({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  });

  Future<void> updateFriendSharedSteps({
    required String userId,
    required int stepsCount,
  });

  Future<String> createFriendInvite({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  });

  Future<void> sendFriendRequest({
    required String fromUserId,
    required String inviteCodeOrLink,
    required String fallbackName,
    required String fallbackEmail,
  });

  Future<void> acceptFriendRequest({
    required String requestId,
    required String userId,
  });

  Future<void> declineFriendRequest({
    required String requestId,
    required String userId,
  });

  Future<void> removeFriend({required String userId, required String friendId});

  Future<void> savePrivacySettings({
    required String userId,
    required SocialPrivacySettings settings,
  });

  Future<String> createInterestChat({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String title,
    required String description,
  });

  Future<String> openFriendChat({
    required String userId,
    required String friendId,
    required String friendName,
    required String fallbackName,
    required String fallbackEmail,
  });

  Future<void> joinInterestChat({
    required String chatId,
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  });

  Future<void> leaveInterestChat({
    required String chatId,
    required String userId,
  });

  Future<void> sendMessage({
    required String chatId,
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String message,
  });

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  });

  Future<void> removeParticipant({
    required String chatId,
    required String targetUserId,
    String? reason,
  });

  Future<void> updateParticipantPermissions({
    required String chatId,
    required String targetUserId,
    required ChatMemberRole role,
    required bool canRemoveMessages,
    required bool canRemoveUsers,
  });

  Stream<List<InterestChatRoom>> listenInterestChats({int limit = 100});

  Stream<InterestChatRoom?> watchInterestChat(String chatId);

  Stream<List<ChatParticipant>> listenParticipants(String chatId);

  Stream<ChatParticipant?> watchParticipant({
    required String chatId,
    required String userId,
  });

  Stream<List<ChatMessage>> listenMessages({
    required String chatId,
    int limit = 50,
  });

  Stream<List<FriendProfile>> listenFriends(String userId);

  Stream<List<FriendRequest>> listenIncomingFriendRequests(String userId);

  Stream<SocialPrivacySettings> watchPrivacySettings(String userId);

  Stream<List<LeaderboardUser>> listenLeaderboard({int limit = 20});
}
