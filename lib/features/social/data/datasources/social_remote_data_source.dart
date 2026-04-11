import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/leaderboard_user.dart';

abstract interface class SocialRemoteDataSource {
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

class UnavailableSocialRemoteDataSource implements SocialRemoteDataSource {
  const UnavailableSocialRemoteDataSource();

  @override
  Future<void> ensureLeaderboardEntry({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async {
    throw const SocialException(AppErrorCode.firebaseConfigurationMissing);
  }

  @override
  Stream<List<LeaderboardUser>> listenLeaderboard({int limit = 20}) {
    return Stream<List<LeaderboardUser>>.error(
      const SocialException(AppErrorCode.firebaseConfigurationMissing),
    );
  }

  @override
  Stream<List<ChatMessage>> listenMessages({int limit = 50}) {
    return Stream<List<ChatMessage>>.error(
      const SocialException(AppErrorCode.firebaseConfigurationMissing),
    );
  }

  @override
  Future<void> sendMessage({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String message,
  }) async {
    throw const SocialException(AppErrorCode.firebaseConfigurationMissing);
  }
}

class FirestoreSocialRemoteDataSource implements SocialRemoteDataSource {
  FirestoreSocialRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const Duration _requestTimeout = Duration(seconds: 15);

  @override
  Future<void> ensureLeaderboardEntry({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
  }) async {
    try {
      final leaderboardReference = _firestore
          .collection('leaderboard')
          .doc(userId);
      final userReference = _firestore.collection('users').doc(userId);

      await _firestore
          .runTransaction((transaction) async {
            final leaderboardSnapshot = await transaction.get(
              leaderboardReference,
            );
            if (leaderboardSnapshot.exists) {
              return;
            }

            final userSnapshot = await transaction.get(userReference);
            final userData = userSnapshot.data() ?? <String, Object?>{};
            final displayName = _resolveSenderName(
              userData['name'] as String?,
              fallbackName,
              fallbackEmail,
            );

            transaction.set(leaderboardReference, <String, Object?>{
              'displayName': displayName,
              'score': 0,
              'workoutsCount': 0,
              'caloriesBurned': 0,
              'updatedAt': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
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
  Stream<List<LeaderboardUser>> listenLeaderboard({int limit = 20}) {
    return _firestore
        .collection('leaderboard')
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

            final byWorkouts = right.workoutsCount.compareTo(
              left.workoutsCount,
            );
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

  @override
  Stream<List<ChatMessage>> listenMessages({int limit = 50}) {
    return _firestore
        .collection('chat_messages')
        .orderBy('sentAt')
        .limitToLast(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => ChatMessage.fromFirestore(document))
              .toList(growable: false),
        )
        .handleError((Object error) {
          throw _mapException(error, AppErrorCode.chatLoadFailed);
        });
  }

  @override
  Future<void> sendMessage({
    required String userId,
    required String fallbackName,
    required String fallbackEmail,
    required String message,
  }) async {
    try {
      final userSnapshot = await _firestore
          .collection('users')
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

      await _firestore
          .collection('chat_messages')
          .add(<String, Object?>{
            'senderId': userId,
            'senderName': senderName,
            'senderEmail': senderEmail.trim(),
            'message': message.trim(),
            'sentAt': FieldValue.serverTimestamp(),
          })
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      throw _mapException(error, AppErrorCode.chatSendFailed);
    } on TimeoutException {
      throw const SocialException(AppErrorCode.chatSendFailed);
    }
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
