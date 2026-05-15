import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/workout_session_controller.dart';
import '../providers/workout_providers.dart';
import '../utils/workout_formatters.dart';
import '../widgets/workout_route_map.dart';

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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Column(
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
                              value: formatWorkoutDistance(
                                state.distanceMeters,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (state.shouldAskForRouteMap)
                  _RouteMapPromptCard(
                    title: l10n.workoutRoutePromptTitle,
                    message: l10n.workoutRoutePromptMessage,
                    needMapLabel: l10n.workoutRoutePromptNeedMap,
                    skipLabel: l10n.workoutRoutePromptSkip,
                    onNeedMap: () {
                      controller.requestRouteMap();
                    },
                    onSkip: controller.skipRouteMap,
                  )
                else if (state.shouldShowLocationEnableRequest)
                  _LocationEnableCard(
                    title: l10n.workoutRouteEnableLocationTitle,
                    message: l10n.workoutRouteEnableLocationMessage,
                    openSettingsLabel: l10n.workoutRouteOpenLocationSettings,
                    checkAgainLabel: l10n.workoutRouteCheckAgain,
                    onOpenSettings: () {
                      controller.openLocationSettings();
                    },
                    onCheckAgain: () {
                      controller.requestRouteMap();
                    },
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.workoutRouteMapTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      WorkoutRouteMap(
                        route: state.route,
                        emptyMessage: l10n.workoutRouteMissing,
                        fullscreenTooltip: l10n.workoutRouteFullscreen,
                        fullscreenTitle: l10n.workoutRouteMapTitle,
                        waitingMessage: l10n.workoutRouteWaitingForSignal,
                        showWaitingState: state.isLocationTrackingAvailable,
                      ),
                    ],
                  ),
                if (!state.isLocationTrackingAvailable &&
                    !state.shouldAskForRouteMap)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l10n.workoutGpsUnavailable,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
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
          ],
        ),
      ),
    );
  }
}

class _RouteMapPromptCard extends StatelessWidget {
  const _RouteMapPromptCard({
    required this.title,
    required this.message,
    required this.needMapLabel,
    required this.skipLabel,
    required this.onNeedMap,
    required this.onSkip,
  });

  final String title;
  final String message;
  final String needMapLabel;
  final String skipLabel;
  final VoidCallback onNeedMap;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onNeedMap,
                  icon: const Icon(Icons.map_rounded),
                  label: Text(needMapLabel),
                ),
                TextButton(onPressed: onSkip, child: Text(skipLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationEnableCard extends StatelessWidget {
  const _LocationEnableCard({
    required this.title,
    required this.message,
    required this.openSettingsLabel,
    required this.checkAgainLabel,
    required this.onOpenSettings,
    required this.onCheckAgain,
  });

  final String title;
  final String message;
  final String openSettingsLabel;
  final String checkAgainLabel;
  final VoidCallback onOpenSettings;
  final VoidCallback onCheckAgain;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.location_on_rounded),
                  label: Text(openSettingsLabel),
                ),
                OutlinedButton.icon(
                  onPressed: onCheckAgain,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(checkAgainLabel),
                ),
              ],
            ),
          ],
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
