import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../nutrition/domain/entities/food_macros.dart';
import '../../domain/entities/coach_media_attachment.dart';
import '../../domain/entities/coach_request.dart';
import '../../domain/entities/coach_student.dart';
import '../../domain/entities/coach_trainer.dart';
import '../../domain/entities/student_workout_assignment.dart';
import '../../domain/entities/trainer_exercise.dart';
import '../../domain/entities/trainer_recipe.dart';
import '../../domain/entities/trainer_workout_template.dart';

DateTime readCoachDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

List<CoachMediaAttachment> readCoachMedia(Object? value) {
  final rawItems = value as List<Object?>?;
  if (rawItems == null) {
    return const <CoachMediaAttachment>[];
  }

  return rawItems
      .whereType<Map<Object?, Object?>>()
      .map((item) {
        final typeName = item['type'] as String? ?? CoachMediaType.image.name;
        final type = CoachMediaType.values.firstWhere(
          (value) => value.name == typeName,
          orElse: () => CoachMediaType.image,
        );
        return CoachMediaAttachment(
          url: (item['url'] as String?) ?? '',
          name: (item['name'] as String?) ?? '',
          type: type,
        );
      })
      .where((item) => item.url.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, Object?>> writeCoachMedia(List<CoachMediaAttachment> media) {
  return media
      .map(
        (item) => <String, Object?>{
          'url': item.url,
          'name': item.name,
          'type': item.type.name,
        },
      )
      .toList(growable: false);
}

class CoachStudentModel extends CoachStudent {
  const CoachStudentModel({
    required super.id,
    required super.name,
    required super.email,
    required super.status,
    required super.linkedAt,
  });

  factory CoachStudentModel.fromFirestore(
    String id,
    Map<String, Object?> json,
  ) {
    return CoachStudentModel(
      id: (json['studentId'] as String?) ?? id,
      name: (json['studentName'] as String?)?.trim().isNotEmpty == true
          ? (json['studentName'] as String).trim()
          : 'Ученик',
      email: (json['studentEmail'] as String?)?.trim() ?? '',
      status: (json['status'] as String?) ?? 'active',
      linkedAt: readCoachDateTime(json['linkedAt']),
    );
  }
}

class CoachTrainerModel extends CoachTrainer {
  const CoachTrainerModel({
    required super.id,
    required super.name,
    required super.email,
    required super.status,
    required super.linkedAt,
  });

  factory CoachTrainerModel.fromFirestore(
    String id,
    Map<String, Object?> json,
  ) {
    return CoachTrainerModel(
      id: (json['trainerId'] as String?) ?? id,
      name: (json['trainerName'] as String?)?.trim().isNotEmpty == true
          ? (json['trainerName'] as String).trim()
          : 'Тренер',
      email: (json['trainerEmail'] as String?)?.trim() ?? '',
      status: (json['status'] as String?) ?? 'active',
      linkedAt: readCoachDateTime(json['linkedAt']),
    );
  }
}

class CoachRequestModel extends CoachRequest {
  const CoachRequestModel({
    required super.id,
    required super.trainerId,
    required super.studentId,
    required super.trainerName,
    required super.trainerEmail,
    required super.studentName,
    required super.studentEmail,
    required super.status,
    required super.createdAt,
  });

  factory CoachRequestModel.fromFirestore(
    String id,
    Map<String, Object?> json,
  ) {
    return CoachRequestModel(
      id: id,
      trainerId: (json['trainerId'] as String?) ?? '',
      studentId: (json['studentId'] as String?) ?? '',
      trainerName: (json['trainerName'] as String?) ?? 'Тренер',
      trainerEmail: (json['trainerEmail'] as String?) ?? '',
      studentName: (json['studentName'] as String?) ?? 'Ученик',
      studentEmail: (json['studentEmail'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      createdAt: readCoachDateTime(json['createdAt']),
    );
  }
}

class TrainerExerciseModel extends TrainerExercise {
  const TrainerExerciseModel({
    required super.id,
    required super.trainerId,
    required super.title,
    required super.description,
    required super.videoUrl,
    required super.media,
    required super.muscleGroups,
    required super.equipment,
    required super.techniqueText,
    required super.createdAt,
  });

  factory TrainerExerciseModel.fromFirestore(
    String id,
    String trainerId,
    Map<String, Object?> json,
  ) {
    return TrainerExerciseModel(
      id: id,
      trainerId: trainerId,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      videoUrl: (json['videoUrl'] as String?) ?? '',
      media: readCoachMedia(json['media']),
      muscleGroups: (json['muscleGroups'] as String?) ?? '',
      equipment: (json['equipment'] as String?) ?? '',
      techniqueText: (json['techniqueText'] as String?) ?? '',
      createdAt: readCoachDateTime(json['createdAt']),
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'trainerId': trainerId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'media': writeCoachMedia(media),
      'muscleGroups': muscleGroups,
      'equipment': equipment,
      'techniqueText': techniqueText,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class TrainerRecipeModel extends TrainerRecipe {
  TrainerRecipeModel({
    required super.id,
    required super.nameEn,
    required super.nameRu,
    required super.macrosPer100Grams,
    required super.trainerId,
    required super.description,
    required super.ingredientsText,
    required super.proportionsText,
    required super.guideText,
    required super.videoUrl,
    required super.media,
    required super.servingGrams,
    required super.createdAt,
    super.assignmentId,
    super.studentId,
    super.trainerName,
  });

  factory TrainerRecipeModel.fromFirestore(
    String id,
    String trainerId,
    Map<String, Object?> json,
  ) {
    return TrainerRecipeModel(
      id: id,
      trainerId: trainerId,
      nameEn: (json['title'] as String?) ?? '',
      nameRu: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      ingredientsText: (json['ingredientsText'] as String?) ?? '',
      proportionsText: (json['proportionsText'] as String?) ?? '',
      guideText: (json['guideText'] as String?) ?? '',
      videoUrl: (json['videoUrl'] as String?) ?? '',
      media: readCoachMedia(json['media']),
      servingGrams: (json['servingGrams'] as num?)?.toDouble() ?? 100,
      macrosPer100Grams: FoodMacros(
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        proteins: (json['proteins'] as num?)?.toDouble() ?? 0,
        fats: (json['fats'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      ),
      createdAt: readCoachDateTime(json['createdAt']),
    );
  }

  factory TrainerRecipeModel.fromAssignmentFirestore(
    String id,
    String studentId,
    Map<String, Object?> json,
  ) {
    return TrainerRecipeModel(
      id: (json['recipeId'] as String?) ?? id,
      assignmentId: id,
      studentId: studentId,
      trainerId: (json['trainerId'] as String?) ?? '',
      trainerName: (json['trainerName'] as String?) ?? '',
      nameEn: (json['title'] as String?) ?? '',
      nameRu: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      ingredientsText: (json['ingredientsText'] as String?) ?? '',
      proportionsText: (json['proportionsText'] as String?) ?? '',
      guideText: (json['guideText'] as String?) ?? '',
      videoUrl: (json['videoUrl'] as String?) ?? '',
      media: readCoachMedia(json['media']),
      servingGrams: (json['servingGrams'] as num?)?.toDouble() ?? 100,
      macrosPer100Grams: FoodMacros(
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        proteins: (json['proteins'] as num?)?.toDouble() ?? 0,
        fats: (json['fats'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      ),
      createdAt: readCoachDateTime(json['createdAt']),
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'trainerId': trainerId,
      'title': nameRu,
      'description': description,
      'ingredientsText': ingredientsText,
      'proportionsText': proportionsText,
      'guideText': guideText,
      'videoUrl': videoUrl,
      'media': writeCoachMedia(media),
      'servingGrams': servingGrams,
      'calories': macrosPer100Grams.calories,
      'proteins': macrosPer100Grams.proteins,
      'fats': macrosPer100Grams.fats,
      'carbs': macrosPer100Grams.carbs,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> toAssignmentFirestore({
    required String studentId,
    required String trainerName,
  }) {
    return <String, Object?>{
      'recipeId': id,
      'studentId': studentId,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'title': nameRu,
      'description': description,
      'ingredientsText': ingredientsText,
      'proportionsText': proportionsText,
      'guideText': guideText,
      'videoUrl': videoUrl,
      'media': writeCoachMedia(media),
      'servingGrams': servingGrams,
      'calories': macrosPer100Grams.calories,
      'proteins': macrosPer100Grams.proteins,
      'fats': macrosPer100Grams.fats,
      'carbs': macrosPer100Grams.carbs,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class TrainerWorkoutTemplateModel extends TrainerWorkoutTemplate {
  const TrainerWorkoutTemplateModel({
    required super.id,
    required super.trainerId,
    required super.title,
    required super.goal,
    required super.instructions,
    required super.exerciseIds,
    required super.createdAt,
  });

  factory TrainerWorkoutTemplateModel.fromFirestore(
    String id,
    String trainerId,
    Map<String, Object?> json,
  ) {
    return TrainerWorkoutTemplateModel(
      id: id,
      trainerId: trainerId,
      title: (json['title'] as String?) ?? '',
      goal: (json['goal'] as String?) ?? '',
      instructions: (json['instructions'] as String?) ?? '',
      exerciseIds:
          (json['exerciseIds'] as List<Object?>?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[],
      createdAt: readCoachDateTime(json['createdAt']),
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'trainerId': trainerId,
      'title': title,
      'goal': goal,
      'instructions': instructions,
      'exerciseIds': exerciseIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> toAssignmentFirestore({
    required String studentId,
    required DateTime scheduledAt,
  }) {
    return <String, Object?>{
      'templateId': id,
      'studentId': studentId,
      'trainerId': trainerId,
      'title': title,
      'goal': goal,
      'instructions': instructions,
      'exerciseIds': exerciseIds,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': 'assigned',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class StudentWorkoutAssignmentModel extends StudentWorkoutAssignment {
  const StudentWorkoutAssignmentModel({
    required super.id,
    required super.trainerId,
    required super.studentId,
    required super.title,
    required super.goal,
    required super.instructions,
    required super.scheduledAt,
    required super.status,
    required super.createdAt,
  });

  factory StudentWorkoutAssignmentModel.fromFirestore(
    String id,
    String studentId,
    Map<String, Object?> json,
  ) {
    return StudentWorkoutAssignmentModel(
      id: id,
      studentId: studentId,
      trainerId: (json['trainerId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      goal: (json['goal'] as String?) ?? '',
      instructions: (json['instructions'] as String?) ?? '',
      scheduledAt: readCoachDateTime(json['scheduledAt']),
      status: (json['status'] as String?) ?? 'assigned',
      createdAt: readCoachDateTime(json['createdAt']),
    );
  }
}
