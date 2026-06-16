class WorkoutExerciseEntry {
  const WorkoutExerciseEntry({
    required this.name,
    this.sets,
    this.reps,
    this.weightKg,
    this.note,
  });

  final String name;
  final int? sets;
  final int? reps;
  final double? weightKg;
  final String? note;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weightKg': weightKg,
      'note': note,
    };
  }

  factory WorkoutExerciseEntry.fromJson(Map<String, Object?> json) {
    return WorkoutExerciseEntry(
      name: json['name'] as String? ?? '',
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }
}
