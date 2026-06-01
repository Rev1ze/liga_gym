import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/coach_request.dart';
import '../../domain/entities/coach_student.dart';
import '../../domain/entities/coach_trainer.dart';
import '../../domain/entities/student_workout_assignment.dart';
import '../../domain/entities/trainer_exercise.dart';
import '../../domain/entities/trainer_recipe.dart';
import '../../domain/entities/trainer_workout_template.dart';
import '../../domain/repositories/coach_repository.dart';
import '../models/coach_models.dart';

class CoachRepositoryImpl implements CoachRepository {
  const CoachRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _users() {
    return _firestore.collection('users');
  }

  CollectionReference<Map<String, dynamic>> _friendInvites() {
    return _firestore.collection('friend_invites');
  }

  CollectionReference<Map<String, dynamic>> _coachRequests() {
    return _firestore.collection('coach_requests');
  }

  DocumentReference<Map<String, dynamic>> _trainer(String trainerId) {
    return _firestore.collection('trainers').doc(trainerId);
  }

  @override
  Future<List<CoachStudent>> loadStudents(String trainerId) async {
    final snapshot = await _firestore
        .collectionGroup('coach_links')
        .where('trainerId', isEqualTo: trainerId)
        .where('status', isEqualTo: 'active')
        .orderBy('linkedAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (document) =>
              CoachStudentModel.fromFirestore(document.id, document.data()),
        )
        .toList(growable: false);
  }

  @override
  Future<List<CoachTrainer>> loadLinkedTrainers(String studentId) async {
    final snapshot = await _users()
        .doc(studentId)
        .collection('coach_links')
        .where('status', isEqualTo: 'active')
        .get();

    final trainers = snapshot.docs
        .map(
          (document) =>
              CoachTrainerModel.fromFirestore(document.id, document.data()),
        )
        .toList(growable: false);
    trainers.sort((a, b) => b.linkedAt.compareTo(a.linkedAt));
    return trainers;
  }

  @override
  Future<void> sendCoachRequest({
    required String trainerId,
    required String friendCode,
    required String trainerName,
    required String trainerEmail,
  }) async {
    final inviteSnapshot = await _friendInvites()
        .doc(friendCode.trim().toLowerCase())
        .get();
    final inviteData = inviteSnapshot.data();
    final studentId = inviteData?['ownerUserId'] as String?;
    if (!inviteSnapshot.exists || studentId == null || studentId.isEmpty) {
      throw StateError('student-not-found');
    }
    if (studentId == trainerId) {
      return;
    }

    final trainerSnapshot = await _users().doc(trainerId).get();
    final trainerData = trainerSnapshot.data() ?? <String, Object?>{};
    await _coachRequests().doc('${trainerId}_$studentId').set(<String, Object?>{
      'trainerId': trainerId,
      'studentId': studentId,
      'trainerName': _readName(
        trainerData,
        fallbackName: trainerName,
        fallbackEmail: trainerEmail,
      ),
      'trainerEmail': _readEmail(trainerData, trainerEmail),
      'studentName': (inviteData?['ownerDisplayName'] as String?) ?? 'Ученик',
      'studentEmail': (inviteData?['ownerEmail'] as String?) ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<CoachRequest>> loadIncomingCoachRequests(String studentId) async {
    final snapshot = await _coachRequests()
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (document) =>
              CoachRequestModel.fromFirestore(document.id, document.data()),
        )
        .toList(growable: false);
  }

  @override
  Future<List<CoachRequest>> loadOutgoingCoachRequests(String trainerId) async {
    final snapshot = await _coachRequests()
        .where('trainerId', isEqualTo: trainerId)
        .get();

    final requests = snapshot.docs
        .map(
          (document) =>
              CoachRequestModel.fromFirestore(document.id, document.data()),
        )
        .where((request) => request.status == 'pending')
        .toList(growable: false);
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  @override
  Future<void> acceptCoachRequest({
    required String requestId,
    required String studentId,
  }) async {
    final requestReference = _coachRequests().doc(requestId);
    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestReference);
      final requestData = requestSnapshot.data();
      if (!requestSnapshot.exists ||
          requestData?['studentId'] != studentId ||
          requestData?['status'] != 'pending') {
        return;
      }

      final trainerId = requestData!['trainerId'] as String;
      transaction.set(
        _users().doc(studentId).collection('coach_links').doc(trainerId),
        <String, Object?>{
          'trainerId': trainerId,
          'studentId': studentId,
          'studentName': requestData['studentName'],
          'studentEmail': requestData['studentEmail'],
          'trainerName': requestData['trainerName'],
          'trainerEmail': requestData['trainerEmail'],
          'status': 'active',
          'linkedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      transaction.set(requestReference, <String, Object?>{
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> declineCoachRequest({
    required String requestId,
    required String studentId,
  }) {
    return _coachRequests().doc(requestId).set(<String, Object?>{
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<TrainerExercise>> loadExercises(String trainerId) async {
    final snapshot = await _trainer(
      trainerId,
    ).collection('exercises').orderBy('createdAt', descending: true).get();

    return snapshot.docs
        .map(
          (document) => TrainerExerciseModel.fromFirestore(
            document.id,
            trainerId,
            document.data(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveExercise(TrainerExercise exercise) {
    final model = TrainerExerciseModel(
      id: exercise.id,
      trainerId: exercise.trainerId,
      title: exercise.title,
      description: exercise.description,
      videoUrl: exercise.videoUrl,
      media: exercise.media,
      muscleGroups: exercise.muscleGroups,
      equipment: exercise.equipment,
      techniqueText: exercise.techniqueText,
      createdAt: exercise.createdAt,
    );

    return _trainer(exercise.trainerId)
        .collection('exercises')
        .doc(exercise.id)
        .set(model.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteExercise({
    required String trainerId,
    required String exerciseId,
  }) {
    return _trainer(trainerId).collection('exercises').doc(exerciseId).delete();
  }

  @override
  Future<List<TrainerRecipe>> loadRecipes(String trainerId) async {
    final snapshot = await _trainer(
      trainerId,
    ).collection('recipes').orderBy('createdAt', descending: true).get();

    return snapshot.docs
        .map(
          (document) => TrainerRecipeModel.fromFirestore(
            document.id,
            trainerId,
            document.data(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveRecipe(TrainerRecipe recipe) {
    final model = TrainerRecipeModel(
      id: recipe.id,
      trainerId: recipe.trainerId,
      nameEn: recipe.nameEn,
      nameRu: recipe.nameRu,
      macrosPer100Grams: recipe.macrosPer100Grams,
      description: recipe.description,
      ingredientsText: recipe.ingredientsText,
      proportionsText: recipe.proportionsText,
      guideText: recipe.guideText,
      videoUrl: recipe.videoUrl,
      media: recipe.media,
      servingGrams: recipe.servingGrams,
      createdAt: recipe.createdAt,
    );

    return _trainer(recipe.trainerId)
        .collection('recipes')
        .doc(recipe.id)
        .set(model.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteRecipe({
    required String trainerId,
    required String recipeId,
  }) {
    return _trainer(trainerId).collection('recipes').doc(recipeId).delete();
  }

  @override
  Future<List<TrainerWorkoutTemplate>> loadWorkoutTemplates(
    String trainerId,
  ) async {
    final snapshot = await _trainer(trainerId)
        .collection('workout_templates')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (document) => TrainerWorkoutTemplateModel.fromFirestore(
            document.id,
            trainerId,
            document.data(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveWorkoutTemplate(TrainerWorkoutTemplate template) {
    final model = TrainerWorkoutTemplateModel(
      id: template.id,
      trainerId: template.trainerId,
      title: template.title,
      goal: template.goal,
      instructions: template.instructions,
      exerciseIds: template.exerciseIds,
      createdAt: template.createdAt,
    );

    return _trainer(template.trainerId)
        .collection('workout_templates')
        .doc(template.id)
        .set(model.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteWorkoutTemplate({
    required String trainerId,
    required String templateId,
  }) {
    return _trainer(
      trainerId,
    ).collection('workout_templates').doc(templateId).delete();
  }

  @override
  Future<void> assignRecipe({
    required String studentId,
    required TrainerRecipe recipe,
    required String trainerName,
  }) {
    final model = TrainerRecipeModel(
      id: recipe.id,
      trainerId: recipe.trainerId,
      nameEn: recipe.nameEn,
      nameRu: recipe.nameRu,
      macrosPer100Grams: recipe.macrosPer100Grams,
      description: recipe.description,
      ingredientsText: recipe.ingredientsText,
      proportionsText: recipe.proportionsText,
      guideText: recipe.guideText,
      videoUrl: recipe.videoUrl,
      media: recipe.media,
      servingGrams: recipe.servingGrams,
      createdAt: recipe.createdAt,
    );

    return _users()
        .doc(studentId)
        .collection('recipe_assignments')
        .doc('${recipe.trainerId}_${recipe.id}')
        .set(
          model.toAssignmentFirestore(
            studentId: studentId,
            trainerName: trainerName,
          ),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> assignWorkout({
    required String studentId,
    required TrainerWorkoutTemplate template,
    required DateTime scheduledAt,
  }) {
    final model = TrainerWorkoutTemplateModel(
      id: template.id,
      trainerId: template.trainerId,
      title: template.title,
      goal: template.goal,
      instructions: template.instructions,
      exerciseIds: template.exerciseIds,
      createdAt: template.createdAt,
    );

    return _users()
        .doc(studentId)
        .collection('workout_assignments')
        .doc(
          '${template.trainerId}_${template.id}_${scheduledAt.millisecondsSinceEpoch}',
        )
        .set(
          model.toAssignmentFirestore(
            studentId: studentId,
            scheduledAt: scheduledAt,
          ),
          SetOptions(merge: true),
        );
  }

  @override
  Future<List<TrainerRecipe>> loadAssignedRecipes(String studentId) async {
    final snapshot = await _users()
        .doc(studentId)
        .collection('recipe_assignments')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (document) => TrainerRecipeModel.fromAssignmentFirestore(
            document.id,
            studentId,
            document.data(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<StudentWorkoutAssignment>> loadAssignedWorkouts(
    String studentId,
  ) async {
    final snapshot = await _users()
        .doc(studentId)
        .collection('workout_assignments')
        .orderBy('scheduledAt')
        .get();

    return snapshot.docs
        .map(
          (document) => StudentWorkoutAssignmentModel.fromFirestore(
            document.id,
            studentId,
            document.data(),
          ),
        )
        .toList(growable: false);
  }

  String _readName(
    Map<String, Object?> data, {
    required String fallbackName,
    required String fallbackEmail,
  }) {
    final name = (data['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final email = _readEmail(data, fallbackEmail);
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    if (fallbackName.trim().isNotEmpty) {
      return fallbackName.trim();
    }

    return 'Ученик';
  }

  String _readEmail(Map<String, Object?> data, String fallbackEmail) {
    final email = (data['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    return fallbackEmail.trim();
  }
}
