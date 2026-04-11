import '../../domain/entities/daily_step_count.dart';

class DailyStepCountModel extends DailyStepCount {
  const DailyStepCountModel({
    required super.userId,
    required super.date,
    required super.steps,
    required this.updatedAt,
  });

  final DateTime updatedAt;

  factory DailyStepCountModel.fromLocalMap(Map<String, Object?> map) {
    return DailyStepCountModel(
      userId: map['user_id']! as String,
      date: _parseDateKey(map['date_key']! as String),
      steps: map['steps']! as int,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }

  Map<String, Object?> toLocalMap() {
    return <String, Object?>{
      'user_id': userId,
      'date_key': buildStepDateKey(date),
      'steps': steps,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  static DateTime _parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

String buildStepDateKey(DateTime date) {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final month = normalizedDate.month.toString().padLeft(2, '0');
  final day = normalizedDate.day.toString().padLeft(2, '0');
  return '${normalizedDate.year}-$month-$day';
}
