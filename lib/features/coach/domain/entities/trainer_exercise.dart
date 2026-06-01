import 'coach_media_attachment.dart';

class TrainerExercise {
  const TrainerExercise({
    required this.id,
    required this.trainerId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.media,
    required this.muscleGroups,
    required this.equipment,
    required this.techniqueText,
    required this.createdAt,
  });

  final String id;
  final String trainerId;
  final String title;
  final String description;
  final String videoUrl;
  final List<CoachMediaAttachment> media;
  final String muscleGroups;
  final String equipment;
  final String techniqueText;
  final DateTime createdAt;
}
