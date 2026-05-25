import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/step_tracking_service.dart';
import '../providers/step_providers.dart';

class StepCounterScreen extends ConsumerStatefulWidget {
  const StepCounterScreen({super.key});

  @override
  ConsumerState<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends ConsumerState<StepCounterScreen> {
  StreamSubscription<Map<String, dynamic>?>? _stepUpdateSubscription;

  @override
  void initState() {
    super.initState();
    if (isStepTrackingSupportedPlatform) {
      _stepUpdateSubscription = FlutterBackgroundService()
          .on(stepTrackingUpdateEvent)
          .listen((_) {
            ref.invalidate(todayStepCountProvider);
            ref.invalidate(stepGoalProvider);
          });
    }
  }

  @override
  void dispose() {
    _stepUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayStepsState = ref.watch(todayStepCountProvider);
    final goalState = ref.watch(stepGoalProvider);

    return LigaPremiumScaffold(
      appBar: AppBar(
        title: Text(l10n.stepCounterTitle),
        actions: [
          IconButton(
            key: AppKeys.stepScreenSettingsButton,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.stepSettings),
            icon: const Icon(Icons.tune_rounded),
            tooltip: l10n.stepCounterSettingsTitle,
          ),
          IconButton(
            key: AppKeys.stepScreenRefreshButton,
            onPressed: () {
              ref.read(stepScreenControllerProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: todayStepsState.when(
                data: (steps) => goalState.when(
                  data: (goal) =>
                      _StepProgressContent(steps: steps, goal: goal),
                  loading: () => const SkeletonCard(height: 360),
                  error: (_, _) => Text(l10n.errorUnknown),
                ),
                loading: () => const SkeletonCard(height: 360),
                error: (_, _) => Text(l10n.errorUnknown),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepProgressContent extends StatelessWidget {
  const _StepProgressContent({required this.steps, required this.goal});

  final int steps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = goal <= 0 ? 0.0 : (steps / goal).clamp(0, 1).toDouble();
    final isGoalReached = steps >= goal;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = isGoalReached
        ? const Color(0xFFB8FF2C)
        : colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          borderRadius: 36,
          tint: accent.withValues(alpha: 0.16),
          child: Column(
            children: [
              SectionHeader(
                title: l10n.stepCounterToday,
                subtitle: l10n.stepCounterTodayHint,
              ),
              const SizedBox(height: 28),
              SizedBox.square(
                dimension: 260,
                child: AnimatedProgressRing(
                  progress: progress,
                  color: accent,
                  strokeWidth: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGoalReached
                            ? Icons.emoji_events_rounded
                            : Icons.directions_walk_rounded,
                        size: 36,
                        color: accent,
                      ),
                      const SizedBox(height: 12),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: steps.toDouble()),
                        duration: LigaMotion.slow,
                        curve: LigaMotion.easeOut,
                        builder: (context, value, _) {
                          return Text(
                            NumberFormat.decimalPattern().format(value.round()),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.stepCounterGoal(goal.toString()),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                isGoalReached
                    ? l10n.stepGoalReachedInline
                    : l10n.stepCounterRemaining(
                        (goal - steps).clamp(0, goal).toString(),
                      ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              HeatmapStrip(
                values: const [0.52, 0.76, 0.31, 0.84, 0.64, 0.93, 0.71],
                color: accent,
              ),
            ],
          ),
        ).premiumEntrance(),
      ],
    );
  }
}
