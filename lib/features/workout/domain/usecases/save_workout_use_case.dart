import '../entities/workout.dart';
import '../entities/workout_save_status.dart';
import '../repositories/workout_repository.dart';

class SaveWorkoutUseCase {
  const SaveWorkoutUseCase(this._workoutRepository);

  final WorkoutRepository _workoutRepository;

  Future<WorkoutSaveStatus> call(Workout workout) {
    return _workoutRepository.saveWorkoutToDatabase(workout);
  }
}
