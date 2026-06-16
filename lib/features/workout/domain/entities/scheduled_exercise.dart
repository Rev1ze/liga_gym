class ScheduledExercise {
  const ScheduledExercise({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseTitle,
    required this.scheduledAt,
    required this.createdAt,
    this.sets,
    this.reps,
    this.note,
    this.iconName,
    this.avatarDataUrl,
  });

  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseTitle;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final int? sets;
  final int? reps;
  final String? note;
  final String? iconName;
  final String? avatarDataUrl;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'userId': userId,
      'exerciseId': exerciseId,
      'exerciseTitle': exerciseTitle,
      'scheduledAt': scheduledAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'sets': sets,
      'reps': reps,
      'note': note,
      'iconName': iconName,
      'avatarDataUrl': avatarDataUrl,
    };
  }

  factory ScheduledExercise.fromJson(Map<String, Object?> json) {
    return ScheduledExercise(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      exerciseTitle: json['exerciseTitle'] as String? ?? '',
      scheduledAt:
          DateTime.tryParse(json['scheduledAt'] as String? ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      note: json['note'] as String?,
      iconName: json['iconName'] as String?,
      avatarDataUrl: json['avatarDataUrl'] as String?,
    );
  }
}
