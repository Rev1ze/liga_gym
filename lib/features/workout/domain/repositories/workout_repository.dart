import '../entities/workout.dart';
import '../entities/workout_save_status.dart';

abstract interface class WorkoutRepository {
  Future<List<Workout>> loadUserWorkouts(String userId);

  Future<WorkoutSaveStatus> saveWorkoutToDatabase(Workout workout);
}
