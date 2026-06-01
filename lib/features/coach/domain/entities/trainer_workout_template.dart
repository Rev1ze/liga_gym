class TrainerWorkoutTemplate {
  const TrainerWorkoutTemplate({
    required this.id,
    required this.trainerId,
    required this.title,
    required this.goal,
    required this.instructions,
    required this.exerciseIds,
    required this.createdAt,
  });

  final String id;
  final String trainerId;
  final String title;
  final String goal;
  final String instructions;
  final List<String> exerciseIds;
  final DateTime createdAt;
}
