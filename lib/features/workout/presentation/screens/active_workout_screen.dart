import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/premium_components.dart';
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
      return LigaPremiumScaffold(
        appBar: AppBar(title: Text(l10n.workoutActiveTitle)),
        child: Center(child: Text(l10n.workoutNoActiveSession)),
      );
    }

    final isRunning = state.status == WorkoutSessionStatus.running;

    return LigaPremiumScaffold(
      appBar: AppBar(title: Text(l10n.workoutActiveTitle)),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _LiveTrainingHero(
                  elapsed: formatWorkoutDuration(state.elapsed),
                  isRunning: isRunning,
                  calories: formatWorkoutCalories(state.calories),
                  distance: formatWorkoutDistance(state.distanceMeters),
                  caloriesLabel: l10n.workoutMetricCalories,
                  distanceLabel: l10n.workoutMetricDistance,
                ).premiumEntrance(),
                const SizedBox(height: 18),
                if (state.shouldAskForRouteMap)
                  _RouteMapPromptCard(
                    title: l10n.workoutRoutePromptTitle,
                    message: l10n.workoutRoutePromptMessage,
                    needMapLabel: l10n.workoutRoutePromptNeedMap,
                    skipLabel: l10n.workoutRoutePromptSkip,
                    onNeedMap: controller.requestRouteMap,
                    onSkip: controller.skipRouteMap,
                  ).premiumEntrance(delayMs: 120)
                else if (state.shouldShowLocationEnableRequest)
                  _LocationEnableCard(
                    title: l10n.workoutRouteEnableLocationTitle,
                    message: l10n.workoutRouteEnableLocationMessage,
                    openSettingsLabel: l10n.workoutRouteOpenLocationSettings,
                    checkAgainLabel: l10n.workoutRouteCheckAgain,
                    onOpenSettings: controller.openLocationSettings,
                    onCheckAgain: controller.requestRouteMap,
                  ).premiumEntrance(delayMs: 120)
                else
                  GlassCard(
                    heroTag: 'workout-route-map',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: l10n.workoutRouteMapTitle,
                          subtitle: state.isLocationTrackingAvailable
                              ? l10n.workoutRouteWaitingForSignal
                              : l10n.workoutRouteMissing,
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: WorkoutRouteMap(
                            route: state.route,
                            emptyMessage: l10n.workoutRouteMissing,
                            fullscreenTooltip: l10n.workoutRouteFullscreen,
                            fullscreenTitle: l10n.workoutRouteMapTitle,
                            waitingMessage: l10n.workoutRouteWaitingForSignal,
                            showWaitingState: state.isLocationTrackingAvailable,
                          ),
                        ),
                      ],
                    ),
                  ).premiumEntrance(delayMs: 120),
                if (!state.isLocationTrackingAvailable &&
                    !state.shouldAskForRouteMap) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.workoutGpsUnavailable,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: AppKeys.workoutPauseButton,
                        onPressed: isRunning
                            ? controller.pauseWorkout
                            : controller.resumeWorkout,
                        icon: Icon(
                          isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          isRunning
                              ? l10n.workoutActivePause
                              : l10n.workoutActiveResume,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
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
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(l10n.workoutActiveStop),
                      ),
                    ),
                  ],
                ).premiumEntrance(delayMs: 180),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveTrainingHero extends StatelessWidget {
  const _LiveTrainingHero({
    required this.elapsed,
    required this.isRunning,
    required this.calories,
    required this.distance,
    required this.caloriesLabel,
    required this.distanceLabel,
  });

  final String elapsed;
  final bool isRunning;
  final String calories;
  final String distance;
  final String caloriesLabel;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      borderRadius: 36,
      tint: colorScheme.primary.withValues(alpha: 0.22),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _LiveStatusPill(isRunning: isRunning),
              const Spacer(),
              Icon(Icons.sensors_rounded, color: colorScheme.secondary),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox.square(
            dimension: 228,
            child: AnimatedProgressRing(
              progress: isRunning ? 0.78 : 0.54,
              color: isRunning ? colorScheme.secondary : colorScheme.tertiary,
              strokeWidth: 13,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    elapsed,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRunning ? 'LIVE TRAINING' : 'PAUSED',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TrainingMetric(
                  label: caloriesLabel,
                  value: calories,
                  icon: Icons.local_fire_department_rounded,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TrainingMetric(
                  label: distanceLabel,
                  value: distance,
                  icon: Icons.route_rounded,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveStatusPill extends StatelessWidget {
  const _LiveStatusPill({required this.isRunning});

  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final color = isRunning
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.tertiary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ).animate().fade(begin: 0.55, end: 1, duration: LigaMotion.fast),
            const SizedBox(width: 8),
            Text(
              isRunning ? 'Recording' : 'Paused',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingMetric extends StatelessWidget {
  const _TrainingMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
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
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: message),
          const SizedBox(height: 14),
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
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, subtitle: message),
          const SizedBox(height: 14),
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
    );
  }
}
