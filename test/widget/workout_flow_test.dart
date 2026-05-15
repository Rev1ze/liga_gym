import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/core/constants/app_keys.dart';
import 'package:liga_gym_app/core/navigation/app_routes.dart';
import 'package:liga_gym_app/core/providers/shared_preferences_provider.dart';
import 'package:liga_gym_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:liga_gym_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_route_point.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_type.dart';
import 'package:liga_gym_app/features/workout/domain/usecases/load_user_workouts_use_case.dart';
import 'package:liga_gym_app/features/workout/domain/usecases/save_workout_use_case.dart';
import 'package:liga_gym_app/features/workout/presentation/screens/workout_history_screen.dart';
import 'package:liga_gym_app/features/workout/presentation/screens/workout_list_screen.dart';
import 'package:liga_gym_app/features/workout/presentation/providers/workout_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes/fake_workout_location_data_source.dart';
import '../support/fakes/in_memory_auth_repository.dart';
import '../support/fakes/in_memory_workout_repository.dart';
import '../support/test_app.dart';
import '../support/test_fixtures.dart';

void main() {
  testWidgets('shows workout history totals and filters by type', (
    tester,
  ) async {
    final authRepository = InMemoryAuthRepository();
    final firebaseAuth = buildSignedInFirebaseAuth(
      uid: 'workout-user',
      email: 'workout@ligagym.dev',
    );
    final workoutRepository = InMemoryWorkoutRepository(
      initialWorkouts: [
        Workout(
          id: 'run-1',
          userId: 'workout-user',
          type: WorkoutType.running,
          startedAt: DateTime(2026, 5, 10, 8),
          endedAt: DateTime(2026, 5, 10, 8, 30),
          duration: const Duration(minutes: 30),
          calories: 300,
          distanceMeters: 5000,
          route: const <WorkoutRoutePoint>[],
          isSynced: true,
        ),
        Workout(
          id: 'strength-1',
          userId: 'workout-user',
          type: WorkoutType.strength,
          startedAt: DateTime(2026, 5, 11, 18),
          endedAt: DateTime(2026, 5, 11, 18, 45),
          duration: const Duration(minutes: 45),
          calories: 250,
          distanceMeters: 0,
          route: const <WorkoutRoutePoint>[],
          isSynced: true,
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(1080, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(
        repository: authRepository,
        home: const WorkoutHistoryScreen(),
        overrides: [
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
          loadUserWorkoutsUseCaseProvider.overrideWith(
            (ref) => LoadUserWorkoutsUseCase(workoutRepository),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('550 kcal'), findsOneWidget);
    expect(find.text('5.00 km'), findsWidgets);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<WorkoutType?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Running').last);
    await tester.pumpAndSettle();

    expect(find.text('300 kcal'), findsWidgets);
    expect(find.text('Strength'), findsNothing);

    await authRepository.dispose();
  });

  testWidgets('plans workout from workout calendar dialog', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();
    final authRepository = InMemoryAuthRepository();
    final firebaseAuth = buildSignedInFirebaseAuth(
      uid: 'workout-user',
      email: 'workout@ligagym.dev',
    );
    final workoutRepository = InMemoryWorkoutRepository();
    await tester.binding.setSurfaceSize(const Size(1080, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(
        repository: authRepository,
        home: const WorkoutListScreen(),
        overrides: [
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          loadUserWorkoutsUseCaseProvider.overrideWith(
            (ref) => LoadUserWorkoutsUseCase(workoutRepository),
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan workout').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.maxLines == 2,
      ),
      'Evening run',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Evening run'), findsOneWidget);

    await authRepository.dispose();
  });

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
