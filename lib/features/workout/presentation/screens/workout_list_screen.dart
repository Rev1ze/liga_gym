import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/notifications/app_notification_service.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/domain/entities/daily_profile_metrics.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../domain/entities/scheduled_workout.dart';
import '../../domain/entities/workout.dart';
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
      _loadUserWorkouts();
    });
  }

  Future<void> _loadUserWorkouts() async {
    await ref.read(workoutListControllerProvider.notifier).loadUserWorkouts();
    if (!mounted) {
      return;
    }

    await _scheduleWorkoutReminders(
      ref.read(workoutListControllerProvider).scheduledWorkouts,
    );
  }

  Future<void> _showWorkoutEntryDialog([DateTime? initialDate]) async {
    final l10n = AppLocalizations.of(context)!;
    final copy = _WorkoutPageCopy(l10n);
    final mode = _isPastDate(initialDate ?? DateTime.now())
        ? _WorkoutEntryMode.completed
        : _WorkoutEntryMode.planned;
    final draft = await showDialog<_WorkoutEntryDraft>(
      context: context,
      builder: (context) => _WorkoutEntryDialog(
        l10n: l10n,
        copy: copy,
        initialDate: initialDate,
        mode: mode,
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    switch (draft.mode) {
      case _WorkoutEntryMode.planned:
        final workout = await ref
            .read(workoutListControllerProvider.notifier)
            .scheduleWorkout(
              type: draft.type,
              scheduledAt: draft.dateTime,
              duration: draft.duration,
              note: draft.note,
            );
        if (workout != null && mounted) {
          await _scheduleWorkoutReminder(workout);
        }
      case _WorkoutEntryMode.completed:
        await ref
            .read(workoutListControllerProvider.notifier)
            .addCompletedWorkout(
              type: draft.type,
              startedAt: draft.dateTime,
              duration: draft.duration,
              distanceMeters: draft.distanceMeters,
            );
    }
  }

  Future<void> _scheduleWorkoutReminders(
    List<ScheduledWorkout> scheduledWorkouts,
  ) async {
    for (final workout in scheduledWorkouts) {
      await _scheduleWorkoutReminder(workout);
    }
  }

  Future<void> _scheduleWorkoutReminder(ScheduledWorkout workout) async {
    final l10n = AppLocalizations.of(context)!;
    final copy = _WorkoutPageCopy(l10n);
    await AppNotificationService.scheduleWorkoutReminder(
      workoutId: workout.id,
      scheduledAt: workout.scheduledAt,
      title: copy.workoutReminderTitle,
      body: copy.workoutReminderBody(localizeWorkoutType(l10n, workout.type)),
    );
  }

  Future<void> _showDaySummary(DateTime date) async {
    final selectedDate = DateUtils.dateOnly(date);
    final state = ref.read(workoutListControllerProvider);
    final scheduledWorkouts = state.scheduledWorkouts
        .where(
          (workout) => DateUtils.isSameDay(workout.scheduledAt, selectedDate),
        )
        .toList(growable: false);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DailySummarySheet(
        date: selectedDate,
        scheduledWorkouts: scheduledWorkouts,
        copy: _WorkoutPageCopy(AppLocalizations.of(context)!),
        l10n: AppLocalizations.of(context)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final copy = _WorkoutPageCopy(l10n);
    final state = ref.watch(workoutListControllerProvider);
    final selectedDate =
        state.selectedDate ?? DateUtils.dateOnly(DateTime.now());
    final visibleMonth =
        state.visibleMonth ?? DateTime(selectedDate.year, selectedDate.month);
    final selectedPlans = state.scheduledWorkouts
        .where((plan) => DateUtils.isSameDay(plan.scheduledAt, selectedDate))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutListTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserWorkouts,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _PrimaryActionsCard(
                copy: copy,
                selectedDate: selectedDate,
                onStartWorkout: () =>
                    Navigator.of(context).pushNamed(AppRoutes.startWorkout),
                onPlanWorkout: () => _showWorkoutEntryDialog(selectedDate),
                onOpenHistory: () =>
                    Navigator.of(context).pushNamed(AppRoutes.workoutHistory),
              ),
              const SizedBox(height: 16),
              _WorkoutCalendarCard(
                copy: copy,
                selectedDate: selectedDate,
                visibleMonth: visibleMonth,
                workouts: state.workouts,
                scheduledWorkouts: state.scheduledWorkouts,
                onPreviousMonth: () => ref
                    .read(workoutListControllerProvider.notifier)
                    .showMonth(
                      DateTime(visibleMonth.year, visibleMonth.month - 1),
                    ),
                onNextMonth: () => ref
                    .read(workoutListControllerProvider.notifier)
                    .showMonth(
                      DateTime(visibleMonth.year, visibleMonth.month + 1),
                    ),
                onSelectDate: (date) => ref
                    .read(workoutListControllerProvider.notifier)
                    .selectDate(date),
                onOpenDaySummary: _showDaySummary,
              ),
              const SizedBox(height: 16),
              _SelectedDayPlansCard(
                copy: copy,
                l10n: l10n,
                isLoading: state.isLoading,
                selectedDate: selectedDate,
                plans: selectedPlans,
                onPlanWorkout: () => _showWorkoutEntryDialog(selectedDate),
                onOpenDaySummary: () => _showDaySummary(selectedDate),
                onDelete: (id) async {
                  await AppNotificationService.cancelWorkoutReminder(id);
                  await ref
                      .read(workoutListControllerProvider.notifier)
                      .deleteScheduledWorkout(id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionsCard extends StatelessWidget {
  const _PrimaryActionsCard({
    required this.copy,
    required this.selectedDate,
    required this.onStartWorkout,
    required this.onPlanWorkout,
    required this.onOpenHistory,
  });

  final _WorkoutPageCopy copy;
  final DateTime selectedDate;
  final VoidCallback onStartWorkout;
  final VoidCallback onPlanWorkout;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.actionsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStartWorkout,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(copy.startWorkoutButton),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPlanWorkout,
              icon: const Icon(Icons.add_task_rounded),
              label: Text(copy.workoutEntryButton(selectedDate)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onOpenHistory,
              icon: const Icon(Icons.format_list_bulleted_rounded),
              label: Text(copy.historyButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCalendarCard extends StatelessWidget {
  const _WorkoutCalendarCard({
    required this.copy,
    required this.selectedDate,
    required this.visibleMonth,
    required this.workouts,
    required this.scheduledWorkouts,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
    required this.onOpenDaySummary,
  });

  final _WorkoutPageCopy copy;
  final DateTime selectedDate;
  final DateTime visibleMonth;
  final List<Workout> workouts;
  final List<ScheduledWorkout> scheduledWorkouts;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<DateTime> onOpenDaySummary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final days = _buildCalendarDays(visibleMonth);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: copy.previousMonthTooltip,
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    DateFormat(
                      'LLLL yyyy',
                      copy.localeName,
                    ).format(visibleMonth),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: copy.nextMonthTooltip,
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: copy.weekdays
                  .map(
                    (weekday) => Expanded(
                      child: Text(
                        weekday,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final isCurrentMonth = date.month == visibleMonth.month;
                final isSelected = DateUtils.isSameDay(date, selectedDate);
                final hasWorkout = workouts.any(
                  (workout) => DateUtils.isSameDay(workout.startedAt, date),
                );
                final hasPlan = scheduledWorkouts.any(
                  (plan) => DateUtils.isSameDay(plan.scheduledAt, date),
                );

                return _CalendarDayButton(
                  date: date,
                  isCurrentMonth: isCurrentMonth,
                  isSelected: isSelected,
                  hasWorkout: hasWorkout,
                  hasPlan: hasPlan,
                  colorScheme: colorScheme,
                  onTap: () => onSelectDate(date),
                  onDoubleTap: () => onOpenDaySummary(date),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _CalendarLegendDot(
                  color: colorScheme.primary,
                  label: copy.completedLegend,
                ),
                _CalendarLegendDot(
                  color: colorScheme.tertiary,
                  label: copy.plannedLegend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _buildCalendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final gridStart = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    return List.generate(42, (index) => gridStart.add(Duration(days: index)));
  }
}

class _CalendarDayButton extends StatelessWidget {
  const _CalendarDayButton({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.hasWorkout,
    required this.hasPlan,
    required this.colorScheme,
    required this.onTap,
    required this.onDoubleTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool hasWorkout;
  final bool hasPlan;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : isCurrentMonth
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foregroundColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasWorkout)
                    _TinyDot(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                    ),
                  if (hasWorkout && hasPlan) const SizedBox(width: 3),
                  if (hasPlan)
                    _TinyDot(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.tertiary,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayPlansCard extends StatelessWidget {
  const _SelectedDayPlansCard({
    required this.copy,
    required this.l10n,
    required this.isLoading,
    required this.selectedDate,
    required this.plans,
    required this.onPlanWorkout,
    required this.onOpenDaySummary,
    required this.onDelete,
  });

  final _WorkoutPageCopy copy;
  final AppLocalizations l10n;
  final bool isLoading;
  final DateTime selectedDate;
  final List<ScheduledWorkout> plans;
  final VoidCallback onPlanWorkout;
  final VoidCallback onOpenDaySummary;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.plansForDate(_formatWorkoutDate(selectedDate)),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onOpenDaySummary,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(copy.daySummaryButton),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (plans.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.noPlansForDate),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onPlanWorkout,
                    icon: const Icon(Icons.add_task_rounded),
                    label: Text(copy.workoutEntryButton(selectedDate)),
                  ),
                ],
              )
            else
              ...plans.map(
                (plan) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_rounded),
                  title: Text(localizeWorkoutType(l10n, plan.type)),
                  subtitle: Text(
                    [
                      DateFormat('HH:mm').format(plan.scheduledAt),
                      _formatShortDuration(plan.duration, copy),
                      if ((plan.note ?? '').isNotEmpty) plan.note!,
                    ].join(' · '),
                  ),
                  trailing: IconButton(
                    tooltip: copy.deletePlanTooltip,
                    onPressed: () => onDelete(plan.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailySummarySheet extends ConsumerWidget {
  const _DailySummarySheet({
    required this.date,
    required this.scheduledWorkouts,
    required this.copy,
    required this.l10n,
  });

  final DateTime date;
  final List<ScheduledWorkout> scheduledWorkouts;
  final _WorkoutPageCopy copy;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsState = ref.watch(dailyProfileMetricsProvider(date));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: metricsState.when(
          data: (metrics) => _DailySummaryContent(
            metrics: metrics,
            scheduledWorkouts: scheduledWorkouts,
            copy: copy,
            l10n: l10n,
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(copy.daySummaryUnavailable),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}

class _DailySummaryContent extends StatelessWidget {
  const _DailySummaryContent({
    required this.metrics,
    required this.scheduledWorkouts,
    required this.copy,
    required this.l10n,
  });

  final DailyProfileMetrics metrics;
  final List<ScheduledWorkout> scheduledWorkouts;
  final _WorkoutPageCopy copy;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            copy.daySummaryTitle(_formatWorkoutDate(metrics.date)),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _DailyMetricGrid(
            children: [
              _DailyMetricTile(
                icon: Icons.directions_walk_rounded,
                label: copy.stepsLabel,
                value: metrics.steps.toString(),
                subtitle: metrics.hasRecordedSteps
                    ? copy.recordedStepsLabel
                    : copy.estimatedStepsLabel,
              ),
              _DailyMetricTile(
                icon: Icons.restaurant_rounded,
                label: copy.caloriesConsumedLabel,
                value: metrics.caloriesConsumed.toStringAsFixed(0),
                subtitle: copy.kcalLabel,
              ),
              _DailyMetricTile(
                icon: Icons.local_fire_department_rounded,
                label: copy.caloriesBurnedLabel,
                value: metrics.caloriesBurned.toStringAsFixed(0),
                subtitle: copy.kcalLabel,
              ),
              _DailyMetricTile(
                icon: Icons.pie_chart_rounded,
                label: copy.macrosLabel,
                value:
                    '${metrics.proteins.toStringAsFixed(0)}/${metrics.fats.toStringAsFixed(0)}/${metrics.carbs.toStringAsFixed(0)}',
                subtitle: copy.gramsLabel,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(copy.completedWorkoutsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (metrics.workouts.isEmpty)
            Text(copy.noCompletedWorkouts)
          else
            ...metrics.workouts.map(
              (workout) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fitness_center_rounded),
                title: Text(localizeWorkoutType(l10n, workout.type)),
                subtitle: Text(
                  [
                    DateFormat('HH:mm').format(workout.startedAt),
                    _formatShortDuration(workout.duration, copy),
                    '${workout.calories.toStringAsFixed(0)} ${copy.kcalLabel}',
                  ].join(' В· '),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(copy.plannedWorkoutsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (scheduledWorkouts.isEmpty)
            Text(copy.noPlansForDate)
          else
            ...scheduledWorkouts.map(
              (workout) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_rounded),
                title: Text(localizeWorkoutType(l10n, workout.type)),
                subtitle: Text(
                  [
                    DateFormat('HH:mm').format(workout.scheduledAt),
                    _formatShortDuration(workout.duration, copy),
                    if ((workout.note ?? '').isNotEmpty) workout.note!,
                  ].join(' В· '),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            copy.foodEntriesCount(metrics.foodEntriesCount),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyMetricGrid extends StatelessWidget {
  const _DailyMetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 4 : 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: isWide ? 1.35 : 1.2,
          children: children,
        );
      },
    );
  }
}

class _DailyMetricTile extends StatelessWidget {
  const _DailyMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const Spacer(),
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _WorkoutEntryMode { planned, completed }

class _WorkoutEntryDialog extends StatefulWidget {
  const _WorkoutEntryDialog({
    required this.l10n,
    required this.copy,
    required this.initialDate,
    required this.mode,
  });

  final AppLocalizations l10n;
  final _WorkoutPageCopy copy;
  final DateTime? initialDate;
  final _WorkoutEntryMode mode;

  @override
  State<_WorkoutEntryDialog> createState() => _WorkoutEntryDialogState();
}

class _WorkoutEntryDialogState extends State<_WorkoutEntryDialog> {
  late final TextEditingController _noteController;
  WorkoutType _selectedType = WorkoutType.running;
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationMinutes = 45;
  double _distanceKm = 0;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _selectedDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  DateTime get _entryDateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  bool get _isCompletedMode => widget.mode == _WorkoutEntryMode.completed;

  bool get _canSave {
    if (_durationMinutes <= 0 || _distanceKm < 0) {
      return false;
    }

    final now = DateTime.now();
    if (_isCompletedMode) {
      return _entryDateTime.isBefore(now);
    }

    return _entryDateTime.isAfter(now.subtract(const Duration(minutes: 1)));
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _isCompletedMode
          ? DateTime(today.year - 10, today.month, today.day)
          : today,
      lastDate: _isCompletedMode ? today : today.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() => _selectedDate = DateUtils.dateOnly(pickedDate));
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime == null || !mounted) {
      return;
    }

    setState(() => _selectedTime = pickedTime);
  }

  void _submit() {
    Navigator.of(context).pop(
      _WorkoutEntryDraft(
        mode: widget.mode,
        type: _selectedType,
        dateTime: _entryDateTime,
        duration: Duration(minutes: _durationMinutes),
        note: _noteController.text,
        distanceMeters: _distanceKm * 1000,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final copy = widget.copy;

    return AlertDialog(
      title: Text(
        _isCompletedMode ? copy.addPastWorkoutButton : copy.planWorkoutButton,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<WorkoutType>(
              initialValue: _selectedType,
              decoration: InputDecoration(labelText: l10n.workoutTypeLabel),
              items: WorkoutType.values
                  .map(
                    (type) => DropdownMenuItem<WorkoutType>(
                      value: type,
                      child: Text(localizeWorkoutType(l10n, type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_rounded),
              label: Text(_formatWorkoutDate(_selectedDate)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_rounded),
              label: Text(_selectedTime.format(context)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _durationMinutes.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: copy.durationMinutesLabel,
                suffixText: 'min',
              ),
              onChanged: (value) {
                setState(() => _durationMinutes = int.tryParse(value) ?? 0);
              },
            ),
            if (_isCompletedMode) ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _distanceKm.toStringAsFixed(1),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: copy.distanceKmLabel,
                  suffixText: 'km',
                ),
                onChanged: (value) {
                  setState(
                    () => _distanceKm =
                        double.tryParse(value.replaceAll(',', '.')) ?? -1,
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(labelText: copy.planNoteLabel),
                maxLines: 2,
              ),
            ],
            if (!_canSave) ...[
              const SizedBox(height: 12),
              Text(
                _isCompletedMode
                    ? copy.pastWorkoutHint
                    : copy.futureWorkoutHint,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(copy.cancelButton),
        ),
        FilledButton.icon(
          onPressed: _canSave ? _submit : null,
          icon: const Icon(Icons.check_rounded),
          label: Text(_isCompletedMode ? copy.addButton : copy.saveButton),
        ),
      ],
    );
  }
}

class _WorkoutEntryDraft {
  const _WorkoutEntryDraft({
    required this.mode,
    required this.type,
    required this.dateTime,
    required this.duration,
    required this.note,
    required this.distanceMeters,
  });

  final _WorkoutEntryMode mode;
  final WorkoutType type;
  final DateTime dateTime;
  final Duration duration;
  final String note;
  final double distanceMeters;
}

class _CalendarLegendDot extends StatelessWidget {
  const _CalendarLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TinyDot(color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TinyDot extends StatelessWidget {
  const _TinyDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox.square(dimension: 6),
    );
  }
}

class _WorkoutPageCopy {
  _WorkoutPageCopy(AppLocalizations l10n)
    : startWorkoutButton = l10n.workoutStartButton,
      localeName = l10n.localeName,
      _isRu = l10n.localeName.startsWith('ru');

  final String startWorkoutButton;
  final String localeName;
  final bool _isRu;

  List<String> get weekdays => _isRu
      ? const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
      : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get actionsTitle => _isRu ? 'Действия' : 'Actions';
  String get planWorkoutButton =>
      _isRu ? 'Запланировать тренировку' : 'Plan workout';
  String get addPastWorkoutButton =>
      _isRu ? 'Добавить прошедшую тренировку' : 'Add past workout';
  String workoutEntryButton(DateTime date) {
    return _isPastDate(date) ? addPastWorkoutButton : planWorkoutButton;
  }

  String get historyButton => _isRu ? 'Все тренировки' : 'All workouts';
  String get noPlansForDate => _isRu
      ? 'На выбранный день тренировок пока нет.'
      : 'No planned workouts for this day.';
  String get completedLegend => _isRu ? 'Прошло' : 'Completed';
  String get plannedLegend => _isRu ? 'План' : 'Planned';
  String get previousMonthTooltip =>
      _isRu ? 'Предыдущий месяц' : 'Previous month';
  String get nextMonthTooltip => _isRu ? 'Следующий месяц' : 'Next month';
  String get planNoteLabel => _isRu ? 'Заметка' : 'Note';
  String get durationMinutesLabel => _isRu ? 'Длительность' : 'Duration';
  String get futureWorkoutHint => _isRu
      ? 'Выберите будущее время тренировки.'
      : 'Choose a future workout time.';
  String get pastWorkoutHint => _isRu
      ? 'Выберите прошедшее время тренировки.'
      : 'Choose a past workout time.';
  String get cancelButton => _isRu ? 'Отмена' : 'Cancel';
  String get saveButton => _isRu ? 'Сохранить' : 'Save';
  String get addButton => _isRu ? 'Добавить' : 'Add';
  String get deletePlanTooltip => _isRu ? 'Удалить план' : 'Delete plan';
  String get minutesLabel => _isRu ? 'мин' : 'min';
  String get hoursLabel => _isRu ? 'ч' : 'h';
  String get distanceKmLabel => _isRu ? 'Дистанция' : 'Distance';
  String get workoutReminderTitle =>
      _isRu ? 'Скоро тренировка' : 'Workout soon';

  String workoutReminderBody(String workoutType) {
    return _isRu
        ? '$workoutType начнётся примерно через час.'
        : '$workoutType starts in about an hour.';
  }

  String plansForDate(String date) {
    return _isRu ? 'План на $date' : 'Plan for $date';
  }

  String get daySummaryButton => _isRu ? 'Сводка дня' : 'Day summary';
  String get daySummaryUnavailable => _isRu
      ? 'Сводка за этот день пока недоступна.'
      : 'The summary for this day is not available yet.';
  String get stepsLabel => _isRu ? 'Шаги' : 'Steps';
  String get recordedStepsLabel => _isRu ? 'записано' : 'recorded';
  String get estimatedStepsLabel => _isRu ? 'оценка' : 'estimated';
  String get caloriesConsumedLabel => _isRu ? 'Получено' : 'Consumed';
  String get caloriesBurnedLabel => _isRu ? 'Сожжено' : 'Burned';
  String get macrosLabel => _isRu ? 'БЖУ' : 'PFC';
  String get gramsLabel => _isRu ? 'граммы' : 'grams';
  String get kcalLabel => _isRu ? 'ккал' : 'kcal';
  String get completedWorkoutsTitle => _isRu ? 'Тренировки' : 'Workouts';
  String get plannedWorkoutsTitle => _isRu ? 'План' : 'Plan';
  String get noCompletedWorkouts => _isRu
      ? 'Завершённых тренировок за этот день нет.'
      : 'No completed workouts for this day.';

  String daySummaryTitle(String date) {
    return _isRu ? 'Сводка за $date' : 'Summary for $date';
  }

  String foodEntriesCount(int count) {
    return _isRu ? 'Записей питания: $count' : 'Food entries: $count';
  }
}

bool _isPastDate(DateTime date) {
  return DateUtils.dateOnly(date).isBefore(DateUtils.dateOnly(DateTime.now()));
}

String _formatWorkoutDate(DateTime date) {
  return DateFormat('dd.MM.yyyy').format(date);
}

String _formatShortDuration(Duration duration, _WorkoutPageCopy copy) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) {
    return '$minutes ${copy.minutesLabel}';
  }

  return '$hours ${copy.hoursLabel} $minutes ${copy.minutesLabel}';
}
