import 'dart:convert';

import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_route_point.dart';
import '../../domain/entities/workout_type.dart';

class WorkoutModel extends Workout {
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
    );
  }

  factory WorkoutModel.fromLocalMap(Map<String, Object?> map) {
    final routeJson = map['route_json'] as String? ?? '[]';
    final decodedRoute = (jsonDecode(routeJson) as List<dynamic>)
        .map(
          (item) => WorkoutRoutePoint.fromJson(
            Map<String, Object?>.from(item as Map),
          ),
        )
        .toList();

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
    );
  }

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
    );
  }
}
