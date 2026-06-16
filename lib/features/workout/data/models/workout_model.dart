import 'dart:convert';

import '../../../../core/offline/offline_sync_record.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_exercise_entry.dart';
import '../../domain/entities/workout_route_point.dart';
import '../../domain/entities/workout_type.dart';

class WorkoutModel extends Workout implements OfflineSyncRecord {
  const WorkoutModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.startedAt,
    required super.endedAt,
    required super.duration,
    required super.calories,
    required super.distanceMeters,
    required super.route,
    required super.isSynced,
    super.title,
    super.note,
    super.place,
    super.exercises,
    super.isManual,
  });

  factory WorkoutModel.fromEntity(Workout workout) {
    return WorkoutModel(
      id: workout.id,
      userId: workout.userId,
      type: workout.type,
      startedAt: workout.startedAt,
      endedAt: workout.endedAt,
      duration: workout.duration,
      calories: workout.calories,
      distanceMeters: workout.distanceMeters,
      route: workout.route,
      isSynced: workout.isSynced,
      title: workout.title,
      note: workout.note,
      place: workout.place,
      exercises: workout.exercises,
      isManual: workout.isManual,
    );
  }

  factory WorkoutModel.fromLocalMap(Map<String, Object?> map) {
    final decodedRoute = _decodeRoute(map['route_json'] as String?);

    return WorkoutModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: WorkoutType.values.byName(map['type'] as String),
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
      endedAt: DateTime.fromMillisecondsSinceEpoch(map['ended_at'] as int),
      duration: Duration(seconds: map['duration_seconds'] as int),
      calories: (map['calories'] as num).toDouble(),
      distanceMeters: (map['distance_meters'] as num).toDouble(),
      route: decodedRoute,
      isSynced: (map['is_synced'] as int) == 1,
      title: _readString(map['title']),
      note: _readString(map['note']),
      place: _readString(map['place']),
      exercises: _decodeExercises(map['exercise_entries_json'] as String?),
      isManual: (map['is_manual'] as int? ?? 0) == 1,
    );
  }

  factory WorkoutModel.fromFirestore(
    String id,
    String userId,
    Map<String, Object?> json,
  ) {
    final decodedRoute = _decodeRoute(json['routeJson'] as String?);

    return WorkoutModel(
      id: id,
      userId: userId,
      type: WorkoutType.values.byName(json['type']! as String),
      startedAt: DateTime.parse(json['startedAt']! as String),
      endedAt: DateTime.parse(json['endedAt']! as String),
      duration: Duration(seconds: json['durationSeconds']! as int),
      calories: (json['calories']! as num).toDouble(),
      distanceMeters: (json['distanceMeters']! as num).toDouble(),
      route: decodedRoute,
      isSynced: true,
      title: _readString(json['title']),
      note: _readString(json['note']),
      place: _readString(json['place']),
      exercises: _decodeExercises(json['exerciseEntriesJson'] as String?),
      isManual: json['isManual'] as bool? ?? false,
    );
  }

  @override
  DateTime get lastModifiedAt => endedAt;

  Map<String, Object?> toLocalMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'started_at': startedAt.millisecondsSinceEpoch,
      'ended_at': endedAt.millisecondsSinceEpoch,
      'duration_seconds': duration.inSeconds,
      'calories': calories,
      'distance_meters': distanceMeters,
      'route_json': jsonEncode(
        route.map((point) => point.toJson()).toList(growable: false),
      ),
      'is_synced': isSynced ? 1 : 0,
      'title': title,
      'note': note,
      'place': place,
      'exercise_entries_json': jsonEncode(
        exercises.map((entry) => entry.toJson()).toList(growable: false),
      ),
      'is_manual': isManual ? 1 : 0,
    };
  }

  Map<String, Object?> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'calories': calories,
      'distanceMeters': distanceMeters,
      'routeJson': jsonEncode(
        route.map((point) => point.toJson()).toList(growable: false),
      ),
      'isSynced': true,
      'title': title,
      'note': note,
      'place': place,
      'exerciseEntriesJson': jsonEncode(
        exercises.map((entry) => entry.toJson()).toList(growable: false),
      ),
      'isManual': isManual,
    };
  }

  WorkoutModel withSyncStatus(bool isSynced) {
    return WorkoutModel(
      id: id,
      userId: userId,
      type: type,
      startedAt: startedAt,
      endedAt: endedAt,
      duration: duration,
      calories: calories,
      distanceMeters: distanceMeters,
      route: route,
      isSynced: isSynced,
      title: title,
      note: note,
      place: place,
      exercises: exercises,
      isManual: isManual,
    );
  }

  static List<WorkoutRoutePoint> _decodeRoute(String? routeJson) {
    if (routeJson == null || routeJson.isEmpty) {
      return const <WorkoutRoutePoint>[];
    }

    try {
      return (jsonDecode(routeJson) as List<dynamic>)
          .map(
            (item) => WorkoutRoutePoint.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const <WorkoutRoutePoint>[];
    }
  }

  static List<WorkoutExerciseEntry> _decodeExercises(String? exercisesJson) {
    if (exercisesJson == null || exercisesJson.isEmpty) {
      return const <WorkoutExerciseEntry>[];
    }

    try {
      return (jsonDecode(exercisesJson) as List<dynamic>)
          .map(
            (item) => WorkoutExerciseEntry.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .where((entry) => entry.name.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <WorkoutExerciseEntry>[];
    }
  }

  static String? _readString(Object? value) {
    final text = value as String?;
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return text.trim();
  }
}
