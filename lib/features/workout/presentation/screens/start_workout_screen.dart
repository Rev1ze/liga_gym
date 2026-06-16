import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ai_coach/presentation/screens/ai_coach_screen.dart';
import '../../domain/entities/workout_exercise_entry.dart';
import '../../domain/entities/workout_type.dart';
import '../../domain/services/workout_metrics_calculator.dart';
import '../providers/workout_providers.dart';
import '../utils/workout_formatters.dart';

class StartWorkoutScreen extends ConsumerStatefulWidget {
  const StartWorkoutScreen({super.key});

  @override
  ConsumerState<StartWorkoutScreen> createState() => _StartWorkoutScreenState();
}

class _StartWorkoutScreenState extends ConsumerState<StartWorkoutScreen> {
  WorkoutType _selectedType = WorkoutType.running;

  Future<void> _startWorkout() async {
    await ref
        .read(workoutSessionControllerProvider.notifier)
        .startWorkoutTimer(_selectedType);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.activeWorkout);
  }

  Future<void> _addCompletedWorkout() async {
    final draft = await showDialog<_CompletedWorkoutDraft>(
      context: context,
      builder: (context) => const _CompletedWorkoutDialog(),
    );
    if (draft == null || !mounted) {
      return;
    }

    await ref
        .read(workoutListControllerProvider.notifier)
        .addCompletedWorkout(
          type: draft.type,
          startedAt: draft.startedAt,
          duration: draft.duration,
          distanceMeters: draft.distanceMeters,
          calories: draft.calories,
          title: draft.title,
          note: draft.description,
          place: draft.place,
          exercises: draft.exercises,
          isManual: true,
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Тренировка добавлена в историю.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return LigaPremiumScaffold(
      appBar: AppBar(title: Text(l10n.workoutStartTitle)),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    borderRadius: 22,
                    tint: colorScheme.secondary.withValues(alpha: 0.14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.secondary,
                                colorScheme.tertiary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.secondary.withValues(
                                  alpha: 0.34,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 34,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.workoutStartSubtitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<WorkoutType>(
                          initialValue: _selectedType,
                          decoration: InputDecoration(
                            labelText: l10n.workoutTypeLabel,
                            prefixIcon: const Icon(
                              Icons.directions_run_rounded,
                            ),
                          ),
                          items: runningWorkoutTypes
                              .map(
                                (type) => DropdownMenuItem<WorkoutType>(
                                  value: type,
                                  child: Text(localizeWorkoutType(l10n, type)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _selectedType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        HeatmapStrip(
                          values: const [0.7, 0.3, 0.86, 0.52, 0.94, 0.61, 1],
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: AppKeys.workoutStartButton,
                          onPressed: _startWorkout,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l10n.workoutStartButton),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _addCompletedWorkout,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text(
                            'Добавить уже сделанную тренировку',
                          ),
                        ),
                      ],
                    ),
                  ).premiumEntrance(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletedWorkoutDialog extends StatefulWidget {
  const _CompletedWorkoutDialog();

  @override
  State<_CompletedWorkoutDialog> createState() =>
      _CompletedWorkoutDialogState();
}

class _CompletedWorkoutDialogState extends State<_CompletedWorkoutDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeController = TextEditingController();
  final _minutesController = TextEditingController(text: '45');
  final _distanceController = TextEditingController(text: '0');
  final List<WorkoutExerciseEntry> _exercises = <WorkoutExerciseEntry>[];
  WorkoutType _type = WorkoutType.strength;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _placeController.dispose();
    _minutesController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  int get _minutes => int.tryParse(_minutesController.text) ?? 0;

  double get _distanceMeters =>
      (double.tryParse(_distanceController.text.replaceAll(',', '.')) ?? 0) *
      1000;

  Duration get _duration => Duration(minutes: _minutes);

  DateTime get _startedAt => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  double get _estimatedCalories {
    if (_minutes <= 0 || _distanceMeters < 0) {
      return 0;
    }

    return WorkoutMetricsCalculator.calculateCaloriesBurned(
      type: _type,
      duration: _duration,
      distanceMeters: _distanceMeters,
    );
  }

  bool get _canSave {
    return _titleController.text.trim().isNotEmpty &&
        _minutes > 0 &&
        _distanceMeters >= 0 &&
        _startedAt.isBefore(DateTime.now());
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(today.year - 10, today.month, today.day),
      lastDate: today,
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

  Future<void> _addExercise() async {
    final exercise = await showDialog<WorkoutExerciseEntry>(
      context: context,
      builder: (context) => const _CompletedWorkoutExerciseDialog(),
    );
    if (exercise == null || !mounted) {
      return;
    }

    setState(() => _exercises.add(exercise));
  }

  void _askAi() {
    final prompt =
        'Оцени мою тренировку: "${_titleController.text.trim()}". '
        'Тип: ${_type.name}. Описание: ${_descriptionController.text.trim()}. '
        'Место: ${_placeController.text.trim()}. Длительность: $_minutes мин. '
        'Дистанция: ${(_distanceMeters / 1000).toStringAsFixed(2)} км. '
        'Упражнения: ${_exercises.map((item) => item.name).join(', ')}. '
        'Примерно сожжено ${_estimatedCalories.toStringAsFixed(0)} ккал (${_calorieEquivalent(_estimatedCalories)}). '
        'Скажи, насколько тренировка была полезной, что улучшить и как восстановиться.';
    Navigator.of(context).pushNamed(
      AppRoutes.aiCoach,
      arguments: AiCoachRouteArguments(initialPrompt: prompt),
    );
  }

  void _submit() {
    if (!_canSave) {
      setState(() {});
      return;
    }

    Navigator.of(context).pop(
      _CompletedWorkoutDraft(
        type: _type,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        place: _placeController.text.trim(),
        startedAt: _startedAt,
        duration: _duration,
        distanceMeters: _distanceMeters,
        calories: _estimatedCalories,
        exercises: List.unmodifiable(_exercises),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Уже сделанная тренировка'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _placeController,
              decoration: const InputDecoration(
                labelText: 'Место',
                prefixIcon: Icon(Icons.place_rounded),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<WorkoutType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Тип'),
              items: WorkoutType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(localizeWorkoutType(l10n, type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_rounded),
                    label: Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Время',
                      suffixText: 'мин',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Дистанция',
                      suffixText: 'км',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.44),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.22),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_estimatedCalories.toStringAsFixed(0)} ккал · ${_calorieEquivalent(_estimatedCalories)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Добавить упражнение'),
            ),
            if (_exercises.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (var index = 0; index < _exercises.length; index++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fitness_center_rounded),
                  title: Text(_exercises[index].name),
                  subtitle: Text(_formatCompletedExercise(_exercises[index])),
                  trailing: IconButton(
                    onPressed: () => setState(() => _exercises.removeAt(index)),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
            ],
            if (!_canSave) ...[
              const SizedBox(height: 8),
              Text(
                'Заполните название, время и выберите прошедшую дату.',
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        OutlinedButton.icon(
          onPressed: _askAi,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Мнение AI'),
        ),
        FilledButton.icon(
          onPressed: _canSave ? _submit : null,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _CompletedWorkoutDraft {
  const _CompletedWorkoutDraft({
    required this.type,
    required this.title,
    required this.description,
    required this.place,
    required this.startedAt,
    required this.duration,
    required this.distanceMeters,
    required this.calories,
    required this.exercises,
  });

  final WorkoutType type;
  final String title;
  final String description;
  final String place;
  final DateTime startedAt;
  final Duration duration;
  final double distanceMeters;
  final double calories;
  final List<WorkoutExerciseEntry> exercises;
}

class _CompletedWorkoutExerciseDialog extends StatefulWidget {
  const _CompletedWorkoutExerciseDialog();

  @override
  State<_CompletedWorkoutExerciseDialog> createState() =>
      _CompletedWorkoutExerciseDialogState();
}

class _CompletedWorkoutExerciseDialogState
    extends State<_CompletedWorkoutExerciseDialog> {
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      WorkoutExerciseEntry(
        name: name,
        sets: int.tryParse(_setsController.text),
        reps: int.tryParse(_repsController.text),
        weightKg: double.tryParse(_weightController.text.replaceAll(',', '.')),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Упражнение'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Подходы'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Повторы'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Вес',
                suffixText: 'кг',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Заметка'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Добавить'),
        ),
      ],
    );
  }
}

String _formatCompletedExercise(WorkoutExerciseEntry exercise) {
  final parts = <String>[
    if (exercise.sets != null) '${exercise.sets} подх.',
    if (exercise.reps != null) '${exercise.reps} повт.',
    if (exercise.weightKg != null)
      '${exercise.weightKg!.toStringAsFixed(1)} кг',
    if ((exercise.note ?? '').isNotEmpty) exercise.note!,
  ];

  return parts.isEmpty ? 'Выполнено' : parts.join(' · ');
}

String _calorieEquivalent(double calories) {
  if (calories <= 0) {
    return 'добавьте время и дистанцию';
  }
  if (calories < 120) {
    return 'примерно один банан';
  }
  if (calories < 260) {
    return 'примерно один латте';
  }
  if (calories < 450) {
    return 'примерно один бургер';
  }
  return 'почти бургер с картошкой';
}
