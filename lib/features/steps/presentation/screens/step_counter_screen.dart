import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/navigation/app_routes.dart';
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

    return Scaffold(
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: todayStepsState.when(
                  data: (steps) => goalState.when(
                    data: (goal) =>
                        _StepProgressContent(steps: steps, goal: goal),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Text(l10n.errorUnknown),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Text(l10n.errorUnknown),
                ),
              ),
            ),
          ],
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

    return Column(
      children: [
        Text(
          l10n.stepCounterToday,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 18,
                  color: colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              SizedBox(
                width: 240,
                height: 240,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 18,
                      color: isGoalReached
                          ? const Color(0xFF16A34A)
                          : colorScheme.primary,
                      backgroundColor: Colors.transparent,
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGoalReached
                        ? Icons.emoji_events_rounded
                        : Icons.directions_walk_rounded,
                    size: 34,
                    color: isGoalReached
                        ? const Color(0xFF16A34A)
                        : colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    NumberFormat.decimalPattern().format(steps),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.stepCounterGoal(goal.toString()),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isGoalReached
              ? l10n.stepGoalReachedInline
              : l10n.stepCounterRemaining(
                  (goal - steps).clamp(0, goal).toString(),
                ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isGoalReached
                ? const Color(0xFF16A34A)
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.stepCounterTodayHint,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}
