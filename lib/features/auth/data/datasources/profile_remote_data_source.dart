import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/user_profile_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<bool> hasUserProfile(String userId);

  Future<void> saveUserProfile(UserProfileModel profile);
}

class UnavailableProfileRemoteDataSource implements ProfileRemoteDataSource {
  const UnavailableProfileRemoteDataSource();

  @override
  Future<bool> hasUserProfile(String userId) => _throwConfigurationMissing();

  @override
  Future<void> saveUserProfile(UserProfileModel profile) =>
      _throwConfigurationMissing();

  Future<T> _throwConfigurationMissing<T>() async {
    throw const ProfileException(AppErrorCode.firebaseConfigurationMissing);
  }
}

class FirestoreProfileRemoteDataSource implements ProfileRemoteDataSource {
  FirestoreProfileRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';
  static const Duration _requestTimeout = Duration(seconds: 15);

  @override
  Future<bool> hasUserProfile(String userId) async {
    try {
      final documentSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get()
          .timeout(_requestTimeout);

      return documentSnapshot.exists;
    } on FirebaseException catch (error) {
      throw ProfileException(_mapFirestoreError(error.code));
    } on TimeoutException {
      throw const ProfileException(AppErrorCode.firebaseConfigurationMissing);
    }
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(profile.userId)
          .set(profile.toFirestore(), SetOptions(merge: true))
          .timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      // Любую ошибку Firestore поднимаем выше как доменную, чтобы UI не зависел от SDK.
      throw ProfileException(_mapFirestoreError(error.code));
    } on TimeoutException {
      throw const ProfileException(AppErrorCode.firebaseConfigurationMissing);
    }
  }

  AppErrorCode _mapFirestoreError(String code) {
    return switch (code) {
      'failed-precondition' => AppErrorCode.firebaseConfigurationMissing,
      'permission-denied' => AppErrorCode.firebaseConfigurationMissing,
      'unavailable' => AppErrorCode.firebaseConfigurationMissing,
      _ => AppErrorCode.profileSaveFailed,
    };
  }
}
