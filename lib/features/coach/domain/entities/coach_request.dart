class CoachRequest {
  const CoachRequest({
    required this.id,
    required this.trainerId,
    required this.studentId,
    required this.trainerName,
    required this.trainerEmail,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String trainerId;
  final String studentId;
  final String trainerName;
  final String trainerEmail;
  final String studentName;
  final String studentEmail;
  final String status;
  final DateTime createdAt;
}
