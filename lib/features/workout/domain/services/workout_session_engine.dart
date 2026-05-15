import '../entities/workout.dart';
import '../entities/workout_route_point.dart';
import '../entities/workout_type.dart';
import 'workout_metrics_calculator.dart';

class WorkoutSessionEngine {
  WorkoutSessionEngine({required this.type, DateTime? startedAt})
    : _startedAt = startedAt ?? DateTime.now();

  final WorkoutType type;
  final DateTime _startedAt;
  final List<WorkoutRoutePoint> _route = <WorkoutRoutePoint>[];

  Duration _pausedDuration = Duration.zero;
  DateTime? _pausedAt;
  double _distanceMeters = 0;

  bool get isPaused => _pausedAt != null;
  DateTime get startedAt => _startedAt;
  double get distanceMeters => _distanceMeters;
  List<WorkoutRoutePoint> get route =>
      List<WorkoutRoutePoint>.unmodifiable(_route);

  Duration elapsedAt(DateTime now) {
    final effectivePausedDuration = _pausedAt == null
        ? _pausedDuration
        : _pausedDuration + now.difference(_pausedAt!);

    final elapsed = now.difference(_startedAt) - effectivePausedDuration;
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  void pause(DateTime now) {
    if (_pausedAt != null) {
      return;
    }

    _pausedAt = now;
  }

  void resume(DateTime now) {
    final pausedAt = _pausedAt;
    if (pausedAt == null) {
      return;
    }

    _pausedDuration += now.difference(pausedAt);
    _pausedAt = null;
  }

  void addRoutePoint(WorkoutRoutePoint point) {
    if (!point.hasValidCoordinates) {
      return;
    }

    if (_route.isNotEmpty) {
      _distanceMeters += WorkoutMetricsCalculator.calculateDistanceBetween(
        _route.last,
        point,
      );
    }

    _route.add(point);
  }

  Workout stop({required String userId, DateTime? endedAt}) {
    final stopTime = endedAt ?? DateTime.now();
    final duration = elapsedAt(stopTime);
    final calories = WorkoutMetricsCalculator.calculateCaloriesBurned(
      type: type,
      duration: duration,
      distanceMeters: _distanceMeters,
    );

    return Workout(
      id: '${userId}_${_startedAt.microsecondsSinceEpoch}',
      userId: userId,
      type: type,
      startedAt: _startedAt,
      endedAt: stopTime,
      duration: duration,
      calories: calories,
      distanceMeters: _distanceMeters,
      route: List<WorkoutRoutePoint>.unmodifiable(_route),
      isSynced: false,
    );
  }
}
