import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/workout_type.dart';
import '../providers/workout_providers.dart';
import '../utils/workout_formatters.dart';

class WorkoutListScreen extends ConsumerStatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  ConsumerState<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends ConsumerState<WorkoutListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutListControllerProvider.notifier).loadUserWorkouts();
    });
  }

  Future<void> _pickDate() async {
    final currentDate = ref.read(workoutListControllerProvider).selectedDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      ref
          .read(workoutListControllerProvider.notifier)
          .filterWorkouts(selectedDate: pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(workoutListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.startWorkout),
        label: Text(l10n.workoutStartButton),
        icon: const Icon(Icons.play_arrow),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      state.selectedDate == null
                          ? l10n.workoutFilterDate
                          : formatWorkoutTimestamp(state.selectedDate!),
                    ),
                  ),
                  DropdownButton<WorkoutType?>(
                    value: state.selectedType,
                    hint: Text(l10n.workoutFilterType),
                    items: [
                      DropdownMenuItem<WorkoutType?>(
                        value: null,
                        child: Text(l10n.workoutFilterAllTypes),
                      ),
                      ...WorkoutType.values.map(
                        (type) => DropdownMenuItem<WorkoutType?>(
                          value: type,
                          child: Text(localizeWorkoutType(l10n, type)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      ref
                          .read(workoutListControllerProvider.notifier)
                          .filterWorkouts(
                            selectedType: value,
                            clearType: value == null,
                          );
                    },
                  ),
                  if (state.selectedDate != null || state.selectedType != null)
                    TextButton(
                      onPressed: () {
                        ref
                            .read(workoutListControllerProvider.notifier)
                            .filterWorkouts(clearDate: true, clearType: true);
                      },
                      child: Text(l10n.workoutFilterClear),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.filteredWorkouts.isEmpty
                    ? Center(
                        child: Text(
                          l10n.workoutListEmpty,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.filteredWorkouts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final workout = state.filteredWorkouts[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          localizeWorkoutType(
                                            l10n,
                                            workout.type,
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                      if (!workout.isSynced)
                                        Chip(
                                          label: Text(
                                            l10n.workoutSavedLocalOnly,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formatWorkoutTimestamp(workout.startedAt),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        '${l10n.workoutMetricDuration}: ${formatWorkoutDuration(workout.duration)}',
                                      ),
                                      Text(
                                        '${l10n.workoutMetricCalories}: ${formatWorkoutCalories(workout.calories)}',
                                      ),
                                      Text(
                                        '${l10n.workoutMetricDistance}: ${formatWorkoutDistance(workout.distanceMeters)}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
