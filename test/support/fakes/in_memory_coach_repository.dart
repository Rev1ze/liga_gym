import 'package:liga_gym_app/features/coach/domain/entities/coach_request.dart';
import 'package:liga_gym_app/features/coach/domain/entities/coach_student.dart';
import 'package:liga_gym_app/features/coach/domain/entities/coach_trainer.dart';
import 'package:liga_gym_app/features/coach/domain/entities/student_workout_assignment.dart';
import 'package:liga_gym_app/features/coach/domain/entities/trainer_exercise.dart';
import 'package:liga_gym_app/features/coach/domain/entities/trainer_recipe.dart';
import 'package:liga_gym_app/features/coach/domain/entities/trainer_workout_template.dart';
import 'package:liga_gym_app/features/coach/domain/repositories/coach_repository.dart';

class InMemoryCoachRepository implements CoachRepository {
  InMemoryCoachRepository({
    this.students = const <CoachStudent>[],
    this.trainers = const <CoachTrainer>[],
    this.incomingRequests = const <CoachRequest>[],
    this.exercises = const <TrainerExercise>[],
    this.recipes = const <TrainerRecipe>[],
    this.workoutTemplates = const <TrainerWorkoutTemplate>[],
    this.assignedRecipes = const <TrainerRecipe>[],
    this.assignedWorkouts = const <StudentWorkoutAssignment>[],
  });

  final List<CoachStudent> students;
  final List<CoachTrainer> trainers;
  final List<CoachRequest> incomingRequests;
  final List<TrainerExercise> exercises;
  final List<TrainerRecipe> recipes;
  final List<TrainerWorkoutTemplate> workoutTemplates;
  final List<TrainerRecipe> assignedRecipes;
  final List<StudentWorkoutAssignment> assignedWorkouts;

  final List<String> sentFriendCodes = <String>[];
  final List<String> acceptedRequestIds = <String>[];
  final List<String> declinedRequestIds = <String>[];
  final List<TrainerExercise> savedExercises = <TrainerExercise>[];
  final List<TrainerRecipe> savedRecipes = <TrainerRecipe>[];
  final List<TrainerWorkoutTemplate> savedWorkoutTemplates =
      <TrainerWorkoutTemplate>[];
  final List<String> deletedExerciseIds = <String>[];
  final List<String> deletedRecipeIds = <String>[];
  final List<String> deletedWorkoutTemplateIds = <String>[];
  final List<String> recipeAssignmentStudentIds = <String>[];
  final List<String> workoutAssignmentStudentIds = <String>[];

  @override
  Future<List<CoachStudent>> loadStudents(String trainerId) async => students;

  @override
  Future<List<CoachTrainer>> loadLinkedTrainers(String studentId) async {
    return trainers;
  }

  @override
  Future<void> sendCoachRequest({
    required String trainerId,
    required String friendCode,
    required String trainerName,
    required String trainerEmail,
  }) async {
    sentFriendCodes.add(friendCode);
  }

  @override
  Future<List<CoachRequest>> loadIncomingCoachRequests(String studentId) async {
    return incomingRequests;
  }

  @override
  Future<List<CoachRequest>> loadOutgoingCoachRequests(String trainerId) async {
    return incomingRequests
        .where((request) => request.trainerId == trainerId)
        .toList(growable: false);
  }

  @override
  Future<void> acceptCoachRequest({
    required String requestId,
    required String studentId,
  }) async {
    acceptedRequestIds.add(requestId);
  }

  @override
  Future<void> declineCoachRequest({
    required String requestId,
    required String studentId,
  }) async {
    declinedRequestIds.add(requestId);
  }

  @override
  Future<List<TrainerExercise>> loadExercises(String trainerId) async {
    return exercises;
  }

  @override
  Future<void> saveExercise(TrainerExercise exercise) async {
    savedExercises.add(exercise);
  }

  @override
  Future<void> deleteExercise({
    required String trainerId,
    required String exerciseId,
  }) async {
    deletedExerciseIds.add(exerciseId);
  }

  @override
  Future<List<TrainerRecipe>> loadRecipes(String trainerId) async => recipes;

  @override
  Future<void> saveRecipe(TrainerRecipe recipe) async {
    savedRecipes.add(recipe);
  }

  @override
  Future<void> deleteRecipe({
    required String trainerId,
    required String recipeId,
  }) async {
    deletedRecipeIds.add(recipeId);
  }

  @override
  Future<List<TrainerWorkoutTemplate>> loadWorkoutTemplates(
    String trainerId,
  ) async {
    return workoutTemplates;
  }

  @override
  Future<void> saveWorkoutTemplate(TrainerWorkoutTemplate template) async {
    savedWorkoutTemplates.add(template);
  }

  @override
  Future<void> deleteWorkoutTemplate({
    required String trainerId,
    required String templateId,
  }) async {
    deletedWorkoutTemplateIds.add(templateId);
  }

  @override
  Future<void> assignRecipe({
    required String studentId,
    required TrainerRecipe recipe,
    required String trainerName,
  }) async {
    recipeAssignmentStudentIds.add(studentId);
  }

  @override
  Future<void> assignWorkout({
    required String studentId,
    required TrainerWorkoutTemplate template,
    required DateTime scheduledAt,
  }) async {
    workoutAssignmentStudentIds.add(studentId);
  }

  @override
  Future<List<TrainerRecipe>> loadAssignedRecipes(String studentId) async {
    return assignedRecipes;
  }

  @override
  Future<List<StudentWorkoutAssignment>> loadAssignedWorkouts(
    String studentId,
  ) async {
    return assignedWorkouts;
  }
}
