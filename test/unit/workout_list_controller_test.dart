import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_route_point.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_type.dart';
import 'package:liga_gym_app/features/workout/domain/usecases/load_user_workouts_use_case.dart';
import 'package:liga_gym_app/features/workout/presentation/providers/workout_providers.dart';

import '../support/fakes/in_memory_workout_repository.dart';
import '../support/test_fixtures.dart';

void main() {
  group('WorkoutListController', () {
    test('loads user workouts and filters them by type', () async {
      final firebaseAuth = buildSignedInFirebaseAuth(
        uid: 'workout-user',
        email: 'workout@ligagym.dev',
      );
      final repository = InMemoryWorkoutRepository(
        initialWorkouts: [
          Workout(
            id: 'run-1',
            userId: 'workout-user',
            type: WorkoutType.running,
            startedAt: DateTime(2026, 4, 11, 8),
            endedAt: DateTime(2026, 4, 11, 8, 25),
            duration: const Duration(minutes: 25),
            calories: 310,
            distanceMeters: 4200,
            route: const <WorkoutRoutePoint>[],
            isSynced: true,
          ),
          Workout(
            id: 'strength-1',
            userId: 'workout-user',
            type: WorkoutType.strength,
            startedAt: DateTime(2026, 4, 10, 18),
            endedAt: DateTime(2026, 4, 10, 18, 45),
            duration: const Duration(minutes: 45),
            calories: 280,
            distanceMeters: 0,
            route: const <WorkoutRoutePoint>[],
            isSynced: true,
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
          loadUserWorkoutsUseCaseProvider.overrideWith(
            (ref) => LoadUserWorkoutsUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(workoutListControllerProvider.notifier)
          .loadUserWorkouts();

      expect(
        container.read(workoutListControllerProvider).filteredWorkouts,
        hasLength(2),
      );

      container
          .read(workoutListControllerProvider.notifier)
          .filterWorkouts(selectedType: WorkoutType.running);

      final filtered = container.read(workoutListControllerProvider);
      expect(filtered.selectedType, WorkoutType.running);
      expect(filtered.filteredWorkouts, hasLength(1));
      expect(filtered.filteredWorkouts.single.id, 'run-1');
    });
  });
}
