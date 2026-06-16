import 'package:flutter/material.dart';

import '../../../../core/widgets/premium_components.dart';
import '../../../water_tracker/presentation/providers/water_tracker_providers.dart';
import '../../../workout/presentation/controllers/workout_list_controller.dart';
import '../../../workout_completion/presentation/providers/workout_completion_providers.dart';

class WaterTrackerCard extends StatelessWidget {
  const WaterTrackerCard({
    super.key,
    required this.water,
    required this.isRu,
    required this.onAdd,
    required this.onRemove,
  });

  final DailyWaterState water;
  final bool isRu;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (water.progress * 100).round();

    return GlassCard(
      tint: colorScheme.primary.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isRu ? 'Вода' : 'Water',
            subtitle: isRu
                ? 'Выпито ${water.consumedMl} / ${water.goalMl} мл'
                : 'Drank ${water.consumedMl} / ${water.goalMl} ml',
            action: SizedBox.square(
              dimension: 58,
              child: AnimatedProgressRing(
                progress: water.progress,
                color: colorScheme.primary,
                strokeWidth: 5,
                child: Icon(
                  Icons.water_drop_rounded,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: water.progress,
              minHeight: 10,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            water.isGoalReached
                ? (isRu ? 'Цель по воде выполнена' : 'Water goal complete')
                : (isRu ? '$percent% дневной цели' : '$percent% of daily goal'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: water.isGoalReached
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in const [100, 250, 500])
                FilledButton.tonalIcon(
                  onPressed: () => onAdd(amount),
                  icon: const Icon(Icons.add_rounded),
                  label: Text('+$amount ${isRu ? 'мл' : 'ml'}'),
                ),
              OutlinedButton.icon(
                onPressed: water.consumedMl == 0 ? null : () => onRemove(100),
                icon: const Icon(Icons.remove_rounded),
                label: Text('-100 ${isRu ? 'мл' : 'ml'}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DailyHabitsSummaryCard extends StatelessWidget {
  const DailyHabitsSummaryCard({
    super.key,
    required this.isRu,
    required this.water,
    required this.workoutState,
    required this.completionState,
    required this.date,
  });

  final bool isRu;
  final DailyWaterState water;
  final WorkoutListState workoutState;
  final WorkoutCompletionState completionState;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final plannedWorkouts = workoutState.scheduledWorkouts
        .where((workout) => DateUtils.isSameDay(workout.scheduledAt, date))
        .toList(growable: false);
    final plannedExercises = workoutState.scheduledExercises
        .where((exercise) => DateUtils.isSameDay(exercise.scheduledAt, date))
        .toList(growable: false);
    final completedWorkouts = workoutState.workouts
        .where((workout) => DateUtils.isSameDay(workout.startedAt, date))
        .length;
    final completionIds = <String>[
      ...plannedWorkouts.map((workout) => workoutCompletionId(workout.id)),
      ...plannedExercises.map((exercise) => exerciseCompletionId(exercise.id)),
    ];
    final plannedCount = completionIds.length;
    final checkedCount = completionState.countCompleted(completionIds);
    final completedCount = plannedCount == 0
        ? completedWorkouts
        : (checkedCount + completedWorkouts).clamp(0, plannedCount);
    final workoutProgress = plannedCount == 0
        ? (completedWorkouts > 0 ? 1.0 : 0.0)
        : completedCount / plannedCount;
    final overallProgress = ((workoutProgress + water.progress) / 2)
        .clamp(0, 1)
        .toDouble();
    final status = _status(overallProgress, plannedCount, completedWorkouts);

    return GlassCard(
      tint: colorScheme.tertiary.withValues(alpha: 0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 78,
            child: AnimatedProgressRing(
              progress: overallProgress,
              color: colorScheme.tertiary,
              strokeWidth: 7,
              child: Text(
                '${(overallProgress * 100).round()}%',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRu ? 'Итог дня' : 'Day summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryPill(
                      icon: Icons.fitness_center_rounded,
                      label: isRu
                          ? '$completedCount / $plannedCount тренировок'
                          : '$completedCount / $plannedCount workouts',
                    ),
                    _SummaryPill(
                      icon: Icons.water_drop_rounded,
                      label: isRu
                          ? '${water.consumedMl} мл воды'
                          : '${water.consumedMl} ml water',
                    ),
                    _SummaryPill(
                      icon: water.isGoalReached
                          ? Icons.verified_rounded
                          : Icons.track_changes_rounded,
                      label: water.isGoalReached
                          ? (isRu ? 'цель воды выполнена' : 'water goal done')
                          : (isRu ? 'цель воды в работе' : 'water in progress'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _status(
    double overallProgress,
    int plannedCount,
    int completedWorkouts,
  ) {
    if (overallProgress >= 0.96) {
      return isRu ? 'Отличный день' : 'Excellent day';
    }
    if (overallProgress >= 0.55) {
      return isRu ? 'Хороший прогресс' : 'Good progress';
    }
    if (plannedCount == 0 && completedWorkouts == 0 && water.consumedMl == 0) {
      return isRu ? 'Сегодня был лёгкий день' : 'Today was a light day';
    }
    return isRu ? 'Можно лучше' : 'Room to improve';
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
