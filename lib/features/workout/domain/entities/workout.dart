import 'workout_route_point.dart';
import 'workout_type.dart';
import 'workout_exercise_entry.dart';

class Workout {
  const Workout({
    required this.id,
    required this.userId,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.calories,
    required this.distanceMeters,
    required this.route,
    required this.isSynced,
    this.title,
    this.note,
    this.place,
    this.exercises = const <WorkoutExerciseEntry>[],
    this.isManual = false,
  });

  final String id;
  final String userId;
  final WorkoutType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final double calories;
  final double distanceMeters;
  final List<WorkoutRoutePoint> route;
  final bool isSynced;
  final String? title;
  final String? note;
  final String? place;
  final List<WorkoutExerciseEntry> exercises;
  final bool isManual;

  Workout copyWith({
    String? id,
    String? userId,
    WorkoutType? type,
    DateTime? startedAt,
    DateTime? endedAt,
    Duration? duration,
    double? calories,
    double? distanceMeters,
    List<WorkoutRoutePoint>? route,
    bool? isSynced,
    Object? title = _sentinel,
    Object? note = _sentinel,
    Object? place = _sentinel,
    List<WorkoutExerciseEntry>? exercises,
    bool? isManual,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      route: route ?? this.route,
      isSynced: isSynced ?? this.isSynced,
      title: title == _sentinel ? this.title : title as String?,
      note: note == _sentinel ? this.note : note as String?,
      place: place == _sentinel ? this.place : place as String?,
      exercises: exercises ?? this.exercises,
      isManual: isManual ?? this.isManual,
    );
  }
}

const Object _sentinel = Object();
