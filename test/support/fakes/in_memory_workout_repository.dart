import 'package:liga_gym_app/features/workout/domain/entities/workout.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_save_status.dart';
import 'package:liga_gym_app/features/workout/domain/repositories/workout_repository.dart';

class InMemoryWorkoutRepository implements WorkoutRepository {
  InMemoryWorkoutRepository({
    List<Workout> initialWorkouts = const <Workout>[],
    this.defaultSaveStatus = WorkoutSaveStatus.synced,
  }) : _workouts = List<Workout>.of(initialWorkouts);

  final WorkoutSaveStatus defaultSaveStatus;
  final List<Workout> _workouts;

  WorkoutSaveStatus? _nextSaveStatus;

  List<Workout> get savedWorkouts => List<Workout>.unmodifiable(_workouts);

  void queueNextSaveStatus(WorkoutSaveStatus status) {
    _nextSaveStatus = status;
  }

  @override
  Future<List<Workout>> loadUserWorkouts(String userId) async {
    return _workouts
        .where((workout) => workout.userId == userId)
        .toList(growable: false);
  }

  @override
  Future<WorkoutSaveStatus> saveWorkoutToDatabase(Workout workout) async {
    final saveStatus = _nextSaveStatus ?? defaultSaveStatus;
    _nextSaveStatus = null;

    _workouts.add(
      saveStatus == WorkoutSaveStatus.synced
          ? workout.copyWith(isSynced: true)
          : workout,
    );

    return saveStatus;
  }
}
