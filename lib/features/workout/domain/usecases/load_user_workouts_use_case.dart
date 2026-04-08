import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

class LoadUserWorkoutsUseCase {
  const LoadUserWorkoutsUseCase(this._workoutRepository);

  final WorkoutRepository _workoutRepository;

  Future<List<Workout>> call(String userId) {
    return _workoutRepository.loadUserWorkouts(userId);
  }
}
