import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/workout_session_controller.dart';
import '../providers/workout_providers.dart';
import '../utils/workout_formatters.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(workoutSessionControllerProvider);
    final controller = ref.read(workoutSessionControllerProvider.notifier);

    final hasActiveSession =
        state.status == WorkoutSessionStatus.running ||
        state.status == WorkoutSessionStatus.paused;

    if (!hasActiveSession) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.workoutActiveTitle)),
        body: Center(child: Text(l10n.workoutNoActiveSession)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutActiveTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        formatWorkoutDuration(state.elapsed),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _MetricTile(
                            label: l10n.workoutMetricCalories,
                            value: formatWorkoutCalories(state.calories),
                          ),
                          _MetricTile(
                            label: l10n.workoutMetricDistance,
                            value: formatWorkoutDistance(state.distanceMeters),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!state.isLocationTrackingAvailable)
                Text(
                  l10n.workoutGpsUnavailable,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: AppKeys.workoutPauseButton,
                      onPressed: state.status == WorkoutSessionStatus.running
                          ? controller.pauseWorkout
                          : controller.resumeWorkout,
                      child: Text(
                        state.status == WorkoutSessionStatus.running
                            ? l10n.workoutActivePause
                            : l10n.workoutActiveResume,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: AppKeys.workoutStopButton,
                      onPressed: () {
                        final workout = controller.stopWorkout();
                        if (workout == null || !context.mounted) {
                          return;
                        }

                        Navigator.of(
                          context,
                        ).pushReplacementNamed(AppRoutes.workoutResult);
                      },
                      child: Text(l10n.workoutActiveStop),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
