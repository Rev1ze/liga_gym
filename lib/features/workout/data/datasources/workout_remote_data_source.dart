import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/workout_model.dart';

abstract interface class WorkoutRemoteDataSource {
  Future<List<WorkoutModel>> loadUserWorkouts(String userId);

  Future<WorkoutModel?> loadWorkoutById({
    required String userId,
    required String workoutId,
  });

  Future<void> saveWorkout(WorkoutModel workout);
}

class UnavailableWorkoutRemoteDataSource implements WorkoutRemoteDataSource {
  const UnavailableWorkoutRemoteDataSource();

  @override
  Future<List<WorkoutModel>> loadUserWorkouts(String userId) async {
    throw const WorkoutException(AppErrorCode.firebaseConfigurationMissing);
  }

  @override
  Future<WorkoutModel?> loadWorkoutById({
    required String userId,
    required String workoutId,
  }) async {
    throw const WorkoutException(AppErrorCode.firebaseConfigurationMissing);
  }

  @override
  Future<void> saveWorkout(WorkoutModel workout) async {
    throw const WorkoutException(AppErrorCode.firebaseConfigurationMissing);
  }
}

class FirestoreWorkoutRemoteDataSource implements WorkoutRemoteDataSource {
  const FirestoreWorkoutRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<List<WorkoutModel>> loadUserWorkouts(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .orderBy('startedAt', descending: true)
        .get();

    return querySnapshot.docs
        .map(
          (document) =>
              WorkoutModel.fromFirestore(document.id, userId, document.data()),
        )
        .toList(growable: false);
  }

  @override
  Future<WorkoutModel?> loadWorkoutById({
    required String userId,
    required String workoutId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return WorkoutModel.fromFirestore(
      snapshot.id,
      userId,
      snapshot.data() ?? <String, Object?>{},
    );
  }

  @override
  Future<void> saveWorkout(WorkoutModel workout) async {
    final userReference = _firestore.collection('users').doc(workout.userId);
    final workoutReference = userReference
        .collection('workouts')
        .doc(workout.id);

    await _firestore.runTransaction((transaction) async {
      final workoutSnapshot = await transaction.get(workoutReference);
      if (workoutSnapshot.exists) {
        transaction.set(
          workoutReference,
          workout.toFirestore(),
          SetOptions(merge: true),
        );
        return;
      }

      final scoreIncrement = _calculateSocialScore(workout);

      transaction.set(workoutReference, workout.toFirestore());
      transaction.set(userReference, <String, Object?>{
        'socialScore': FieldValue.increment(scoreIncrement),
        'socialWorkoutsCount': FieldValue.increment(1),
        'socialCaloriesBurned': FieldValue.increment(workout.calories),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await _syncFriendSnapshot(workout.userId);
  }

  int _calculateSocialScore(WorkoutModel workout) {
    final durationPoints = workout.duration.inMinutes;
    final caloriesPoints = (workout.calories / 10).round();
    final distancePoints = (workout.distanceMeters / 1000).round() * 5;
    return (durationPoints + caloriesPoints + distancePoints).clamp(10, 500);
  }

  Future<void> _syncFriendSnapshot(String userId) async {
    final userReference = _firestore.collection('users').doc(userId);
    final userSnapshot = await userReference.get();
    final userData = userSnapshot.data() ?? <String, Object?>{};
    final friendsSnapshot = await userReference.collection('friends').get();
    if (friendsSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final friend in friendsSnapshot.docs) {
      batch.set(
        _firestore
            .collection('users')
            .doc(friend.id)
            .collection('friends')
            .doc(userId),
        <String, Object?>{
          'displayName':
              ((userData['name'] as String?)?.trim().isNotEmpty == true)
              ? (userData['name'] as String).trim()
              : 'Athlete',
          'email': (userData['email'] as String?)?.trim() ?? '',
          'city': (userData['city'] as String?)?.trim(),
          'score': (userData['socialScore'] as num?)?.toInt() ?? 0,
          'workoutsCount':
              (userData['socialWorkoutsCount'] as num?)?.toInt() ?? 0,
          'caloriesBurned':
              (userData['socialCaloriesBurned'] as num?)?.toDouble() ?? 0,
          'stepsCount': (userData['socialStepsCount'] as num?)?.toInt() ?? 0,
          'visibleInFriendLeaderboard':
              userData['visibleInFriendLeaderboard'] as bool? ?? true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
