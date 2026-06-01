import '../../../coach/domain/entities/coach_trainer.dart';
import '../../../coach/domain/entities/coach_media_attachment.dart';

class TrainerMaterialsRouteArguments {
  const TrainerMaterialsRouteArguments({required this.trainer});

  final CoachTrainer trainer;
}

class TrainerMaterialDetailsRouteArguments {
  const TrainerMaterialDetailsRouteArguments({
    required this.title,
    required this.subtitle,
    required this.iconCodePoint,
    required this.sections,
    this.media = const <CoachMediaAttachment>[],
  });

  final String title;
  final String subtitle;
  final int iconCodePoint;
  final List<TrainerMaterialDetailSection> sections;
  final List<CoachMediaAttachment> media;
}

class TrainerMaterialDetailSection {
  const TrainerMaterialDetailSection({
    required this.title,
    required this.body,
    this.chips = const <String>[],
  });

  final String title;
  final String body;
  final List<String> chips;
}
