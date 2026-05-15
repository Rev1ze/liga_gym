import 'dart:math' as math;

import '../entities/workout_route_point.dart';
import '../entities/workout_type.dart';

abstract final class WorkoutMetricsCalculator {
  static double calculateCaloriesBurned({
    required WorkoutType type,
    required Duration duration,
    required double distanceMeters,
  }) {
    final durationMinutes = duration.inSeconds / 60;
    final distanceKm = distanceMeters / 1000;

    final calories = switch (type) {
      WorkoutType.running => (durationMinutes * 9.8) + (distanceKm * 1.1),
      WorkoutType.cycling => (durationMinutes * 7.5) + (distanceKm * 0.4),
      WorkoutType.walking => (durationMinutes * 4.8) + (distanceKm * 0.6),
      WorkoutType.strength => durationMinutes * 6.2,
      WorkoutType.cardio => (durationMinutes * 8.2) + (distanceKm * 0.3),
    };

    return double.parse(calories.toStringAsFixed(1));
  }

  static double calculateDistanceBetween(
    WorkoutRoutePoint start,
    WorkoutRoutePoint end,
  ) {
    if (!start.hasValidCoordinates || !end.hasValidCoordinates) {
      return 0;
    }

    const earthRadiusMeters = 6371000.0;
    final latitudeDistance = _toRadians(end.latitude - start.latitude);
    final longitudeDistance = _toRadians(end.longitude - start.longitude);
    final startLatitude = _toRadians(start.latitude);
    final endLatitude = _toRadians(end.latitude);

    final haversine =
        math.pow(math.sin(latitudeDistance / 2), 2) +
        math.cos(startLatitude) *
            math.cos(endLatitude) *
            math.pow(math.sin(longitudeDistance / 2), 2);
    final normalizedHaversine = haversine.clamp(0, 1).toDouble();
    final angularDistance =
        2 *
        math.atan2(
          math.sqrt(normalizedHaversine),
          math.sqrt(1 - normalizedHaversine),
        );

    final distance = earthRadiusMeters * angularDistance;
    return distance.isFinite ? distance : 0;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
