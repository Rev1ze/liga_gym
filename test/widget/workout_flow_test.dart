import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/core/constants/app_keys.dart';
import 'package:liga_gym_app/core/navigation/app_routes.dart';
import 'package:liga_gym_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:liga_gym_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_route_point.dart';
import 'package:liga_gym_app/features/workout/domain/usecases/load_user_workouts_use_case.dart';
import 'package:liga_gym_app/features/workout/domain/usecases/save_workout_use_case.dart';
import 'package:liga_gym_app/features/workout/presentation/providers/workout_providers.dart';

import '../support/fakes/fake_workout_location_data_source.dart';
import '../support/fakes/in_memory_auth_repository.dart';
import '../support/fakes/in_memory_workout_repository.dart';
import '../support/test_app.dart';
import '../support/test_fixtures.dart';

void main() {
  testWidgets('completes workout flow from start to save', (tester) async {
    final authRepository = InMemoryAuthRepository();
    final firebaseAuth = buildSignedInFirebaseAuth(
      uid: 'workout-user',
      email: 'workout@ligagym.dev',
    );
    final workoutRepository = InMemoryWorkoutRepository();
    final locationDataSource = FakeWorkoutLocationDataSource();
    await tester.binding.setSurfaceSize(const Size(1440, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(locationDataSource.dispose);

    await tester.pumpWidget(
      buildRoutedTestApp(
        repository: authRepository,
        initialRoute: AppRoutes.startWorkout,
        overrides: [
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
          loadUserWorkoutsUseCaseProvider.overrideWith(
            (ref) => LoadUserWorkoutsUseCase(workoutRepository),
          ),
          saveWorkoutUseCaseProvider.overrideWith(
            (ref) => SaveWorkoutUseCase(workoutRepository),
          ),
          workoutLocationDataSourceProvider.overrideWithValue(
            locationDataSource,
          ),
          dashboardAnalyticsProvider.overrideWith(
            (ref) async => buildDashboardAnalyticsFixture(),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.workoutStartButton));
    await tester.pump();

    locationDataSource.emitRoutePoint(
      WorkoutRoutePoint(
        latitude: 56.8389,
        longitude: 60.6057,
        recordedAt: DateTime(2026, 4, 11, 9, 0, 5),
      ),
    );
    locationDataSource.emitRoutePoint(
      WorkoutRoutePoint(
        latitude: 56.8394,
        longitude: 60.6072,
        recordedAt: DateTime(2026, 4, 11, 9, 0, 15),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(find.byKey(AppKeys.workoutStopButton), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.workoutStopButton));
    await tester.pumpAndSettle();

    expect(find.text('Workout result'), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.workoutResultSaveButton));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(workoutRepository.savedWorkouts, hasLength(1));

    await authRepository.dispose();
  });
}
