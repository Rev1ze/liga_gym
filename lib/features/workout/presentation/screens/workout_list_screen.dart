import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
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
      ref.read(workoutListControllerProvider.notifier).loadUserWorkouts();
    });
  }

  Future<void> _showScheduleDialog([DateTime? initialDate]) async {
    final l10n = AppLocalizations.of(context)!;
    final copy = _WorkoutPageCopy(l10n);
    final draft = await showDialog<_WorkoutPlanDraft>(
      context: context,
      builder: (context) => _ScheduleWorkoutDialog(
        l10n: l10n,
        copy: copy,
        initialDate: initialDate,
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    await ref
        .read(workoutListControllerProvider.notifier)
        .scheduleWorkout(
          type: draft.type,
          scheduledAt: draft.scheduledAt,
          duration: draft.duration,
          note: draft.note,
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
          onRefresh: () => ref
              .read(workoutListControllerProvider.notifier)
              .loadUserWorkouts(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _PrimaryActionsCard(
                copy: copy,
                onStartWorkout: () =>
                    Navigator.of(context).pushNamed(AppRoutes.startWorkout),
                onPlanWorkout: () => _showScheduleDialog(selectedDate),
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
              ),
              const SizedBox(height: 16),
              _SelectedDayPlansCard(
                copy: copy,
                l10n: l10n,
                isLoading: state.isLoading,
                selectedDate: selectedDate,
                plans: selectedPlans,
                onPlanWorkout: () => _showScheduleDialog(selectedDate),
                onDelete: (id) => ref
                    .read(workoutListControllerProvider.notifier)
                    .deleteScheduledWorkout(id),
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
    required this.onStartWorkout,
    required this.onPlanWorkout,
    required this.onOpenHistory,
  });

  final _WorkoutPageCopy copy;
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
              label: Text(copy.planWorkoutButton),
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
  });

  final _WorkoutPageCopy copy;
  final DateTime selectedDate;
  final DateTime visibleMonth;
  final List<Workout> workouts;
  final List<ScheduledWorkout> scheduledWorkouts;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

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
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool hasWorkout;
  final bool hasPlan;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

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
    required this.onDelete,
  });

  final _WorkoutPageCopy copy;
  final AppLocalizations l10n;
  final bool isLoading;
  final DateTime selectedDate;
  final List<ScheduledWorkout> plans;
  final VoidCallback onPlanWorkout;
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
                    label: Text(copy.planWorkoutButton),
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

class _ScheduleWorkoutDialog extends StatefulWidget {
  const _ScheduleWorkoutDialog({
    required this.l10n,
    required this.copy,
    required this.initialDate,
  });

  final AppLocalizations l10n;
  final _WorkoutPageCopy copy;
  final DateTime? initialDate;

  @override
  State<_ScheduleWorkoutDialog> createState() => _ScheduleWorkoutDialogState();
}

class _ScheduleWorkoutDialogState extends State<_ScheduleWorkoutDialog> {
  late final TextEditingController _noteController;
  WorkoutType _selectedType = WorkoutType.running;
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationMinutes = 45;

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

  DateTime get _scheduledAt => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  bool get _canSave {
    return _durationMinutes > 0 &&
        _scheduledAt.isAfter(
          DateTime.now().subtract(const Duration(minutes: 1)),
        );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      _WorkoutPlanDraft(
        type: _selectedType,
        scheduledAt: _scheduledAt,
        duration: Duration(minutes: _durationMinutes),
        note: _noteController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final copy = widget.copy;

    return AlertDialog(
      title: Text(copy.planWorkoutButton),
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
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: copy.planNoteLabel),
              maxLines: 2,
            ),
            if (!_canSave) ...[
              const SizedBox(height: 12),
              Text(
                copy.futureWorkoutHint,
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
          label: Text(copy.saveButton),
        ),
      ],
    );
  }
}

class _WorkoutPlanDraft {
  const _WorkoutPlanDraft({
    required this.type,
    required this.scheduledAt,
    required this.duration,
    required this.note,
  });

  final WorkoutType type;
  final DateTime scheduledAt;
  final Duration duration;
  final String note;
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
  String get cancelButton => _isRu ? 'Отмена' : 'Cancel';
  String get saveButton => _isRu ? 'Сохранить' : 'Save';
  String get deletePlanTooltip => _isRu ? 'Удалить план' : 'Delete plan';
  String get minutesLabel => _isRu ? 'мин' : 'min';
  String get hoursLabel => _isRu ? 'ч' : 'h';

  String plansForDate(String date) {
    return _isRu ? 'План на $date' : 'Plan for $date';
  }
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
