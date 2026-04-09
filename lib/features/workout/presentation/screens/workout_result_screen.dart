import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/workout_save_status.dart';
import '../controllers/workout_session_controller.dart';
import '../providers/workout_providers.dart';
import '../utils/workout_formatters.dart';

class WorkoutResultScreen extends ConsumerWidget {
  const WorkoutResultScreen({super.key});

  Future<void> _saveWorkout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final saveStatus = await ref
          .read(workoutSessionControllerProvider.notifier)
          .saveWorkoutToDatabase();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saveStatus == WorkoutSaveStatus.synced
                ? l10n.workoutSavedSynced
                : l10n.workoutSavedLocalOnly,
          ),
        ),
      );

      ref.invalidate(dashboardAnalyticsProvider);
      ref.read(workoutListControllerProvider.notifier).loadUserWorkouts();
      ref.read(workoutSessionControllerProvider.notifier).reset();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    } on AppException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(workoutSessionControllerProvider);
    final workout = state.completedWorkout;

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.workoutResultTitle)),
        body: Center(child: Text(l10n.workoutNoResult)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutResultTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.workoutResultSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _ResultRow(
                        label: l10n.workoutMetricDuration,
                        value: formatWorkoutDuration(workout.duration),
                      ),
                      const SizedBox(height: 12),
                      _ResultRow(
                        label: l10n.workoutMetricCalories,
                        value: formatWorkoutCalories(workout.calories),
                      ),
                      const SizedBox(height: 12),
                      _ResultRow(
                        label: l10n.workoutMetricDistance,
                        value: formatWorkoutDistance(workout.distanceMeters),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: AppKeys.workoutResultSaveButton,
                        onPressed: state.status == WorkoutSessionStatus.saving
                            ? null
                            : () => _saveWorkout(context, ref),
                        icon: const Icon(Icons.save),
                        label: Text(l10n.workoutResultSave),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
