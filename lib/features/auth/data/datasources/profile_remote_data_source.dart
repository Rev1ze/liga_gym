import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/weight_history_entry.dart';
import '../models/user_profile_model.dart';
import '../models/weight_history_entry_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<bool> hasUserProfile(String userId);

  Future<UserProfileModel?> getUserProfile(String userId);

  Future<void> saveUserProfile(UserProfileModel profile);

  Future<List<WeightHistoryEntry>> loadWeightHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  });
}

class UnavailableProfileRemoteDataSource implements ProfileRemoteDataSource {
  const UnavailableProfileRemoteDataSource();

  @override
  Future<bool> hasUserProfile(String userId) => _throwConfigurationMissing();

  @override
  Future<UserProfileModel?> getUserProfile(String userId) =>
      _throwConfigurationMissing();

  @override
  Future<void> saveUserProfile(UserProfileModel profile) =>
      _throwConfigurationMissing();

  @override
  Future<List<WeightHistoryEntry>> loadWeightHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) => _throwConfigurationMissing();

  Future<T> _throwConfigurationMissing<T>() async {
    throw const ProfileException(AppErrorCode.firebaseConfigurationMissing);
  }
}

class FirestoreProfileRemoteDataSource implements ProfileRemoteDataSource {
  FirestoreProfileRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';
  static const String _leaderboardCollection = 'leaderboard';
  static const String _weightHistoryCollection = 'weight_history';
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
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final documentSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get()
          .timeout(_requestTimeout);

      if (!documentSnapshot.exists) {
        return null;
      }

      final data = documentSnapshot.data();
      if (data == null) {
        return null;
      }

      return UserProfileModel.fromFirestore(userId, data);
    } on FirebaseException catch (error) {
      throw ProfileException(_mapFirestoreError(error.code));
    } on TimeoutException {
      throw const ProfileException(AppErrorCode.firebaseConfigurationMissing);
    }
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    try {
      final now = DateUtils.dateOnly(DateTime.now());
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection(_usersCollection).doc(profile.userId),
        profile.toFirestore(),
        SetOptions(merge: true),
      );
      batch.set(
        _firestore.collection(_leaderboardCollection).doc(profile.userId),
        <String, Object?>{
          'displayName': profile.name,
          'score': FieldValue.increment(0),
          'workoutsCount': FieldValue.increment(0),
          'caloriesBurned': FieldValue.increment(0),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (profile.currentWeightKg != null) {
        batch.set(
          _firestore
              .collection(_usersCollection)
              .doc(profile.userId)
              .collection(_weightHistoryCollection)
              .doc(_weightHistoryDocId(now)),
          WeightHistoryEntryModel(
            userId: profile.userId,
            recordedAt: now,
            weightKg: profile.currentWeightKg!,
          ).toFirestore(),
          SetOptions(merge: true),
        );
      }

      await batch.commit().timeout(_requestTimeout);
    } on FirebaseException catch (error) {
      // Любую ошибку Firestore поднимаем выше как доменную, чтобы UI не зависел от SDK.
      throw ProfileException(_mapFirestoreError(error.code));
    } on TimeoutException {
      throw const ProfileException(AppErrorCode.firebaseConfigurationMissing);
    }
  }

  @override
  Future<List<WeightHistoryEntry>> loadWeightHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final normalizedFrom = DateUtils.dateOnly(from);
      final normalizedTo = DateUtils.dateOnly(to).add(const Duration(days: 1));
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_weightHistoryCollection)
          .where(
            'recordedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedFrom),
          )
          .where('recordedAt', isLessThan: Timestamp.fromDate(normalizedTo))
          .orderBy('recordedAt')
          .get()
          .timeout(_requestTimeout);

      return querySnapshot.docs
          .map(
            (document) =>
                WeightHistoryEntryModel.fromFirestore(userId, document.data()),
          )
          .toList(growable: false);
    } on FirebaseException catch (error) {
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

  String _weightHistoryDocId(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}$month$day';
  }
}
