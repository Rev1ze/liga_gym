import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/chat_member_role.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_participant.dart';
import '../../domain/entities/interest_chat_room.dart';
import '../../domain/entities/leaderboard_user.dart';

abstract interface class SocialRemoteDataSource {
  Future<void> ensureLeaderboardEntry({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  });

  Future<void> updateLeaderboardSteps({
    required String userId,
    required int stepsCount,
  });

  Future<String> createInterestChat({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String title,
    required String description,
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
  }) async => throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async => throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> ensureLeaderboardEntry({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async => throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> joinInterestChat({
    required String chatId,
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async => throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> leaveInterestChat({
    required String chatId,
    required String userId,
  }) async => throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Stream<List<InterestChatRoom>> listenInterestChats({int limit = 100}) =>
      Stream<List<InterestChatRoom>>.error(
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
  }) async => throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> sendMessage({
    required String chatId,
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String message,
  }) async => throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> updateLeaderboardSteps({
    required String userId,
    required int stepsCount,
  }) async => throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

  @override
  Future<void> updateParticipantPermissions({
    required String chatId,
    required String targetUserId,
    required ChatMemberRole role,
    required bool canRemoveMessages,
    required bool canRemoveUsers,
  }) async => throw const SocialException(AppErrorCode.firebaseConfigurationMissing);

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
}

class FirestoreSocialRemoteDataSource implements SocialRemoteDataSource {
  FirestoreSocialRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const Duration _requestTimeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _leaderboard =>
      _firestore.collection('leaderboard');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _interestChats =>
      _firestore.collection('interest_chats');

  @override
  Future<void> ensureLeaderboardEntry({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async {
    try {
      final leaderboardReference = _leaderboard.doc(userId);
      final userReference = _users.doc(userId);

      await _firestore.runTransaction((transaction) async {
        final leaderboardSnapshot = await transaction.get(leaderboardReference);
        final userSnapshot = await transaction.get(userReference);
        final userData = userSnapshot.data() ?? <String, Object?>{};
        final displayName = _resolveSenderName(
          userData['name'] as String?,
          fallbackName,
          fallbackEmail,
        );
        final city = (userData['city'] as String?)?.trim();

        transaction.set(leaderboardReference, <String, Object?>{
          'displayName': displayName,
          'city': city?.isEmpty == true ? null : city,
          'countryCode': 'RU',
          'score': leaderboardSnapshot.data()?['score'] ?? 0,
          'workoutsCount': leaderboardSnapshot.data()?['workoutsCount'] ?? 0,
          'caloriesBurned': leaderboardSnapshot.data()?['caloriesBurned'] ?? 0,
          'stepsCount': leaderboardSnapshot.data()?['stepsCount'] ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt':
              leaderboardSnapshot.data()?['createdAt'] ??
              FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }).timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.leaderboardLoadFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.leaderboardLoadFailed);
    }
  }

  @override
  Future<void> updateLeaderboardSteps({
    required String userId,
    required int stepsCount,
  }) async {
    try {
      await _leaderboard.doc(userId).set(<String, Object?>{
        'stepsCount': stepsCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.leaderboardLoadFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.leaderboardLoadFailed);
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
      final userSnapshot = await _users.doc(userId).get().timeout(_requestTimeout);
      final userData = userSnapshot.data() ?? <String, Object?>{};
      final displayName = _resolveSenderName(
        userData['name'] as String?,
        fallbackName,
        fallbackEmail,
      );
      final roomReference = _interestChats.doc();
      final memberReference = roomReference.collection('members').doc(userId);
      final createdAt = FieldValue.serverTimestamp();

      await _firestore.runTransaction((transaction) async {
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
      }).timeout(_requestTimeout);

      return roomReference.id;
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
      final userSnapshot = await _users.doc(userId).get().timeout(_requestTimeout);
      final userData = userSnapshot.data() ?? <String, Object?>{};
      final displayName = _resolveSenderName(
        userData['name'] as String?,
        fallbackName,
        fallbackEmail,
      );

      await _firestore.runTransaction((transaction) async {
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
      }).timeout(_requestTimeout);
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
      await _firestore.runTransaction((transaction) async {
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
      }).timeout(_requestTimeout);
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
      final userSnapshot = await _users.doc(userId).get().timeout(_requestTimeout);
      final userData = userSnapshot.data() ?? <String, Object?>{};
      final senderName = _resolveSenderName(
        userData['name'] as String?,
        fallbackName,
        fallbackEmail,
      );
      final storedEmail = (userData['email'] as String?)?.trim() ?? '';
      final senderEmail = storedEmail.isNotEmpty ? storedEmail : fallbackEmail;

      await messagesReference.add(<String, Object?>{
        'senderId': userId,
        'senderName': senderName,
        'senderEmail': senderEmail.trim(),
        'senderCity': (userData['city'] as String?)?.trim(),
        'message': message.trim(),
        'sentAt': FieldValue.serverTimestamp(),
      }).timeout(_requestTimeout);

      await roomReference.set(<String, Object?>{
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(_requestTimeout);
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
      final memberReference = roomReference.collection('members').doc(targetUserId);
      await _firestore.runTransaction((transaction) async {
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
      }).timeout(_requestTimeout);
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
        .map((snapshot) => snapshot.exists ? InterestChatRoom.fromSnapshot(snapshot) : null)
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
        .map((snapshot) => snapshot.exists ? ChatParticipant.fromSnapshot(snapshot) : null)
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
  Stream<List<LeaderboardUser>> listenLeaderboard({int limit = 20}) {
    return _leaderboard
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs
              .map((document) => LeaderboardUser.fromFirestore(document))
              .toList(growable: false);

          users.sort((left, right) {
            final byScore = right.score.compareTo(left.score);
            if (byScore != 0) {
              return byScore;
            }

            final byWorkouts = right.workoutsCount.compareTo(left.workoutsCount);
            if (byWorkouts != 0) {
              return byWorkouts;
            }

            return left.displayName.toLowerCase().compareTo(
              right.displayName.toLowerCase(),
            );
          });

          return users;
        })
        .handleError((Object error) {
          throw _mapException(error, AppErrorCode.leaderboardLoadFailed);
        });
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
}
