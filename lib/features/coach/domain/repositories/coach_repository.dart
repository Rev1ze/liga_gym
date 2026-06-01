import '../entities/coach_request.dart';
import '../entities/coach_student.dart';
import '../entities/coach_trainer.dart';
import '../entities/student_workout_assignment.dart';
import '../entities/trainer_exercise.dart';
import '../entities/trainer_recipe.dart';
import '../entities/trainer_workout_template.dart';

abstract interface class CoachRepository {
  Future<List<CoachStudent>> loadStudents(String trainerId);

  Future<List<CoachTrainer>> loadLinkedTrainers(String studentId);

  Future<void> sendCoachRequest({
    required String trainerId,
    required String friendCode,
    required String trainerName,
    required String trainerEmail,
  });

  Future<List<CoachRequest>> loadIncomingCoachRequests(String studentId);

  Future<List<CoachRequest>> loadOutgoingCoachRequests(String trainerId);

  Future<void> acceptCoachRequest({
    required String requestId,
    required String studentId,
  });

  Future<void> declineCoachRequest({
    required String requestId,
    required String studentId,
  });

  Future<List<TrainerExercise>> loadExercises(String trainerId);

  Future<void> saveExercise(TrainerExercise exercise);

  Future<void> deleteExercise({
    required String trainerId,
    required String exerciseId,
  });

  Future<List<TrainerRecipe>> loadRecipes(String trainerId);

  Future<void> saveRecipe(TrainerRecipe recipe);

  Future<void> deleteRecipe({
    required String trainerId,
    required String recipeId,
  });

  Future<List<TrainerWorkoutTemplate>> loadWorkoutTemplates(String trainerId);

  Future<void> saveWorkoutTemplate(TrainerWorkoutTemplate template);

  Future<void> deleteWorkoutTemplate({
    required String trainerId,
    required String templateId,
  });

  Future<void> assignRecipe({
    required String studentId,
    required TrainerRecipe recipe,
    required String trainerName,
  });

  Future<void> assignWorkout({
    required String studentId,
    required TrainerWorkoutTemplate template,
    required DateTime scheduledAt,
  });

  Future<List<TrainerRecipe>> loadAssignedRecipes(String studentId);

  Future<List<StudentWorkoutAssignment>> loadAssignedWorkouts(String studentId);
}
