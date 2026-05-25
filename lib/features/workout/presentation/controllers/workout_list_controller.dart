import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../domain/entities/scheduled_workout.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_route_point.dart';
import '../../domain/entities/workout_save_status.dart';
import '../../domain/entities/workout_type.dart';
import '../../domain/services/workout_metrics_calculator.dart';
import '../providers/workout_providers.dart';

@immutable
class WorkoutListState {
  const WorkoutListState({
    this.isLoading = false,
    this.workouts = const <Workout>[],
    this.filteredWorkouts = const <Workout>[],
    this.scheduledWorkouts = const <ScheduledWorkout>[],
    this.selectedDate,
    this.selectedType,
    this.visibleMonth,
  });

  final bool isLoading;
  final List<Workout> workouts;
  final List<Workout> filteredWorkouts;
  final List<ScheduledWorkout> scheduledWorkouts;
  final DateTime? selectedDate;
  final WorkoutType? selectedType;
  final DateTime? visibleMonth;

  WorkoutListState copyWith({
    bool? isLoading,
    List<Workout>? workouts,
    List<Workout>? filteredWorkouts,
    List<ScheduledWorkout>? scheduledWorkouts,
    Object? selectedDate = _sentinel,
    Object? selectedType = _sentinel,
    Object? visibleMonth = _sentinel,
  }) {
    return WorkoutListState(
      isLoading: isLoading ?? this.isLoading,
      workouts: workouts ?? this.workouts,
      filteredWorkouts: filteredWorkouts ?? this.filteredWorkouts,
      scheduledWorkouts: scheduledWorkouts ?? this.scheduledWorkouts,
      selectedDate: selectedDate == _sentinel
          ? this.selectedDate
          : selectedDate as DateTime?,
      selectedType: selectedType == _sentinel
          ? this.selectedType
          : selectedType as WorkoutType?,
      visibleMonth: visibleMonth == _sentinel
          ? this.visibleMonth
          : visibleMonth as DateTime?,
    );
  }
}

const Object _sentinel = Object();

class WorkoutListController extends Notifier<WorkoutListState> {
  @override
  WorkoutListState build() => const WorkoutListState();

  Future<void> loadUserWorkouts() async {
    final user = ref.read(firebaseWorkoutUserProvider);
    if (user == null) {
      state = const WorkoutListState();
      return;
    }

    state = state.copyWith(isLoading: true);
    final workouts = await ref
        .read(loadUserWorkoutsUseCaseProvider)
        .call(user.uid);
    final scheduledWorkouts = _loadScheduledWorkouts(user.uid);

    state = state.copyWith(
      isLoading: false,
      workouts: workouts,
      scheduledWorkouts: scheduledWorkouts,
      filteredWorkouts: _applyFilters(
        workouts: workouts,
        selectedDate: state.selectedDate,
        selectedType: state.selectedType,
      ),
    );
  }

  Future<ScheduledWorkout?> scheduleWorkout({
    required WorkoutType type,
    required DateTime scheduledAt,
    required Duration duration,
    String? note,
  }) async {
    final user = ref.read(firebaseWorkoutUserProvider);
    if (user == null) {
      return null;
    }

    final createdAt = DateTime.now();
    final trimmedNote = note?.trim();
    final nextWorkout = ScheduledWorkout(
      id: '${createdAt.microsecondsSinceEpoch}',
      userId: user.uid,
      type: type,
      scheduledAt: scheduledAt,
      duration: duration,
      createdAt: createdAt,
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
    );
    final nextScheduledWorkouts = [...state.scheduledWorkouts, nextWorkout]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    state = state.copyWith(scheduledWorkouts: nextScheduledWorkouts);
    await _saveScheduledWorkouts(user.uid, nextScheduledWorkouts);
    return nextWorkout;
  }

  Future<WorkoutSaveStatus?> addCompletedWorkout({
    required WorkoutType type,
    required DateTime startedAt,
    required Duration duration,
    required double distanceMeters,
  }) async {
    final user = ref.read(firebaseWorkoutUserProvider);
    if (user == null) {
      return null;
    }

    final createdAt = DateTime.now();
    final workout = Workout(
      id: 'manual-${createdAt.microsecondsSinceEpoch}',
      userId: user.uid,
      type: type,
      startedAt: startedAt,
      endedAt: startedAt.add(duration),
      duration: duration,
      calories: WorkoutMetricsCalculator.calculateCaloriesBurned(
        type: type,
        duration: duration,
        distanceMeters: distanceMeters,
      ),
      distanceMeters: distanceMeters,
      route: const <WorkoutRoutePoint>[],
      isSynced: false,
    );
    final saveStatus = await ref.read(saveWorkoutUseCaseProvider).call(workout);
    final savedWorkout = switch (saveStatus) {
      WorkoutSaveStatus.synced => workout.copyWith(isSynced: true),
      WorkoutSaveStatus.savedLocally => workout,
    };
    final nextWorkouts = [...state.workouts, savedWorkout]
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));

    state = state.copyWith(
      workouts: nextWorkouts,
      filteredWorkouts: _applyFilters(
        workouts: nextWorkouts,
        selectedDate: state.selectedDate,
        selectedType: state.selectedType,
      ),
    );

    return saveStatus;
  }

  Future<void> deleteScheduledWorkout(String id) async {
    final user = ref.read(firebaseWorkoutUserProvider);
    if (user == null) {
      return;
    }

    final nextScheduledWorkouts = state.scheduledWorkouts
        .where((workout) => workout.id != id)
        .toList(growable: false);

    state = state.copyWith(scheduledWorkouts: nextScheduledWorkouts);
    await _saveScheduledWorkouts(user.uid, nextScheduledWorkouts);
  }

  void selectDate(DateTime date) {
    final selectedDate = DateUtils.dateOnly(date);

    state = state.copyWith(
      selectedDate: selectedDate,
      visibleMonth: DateTime(selectedDate.year, selectedDate.month),
      filteredWorkouts: _applyFilters(
        workouts: state.workouts,
        selectedDate: selectedDate,
        selectedType: state.selectedType,
      ),
    );
  }

  void showMonth(DateTime month) {
    state = state.copyWith(visibleMonth: DateTime(month.year, month.month));
  }

  void filterWorkouts({
    DateTime? selectedDate,
    WorkoutType? selectedType,
    bool clearDate = false,
    bool clearType = false,
  }) {
    final nextDate = clearDate
        ? null
        : selectedDate == null
        ? state.selectedDate
        : DateUtils.dateOnly(selectedDate);
    final nextType = clearType ? null : selectedType ?? state.selectedType;

    state = state.copyWith(
      selectedDate: nextDate,
      selectedType: nextType,
      filteredWorkouts: _applyFilters(
        workouts: state.workouts,
        selectedDate: nextDate,
        selectedType: nextType,
      ),
    );
  }

  List<ScheduledWorkout> scheduledForDate(DateTime date) {
    return state.scheduledWorkouts
        .where((workout) => DateUtils.isSameDay(workout.scheduledAt, date))
        .toList(growable: false);
  }

  List<Workout> _applyFilters({
    required List<Workout> workouts,
    required DateTime? selectedDate,
    required WorkoutType? selectedType,
  }) {
    return workouts
        .where((workout) {
          final matchesDate =
              selectedDate == null ||
              DateUtils.isSameDay(workout.startedAt, selectedDate);
          final matchesType =
              selectedType == null || workout.type == selectedType;

          return matchesDate && matchesType;
        })
        .toList(growable: false);
  }

  List<ScheduledWorkout> _loadScheduledWorkouts(String userId) {
    final sharedPreferences = ref.read(sharedPreferencesProvider);
    final payload = sharedPreferences?.getString(_scheduledWorkoutsKey(userId));
    if (payload == null || payload.isEmpty) {
      return const <ScheduledWorkout>[];
    }

    try {
      final decoded = jsonDecode(payload) as List<dynamic>;
      final scheduledWorkouts = decoded
          .map(
            (entry) =>
                ScheduledWorkout.fromJson(Map<String, Object?>.from(entry)),
          )
          .where((workout) => workout.userId == userId)
          .toList(growable: false);

      return scheduledWorkouts
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    } on Object {
      return const <ScheduledWorkout>[];
    }
  }

  Future<void> _saveScheduledWorkouts(
    String userId,
    List<ScheduledWorkout> scheduledWorkouts,
  ) async {
    final sharedPreferences = ref.read(sharedPreferencesProvider);
    if (sharedPreferences == null) {
      return;
    }

    final payload = jsonEncode(
      scheduledWorkouts.map((workout) => workout.toJson()).toList(),
    );
    await sharedPreferences.setString(_scheduledWorkoutsKey(userId), payload);
  }

  String _scheduledWorkoutsKey(String userId) {
    return 'workout_scheduled_workouts_$userId';
  }
}
