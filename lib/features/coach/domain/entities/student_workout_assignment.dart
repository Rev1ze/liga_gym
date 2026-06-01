class StudentWorkoutAssignment {
  const StudentWorkoutAssignment({
    required this.id,
    required this.trainerId,
    required this.studentId,
    required this.title,
    required this.goal,
    required this.instructions,
    required this.scheduledAt,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String trainerId;
  final String studentId;
  final String title;
  final String goal;
  final String instructions;
  final DateTime scheduledAt;
  final String status;
  final DateTime createdAt;
}
