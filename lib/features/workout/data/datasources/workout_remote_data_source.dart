import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/workout_model.dart';

abstract interface class WorkoutRemoteDataSource {
  Future<void> saveWorkout(WorkoutModel workout);
}

class UnavailableWorkoutRemoteDataSource implements WorkoutRemoteDataSource {
  const UnavailableWorkoutRemoteDataSource();

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
  Future<void> saveWorkout(WorkoutModel workout) {
    return _firestore
        .collection('users')
        .doc(workout.userId)
        .collection('workouts')
        .doc(workout.id)
        .set(workout.toFirestore());
  }
}
