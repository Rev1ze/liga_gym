import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/offline_sync_service.dart';
import '../datasources/workout_local_data_source.dart';
import '../datasources/workout_remote_data_source.dart';
import '../models/workout_model.dart';

class WorkoutOfflineSyncService extends OfflineSyncService<WorkoutModel> {
  const WorkoutOfflineSyncService({
    required WorkoutLocalDataSource workoutLocalDataSource,
    required WorkoutRemoteDataSource workoutRemoteDataSource,
  }) : _workoutLocalDataSource = workoutLocalDataSource,
       _workoutRemoteDataSource = workoutRemoteDataSource;

  final WorkoutLocalDataSource _workoutLocalDataSource;
  final WorkoutRemoteDataSource _workoutRemoteDataSource;

  @override
  Future<void> syncDataWithServer({required String userId}) async {
    final pendingWorkouts = await _workoutLocalDataSource.loadPendingWorkouts(
      userId,
    );

    for (final localWorkout in pendingWorkouts) {
      try {
        final remoteWorkout = await _workoutRemoteDataSource.loadWorkoutById(
          userId: userId,
          workoutId: localWorkout.id,
        );
        final resolvedWorkout = resolveConflicts(
          localRecord: localWorkout,
          remoteRecord: remoteWorkout,
        );

        if (_shouldKeepRemoteVersion(
          localWorkout: localWorkout,
          remoteWorkout: remoteWorkout,
          resolvedWorkout: resolvedWorkout,
        )) {
          await _workoutLocalDataSource.saveWorkout(
            resolvedWorkout.withSyncStatus(true),
          );
          continue;
        }

        await _workoutRemoteDataSource.saveWorkout(resolvedWorkout);
        await _workoutLocalDataSource.markWorkoutSynced(resolvedWorkout.id);
      } on AppException {
        // Keep the workout locally and retry on the next sync cycle.
      } catch (_) {
        // Background sync should stay non-blocking for the user flow.
      }
    }
  }

  bool _shouldKeepRemoteVersion({
    required WorkoutModel localWorkout,
    required WorkoutModel? remoteWorkout,
    required WorkoutModel resolvedWorkout,
  }) {
    final remote = remoteWorkout;
    if (remote == null) {
      return false;
    }

    return identical(resolvedWorkout, remote) ||
        remote.lastModifiedAt.isAfter(localWorkout.lastModifiedAt);
  }
}
