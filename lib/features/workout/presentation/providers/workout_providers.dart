import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/workout_local_data_source.dart';
import '../../data/datasources/workout_location_data_source.dart';
import '../../data/datasources/workout_remote_data_source.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../data/services/workout_offline_sync_service.dart';
import '../../domain/usecases/load_user_workouts_use_case.dart';
import '../../domain/usecases/save_workout_use_case.dart';
import '../controllers/workout_list_controller.dart';
import '../controllers/workout_session_controller.dart';

final firebaseWorkoutUserProvider = Provider(
  (ref) => ref.watch(firebaseAuthProvider).currentUser,
);

final workoutLocalDataSourceProvider = Provider<WorkoutLocalDataSource>(
  (ref) => SqfliteWorkoutLocalDataSource(),
);

final workoutRemoteDataSourceProvider = Provider<WorkoutRemoteDataSource>((
  ref,
) {
  final firebaseBootstrap = ref.watch(firebaseBootstrapProvider);
  if (!firebaseBootstrap.isConfigured) {
    return const UnavailableWorkoutRemoteDataSource();
  }

  return FirestoreWorkoutRemoteDataSource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final workoutLocationDataSourceProvider = Provider<WorkoutLocationDataSource>(
  (ref) => const GeolocatorWorkoutLocationDataSource(),
);

final workoutOfflineSyncServiceProvider = Provider<WorkoutOfflineSyncService>((
  ref,
) {
  return WorkoutOfflineSyncService(
    workoutLocalDataSource: ref.watch(workoutLocalDataSourceProvider),
    workoutRemoteDataSource: ref.watch(workoutRemoteDataSourceProvider),
  );
});

final workoutRepositoryProvider = Provider(
  (ref) => WorkoutRepositoryImpl(
    workoutLocalDataSource: ref.watch(workoutLocalDataSourceProvider),
    workoutRemoteDataSource: ref.watch(workoutRemoteDataSourceProvider),
    workoutOfflineSyncService: ref.watch(workoutOfflineSyncServiceProvider),
  ),
);

final loadUserWorkoutsUseCaseProvider = Provider(
  (ref) => LoadUserWorkoutsUseCase(ref.watch(workoutRepositoryProvider)),
);

final saveWorkoutUseCaseProvider = Provider(
  (ref) => SaveWorkoutUseCase(ref.watch(workoutRepositoryProvider)),
);

final workoutListControllerProvider =
    NotifierProvider<WorkoutListController, WorkoutListState>(
      WorkoutListController.new,
    );

final workoutSessionControllerProvider =
    NotifierProvider<WorkoutSessionController, WorkoutSessionState>(
      WorkoutSessionController.new,
    );
