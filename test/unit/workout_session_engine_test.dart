import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_route_point.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_type.dart';
import 'package:liga_gym_app/features/workout/domain/services/workout_session_engine.dart';

void main() {
  group('WorkoutSessionEngine', () {
    test('tracks elapsed time and excludes paused duration', () {
      final startedAt = DateTime.utc(2026, 4, 8, 10, 0, 0);
      final engine = WorkoutSessionEngine(
        type: WorkoutType.running,
        startedAt: startedAt,
      );

      expect(
        engine.elapsedAt(startedAt.add(const Duration(minutes: 5))),
        const Duration(minutes: 5),
      );

      engine.pause(startedAt.add(const Duration(minutes: 5)));

      expect(
        engine.elapsedAt(startedAt.add(const Duration(minutes: 8))),
        const Duration(minutes: 5),
      );

      engine.resume(startedAt.add(const Duration(minutes: 8)));

      expect(
        engine.elapsedAt(startedAt.add(const Duration(minutes: 10))),
        const Duration(minutes: 7),
      );
    });

    test('accumulates route points and distance', () {
      final engine = WorkoutSessionEngine(
        type: WorkoutType.walking,
        startedAt: DateTime.utc(2026, 4, 8, 10),
      );

      engine.addRoutePoint(
        WorkoutRoutePoint(
          latitude: 56.8389,
          longitude: 60.6057,
          recordedAt: DateTime.utc(2026, 4, 8, 10),
        ),
      );
      engine.addRoutePoint(
        WorkoutRoutePoint(
          latitude: 56.8394,
          longitude: 60.6067,
          recordedAt: DateTime.utc(2026, 4, 8, 10, 2),
        ),
      );

      expect(engine.route.length, 2);
      expect(engine.distanceMeters, greaterThan(80));
    });

    test('creates completed workout snapshot on stop', () {
      final startedAt = DateTime.utc(2026, 4, 8, 10, 0, 0);
      final endedAt = startedAt.add(const Duration(minutes: 15));
      final engine = WorkoutSessionEngine(
        type: WorkoutType.cycling,
        startedAt: startedAt,
      );

      engine.addRoutePoint(
        WorkoutRoutePoint(
          latitude: 55.751244,
          longitude: 37.618423,
          recordedAt: DateTime.utc(2026, 4, 8, 10, 0, 10),
        ),
      );
      engine.addRoutePoint(
        WorkoutRoutePoint(
          latitude: 55.752244,
          longitude: 37.619423,
          recordedAt: DateTime.utc(2026, 4, 8, 10, 14, 30),
        ),
      );

      final workout = engine.stop(userId: 'user-42', endedAt: endedAt);

      expect(workout.id, startsWith('user-42_'));
      expect(workout.userId, 'user-42');
      expect(workout.type, WorkoutType.cycling);
      expect(workout.startedAt, startedAt);
      expect(workout.endedAt, endedAt);
      expect(workout.duration, const Duration(minutes: 15));
      expect(workout.isSynced, isFalse);
      expect(workout.route.length, 2);
      expect(workout.distanceMeters, greaterThan(100));
      expect(workout.calories, greaterThan(112));
    });
  });
}
