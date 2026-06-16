import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_route_point.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_type.dart';
import 'package:liga_gym_app/features/workout/domain/services/workout_metrics_calculator.dart';

void main() {
  group('WorkoutMetricsCalculator', () {
    test('calculates running calories using duration and distance', () {
      final calories = WorkoutMetricsCalculator.calculateCaloriesBurned(
        type: WorkoutType.running,
        duration: const Duration(minutes: 30),
        distanceMeters: 5000,
      );

      expect(calories, 299.5);
    });

    test('ignores distance for strength calories', () {
      final calories = WorkoutMetricsCalculator.calculateCaloriesBurned(
        type: WorkoutType.strength,
        duration: const Duration(minutes: 45),
        distanceMeters: 3200,
      );

      expect(calories, 279.0);
    });

    test('uses hidden route telemetry for uphill running calories', () {
      final route = [
        WorkoutRoutePoint(
          latitude: 55.0,
          longitude: 60.0,
          recordedAt: DateTime.utc(2026, 6, 5, 8),
          altitudeMeters: 120,
          accuracyMeters: 6,
          speedMetersPerSecond: 3.2,
        ),
        WorkoutRoutePoint(
          latitude: 55.001,
          longitude: 60.001,
          recordedAt: DateTime.utc(2026, 6, 5, 8, 5),
          altitudeMeters: 138,
          accuracyMeters: 5,
          speedMetersPerSecond: 3.4,
        ),
        WorkoutRoutePoint(
          latitude: 55.002,
          longitude: 60.002,
          recordedAt: DateTime.utc(2026, 6, 5, 8, 10),
          altitudeMeters: 154,
          accuracyMeters: 5,
          speedMetersPerSecond: 3.5,
        ),
      ];

      final flatCalories = WorkoutMetricsCalculator.calculateCaloriesBurned(
        type: WorkoutType.running,
        duration: const Duration(minutes: 30),
        distanceMeters: 5000,
      );
      final uphillCalories = WorkoutMetricsCalculator.calculateCaloriesBurned(
        type: WorkoutType.running,
        duration: const Duration(minutes: 30),
        distanceMeters: 5000,
        route: route,
      );
      final telemetry = WorkoutMetricsCalculator.analyzeRouteTelemetry(route);

      expect(telemetry.elevationGainMeters, 34);
      expect(telemetry.averageAccuracyMeters, closeTo(5.3, 0.1));
      expect(uphillCalories, greaterThan(flatCalories));
    });

    test('calculates geographic distance between route points', () {
      final start = WorkoutRoutePoint(
        latitude: 0,
        longitude: 0,
        recordedAt: DateTime.utc(2026, 4, 8, 10),
      );
      final end = WorkoutRoutePoint(
        latitude: 0,
        longitude: 0.001,
        recordedAt: DateTime.utc(2026, 4, 8, 10, 1),
      );

      final distance = WorkoutMetricsCalculator.calculateDistanceBetween(
        start,
        end,
      );

      expect(distance, closeTo(111.2, 0.5));
    });
  });
}
