import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/notifications/app_notification_service.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../ai_coach/presentation/screens/ai_coach_screen.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../../domain/entities/custom_exercise.dart';
import '../providers/exercise_library_providers.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  bool _favoritesOnly = false;
  String _category = 'all';

  Future<void> _upsertExercise([CustomExercise? initial]) async {
    final exercise = await showDialog<CustomExercise>(
      context: context,
      builder: (context) => _ExerciseEditorDialog(initial: initial),
    );
    if (exercise == null) {
      return;
    }

    await ref.read(exerciseLibraryProvider.notifier).saveExercise(exercise);
  }

  Future<void> _confirmDeleteExercise(CustomExercise exercise) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить упражнение?'),
        content: Text(
          'Вы реально хотите удалить "${exercise.title}"? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) {
      return;
    }

    await ref
        .read(exerciseLibraryProvider.notifier)
        .deleteExercise(exercise.id);
  }

  Future<void> _scheduleExercise(CustomExercise exercise) async {
    final draft = await showDialog<_ExerciseScheduleDraft>(
      context: context,
      builder: (context) => _ExerciseScheduleDialog(exercise: exercise),
    );
    if (draft == null || !mounted) {
      return;
    }

    final scheduledExercise = await ref
        .read(workoutListControllerProvider.notifier)
        .scheduleExercise(
          exerciseId: exercise.id,
          exerciseTitle: exercise.title,
          scheduledAt: draft.dateTime,
          sets: draft.sets,
          reps: draft.reps,
          note: draft.note,
          iconName: exercise.iconName,
          avatarDataUrl: exercise.avatarDataUrl,
        );
    if (scheduledExercise == null) {
      return;
    }

    await AppNotificationService.scheduleWorkoutReminder(
      workoutId: scheduledExercise.id,
      scheduledAt: scheduledExercise.scheduledAt,
      title: 'Скоро упражнение',
      body: '${exercise.title} запланировано на сегодня.',
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${exercise.title}: ${DateFormat('dd.MM HH:mm').format(draft.dateTime)}',
        ),
      ),
    );
  }

  void _assessExercise(CustomExercise exercise) {
    final category = [
      exercise.defaultCategory,
      if (exercise.customCategory.isNotEmpty) exercise.customCategory,
    ].join(', ');
    final prompt =
        'Оцени упражнение "${exercise.title}" для моего плана тренировок. '
        'Категории: $category. Мышцы: ${exercise.muscleGroups}. '
        'Оборудование: ${exercise.equipment}. Техника: ${exercise.techniqueText}. '
        'Дай оценку пользы, рисков, техники и кому оно подходит.';

    Navigator.of(context).pushNamed(
      AppRoutes.aiCoach,
      arguments: AiCoachRouteArguments(initialPrompt: prompt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exerciseLibraryProvider);
    final visibleExercises = exercises
        .where((exercise) {
          final matchesFavorite = !_favoritesOnly || exercise.isFavorite;
          final matchesCategory =
              _category == 'all' || exercise.defaultCategory == _category;
          return matchesFavorite && matchesCategory;
        })
        .toList(growable: false);

    return LigaPremiumScaffold(
      appBar: AppBar(
        title: const Text('Упражнения'),
        actions: [
          IconButton(
            tooltip: 'Добавить упражнение',
            onPressed: () => _upsertExercise(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upsertExercise(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _ExerciseLibraryHero(exercises: exercises),
            const SizedBox(height: 12),
            _ExerciseFilters(
              favoritesOnly: _favoritesOnly,
              category: _category,
              onFavoritesChanged: (value) =>
                  setState(() => _favoritesOnly = value),
              onCategoryChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 12),
            if (visibleExercises.isEmpty)
              const GlassCard(
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Text('Пока нет упражнений в этой подборке.'),
                ),
              )
            else
              for (final exercise in visibleExercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExerciseCard(
                    exercise: exercise,
                    onEdit: () => _upsertExercise(exercise),
                    onDelete: () => _confirmDeleteExercise(exercise),
                    onFavorite: () => ref
                        .read(exerciseLibraryProvider.notifier)
                        .toggleFavorite(exercise),
                    onAssess: () => _assessExercise(exercise),
                    onSchedule: () => _scheduleExercise(exercise),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseLibraryHero extends StatelessWidget {
  const _ExerciseLibraryHero({required this.exercises});

  final List<CustomExercise> exercises;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final favoriteCount = exercises.where((item) => item.isFavorite).length;
    final customCategories = exercises
        .map((item) => item.customCategory.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .length;

    return GlassCard(
      borderRadius: 20,
      tint: colorScheme.primary.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [colorScheme.secondary, colorScheme.tertiary],
                  ),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Библиотека упражнений',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExercisePill(
                icon: Icons.inventory_2_rounded,
                label: '${exercises.length} всего',
              ),
              _ExercisePill(
                icon: Icons.star_rounded,
                label: '$favoriteCount любимых',
              ),
              _ExercisePill(
                icon: Icons.sell_rounded,
                label: '$customCategories своих категорий',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseFilters extends StatelessWidget {
  const _ExerciseFilters({
    required this.favoritesOnly,
    required this.category,
    required this.onFavoritesChanged,
    required this.onCategoryChanged,
  });

  final bool favoritesOnly;
  final String category;
  final ValueChanged<bool> onFavoritesChanged;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              selected: favoritesOnly,
              label: const Text('Любимые'),
              avatar: const Icon(Icons.star_rounded, size: 18),
              onSelected: onFavoritesChanged,
            ),
            DropdownButton<String>(
              value: category,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Все категории')),
                DropdownMenuItem(value: 'strength', child: Text('Силовое')),
                DropdownMenuItem(value: 'cardio', child: Text('Кардио')),
                DropdownMenuItem(value: 'mobility', child: Text('Мобильность')),
                DropdownMenuItem(
                  value: 'recovery',
                  child: Text('Восстановление'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onCategoryChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
    required this.onFavorite,
    required this.onAssess,
    required this.onSchedule,
  });

  final CustomExercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  final VoidCallback onAssess;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExerciseThumb(
                  avatarDataUrl: exercise.avatarDataUrl,
                  iconName: exercise.iconName,
                  photoDataUrls: exercise.photoDataUrls,
                  size: 72,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _ExercisePill(
                            icon: _exerciseIconFromName(exercise.iconName),
                            label: _categoryLabel(exercise.defaultCategory),
                          ),
                          if (exercise.customCategory.isNotEmpty)
                            _ExercisePill(
                              icon: Icons.sell_rounded,
                              label: exercise.customCategory,
                            ),
                          if (exercise.muscleGroups.isNotEmpty)
                            _ExercisePill(
                              icon: Icons.accessibility_new_rounded,
                              label: exercise.muscleGroups,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: exercise.isFavorite
                      ? 'Убрать из любимых'
                      : 'В любимые',
                  onPressed: onFavorite,
                  icon: Icon(
                    exercise.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                  ),
                ),
              ],
            ),
            if (exercise.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(exercise.description),
            ],
            if (exercise.techniqueText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(exercise.techniqueText),
            ],
            if (exercise.photoDataUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: exercise.photoDataUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final bytes = _decodeDataUrl(exercise.photoDataUrls[index]);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox.square(
                        dimension: 58,
                        child: bytes == null
                            ? const ColoredBox(color: Colors.black12)
                            : Image.memory(bytes, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onSchedule,
                  icon: const Icon(Icons.event_available_rounded),
                  label: const Text('Запланировать'),
                ),
                FilledButton.icon(
                  onPressed: onAssess,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Оценить с AI'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Редактировать'),
                ),
                IconButton.outlined(
                  tooltip: 'Удалить',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  const _ExerciseThumb({
    required this.avatarDataUrl,
    required this.iconName,
    required this.photoDataUrls,
    this.size = 58,
  });

  final String avatarDataUrl;
  final String iconName;
  final List<String> photoDataUrls;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = avatarDataUrl.isNotEmpty
        ? _decodeDataUrl(avatarDataUrl)
        : photoDataUrls.isEmpty
        ? null
        : _decodeDataUrl(photoDataUrls.first);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: size,
        child: image == null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.secondaryContainer,
                      colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Icon(
                  _exerciseIconFromName(iconName),
                  color: colorScheme.onSecondaryContainer,
                  size: size * 0.48,
                ),
              )
            : Image.memory(image, fit: BoxFit.cover),
      ),
    );
  }
}

class _ExercisePill extends StatelessWidget {
  const _ExercisePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colorScheme.primary),
            const SizedBox(width: 5),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _ExerciseEditorDialog extends StatefulWidget {
  const _ExerciseEditorDialog({this.initial});

  final CustomExercise? initial;

  @override
  State<_ExerciseEditorDialog> createState() => _ExerciseEditorDialogState();
}

class _ExerciseEditorDialogState extends State<_ExerciseEditorDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _muscleGroups = TextEditingController();
  final _equipment = TextEditingController();
  final _technique = TextEditingController();
  final _customCategory = TextEditingController();
  final List<String> _photoDataUrls = <String>[];
  String _avatarDataUrl = '';
  String _iconName = 'dumbbell';
  String _defaultCategory = 'strength';
  bool _isFavorite = false;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) {
      return;
    }

    _title.text = initial.title;
    _description.text = initial.description;
    _muscleGroups.text = initial.muscleGroups;
    _equipment.text = initial.equipment;
    _technique.text = initial.techniqueText;
    _customCategory.text = initial.customCategory;
    _defaultCategory = initial.defaultCategory;
    _avatarDataUrl = initial.avatarDataUrl;
    _iconName = initial.iconName;
    _isFavorite = initial.isFavorite;
    _photoDataUrls.addAll(initial.photoDataUrls);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _muscleGroups.dispose();
    _equipment.dispose();
    _technique.dispose();
    _customCategory.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final dataUrl = await _pickImageDataUrl();
    if (dataUrl == null || !mounted) {
      return;
    }

    setState(() => _avatarDataUrl = dataUrl);
  }

  Future<void> _pickPhoto() async {
    final dataUrl = await _pickImageDataUrl();
    if (dataUrl == null || !mounted) {
      return;
    }

    setState(() => _photoDataUrls.add(dataUrl));
  }

  Future<String?> _pickImageDataUrl() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    if (file == null) {
      return null;
    }

    setState(() => _isPicking = true);
    final bytes = await file.readAsBytes();
    if (!mounted) {
      return null;
    }

    setState(() => _isPicking = false);
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty || _isPicking) {
      return;
    }

    Navigator.of(context).pop(
      CustomExercise(
        id:
            widget.initial?.id ??
            'custom_exercise_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        description: _description.text.trim(),
        muscleGroups: _muscleGroups.text.trim(),
        equipment: _equipment.text.trim(),
        techniqueText: _technique.text.trim(),
        defaultCategory: _defaultCategory,
        customCategory: _customCategory.text.trim(),
        avatarDataUrl: _avatarDataUrl,
        iconName: _iconName,
        photoDataUrls: List.unmodifiable(_photoDataUrls),
        isFavorite: _isFavorite,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Новое упражнение' : 'Упражнение'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ExerciseThumb(
                  avatarDataUrl: _avatarDataUrl,
                  iconName: _iconName,
                  photoDataUrls: _photoDataUrls,
                  size: 64,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPicking ? null : _pickAvatar,
                    icon: const Icon(Icons.account_circle_rounded),
                    label: const Text('Аватарка'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Иконка', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _exerciseIconOptions)
                  ChoiceChip(
                    selected: _iconName == option.name,
                    avatar: Icon(option.icon, size: 18),
                    label: Text(option.label),
                    onSelected: (_) => setState(() => _iconName = option.name),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _defaultCategory,
              decoration: const InputDecoration(labelText: 'Категория'),
              items: const [
                DropdownMenuItem(value: 'strength', child: Text('Силовое')),
                DropdownMenuItem(value: 'cardio', child: Text('Кардио')),
                DropdownMenuItem(value: 'mobility', child: Text('Мобильность')),
                DropdownMenuItem(
                  value: 'recovery',
                  child: Text('Восстановление'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _defaultCategory = value);
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customCategory,
              decoration: const InputDecoration(labelText: 'Своя категория'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _muscleGroups,
              decoration: const InputDecoration(labelText: 'Мышечные группы'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _equipment,
              decoration: const InputDecoration(labelText: 'Оборудование'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _technique,
              decoration: const InputDecoration(
                labelText: 'Техника выполнения',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isFavorite,
              title: const Text('Любимое упражнение'),
              onChanged: (value) => setState(() => _isFavorite = value),
            ),
            OutlinedButton.icon(
              onPressed: _isPicking ? null : _pickPhoto,
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(_isPicking ? 'Добавляю...' : 'Добавить фото'),
            ),
            if (_photoDataUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var index = 0; index < _photoDataUrls.length; index++)
                    _EditablePhotoChip(
                      dataUrl: _photoDataUrls[index],
                      onRemove: () =>
                          setState(() => _photoDataUrls.removeAt(index)),
                    ),
                ],
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
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _EditablePhotoChip extends StatelessWidget {
  const _EditablePhotoChip({required this.dataUrl, required this.onRemove});

  final String dataUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeDataUrl(dataUrl);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 72,
            child: bytes == null
                ? const ColoredBox(color: Colors.black12)
                : Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: IconButton.filledTonal(
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            padding: EdgeInsets.zero,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ),
      ],
    );
  }
}

class _ExerciseScheduleDialog extends StatefulWidget {
  const _ExerciseScheduleDialog({required this.exercise});

  final CustomExercise exercise;

  @override
  State<_ExerciseScheduleDialog> createState() =>
      _ExerciseScheduleDialogState();
}

class _ExerciseScheduleDialogState extends State<_ExerciseScheduleDialog> {
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  DateTime get _dateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  bool get _canSave =>
      _dateTime.isAfter(DateTime.now().subtract(const Duration(minutes: 1)));

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
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
    if (!_canSave) {
      return;
    }

    Navigator.of(context).pop(
      _ExerciseScheduleDraft(
        dateTime: _dateTime,
        sets: int.tryParse(_setsController.text),
        reps: int.tryParse(_repsController.text),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Запланировать ${widget.exercise.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_rounded),
              label: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_rounded),
              label: Text(_selectedTime.format(context)),
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
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Заметка'),
              maxLines: 2,
            ),
            if (!_canSave) ...[
              const SizedBox(height: 10),
              Text(
                'Выберите будущее время.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
        FilledButton.icon(
          onPressed: _canSave ? _submit : null,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _ExerciseScheduleDraft {
  const _ExerciseScheduleDraft({
    required this.dateTime,
    required this.note,
    this.sets,
    this.reps,
  });

  final DateTime dateTime;
  final int? sets;
  final int? reps;
  final String note;
}

class _ExerciseIconOption {
  const _ExerciseIconOption({
    required this.name,
    required this.label,
    required this.icon,
  });

  final String name;
  final String label;
  final IconData icon;
}

const _exerciseIconOptions = <_ExerciseIconOption>[
  _ExerciseIconOption(
    name: 'dumbbell',
    label: 'Сила',
    icon: Icons.fitness_center_rounded,
  ),
  _ExerciseIconOption(
    name: 'run',
    label: 'Бег',
    icon: Icons.directions_run_rounded,
  ),
  _ExerciseIconOption(
    name: 'heart',
    label: 'Пульс',
    icon: Icons.favorite_rounded,
  ),
  _ExerciseIconOption(name: 'bolt', label: 'Мощь', icon: Icons.bolt_rounded),
  _ExerciseIconOption(
    name: 'mobility',
    label: 'Йога',
    icon: Icons.self_improvement_rounded,
  ),
  _ExerciseIconOption(
    name: 'core',
    label: 'Кор',
    icon: Icons.accessibility_new_rounded,
  ),
  _ExerciseIconOption(name: 'timer', label: 'Темп', icon: Icons.timer_rounded),
];

IconData _exerciseIconFromName(String? iconName) {
  return _exerciseIconOptions
      .firstWhere(
        (option) => option.name == iconName,
        orElse: () => _exerciseIconOptions.first,
      )
      .icon;
}

String _categoryLabel(String category) {
  return switch (category) {
    'strength' => 'Силовое',
    'cardio' => 'Кардио',
    'mobility' => 'Мобильность',
    'recovery' => 'Восстановление',
    _ => category,
  };
}

Uint8List? _decodeDataUrl(String value) {
  final commaIndex = value.indexOf(',');
  final payload = commaIndex == -1 ? value : value.substring(commaIndex + 1);
  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}
