import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_save_status.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/workout_local_data_source.dart';
import '../datasources/workout_remote_data_source.dart';
import '../models/workout_model.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  const WorkoutRepositoryImpl({
    required WorkoutLocalDataSource workoutLocalDataSource,
    required WorkoutRemoteDataSource workoutRemoteDataSource,
  }) : _workoutLocalDataSource = workoutLocalDataSource,
       _workoutRemoteDataSource = workoutRemoteDataSource;

  final WorkoutLocalDataSource _workoutLocalDataSource;
  final WorkoutRemoteDataSource _workoutRemoteDataSource;

  @override
  Future<List<Workout>> loadUserWorkouts(String userId) async {
    try {
      return await _workoutLocalDataSource.loadUserWorkouts(userId);
    } catch (_) {
      throw const WorkoutException(AppErrorCode.workoutSaveFailed);
    }
  }

  @override
  Future<WorkoutSaveStatus> saveWorkoutToDatabase(Workout workout) async {
    final model = WorkoutModel.fromEntity(workout).withSyncStatus(false);

    try {
      await _workoutLocalDataSource.saveWorkout(model);
    } catch (_) {
      throw const WorkoutException(AppErrorCode.workoutSaveFailed);
    }

    try {
      await _workoutRemoteDataSource.saveWorkout(model);
      await _workoutLocalDataSource.markWorkoutSynced(workout.id);
      return WorkoutSaveStatus.synced;
    } on AppException {
      return WorkoutSaveStatus.savedLocally;
    } catch (_) {
      return WorkoutSaveStatus.savedLocally;
    }
  }
}
