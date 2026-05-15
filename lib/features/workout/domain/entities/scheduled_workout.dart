import 'workout_type.dart';

class ScheduledWorkout {
  const ScheduledWorkout({
    required this.id,
    required this.userId,
    required this.type,
    required this.scheduledAt,
    required this.duration,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String userId;
  final WorkoutType type;
  final DateTime scheduledAt;
  final Duration duration;
  final DateTime createdAt;
  final String? note;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'scheduledAt': scheduledAt.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory ScheduledWorkout.fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String? ?? WorkoutType.running.name;
    final type = WorkoutType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => WorkoutType.running,
    );

    return ScheduledWorkout(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: type,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      duration: Duration(minutes: (json['durationMinutes'] as num).toInt()),
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );
  }
}
