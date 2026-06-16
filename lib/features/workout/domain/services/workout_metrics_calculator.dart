import 'dart:math' as math;

import '../entities/workout_route_point.dart';
import '../entities/workout_type.dart';

abstract final class WorkoutMetricsCalculator {
  static double calculateCaloriesBurned({
    required WorkoutType type,
    required Duration duration,
    required double distanceMeters,
    List<WorkoutRoutePoint> route = const <WorkoutRoutePoint>[],
  }) {
    final durationMinutes = duration.inSeconds / 60;
    final distanceKm = distanceMeters / 1000;

    final calories = switch (type) {
      WorkoutType.running => (durationMinutes * 9.8) + (distanceKm * 1.1),
      WorkoutType.treadmillRunning =>
        (durationMinutes * 9.4) + (distanceKm * 0.9),
      WorkoutType.trailRunning => (durationMinutes * 11.2) + (distanceKm * 1.4),
      WorkoutType.intervalRunning =>
        (durationMinutes * 12.4) + (distanceKm * 1.2),
      WorkoutType.cycling => (durationMinutes * 7.5) + (distanceKm * 0.4),
      WorkoutType.walking => (durationMinutes * 4.8) + (distanceKm * 0.6),
      WorkoutType.strength => durationMinutes * 6.2,
      WorkoutType.cardio => (durationMinutes * 8.2) + (distanceKm * 0.3),
    };

    final routeTelemetry = analyzeRouteTelemetry(route);
    final elevationBonus = switch (type) {
      WorkoutType.running ||
      WorkoutType.treadmillRunning ||
      WorkoutType.trailRunning ||
      WorkoutType.intervalRunning ||
      WorkoutType.walking => routeTelemetry.elevationGainMeters * 0.7,
      WorkoutType.cycling => routeTelemetry.elevationGainMeters * 0.42,
      WorkoutType.strength || WorkoutType.cardio => 0.0,
    };
    final speedMultiplier = _speedEffortMultiplier(
      type,
      routeTelemetry.averageSpeedMetersPerSecond,
    );
    final adjustedCalories = (calories * speedMultiplier) + elevationBonus;

    return double.parse(adjustedCalories.toStringAsFixed(1));
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

  static WorkoutRouteTelemetry analyzeRouteTelemetry(
    List<WorkoutRoutePoint> route,
  ) {
    if (route.length < 2) {
      return const WorkoutRouteTelemetry();
    }

    var elevationGainMeters = 0.0;
    var previousAltitude = route.first.altitudeMeters;
    for (final point in route.skip(1)) {
      final altitude = point.altitudeMeters;
      if (altitude == null || !altitude.isFinite) {
        continue;
      }
      if (previousAltitude == null || !previousAltitude.isFinite) {
        previousAltitude = altitude;
        continue;
      }

      final delta = altitude - previousAltitude;
      if (delta > 1.5) {
        elevationGainMeters += delta;
      }
      previousAltitude = altitude;
    }

    final speedSamples = route
        .map((point) => point.speedMetersPerSecond)
        .whereType<double>()
        .where((speed) => speed.isFinite && speed > 0 && speed < 12)
        .toList(growable: false);
    final averageSpeed = speedSamples.isEmpty
        ? 0.0
        : speedSamples.reduce((left, right) => left + right) /
              speedSamples.length;

    final accuracySamples = route
        .map((point) => point.accuracyMeters)
        .whereType<double>()
        .where((accuracy) => accuracy.isFinite && accuracy > 0)
        .toList(growable: false);
    final averageAccuracy = accuracySamples.isEmpty
        ? null
        : accuracySamples.reduce((left, right) => left + right) /
              accuracySamples.length;

    return WorkoutRouteTelemetry(
      elevationGainMeters: elevationGainMeters,
      averageSpeedMetersPerSecond: averageSpeed,
      averageAccuracyMeters: averageAccuracy,
      pointCount: route.length,
    );
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  static double _speedEffortMultiplier(
    WorkoutType type,
    double averageSpeedMetersPerSecond,
  ) {
    if (averageSpeedMetersPerSecond <= 0) {
      return 1;
    }

    final speedKmH = averageSpeedMetersPerSecond * 3.6;
    return switch (type) {
      WorkoutType.running ||
      WorkoutType.treadmillRunning ||
      WorkoutType.trailRunning =>
        speedKmH >= 13
            ? 1.08
            : speedKmH >= 10
            ? 1.04
            : 1,
      WorkoutType.intervalRunning => speedKmH >= 14 ? 1.1 : 1.04,
      WorkoutType.walking => speedKmH >= 6.5 ? 1.05 : 1,
      WorkoutType.cycling =>
        speedKmH >= 28
            ? 1.07
            : speedKmH >= 22
            ? 1.03
            : 1,
      WorkoutType.strength || WorkoutType.cardio => 1,
    };
  }
}

class WorkoutRouteTelemetry {
  const WorkoutRouteTelemetry({
    this.elevationGainMeters = 0,
    this.averageSpeedMetersPerSecond = 0,
    this.averageAccuracyMeters,
    this.pointCount = 0,
  });

  final double elevationGainMeters;
  final double averageSpeedMetersPerSecond;
  final double? averageAccuracyMeters;
  final int pointCount;

  bool get hasElevationData => elevationGainMeters > 0;
  bool get hasSpeedData => averageSpeedMetersPerSecond > 0;
}
