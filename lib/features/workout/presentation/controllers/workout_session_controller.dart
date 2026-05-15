import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_route_point.dart';
import '../../domain/entities/workout_save_status.dart';
import '../../domain/entities/workout_type.dart';
import '../../domain/services/workout_metrics_calculator.dart';
import '../../domain/services/workout_session_engine.dart';
import '../providers/workout_providers.dart';

enum WorkoutSessionStatus { idle, running, paused, completed, saving }

@immutable
class WorkoutSessionState {
  const WorkoutSessionState({
    this.status = WorkoutSessionStatus.idle,
    this.workoutType,
    this.elapsed = Duration.zero,
    this.calories = 0,
    this.distanceMeters = 0,
    this.route = const <WorkoutRoutePoint>[],
    this.completedWorkout,
    this.isLocationTrackingAvailable = true,
    this.shouldAskForRouteMap = false,
    this.shouldShowLocationEnableRequest = false,
  });

  final WorkoutSessionStatus status;
  final WorkoutType? workoutType;
  final Duration elapsed;
  final double calories;
  final double distanceMeters;
  final List<WorkoutRoutePoint> route;
  final Workout? completedWorkout;
  final bool isLocationTrackingAvailable;
  final bool shouldAskForRouteMap;
  final bool shouldShowLocationEnableRequest;

  WorkoutSessionState copyWith({
    WorkoutSessionStatus? status,
    Object? workoutType = _sentinel,
    Duration? elapsed,
    double? calories,
    double? distanceMeters,
    List<WorkoutRoutePoint>? route,
    Object? completedWorkout = _sentinel,
    bool? isLocationTrackingAvailable,
    bool? shouldAskForRouteMap,
    bool? shouldShowLocationEnableRequest,
  }) {
    return WorkoutSessionState(
      status: status ?? this.status,
      workoutType: workoutType == _sentinel
          ? this.workoutType
          : workoutType as WorkoutType?,
      elapsed: elapsed ?? this.elapsed,
      calories: calories ?? this.calories,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      route: route ?? this.route,
      completedWorkout: completedWorkout == _sentinel
          ? this.completedWorkout
          : completedWorkout as Workout?,
      isLocationTrackingAvailable:
          isLocationTrackingAvailable ?? this.isLocationTrackingAvailable,
      shouldAskForRouteMap: shouldAskForRouteMap ?? this.shouldAskForRouteMap,
      shouldShowLocationEnableRequest:
          shouldShowLocationEnableRequest ??
          this.shouldShowLocationEnableRequest,
    );
  }
}

const Object _sentinel = Object();

class WorkoutSessionController extends Notifier<WorkoutSessionState> {
  WorkoutSessionEngine? _engine;
  Timer? _ticker;
  StreamSubscription<WorkoutRoutePoint>? _locationSubscription;

  @override
  WorkoutSessionState build() {
    ref.onDispose(_disposeResources);
    return const WorkoutSessionState();
  }

  Future<void> startWorkoutTimer(WorkoutType type) async {
    _disposeResources();

    _engine = WorkoutSessionEngine(type: type);
    final locationEnabled = await ref
        .read(workoutLocationDataSourceProvider)
        .prepareTracking();

    state = WorkoutSessionState(
      status: WorkoutSessionStatus.running,
      workoutType: type,
      isLocationTrackingAvailable: locationEnabled,
      shouldAskForRouteMap: !locationEnabled,
    );

    _startTicker();
    if (locationEnabled) {
      _startLocationSubscription();
    }
  }

  Future<void> requestRouteMap() async {
    if (state.status != WorkoutSessionStatus.running &&
        state.status != WorkoutSessionStatus.paused) {
      return;
    }

    final locationEnabled = await ref
        .read(workoutLocationDataSourceProvider)
        .prepareTracking();

    if (locationEnabled) {
      state = state.copyWith(
        isLocationTrackingAvailable: true,
        shouldAskForRouteMap: false,
        shouldShowLocationEnableRequest: false,
      );
      _startLocationSubscription();
      return;
    }

    state = state.copyWith(
      isLocationTrackingAvailable: false,
      shouldAskForRouteMap: false,
      shouldShowLocationEnableRequest: true,
    );
  }

  void skipRouteMap() {
    state = state.copyWith(
      shouldAskForRouteMap: false,
      shouldShowLocationEnableRequest: false,
    );
  }

  Future<void> openLocationSettings() {
    return ref.read(workoutLocationDataSourceProvider).openLocationSettings();
  }

  void pauseWorkout() {
    final engine = _engine;
    if (engine == null || state.status != WorkoutSessionStatus.running) {
      return;
    }

    engine.pause(DateTime.now());
    _refreshState(status: WorkoutSessionStatus.paused);
  }

  void resumeWorkout() {
    final engine = _engine;
    if (engine == null || state.status != WorkoutSessionStatus.paused) {
      return;
    }

    engine.resume(DateTime.now());
    _refreshState(status: WorkoutSessionStatus.running);
  }

  Workout? stopWorkout() {
    final engine = _engine;
    final user = ref.read(firebaseWorkoutUserProvider);
    if (engine == null || user == null) {
      return null;
    }

    final workout = engine.stop(userId: user.uid);
    _disposeResources();
    state = state.copyWith(
      status: WorkoutSessionStatus.completed,
      elapsed: workout.duration,
      calories: workout.calories,
      distanceMeters: workout.distanceMeters,
      route: workout.route,
      completedWorkout: workout,
      shouldAskForRouteMap: false,
      shouldShowLocationEnableRequest: false,
    );

    return workout;
  }

  Future<WorkoutSaveStatus> saveWorkoutToDatabase() async {
    final workout = state.completedWorkout;
    if (workout == null) {
      throw const WorkoutException(AppErrorCode.workoutSaveFailed);
    }

    state = state.copyWith(status: WorkoutSessionStatus.saving);
    final saveStatus = await ref.read(saveWorkoutUseCaseProvider).call(workout);

    final savedWorkout = switch (saveStatus) {
      WorkoutSaveStatus.synced => workout.copyWith(isSynced: true),
      WorkoutSaveStatus.savedLocally => workout,
    };

    state = state.copyWith(
      status: WorkoutSessionStatus.completed,
      completedWorkout: savedWorkout,
    );

    return saveStatus;
  }

  void reset() {
    _disposeResources();
    state = const WorkoutSessionState();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == WorkoutSessionStatus.running ||
          state.status == WorkoutSessionStatus.paused) {
        _refreshState();
      }
    });
  }

  void _handleRoutePoint(WorkoutRoutePoint point) {
    final engine = _engine;
    if (engine == null || state.status != WorkoutSessionStatus.running) {
      return;
    }

    engine.addRoutePoint(point);
    _refreshState();
  }

  void _startLocationSubscription() {
    _locationSubscription?.cancel();
    _locationSubscription = ref
        .read(workoutLocationDataSourceProvider)
        .watchRoute()
        .listen(_handleRoutePoint);
  }

  void _refreshState({WorkoutSessionStatus? status}) {
    final engine = _engine;
    if (engine == null) {
      return;
    }

    final elapsed = engine.elapsedAt(DateTime.now());
    final distanceMeters = engine.distanceMeters;
    final calories = WorkoutMetricsCalculator.calculateCaloriesBurned(
      type: engine.type,
      duration: elapsed,
      distanceMeters: distanceMeters,
    );

    state = state.copyWith(
      status: status ?? state.status,
      workoutType: engine.type,
      elapsed: elapsed,
      calories: calories,
      distanceMeters: distanceMeters,
      route: engine.route,
    );
  }

  void _disposeResources() {
    _ticker?.cancel();
    _ticker = null;
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }
}
