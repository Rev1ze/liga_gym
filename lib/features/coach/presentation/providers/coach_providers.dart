import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/coach_repository_impl.dart';
import '../../domain/entities/coach_request.dart';
import '../../domain/entities/coach_student.dart';
import '../../domain/entities/coach_trainer.dart';
import '../../domain/entities/student_workout_assignment.dart';
import '../../domain/entities/trainer_exercise.dart';
import '../../domain/entities/trainer_recipe.dart';
import '../../domain/entities/trainer_workout_template.dart';
import '../../domain/repositories/coach_repository.dart';

class TrainerSharedContent {
  const TrainerSharedContent({
    required this.exercises,
    required this.recipes,
    required this.workoutTemplates,
    required this.assignedRecipes,
    required this.assignedWorkouts,
  });

  final List<TrainerExercise> exercises;
  final List<TrainerRecipe> recipes;
  final List<TrainerWorkoutTemplate> workoutTemplates;
  final List<TrainerRecipe> assignedRecipes;
  final List<StudentWorkoutAssignment> assignedWorkouts;
}

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepositoryImpl(firestore: ref.watch(firebaseFirestoreProvider));
});

final coachStudentsProvider = FutureProvider<List<CoachStudent>>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return const <CoachStudent>[];
  }

  return ref.watch(coachRepositoryProvider).loadStudents(user.uid);
});

final linkedCoachTrainersProvider = FutureProvider<List<CoachTrainer>>((
  ref,
) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return const <CoachTrainer>[];
  }

  return ref.watch(coachRepositoryProvider).loadLinkedTrainers(user.uid);
});

final incomingCoachRequestsProvider = FutureProvider<List<CoachRequest>>((
  ref,
) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return const <CoachRequest>[];
  }

  return ref.watch(coachRepositoryProvider).loadIncomingCoachRequests(user.uid);
});

final outgoingCoachRequestsProvider = FutureProvider<List<CoachRequest>>((
  ref,
) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return const <CoachRequest>[];
  }

  return ref.watch(coachRepositoryProvider).loadOutgoingCoachRequests(user.uid);
});

final trainerExercisesProvider = FutureProvider<List<TrainerExercise>>((
  ref,
) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return const <TrainerExercise>[];
  }

  return ref.watch(coachRepositoryProvider).loadExercises(user.uid);
});

final trainerRecipesProvider = FutureProvider<List<TrainerRecipe>>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return const <TrainerRecipe>[];
  }

  return ref.watch(coachRepositoryProvider).loadRecipes(user.uid);
});

final trainerWorkoutTemplatesProvider =
    FutureProvider<List<TrainerWorkoutTemplate>>((ref) async {
      final user = ref.watch(firebaseAuthProvider).currentUser;
      if (user == null) {
        return const <TrainerWorkoutTemplate>[];
      }

      return ref.watch(coachRepositoryProvider).loadWorkoutTemplates(user.uid);
    });

final assignedTrainerRecipesProvider = FutureProvider<List<TrainerRecipe>>((
  ref,
) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return const <TrainerRecipe>[];
  }

  return ref.watch(coachRepositoryProvider).loadAssignedRecipes(user.uid);
});

final assignedTrainerWorkoutsProvider =
    FutureProvider<List<StudentWorkoutAssignment>>((ref) async {
      final user = ref.watch(firebaseAuthProvider).currentUser;
      if (user == null) {
        return const <StudentWorkoutAssignment>[];
      }

      return ref.watch(coachRepositoryProvider).loadAssignedWorkouts(user.uid);
    });

final trainerSharedContentProvider =
    FutureProvider.family<TrainerSharedContent, String>((ref, trainerId) async {
      final user = ref.watch(firebaseAuthProvider).currentUser;
      if (user == null) {
        return const TrainerSharedContent(
          exercises: <TrainerExercise>[],
          recipes: <TrainerRecipe>[],
          workoutTemplates: <TrainerWorkoutTemplate>[],
          assignedRecipes: <TrainerRecipe>[],
          assignedWorkouts: <StudentWorkoutAssignment>[],
        );
      }

      final repository = ref.watch(coachRepositoryProvider);
      final exercises = await repository.loadExercises(trainerId);
      final recipes = await repository.loadRecipes(trainerId);
      final workoutTemplates = await repository.loadWorkoutTemplates(trainerId);
      final assignedRecipes = (await repository.loadAssignedRecipes(user.uid))
          .where((recipe) => recipe.trainerId == trainerId)
          .toList(growable: false);
      final assignedWorkouts = (await repository.loadAssignedWorkouts(user.uid))
          .where((workout) => workout.trainerId == trainerId)
          .toList(growable: false);

      return TrainerSharedContent(
        exercises: exercises,
        recipes: recipes,
        workoutTemplates: workoutTemplates,
        assignedRecipes: assignedRecipes,
        assignedWorkouts: assignedWorkouts,
      );
    });
