import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_save_status.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/workout_local_data_source.dart';
import '../datasources/workout_remote_data_source.dart';
import '../models/workout_model.dart';
import '../services/workout_offline_sync_service.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  const WorkoutRepositoryImpl({
    required WorkoutLocalDataSource workoutLocalDataSource,
    required WorkoutRemoteDataSource workoutRemoteDataSource,
    required WorkoutOfflineSyncService workoutOfflineSyncService,
  }) : _workoutLocalDataSource = workoutLocalDataSource,
       _workoutRemoteDataSource = workoutRemoteDataSource,
       _workoutOfflineSyncService = workoutOfflineSyncService;

  final WorkoutLocalDataSource _workoutLocalDataSource;
  final WorkoutRemoteDataSource _workoutRemoteDataSource;
  final WorkoutOfflineSyncService _workoutOfflineSyncService;

  @override
  Future<List<Workout>> loadUserWorkouts(String userId) async {
    List<WorkoutModel> localWorkouts;
    try {
      localWorkouts = await _workoutLocalDataSource.loadUserWorkouts(userId);
    } catch (_) {
      throw const WorkoutException(AppErrorCode.workoutSaveFailed);
    }

    try {
      await _workoutOfflineSyncService.syncDataWithServer(userId: userId);
      final refreshedLocalWorkouts = await _workoutLocalDataSource
          .loadUserWorkouts(userId);
      if (refreshedLocalWorkouts.isNotEmpty) {
        localWorkouts = refreshedLocalWorkouts;
      }
    } catch (_) {
      // The workout list should remain available from the local cache.
    }

    try {
      final remoteWorkouts = await _workoutRemoteDataSource.loadUserWorkouts(
        userId,
      );
      final mergedWorkouts = _mergeWorkouts(
        localWorkouts: localWorkouts,
        remoteWorkouts: remoteWorkouts,
      );

      await _workoutLocalDataSource.saveWorkouts(mergedWorkouts);
      return mergedWorkouts;
    } on AppException {
      return localWorkouts;
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
      await _workoutOfflineSyncService.syncDataWithServer(
        userId: workout.userId,
      );
      final savedWorkouts = await _workoutLocalDataSource.loadUserWorkouts(
        workout.userId,
      );
      final savedWorkout = savedWorkouts.firstWhere(
        (item) => item.id == workout.id,
      );
      return savedWorkout.isSynced
          ? WorkoutSaveStatus.synced
          : WorkoutSaveStatus.savedLocally;
    } catch (_) {
      return WorkoutSaveStatus.savedLocally;
    }
  }

  List<WorkoutModel> _mergeWorkouts({
    required List<WorkoutModel> localWorkouts,
    required List<WorkoutModel> remoteWorkouts,
  }) {
    final localById = {
      for (final workout in localWorkouts) workout.id: workout,
    };

    final mergedWorkouts = <WorkoutModel>[
      for (final remoteWorkout in remoteWorkouts)
        _resolveWorkout(
          localWorkout: localById.remove(remoteWorkout.id),
          remoteWorkout: remoteWorkout,
        ),
      ...localById.values,
    ];

    mergedWorkouts.sort(
      (left, right) => right.startedAt.compareTo(left.startedAt),
    );
    return mergedWorkouts;
  }

  WorkoutModel _resolveWorkout({
    required WorkoutModel? localWorkout,
    required WorkoutModel remoteWorkout,
  }) {
    final local = localWorkout;
    if (local == null) {
      return remoteWorkout.withSyncStatus(true);
    }

    final resolvedWorkout = _workoutOfflineSyncService.resolveConflicts(
      localRecord: local,
      remoteRecord: remoteWorkout,
    );

    if (identical(resolvedWorkout, remoteWorkout)) {
      return remoteWorkout.withSyncStatus(true);
    }

    return resolvedWorkout;
  }
}
