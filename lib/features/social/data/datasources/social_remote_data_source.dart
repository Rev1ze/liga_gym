import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/chat_member_role.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_participant.dart';
import '../../domain/entities/friend_profile.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/entities/interest_chat_room.dart';
import '../../domain/entities/leaderboard_user.dart';
import '../../domain/entities/social_privacy.dart';

abstract interface class SocialRemoteDataSource {
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

class UnavailableSocialRemoteDataSource implements SocialRemoteDataSource {
  const UnavailableSocialRemoteDataSource();

  @override
  Future<String> createInterestChat({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String title,
    required String description,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<String> openFriendChat({
    required String userId,
    required String friendId,
    required String friendName,
    required String fallbackName,
    required String fallbackEmail,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> ensureSocialProfile({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> acceptFriendRequest({
    required String requestId,
    required String userId,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<String> createFriendInvite({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> declineFriendRequest({
    required String requestId,
    required String userId,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> joinInterestChat({
    required String chatId,
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> leaveInterestChat({
    required String chatId,
    required String userId,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Stream<List<InterestChatRoom>> listenInterestChats({int limit = 100}) =>
      Stream<List<InterestChatRoom>>.error(
        const SocialException(AppErrorCode.firebaseConfigurationMissing),
      );

  @override
  Stream<List<FriendProfile>> listenFriends(String userId) =>
      Stream<List<FriendProfile>>.error(
        const SocialException(AppErrorCode.firebaseConfigurationMissing),
      );

  @override
  Stream<List<FriendRequest>> listenIncomingFriendRequests(String userId) =>
      Stream<List<FriendRequest>>.error(
        const SocialException(AppErrorCode.firebaseConfigurationMissing),
      );

  @override
  Stream<List<LeaderboardUser>> listenLeaderboard({int limit = 20}) =>
      Stream<List<LeaderboardUser>>.error(
        const SocialException(AppErrorCode.firebaseConfigurationMissing),
      );

  @override
  Stream<List<ChatMessage>> listenMessages({
    required String chatId,
    int limit = 50,
  }) => Stream<List<ChatMessage>>.error(
    const SocialException(AppErrorCode.firebaseConfigurationMissing),
  );

  @override
  Stream<List<ChatParticipant>> listenParticipants(String chatId) =>
      Stream<List<ChatParticipant>>.error(
        const SocialException(AppErrorCode.firebaseConfigurationMissing),
      );

  @override
  Future<void> removeParticipant({
    required String chatId,
    required String targetUserId,
    String? reason,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> savePrivacySettings({
    required String userId,
    required SocialPrivacySettings settings,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String inviteCodeOrLink,
    required String fallbackName,
    required String fallbackEmail,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> sendMessage({
    required String chatId,
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String message,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> updateFriendSharedSteps({
    required String userId,
    required int stepsCount,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> updateParticipantPermissions({
    required String chatId,
    required String targetUserId,
    required ChatMemberRole role,
    required bool canRemoveMessages,
    required bool canRemoveUsers,
  }) async =>
      throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Stream<InterestChatRoom?> watchInterestChat(String chatId) =>
      Stream<InterestChatRoom?>.error(
        const SocialException(AppErrorCode.firebaseConfigurationMissing),
      );

  @override
  Stream<ChatParticipant?> watchParticipant({
    required String chatId,
    required String userId,
  }) => Stream<ChatParticipant?>.error(
    const SocialException(AppErrorCode.firebaseConfigurationMissing),
  );

  @override
  Stream<SocialPrivacySettings> watchPrivacySettings(String userId) =>
      Stream<SocialPrivacySettings>.error(
        const SocialException(AppErrorCode.firebaseConfigurationMissing),
      );
}

class FirestoreSocialRemoteDataSource implements SocialRemoteDataSource {
  FirestoreSocialRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const Duration _requestTimeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _interestChats =>
      _firestore.collection('interest_chats');
  CollectionReference<Map<String, dynamic>> get _friendRequests =>
      _firestore.collection('friend_requests');
  CollectionReference<Map<String, dynamic>> get _friendInvites =>
      _firestore.collection('friend_invites');

  @override
  Future<void> ensureSocialProfile({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async {
    try {
      final userReference = _users.doc(userId);

      await _firestore
          .runTransaction((transaction) async {
            final userSnapshot = await transaction.get(userReference);
            final userData = userSnapshot.data() ?? <String, Object?>{};
            final displayName = _resolveSenderName(
              userData['name'] as String?,
              fallbackName,
              fallbackEmail,
            );

            transaction.set(userReference, <String, Object?>{
              'name': displayName,
              'email': (userData['email'] as String?)?.trim().isNotEmpty == true
                  ? (userData['email'] as String).trim()
                  : fallbackEmail.trim(),
              'socialScore': userData['socialScore'] ?? 0,
              'socialWorkoutsCount': userData['socialWorkoutsCount'] ?? 0,
              'socialCaloriesBurned': userData['socialCaloriesBurned'] ?? 0,
              'socialStepsCount': userData['socialStepsCount'] ?? 0,
              'visibleInFriendLeaderboard':
                  userData['visibleInFriendLeaderboard'] ?? true,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          })
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.leaderboardLoadFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.leaderboardLoadFailed);
    }
  }

  @override
  Future<void> updateFriendSharedSteps({
    required String userId,
    required int stepsCount,
  }) async {
    try {
      await _users
          .doc(userId)
          .set(<String, Object?>{
            'socialStepsCount': stepsCount,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.leaderboardLoadFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.leaderboardLoadFailed);
    }

    try {
      await _syncFriendSnapshot(userId);
    } on Object {
      // Friend mirrors are best-effort; step tracking must not fail when the
      // social collections are not available yet.
    }
  }

  @override
  Future<String> createFriendInvite({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async {
    try {
      await ensureSocialProfile(
        userId: userId,
        fallbackName: fallbackName,
        fallbackEmail: fallbackEmail,
      );
      final userData = await _loadUserData(userId);
      final friendCode = _normalizeFriendCode(
        userData['friendCode'] as String?,
      );
      if (friendCode.isEmpty) {
        throw const SocialException(AppErrorCode.profileSaveFailed);
      }
      final inviteReference = _friendInvites.doc(friendCode);
      await inviteReference
          .set(<String, Object?>{
            'ownerUserId': userId,
            'ownerDisplayName': _resolveSenderName(
              userData['name'] as String?,
              fallbackName,
              fallbackEmail,
            ),
            'ownerEmail': (userData['email'] as String?)?.trim() ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_requestTimeout);
      return friendCode;
    } on SocialException {
      rethrow;
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String inviteCodeOrLink,
    required String fallbackName,
    required String fallbackEmail,
  }) async {
    try {
      final inviteId = _extractInviteId(inviteCodeOrLink);
      final inviteSnapshot = await _friendInvites
          .doc(inviteId)
          .get()
          .timeout(_requestTimeout);
      final inviteData = inviteSnapshot.data();
      final toUserId = inviteData?['ownerUserId'] as String?;
      if (!inviteSnapshot.exists || toUserId == null || toUserId.isEmpty) {
        throw const SocialException(AppErrorCode.userNotFound);
      }
      if (toUserId == fromUserId) {
        return;
      }

      final fromData = await _loadUserData(fromUserId);
      final fromSettings = await _loadPrivacySettings(fromUserId);
      final requestId = _friendRequestId(fromUserId, toUserId);
      await _friendRequests
          .doc(requestId)
          .set(<String, Object?>{
            'fromUserId': fromUserId,
            'toUserId': toUserId,
            'fromDisplayName': _resolveSenderName(
              fromData['name'] as String?,
              fallbackName,
              fallbackEmail,
            ),
            'fromEmail':
                ((fromData['email'] as String?)?.trim().isNotEmpty == true
                        ? fromData['email'] as String
                        : fallbackEmail)
                    .trim(),
            'fromAllowedCategories': _allowedCategoriesForFriend(
              toUserId,
              fromSettings,
            ).map((category) => category.name).toList(growable: false),
            'fromVisibleInFriendLeaderboard':
                fromSettings.visibleInFriendLeaderboard,
            'status': FriendRequestStatus.pending.name,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(_requestTimeout);
    } on SocialException {
      rethrow;
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> acceptFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    try {
      final requestReference = _friendRequests.doc(requestId);

      await _firestore
          .runTransaction((transaction) async {
            final requestSnapshot = await transaction.get(requestReference);
            final requestData = requestSnapshot.data();
            if (!requestSnapshot.exists ||
                requestData?['toUserId'] != userId ||
                requestData?['status'] != FriendRequestStatus.pending.name) {
              return;
            }

            final fromUserId = requestData!['fromUserId'] as String;
            final toSnapshot = await transaction.get(_users.doc(userId));
            final toData = toSnapshot.data() ?? <String, Object?>{};
            final fromData = <String, Object?>{
              'name': requestData['fromDisplayName'],
              'email': requestData['fromEmail'],
              'socialScore': 0,
              'socialWorkoutsCount': 0,
              'socialCaloriesBurned': 0,
              'socialStepsCount': 0,
              'visibleInFriendLeaderboard':
                  requestData['fromVisibleInFriendLeaderboard'] ?? true,
            };
            final toSettingsSnapshot = await transaction.get(
              _users.doc(userId).collection('social_settings').doc('privacy'),
            );
            final toSettings = toSettingsSnapshot.exists
                ? SocialPrivacySettings.fromMap(
                    toSettingsSnapshot.data() ?? <String, Object?>{},
                  )
                : SocialPrivacySettings.defaults();

            transaction.set(
              _users.doc(userId).collection('friends').doc(fromUserId),
              _buildFriendSnapshot(
                fromUserId,
                fromData,
                allowedCategories: _parseCategoryNames(
                  requestData['fromAllowedCategories'],
                ),
                visibleInFriendLeaderboard:
                    requestData['fromVisibleInFriendLeaderboard'] as bool?,
              ),
              SetOptions(merge: true),
            );
            transaction.set(
              _users.doc(fromUserId).collection('friends').doc(userId),
              _buildFriendSnapshot(
                userId,
                toData,
                allowedCategories: _allowedCategoriesForFriend(
                  fromUserId,
                  toSettings,
                ),
                visibleInFriendLeaderboard:
                    toSettings.visibleInFriendLeaderboard,
              ),
              SetOptions(merge: true),
            );
            transaction.set(requestReference, <String, Object?>{
              'status': FriendRequestStatus.accepted.name,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          })
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> declineFriendRequest({
    required String requestId,
    required String userId,
  }) async {
    try {
      await _friendRequests
          .doc(requestId)
          .set(<String, Object?>{
            'status': FriendRequestStatus.declined.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      final batch = _firestore.batch();
      batch.delete(_users.doc(userId).collection('friends').doc(friendId));
      batch.delete(_users.doc(friendId).collection('friends').doc(userId));
      await batch.commit().timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> savePrivacySettings({
    required String userId,
    required SocialPrivacySettings settings,
  }) async {
    try {
      await _users
          .doc(userId)
          .collection('social_settings')
          .doc('privacy')
          .set(settings.toFirestore(), SetOptions(merge: true))
          .timeout(_requestTimeout);
      await _users
          .doc(userId)
          .set(<String, Object?>{
            'visibleInFriendLeaderboard': settings.visibleInFriendLeaderboard,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(_requestTimeout);
      await _syncFriendSnapshot(userId, settings: settings);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<String> createInterestChat({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String title,
    required String description,
  }) async {
    try {
      final userSnapshot = await _users
          .doc(userId)
          .get()
          .timeout(_requestTimeout);
      final userData = userSnapshot.data() ?? <String, Object?>{};
      final displayName = _resolveSenderName(
        userData['name'] as String?,
        fallbackName,
        fallbackEmail,
      );
      final roomReference = _interestChats.doc();
      final memberReference = roomReference.collection('members').doc(userId);
      final createdAt = FieldValue.serverTimestamp();

      await _firestore
          .runTransaction((transaction) async {
            transaction.set(roomReference, <String, Object?>{
              'title': title.trim(),
              'description': description.trim(),
              'createdBy': userId,
              'createdByName': displayName,
              'searchIndex': _buildSearchIndex(title, description),
              'memberCount': 1,
              'createdAt': createdAt,
              'updatedAt': createdAt,
              'lastMessageAt': null,
            });
            transaction.set(memberReference, <String, Object?>{
              'displayName': displayName,
              'city': (userData['city'] as String?)?.trim(),
              'role': ChatMemberRole.admin.name,
              'canRemoveMessages': true,
              'canRemoveUsers': true,
              'joinedAt': createdAt,
            });
          })
          .timeout(_requestTimeout);

      return roomReference.id;
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<String> openFriendChat({
    required String userId,
    required String friendId,
    required String friendName,
    required String fallbackName,
    required String fallbackEmail,
  }) async {
    try {
      final userSnapshot = await _users
          .doc(userId)
          .get()
          .timeout(_requestTimeout);
      final userData = userSnapshot.data() ?? <String, Object?>{};
      final userName = _resolveSenderName(
        userData['name'] as String?,
        fallbackName,
        fallbackEmail,
      );
      final trimmedFriendName = friendName.trim().isEmpty
          ? 'Friend'
          : friendName.trim();
      final ids = <String>[userId, friendId]..sort();
      final chatId = 'dm_${ids.join('_')}';
      final roomReference = _interestChats.doc(chatId);
      final createdAt = FieldValue.serverTimestamp();

      await _firestore
          .runTransaction((transaction) async {
            final roomSnapshot = await transaction.get(roomReference);
            final roomData = roomSnapshot.data() ?? <String, Object?>{};
            final roomPayload = <String, Object?>{
              'type': 'friend_dm',
              'title': roomData['title'] ?? 'Личный чат',
              'description': roomData['description'] ?? 'Личные сообщения',
              'createdBy': roomData['createdBy'] ?? userId,
              'createdByName': roomData['createdByName'] ?? userName,
              'participantIds': ids,
              'directKey': ids.join('_'),
              'searchIndex': _buildSearchIndex(
                '$userName $trimmedFriendName',
                'direct messages',
              ),
              'memberCount': 2,
              'updatedAt': createdAt,
              if (!roomSnapshot.exists) 'createdAt': createdAt,
              if (!roomSnapshot.exists) 'lastMessageAt': null,
            };
            transaction.set(
              roomReference,
              roomPayload,
              SetOptions(merge: true),
            );
            transaction.set(
              roomReference.collection('members').doc(userId),
              <String, Object?>{
                'displayName': userName,
                'city': (userData['city'] as String?)?.trim(),
                'role': ChatMemberRole.member.name,
                'canRemoveMessages': false,
                'canRemoveUsers': false,
                'joinedAt': createdAt,
              },
              SetOptions(merge: true),
            );
            transaction.set(
              roomReference.collection('members').doc(friendId),
              <String, Object?>{
                'displayName': trimmedFriendName,
                'role': ChatMemberRole.member.name,
                'canRemoveMessages': false,
                'canRemoveUsers': false,
                'joinedAt': createdAt,
              },
              SetOptions(merge: true),
            );
          })
          .timeout(_requestTimeout);

      return chatId;
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> joinInterestChat({
    required String chatId,
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async {
    try {
      final roomReference = _interestChats.doc(chatId);
      final memberReference = roomReference.collection('members').doc(userId);
      final userSnapshot = await _users
          .doc(userId)
          .get()
          .timeout(_requestTimeout);
      final userData = userSnapshot.data() ?? <String, Object?>{};
      final displayName = _resolveSenderName(
        userData['name'] as String?,
        fallbackName,
        fallbackEmail,
      );

      await _firestore
          .runTransaction((transaction) async {
            final memberSnapshot = await transaction.get(memberReference);
            if (memberSnapshot.exists) {
              return;
            }

            transaction.set(memberReference, <String, Object?>{
              'displayName': displayName,
              'city': (userData['city'] as String?)?.trim(),
              'role': ChatMemberRole.member.name,
              'canRemoveMessages': false,
              'canRemoveUsers': false,
              'joinedAt': FieldValue.serverTimestamp(),
            });
            transaction.set(roomReference, <String, Object?>{
              'memberCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          })
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> leaveInterestChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      final roomReference = _interestChats.doc(chatId);
      final memberReference = roomReference.collection('members').doc(userId);
      await _firestore
          .runTransaction((transaction) async {
            final memberSnapshot = await transaction.get(memberReference);
            if (!memberSnapshot.exists) {
              return;
            }

            final data = memberSnapshot.data() ?? <String, dynamic>{};
            if (data['role'] == ChatMemberRole.admin.name) {
              return;
            }
            transaction.delete(memberReference);
            transaction.set(roomReference, <String, Object?>{
              'memberCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          })
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String message,
  }) async {
    try {
      final roomReference = _interestChats.doc(chatId);
      final messagesReference = roomReference.collection('messages');
      final userSnapshot = await _users
          .doc(userId)
          .get()
          .timeout(_requestTimeout);
      final userData = userSnapshot.data() ?? <String, Object?>{};
      final senderName = _resolveSenderName(
        userData['name'] as String?,
        fallbackName,
        fallbackEmail,
      );
      final storedEmail = (userData['email'] as String?)?.trim() ?? '';
      final senderEmail = storedEmail.isNotEmpty ? storedEmail : fallbackEmail;

      await messagesReference
          .add(<String, Object?>{
            'senderId': userId,
            'senderName': senderName,
            'senderEmail': senderEmail.trim(),
            'senderCity': (userData['city'] as String?)?.trim(),
            'message': message.trim(),
            'sentAt': FieldValue.serverTimestamp(),
          })
          .timeout(_requestTimeout);

      await roomReference
          .set(<String, Object?>{
            'lastMessageAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _interestChats
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete()
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> removeParticipant({
    required String chatId,
    required String targetUserId,
    String? reason,
  }) async {
    try {
      final roomReference = _interestChats.doc(chatId);
      final memberReference = roomReference
          .collection('members')
          .doc(targetUserId);
      await _firestore
          .runTransaction((transaction) async {
            final memberSnapshot = await transaction.get(memberReference);
            if (!memberSnapshot.exists) {
              return;
            }

            transaction.delete(memberReference);
            transaction.set(roomReference, <String, Object?>{
              'memberCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            if ((reason ?? '').trim().isNotEmpty) {
              transaction.set(
                roomReference.collection('moderation_logs').doc(),
                <String, Object?>{
                  'targetUserId': targetUserId,
                  'reason': reason!.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                },
              );
            }
          })
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Future<void> updateParticipantPermissions({
    required String chatId,
    required String targetUserId,
    required ChatMemberRole role,
    required bool canRemoveMessages,
    required bool canRemoveUsers,
  }) async {
    try {
      await _interestChats
          .doc(chatId)
          .collection('members')
          .doc(targetUserId)
          .set(<String, Object?>{
            'role': role.name,
            'canRemoveMessages': canRemoveMessages,
            'canRemoveUsers': canRemoveUsers,
          }, SetOptions(merge: true))
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
  }

  @override
  Stream<List<InterestChatRoom>> listenInterestChats({int limit = 100}) {
    return _interestChats
        .orderBy('lastMessageAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(InterestChatRoom.fromFirestore)
              .toList(growable: false),
        )
        .handleError((Object error) {
          throw _mapException(error, AppErrorCode.chatLoadFailed);
        });
  }

  @override
  Stream<InterestChatRoom?> watchInterestChat(String chatId) {
    return _interestChats
        .doc(chatId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists ? InterestChatRoom.fromSnapshot(snapshot) : null,
        )
        .handleError((Object error) {
          throw _mapException(error, AppErrorCode.chatLoadFailed);
        });
  }

  @override
  Stream<List<ChatParticipant>> listenParticipants(String chatId) {
    return _interestChats
        .doc(chatId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChatParticipant.fromFirestore)
              .toList(growable: false),
        )
        .handleError((Object error) {
          throw _mapException(error, AppErrorCode.chatLoadFailed);
        });
  }

  @override
  Stream<ChatParticipant?> watchParticipant({
    required String chatId,
    required String userId,
  }) {
    return _interestChats
        .doc(chatId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.exists ? ChatParticipant.fromSnapshot(snapshot) : null,
        )
        .handleError((Object error) {
          throw _mapException(error, AppErrorCode.chatLoadFailed);
        });
  }

  @override
  Stream<List<ChatMessage>> listenMessages({
    required String chatId,
    int limit = 50,
  }) {
    return _interestChats
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt')
        .limitToLast(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChatMessage.fromFirestore)
              .toList(growable: false),
        )
        .handleError((Object error) {
          throw _mapException(error, AppErrorCode.chatLoadFailed);
        });
  }

  @override
  Stream<List<FriendProfile>> listenFriends(String userId) {
    return _users
        .doc(userId)
        .collection('friends')
        .orderBy('displayName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(FriendProfile.fromFirestore)
              .toList(growable: false),
        )
        .handleError((Object error) {
          if (_isPermissionDenied(error)) {
            return const <FriendProfile>[];
          }
          throw _mapException(error, AppErrorCode.leaderboardLoadFailed);
        });
  }

  @override
  Stream<List<FriendRequest>> listenIncomingFriendRequests(String userId) {
    return _friendRequests
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(FriendRequest.fromFirestore)
              .where((request) => request.status == FriendRequestStatus.pending)
              .toList(growable: false);
          requests.sort((left, right) {
            final leftDate =
                left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final rightDate =
                right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return rightDate.compareTo(leftDate);
          });
          return requests;
        })
        .handleError((Object error) {
          if (_isPermissionDenied(error)) {
            return const <FriendRequest>[];
          }
          throw _mapException(error, AppErrorCode.chatLoadFailed);
        });
  }

  @override
  Stream<SocialPrivacySettings> watchPrivacySettings(String userId) {
    return _users
        .doc(userId)
        .collection('social_settings')
        .doc('privacy')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return SocialPrivacySettings.defaults();
          }
          return SocialPrivacySettings.fromMap(
            snapshot.data() ?? <String, Object?>{},
          );
        })
        .handleError((Object error) {
          if (_isPermissionDenied(error)) {
            return SocialPrivacySettings.defaults();
          }
          throw _mapException(error, AppErrorCode.chatLoadFailed);
        });
  }

  @override
  Stream<List<LeaderboardUser>> listenLeaderboard({int limit = 20}) {
    return Stream<List<LeaderboardUser>>.value(const <LeaderboardUser>[]);
  }

  Future<Map<String, Object?>> _loadUserData(String userId) async {
    final snapshot = await _users.doc(userId).get().timeout(_requestTimeout);
    return snapshot.data() ?? <String, Object?>{};
  }

  Future<SocialPrivacySettings> _loadPrivacySettings(String userId) async {
    final snapshot = await _users
        .doc(userId)
        .collection('social_settings')
        .doc('privacy')
        .get()
        .timeout(_requestTimeout);
    if (!snapshot.exists) {
      return SocialPrivacySettings.defaults();
    }
    return SocialPrivacySettings.fromMap(
      snapshot.data() ?? <String, Object?>{},
    );
  }

  Future<void> _syncFriendSnapshot(
    String userId, {
    SocialPrivacySettings? settings,
  }) async {
    final userData = await _loadUserData(userId);
    final SocialPrivacySettings resolvedSettings =
        settings ??
        await _users
            .doc(userId)
            .collection('social_settings')
            .doc('privacy')
            .get()
            .timeout(_requestTimeout)
            .then(
              (snapshot) => snapshot.exists
                  ? SocialPrivacySettings.fromMap(
                      snapshot.data() ?? <String, Object?>{},
                    )
                  : SocialPrivacySettings.defaults(),
            );
    final friendsSnapshot = await _users
        .doc(userId)
        .collection('friends')
        .get()
        .timeout(_requestTimeout);
    if (friendsSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final friendDocument in friendsSnapshot.docs) {
      final allowedCategories = _allowedCategoriesForFriend(
        friendDocument.id,
        resolvedSettings,
      );
      batch.set(
        _users.doc(friendDocument.id).collection('friends').doc(userId),
        _buildFriendSnapshot(
          userId,
          userData,
          allowedCategories: allowedCategories,
          visibleInFriendLeaderboard:
              resolvedSettings.visibleInFriendLeaderboard,
        ),
        SetOptions(merge: true),
      );
    }
    await batch.commit().timeout(_requestTimeout);
  }

  Map<String, Object?> _buildFriendSnapshot(
    String userId,
    Map<String, Object?> data, {
    Set<SocialPrivacyCategory>? allowedCategories,
    bool? visibleInFriendLeaderboard,
  }) {
    final settings = SocialPrivacySettings.fromMap(data);
    return <String, Object?>{
      'displayName': (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Athlete',
      'email': (data['email'] as String?)?.trim() ?? '',
      'city': (data['city'] as String?)?.trim(),
      'score': (data['socialScore'] as num?)?.toInt() ?? 0,
      'workoutsCount': (data['socialWorkoutsCount'] as num?)?.toInt() ?? 0,
      'caloriesBurned': (data['socialCaloriesBurned'] as num?)?.toDouble() ?? 0,
      'stepsCount': (data['socialStepsCount'] as num?)?.toInt() ?? 0,
      'visibleInFriendLeaderboard':
          visibleInFriendLeaderboard ??
          (data['visibleInFriendLeaderboard'] as bool?) ??
          settings.visibleInFriendLeaderboard,
      'allowedCategories':
          (allowedCategories ?? settings.defaultAllowedCategories)
              .map((category) => category.name)
              .toList(growable: false),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Set<SocialPrivacyCategory> _allowedCategoriesForFriend(
    String friendId,
    SocialPrivacySettings settings,
  ) {
    final allowed = <SocialPrivacyCategory>{
      ...settings.defaultAllowedCategories,
    };
    for (final group in settings.groups) {
      if (group.memberIds.contains(friendId)) {
        allowed.addAll(group.allowedCategories);
      }
    }
    if (!settings.visibleInFriendLeaderboard) {
      allowed.remove(SocialPrivacyCategory.friendLeaderboard);
    }
    return allowed;
  }

  Set<SocialPrivacyCategory> _parseCategoryNames(Object? raw) {
    final names = (raw as List<dynamic>?)?.whereType<String>().toSet();
    if (names == null || names.isEmpty) {
      return SocialPrivacyCategory.values.toSet();
    }
    return SocialPrivacyCategory.values
        .where((category) => names.contains(category.name))
        .toSet();
  }

  String _extractInviteId(String value) {
    final trimmed = value.trim();
    final parsed = Uri.tryParse(trimmed);
    final fromInviteParam = parsed?.queryParameters['invite'];
    if (fromInviteParam != null && fromInviteParam.trim().isNotEmpty) {
      return _normalizeFriendCode(fromInviteParam);
    }
    final marker = RegExp(r'invite=([^&\s]+)').firstMatch(trimmed);
    if (marker != null) {
      return _normalizeFriendCode(marker.group(1));
    }
    return _normalizeFriendCode(trimmed);
  }

  String _friendRequestId(String fromUserId, String toUserId) {
    return '${fromUserId}_$toUserId';
  }

  String _normalizeFriendCode(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  List<String> _buildSearchIndex(String title, String description) {
    final normalized = '${title.trim()} ${description.trim()}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Zа-яА-Я0-9\s]'), ' ');
    final words = normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return words;
  }

  String _resolveSenderName(
    String? storedName,
    String fallbackName,
    String fallbackEmail,
  ) {
    final normalizedStoredName = storedName?.trim() ?? '';
    if (normalizedStoredName.isNotEmpty) {
      return normalizedStoredName;
    }

    final normalizedFallbackName = fallbackName.trim();
    if (normalizedFallbackName.isNotEmpty) {
      return normalizedFallbackName;
    }

    final normalizedFallbackEmail = fallbackEmail.trim();
    if (normalizedFallbackEmail.isNotEmpty) {
      return normalizedFallbackEmail.split('@').first;
    }

    return 'Athlete';
  }

  SocialException _mapException(Object error, AppErrorCode fallbackCode) {
    if (error is SocialException) {
      return error;
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => const SocialException(
          AppErrorCode.firebaseConfigurationMissing,
        ),
        'failed-precondition' => const SocialException(
          AppErrorCode.firebaseConfigurationMissing,
        ),
        'unavailable' => SocialException(fallbackCode),
        _ => SocialException(fallbackCode),
      };
    }
    return SocialException(fallbackCode);
  }

  bool _isPermissionDenied(Object error) {
    return error is FirebaseException && error.code == 'permission-denied';
  }
}
