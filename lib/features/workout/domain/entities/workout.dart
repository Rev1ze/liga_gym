import 'workout_route_point.dart';
import 'workout_type.dart';

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
    );
  }
}
