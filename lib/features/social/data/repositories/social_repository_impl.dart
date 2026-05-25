import '../../domain/entities/chat_member_role.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_participant.dart';
import '../../domain/entities/friend_profile.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/entities/interest_chat_room.dart';
import '../../domain/entities/leaderboard_user.dart';
import '../../domain/entities/social_privacy.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_data_source.dart';

class SocialRepositoryImpl implements SocialRepository {
  const SocialRepositoryImpl({required SocialRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final SocialRemoteDataSource _remoteDataSource;

  @override
  Future<String> createInterestChat({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String title,
    required String description,
  }) {
    return _remoteDataSource.createInterestChat(
      userId: userId,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
      title: title,
      description: description,
    );
  }

  @override
  Future<String> openFriendChat({
    required String userId,
    required String friendId,
    required String friendName,
    required String fallbackName,
    required String fallbackEmail,
  }) {
    return _remoteDataSource.openFriendChat(
      userId: userId,
      friendId: friendId,
      friendName: friendName,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
    );
  }

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) {
    return _remoteDataSource.deleteMessage(
      chatId: chatId,
      messageId: messageId,
    );
  }

  @override
  Future<void> ensureSocialProfile({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) {
    return _remoteDataSource.ensureSocialProfile(
      userId: userId,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
    );
  }

  @override
  Future<void> acceptFriendRequest({
    required String requestId,
    required String userId,
  }) {
    return _remoteDataSource.acceptFriendRequest(
      requestId: requestId,
      userId: userId,
    );
  }

  @override
  Future<String> createFriendInvite({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) {
    return _remoteDataSource.createFriendInvite(
      userId: userId,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
    );
  }

  @override
  Future<void> declineFriendRequest({
    required String requestId,
    required String userId,
  }) {
    return _remoteDataSource.declineFriendRequest(
      requestId: requestId,
      userId: userId,
    );
  }

  @override
  Future<void> joinInterestChat({
    required String chatId,
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) {
    return _remoteDataSource.joinInterestChat(
      chatId: chatId,
      userId: userId,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
    );
  }

  @override
  Future<void> leaveInterestChat({
    required String chatId,
    required String userId,
  }) {
    return _remoteDataSource.leaveInterestChat(chatId: chatId, userId: userId);
  }

  @override
  Stream<List<InterestChatRoom>> listenInterestChats({int limit = 100}) {
    return _remoteDataSource.listenInterestChats(limit: limit);
  }

  @override
  Stream<List<FriendProfile>> listenFriends(String userId) {
    return _remoteDataSource.listenFriends(userId);
  }

  @override
  Stream<List<FriendRequest>> listenIncomingFriendRequests(String userId) {
    return _remoteDataSource.listenIncomingFriendRequests(userId);
  }

  @override
  Stream<List<LeaderboardUser>> listenLeaderboard({int limit = 20}) {
    return _remoteDataSource.listenLeaderboard(limit: limit);
  }

  @override
  Stream<List<ChatMessage>> listenMessages({
    required String chatId,
    int limit = 50,
  }) {
    return _remoteDataSource.listenMessages(chatId: chatId, limit: limit);
  }

  @override
  Stream<List<ChatParticipant>> listenParticipants(String chatId) {
    return _remoteDataSource.listenParticipants(chatId);
  }

  @override
  Future<void> removeParticipant({
    required String chatId,
    required String targetUserId,
    String? reason,
  }) {
    return _remoteDataSource.removeParticipant(
      chatId: chatId,
      targetUserId: targetUserId,
      reason: reason,
    );
  }

  @override
  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) {
    return _remoteDataSource.removeFriend(userId: userId, friendId: friendId);
  }

  @override
  Future<void> savePrivacySettings({
    required String userId,
    required SocialPrivacySettings settings,
  }) {
    return _remoteDataSource.savePrivacySettings(
      userId: userId,
      settings: settings,
    );
  }

  @override
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String inviteCodeOrLink,
    required String fallbackName,
    required String fallbackEmail,
  }) {
    return _remoteDataSource.sendFriendRequest(
      fromUserId: fromUserId,
      inviteCodeOrLink: inviteCodeOrLink,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
    );
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String message,
  }) {
    return _remoteDataSource.sendMessage(
      chatId: chatId,
      userId: userId,
      fallbackName: fallbackName,
      fallbackEmail: fallbackEmail,
      message: message,
    );
  }

  @override
  Future<void> updateFriendSharedSteps({
    required String userId,
    required int stepsCount,
  }) {
    return _remoteDataSource.updateFriendSharedSteps(
      userId: userId,
      stepsCount: stepsCount,
    );
  }

  @override
  Future<void> updateParticipantPermissions({
    required String chatId,
    required String targetUserId,
    required ChatMemberRole role,
    required bool canRemoveMessages,
    required bool canRemoveUsers,
  }) {
    return _remoteDataSource.updateParticipantPermissions(
      chatId: chatId,
      targetUserId: targetUserId,
      role: role,
      canRemoveMessages: canRemoveMessages,
      canRemoveUsers: canRemoveUsers,
    );
  }

  @override
  Stream<InterestChatRoom?> watchInterestChat(String chatId) {
    return _remoteDataSource.watchInterestChat(chatId);
  }

  @override
  Stream<ChatParticipant?> watchParticipant({
    required String chatId,
    required String userId,
  }) {
    return _remoteDataSource.watchParticipant(chatId: chatId, userId: userId);
  }

  @override
  Stream<SocialPrivacySettings> watchPrivacySettings(String userId) {
    return _remoteDataSource.watchPrivacySettings(userId);
  }
}
