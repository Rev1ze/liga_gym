import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_type.dart';
import '../providers/workout_providers.dart';

@immutable
class WorkoutListState {
  const WorkoutListState({
    this.isLoading = false,
    this.workouts = const <Workout>[],
    this.filteredWorkouts = const <Workout>[],
    this.selectedDate,
    this.selectedType,
  });

  final bool isLoading;
  final List<Workout> workouts;
  final List<Workout> filteredWorkouts;
  final DateTime? selectedDate;
  final WorkoutType? selectedType;

  WorkoutListState copyWith({
    bool? isLoading,
    List<Workout>? workouts,
    List<Workout>? filteredWorkouts,
    Object? selectedDate = _sentinel,
    Object? selectedType = _sentinel,
  }) {
    return WorkoutListState(
      isLoading: isLoading ?? this.isLoading,
      workouts: workouts ?? this.workouts,
      filteredWorkouts: filteredWorkouts ?? this.filteredWorkouts,
      selectedDate: selectedDate == _sentinel
          ? this.selectedDate
          : selectedDate as DateTime?,
      selectedType: selectedType == _sentinel
          ? this.selectedType
          : selectedType as WorkoutType?,
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

    state = state.copyWith(
      isLoading: false,
      workouts: workouts,
      filteredWorkouts: _applyFilters(
        workouts: workouts,
        selectedDate: state.selectedDate,
        selectedType: state.selectedType,
      ),
    );
  }

  void filterWorkouts({
    DateTime? selectedDate,
    WorkoutType? selectedType,
    bool clearDate = false,
    bool clearType = false,
  }) {
    final nextDate = clearDate ? null : selectedDate ?? state.selectedDate;
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
}
