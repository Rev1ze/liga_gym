import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/user_profile_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<bool> hasUserProfile(String userId);

  Future<void> saveUserProfile(UserProfileModel profile);
}

class FirestoreProfileRemoteDataSource implements ProfileRemoteDataSource {
  FirestoreProfileRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';

  @override
  Future<bool> hasUserProfile(String userId) async {
    try {
      final documentSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      return documentSnapshot.exists;
    } on FirebaseException catch (error) {
      throw ProfileException(_mapFirestoreError(error.code));
    }
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(profile.userId)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } on FirebaseException catch (error) {
      // Любую ошибку Firestore поднимаем выше как доменную, чтобы UI не зависел от SDK.
      throw ProfileException(_mapFirestoreError(error.code));
    }
  }

  AppErrorCode _mapFirestoreError(String code) {
    return switch (code) {
      'failed-precondition' => AppErrorCode.firebaseConfigurationMissing,
      _ => AppErrorCode.profileSaveFailed,
    };
  }
}
