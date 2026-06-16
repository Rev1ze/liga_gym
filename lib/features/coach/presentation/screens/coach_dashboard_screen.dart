// ignore_for_file: unused_element_parameter

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/supabase/supabase_bootstrap.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../auth/presentation/controllers/auth_action_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../nutrition/domain/entities/food_macros.dart';
import '../../domain/entities/coach_media_attachment.dart';
import '../../domain/entities/coach_request.dart';
import '../../domain/entities/coach_student.dart';
import '../../domain/entities/trainer_exercise.dart';
import '../../domain/entities/trainer_recipe.dart';
import '../../domain/entities/trainer_workout_template.dart';
import '../providers/coach_providers.dart';

const _coachMediaUploadTimeout = Duration(seconds: 45);

class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authActionControllerProvider.notifier).signOut();
    if (!context.mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  Future<void> _sendStudentInvite(BuildContext context, WidgetRef ref) async {
    final friendCode = await showDialog<String>(
      context: context,
      builder: (context) => const _StudentInviteDialog(),
    );
    final trainerId = ref.read(currentFirebaseUserProvider)?.uid;
    if (friendCode == null || friendCode.isEmpty || trainerId == null) {
      return;
    }

    final profile = await ref.read(currentUserProfileProvider.future);
    try {
      await ref
          .read(coachRepositoryProvider)
          .sendCoachRequest(
            trainerId: trainerId,
            friendCode: friendCode,
            trainerName: profile?.name ?? 'Тренер',
            trainerEmail: profile?.email ?? '',
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Приглашение отправлено ученику.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ученик с таким кодом не найден.')),
      );
    }
  }

  Future<void> _upsertExercise(
    BuildContext context,
    WidgetRef ref, {
    TrainerExercise? initial,
  }) async {
    final trainerId = ref.read(currentFirebaseUserProvider)?.uid;
    if (trainerId == null) {
      return;
    }

    final exercise = await Navigator.of(context).push<TrainerExercise>(
      _coachEditorRoute(
        _ExerciseDialog(trainerId: trainerId, initial: initial),
      ),
    );
    if (exercise == null) {
      return;
    }

    await ref.read(coachRepositoryProvider).saveExercise(exercise);
    ref.invalidate(trainerExercisesProvider);
  }

  Future<void> _deleteExercise(
    BuildContext context,
    WidgetRef ref,
    TrainerExercise exercise,
  ) async {
    if (!await _confirmDelete(context, exercise.title)) {
      return;
    }
    await ref
        .read(coachRepositoryProvider)
        .deleteExercise(trainerId: exercise.trainerId, exerciseId: exercise.id);
    ref.invalidate(trainerExercisesProvider);
  }

  Future<void> _upsertRecipe(
    BuildContext context,
    WidgetRef ref, {
    TrainerRecipe? initial,
  }) async {
    final trainerId = ref.read(currentFirebaseUserProvider)?.uid;
    if (trainerId == null) {
      return;
    }

    final recipe = await Navigator.of(context).push<TrainerRecipe>(
      _coachEditorRoute(_RecipeDialog(trainerId: trainerId, initial: initial)),
    );
    if (recipe == null) {
      return;
    }

    await ref.read(coachRepositoryProvider).saveRecipe(recipe);
    ref.invalidate(trainerRecipesProvider);
  }

  Future<void> _deleteRecipe(
    BuildContext context,
    WidgetRef ref,
    TrainerRecipe recipe,
  ) async {
    if (!await _confirmDelete(context, recipe.nameRu)) {
      return;
    }
    await ref
        .read(coachRepositoryProvider)
        .deleteRecipe(trainerId: recipe.trainerId, recipeId: recipe.id);
    ref.invalidate(trainerRecipesProvider);
  }

  Future<void> _upsertTemplate(
    BuildContext context,
    WidgetRef ref,
    List<TrainerExercise> exercises, {
    TrainerWorkoutTemplate? initial,
  }) async {
    final trainerId = ref.read(currentFirebaseUserProvider)?.uid;
    if (trainerId == null) {
      return;
    }

    final template = await Navigator.of(context).push<TrainerWorkoutTemplate>(
      _coachEditorRoute(
        _WorkoutTemplateDialog(
          trainerId: trainerId,
          exercises: exercises,
          initial: initial,
        ),
      ),
    );
    if (template == null) {
      return;
    }

    await ref.read(coachRepositoryProvider).saveWorkoutTemplate(template);
    ref.invalidate(trainerWorkoutTemplatesProvider);
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    WidgetRef ref,
    TrainerWorkoutTemplate template,
  ) async {
    if (!await _confirmDelete(context, template.title)) {
      return;
    }
    await ref
        .read(coachRepositoryProvider)
        .deleteWorkoutTemplate(
          trainerId: template.trainerId,
          templateId: template.id,
        );
    ref.invalidate(trainerWorkoutTemplatesProvider);
  }

  Future<void> _assignRecipe(
    BuildContext context,
    WidgetRef ref,
    List<CoachStudent> students,
    TrainerRecipe recipe,
  ) async {
    final student = await showDialog<CoachStudent>(
      context: context,
      builder: (context) => _StudentPickerDialog(students: students),
    );
    if (student == null) {
      return;
    }

    final profile = await ref.read(currentUserProfileProvider.future);
    await ref
        .read(coachRepositoryProvider)
        .assignRecipe(
          studentId: student.id,
          recipe: recipe,
          trainerName: profile?.name ?? 'Тренер',
        );
  }

  Future<void> _assignWorkout(
    BuildContext context,
    WidgetRef ref,
    List<CoachStudent> students,
    TrainerWorkoutTemplate template,
  ) async {
    final assignment = await showDialog<_WorkoutAssignmentDraft>(
      context: context,
      builder: (context) =>
          _WorkoutAssignmentDialog(students: students, template: template),
    );
    if (assignment == null) {
      return;
    }

    await ref
        .read(coachRepositoryProvider)
        .assignWorkout(
          studentId: assignment.student.id,
          template: template,
          scheduledAt: assignment.scheduledAt,
        );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удалить?'),
            content: Text('“$title” будет удалено.'),
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
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsState = ref.watch(coachStudentsProvider);
    final outgoingRequestsState = ref.watch(outgoingCoachRequestsProvider);
    final exercisesState = ref.watch(trainerExercisesProvider);
    final recipesState = ref.watch(trainerRecipesProvider);
    final templatesState = ref.watch(trainerWorkoutTemplatesProvider);
    final isSigningOut = ref.watch(authActionControllerProvider).isLoading;

    return DefaultTabController(
      length: 4,
      child: LigaPremiumScaffold(
        appBar: AppBar(
          title: const Text('Кабинет тренера'),
          actions: [
            IconButton(
              tooltip: 'Обновить',
              onPressed: () {
                ref.invalidate(coachStudentsProvider);
                ref.invalidate(outgoingCoachRequestsProvider);
                ref.invalidate(trainerExercisesProvider);
                ref.invalidate(trainerRecipesProvider);
                ref.invalidate(trainerWorkoutTemplatesProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
            TextButton(
              onPressed: isSigningOut ? null : () => _signOut(context, ref),
              child: const Text('Выйти'),
            ),
          ],
          bottom: const TabBar(
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              Tab(icon: Icon(Icons.groups_rounded), text: 'Ученики'),
              Tab(icon: Icon(Icons.fitness_center_rounded), text: 'Упр-я'),
              Tab(icon: Icon(Icons.restaurant_menu_rounded), text: 'Рецепты'),
              Tab(icon: Icon(Icons.assignment_rounded), text: 'Планы'),
            ],
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            children: [
              _AsyncSection<List<CoachStudent>>(
                state: studentsState,
                builder: (students) => _StudentsTab(
                  students: students,
                  pendingRequests:
                      outgoingRequestsState.asData?.value ?? const [],
                  onInviteStudent: () => _sendStudentInvite(context, ref),
                ),
              ),
              _AsyncSection<List<TrainerExercise>>(
                state: exercisesState,
                builder: (exercises) => _ExercisesTab(
                  exercises: exercises,
                  onCreate: () => _upsertExercise(context, ref),
                  onEdit: (exercise) =>
                      _upsertExercise(context, ref, initial: exercise),
                  onDelete: (exercise) =>
                      _deleteExercise(context, ref, exercise),
                ),
              ),
              _AsyncSection<List<TrainerRecipe>>(
                state: recipesState,
                builder: (recipes) => _RecipesTab(
                  recipes: recipes,
                  students: studentsState.asData?.value ?? const [],
                  onCreate: () => _upsertRecipe(context, ref),
                  onEdit: (recipe) =>
                      _upsertRecipe(context, ref, initial: recipe),
                  onDelete: (recipe) => _deleteRecipe(context, ref, recipe),
                  onAssign: (recipe) => _assignRecipe(
                    context,
                    ref,
                    studentsState.asData?.value ?? const [],
                    recipe,
                  ),
                ),
              ),
              _AsyncSection<List<TrainerWorkoutTemplate>>(
                state: templatesState,
                builder: (templates) => _TemplatesTab(
                  templates: templates,
                  exercises: exercisesState.asData?.value ?? const [],
                  students: studentsState.asData?.value ?? const [],
                  onCreate: () => _upsertTemplate(
                    context,
                    ref,
                    exercisesState.asData?.value ?? const [],
                  ),
                  onEdit: (template) => _upsertTemplate(
                    context,
                    ref,
                    exercisesState.asData?.value ?? const [],
                    initial: template,
                  ),
                  onDelete: (template) =>
                      _deleteTemplate(context, ref, template),
                  onAssign: (template) => _assignWorkout(
                    context,
                    ref,
                    studentsState.asData?.value ?? const [],
                    template,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

PageRouteBuilder<T> _coachEditorRoute<T extends Object?>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _AsyncSection<T> extends StatelessWidget {
  const _AsyncSection({required this.state, required this.builder});

  final AsyncValue<T> state;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(child: Text('Не удалось загрузить данные.\n$error')),
        ],
      ),
    );
  }
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({
    required this.students,
    required this.pendingRequests,
    required this.onInviteStudent,
  });

  final List<CoachStudent> students;
  final List<CoachRequest> pendingRequests;
  final VoidCallback onInviteStudent;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ActionHeaderCard(
          title: 'Ученики',
          subtitle:
              'Попросите ученика прислать код друга из профиля. После отправки приглашения ученик должен принять его у себя.',
          buttonLabel: 'Пригласить по коду',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: onInviteStudent,
        ),
        const SizedBox(height: 12),
        if (pendingRequests.isNotEmpty) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ожидают принятия',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                for (final request in pendingRequests)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.hourglass_top_rounded),
                    title: Text(request.studentName),
                    subtitle: Text(
                      [
                        if (request.studentEmail.isNotEmpty)
                          request.studentEmail,
                        'ID: ${request.studentId}',
                      ].join('\n'),
                    ),
                    isThreeLine: request.studentEmail.isNotEmpty,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (students.isEmpty)
          const _EmptyCard(text: 'Пока нет подтвержденных учеников.')
        else
          for (final student in students) ...[
            GlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text(student.name),
                subtitle: Text(
                  [
                    if (student.email.isNotEmpty) student.email,
                    'ID: ${student.id}',
                  ].join('\n'),
                ),
                isThreeLine: student.email.isNotEmpty,
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ExercisesTab extends StatelessWidget {
  const _ExercisesTab({
    required this.exercises,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TrainerExercise> exercises;
  final VoidCallback onCreate;
  final ValueChanged<TrainerExercise> onEdit;
  final ValueChanged<TrainerExercise> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ActionHeaderCard(
          title: 'Библиотека упражнений',
          subtitle:
              'Создавайте упражнения с техникой, фото и видео из галереи.',
          buttonLabel: 'Новое упражнение',
          icon: Icons.add_rounded,
          onPressed: onCreate,
        ),
        const SizedBox(height: 12),
        if (exercises.isEmpty)
          const _EmptyCard(text: 'В библиотеке пока нет упражнений.')
        else
          for (final exercise in exercises) ...[
            _ExerciseCard(
              exercise: exercise,
              onEdit: () => onEdit(exercise),
              onDelete: () => onDelete(exercise),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _RecipesTab extends StatelessWidget {
  const _RecipesTab({
    required this.recipes,
    required this.students,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
  });

  final List<TrainerRecipe> recipes;
  final List<CoachStudent> students;
  final VoidCallback onCreate;
  final ValueChanged<TrainerRecipe> onEdit;
  final ValueChanged<TrainerRecipe> onDelete;
  final ValueChanged<TrainerRecipe> onAssign;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ActionHeaderCard(
          title: 'Рецепты тренера',
          subtitle:
              'Рецепт включает пропорции, текстовый гайд, КБЖУ и медиа из галереи.',
          buttonLabel: 'Новый рецепт',
          icon: Icons.add_rounded,
          onPressed: onCreate,
        ),
        const SizedBox(height: 12),
        if (recipes.isEmpty)
          const _EmptyCard(text: 'Пока нет рецептов.')
        else
          for (final recipe in recipes) ...[
            _RecipeCard(
              recipe: recipe,
              canAssign: students.isNotEmpty,
              onAssign: () => onAssign(recipe),
              onEdit: () => onEdit(recipe),
              onDelete: () => onDelete(recipe),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab({
    required this.templates,
    required this.exercises,
    required this.students,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
  });

  final List<TrainerWorkoutTemplate> templates;
  final List<TrainerExercise> exercises;
  final List<CoachStudent> students;
  final VoidCallback onCreate;
  final ValueChanged<TrainerWorkoutTemplate> onEdit;
  final ValueChanged<TrainerWorkoutTemplate> onDelete;
  final ValueChanged<TrainerWorkoutTemplate> onAssign;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ActionHeaderCard(
          title: 'Шаблоны тренировок',
          subtitle:
              'Собирайте тренировку из упражнений и назначайте ученику на дату.',
          buttonLabel: 'Новая тренировка',
          icon: Icons.add_rounded,
          onPressed: onCreate,
        ),
        const SizedBox(height: 12),
        if (templates.isEmpty)
          const _EmptyCard(text: 'Пока нет шаблонов тренировок.')
        else
          for (final template in templates) ...[
            _TemplateCard(
              template: template,
              exercises: exercises,
              canAssign: students.isNotEmpty,
              onAssign: () => onAssign(template),
              onEdit: () => onEdit(template),
              onDelete: () => onDelete(template),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ActionHeaderCard extends StatelessWidget {
  const _ActionHeaderCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      tint: colorScheme.primary.withValues(alpha: 0.10),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
            ),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _LegacyActionHeaderCard extends StatelessWidget {
  const _LegacyActionHeaderCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainerExercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: exercise.title,
            subtitle: exercise.muscleGroups.isEmpty
                ? null
                : 'Мышцы: ${exercise.muscleGroups}',
            action: _CardActions(onEdit: onEdit, onDelete: onDelete),
          ),
          const SizedBox(height: 8),
          if (exercise.description.isNotEmpty) Text(exercise.description),
          if (exercise.equipment.isNotEmpty)
            Text('Оборудование: ${exercise.equipment}'),
          if (exercise.techniqueText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(exercise.techniqueText),
          ],
          _MediaSummary(media: exercise.media),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.canAssign,
    required this.onAssign,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainerRecipe recipe;
  final bool canAssign;
  final VoidCallback onAssign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: recipe.nameRu,
            subtitle:
                '${recipe.servingGrams.toStringAsFixed(0)} г порция · ${recipe.macrosPer100Grams.calories.toStringAsFixed(0)} ккал / 100 г',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Назначить ученику',
                  onPressed: canAssign ? onAssign : null,
                  icon: const Icon(Icons.send_rounded),
                ),
                _CardActions(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
          ),
          if (recipe.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(recipe.description),
          ],
          if (recipe.proportionsText.isNotEmpty)
            Text('Пропорции: ${recipe.proportionsText}'),
          _MediaSummary(media: recipe.media),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.exercises,
    required this.canAssign,
    required this.onAssign,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainerWorkoutTemplate template;
  final List<TrainerExercise> exercises;
  final bool canAssign;
  final VoidCallback onAssign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final exerciseById = {
      for (final exercise in exercises) exercise.id: exercise,
    };
    final exerciseTitles = [
      for (final id in template.exerciseIds)
        exerciseById[id]?.title ?? 'Упражнение удалено',
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: template.title,
            subtitle: template.goal,
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Назначить ученику',
                  onPressed: canAssign ? onAssign : null,
                  icon: const Icon(Icons.event_available_rounded),
                ),
                _CardActions(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
          ),
          if (exerciseTitles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(exerciseTitles.join(' · ')),
          ],
          if (template.instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(template.instructions),
          ],
        ],
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Редактировать',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Удалить',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }
}

class _MediaSummary extends StatelessWidget {
  const _MediaSummary({required this.media});

  final List<CoachMediaAttachment> media;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return const SizedBox.shrink();
    }

    final images = media.where((item) => item.type == CoachMediaType.image);
    final videos = media.where((item) => item.type == CoachMediaType.video);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (images.isNotEmpty)
            Chip(
              avatar: const Icon(Icons.image_outlined, size: 16),
              label: Text('Фото: ${images.length}'),
            ),
          if (videos.isNotEmpty)
            Chip(
              avatar: const Icon(Icons.videocam_outlined, size: 16),
              label: Text('Видео: ${videos.length}'),
            ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Text(text));
  }
}

class _StudentInviteDialog extends StatefulWidget {
  const _StudentInviteDialog();

  @override
  State<_StudentInviteDialog> createState() => _StudentInviteDialogState();
}

class _StudentInviteDialogState extends State<_StudentInviteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Пригласить ученика'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Код друга ученика',
          helperText: 'Ученик копирует этот код в своем профиле.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim().toLowerCase()),
          child: const Text('Отправить'),
        ),
      ],
    );
  }
}

class _StudentPickerDialog extends StatelessWidget {
  const _StudentPickerDialog({required this.students});

  final List<CoachStudent> students;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Выберите ученика'),
      children: [
        for (final student in students)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(student),
            child: Text(student.name),
          ),
      ],
    );
  }
}

class _ExerciseDialog extends ConsumerStatefulWidget {
  const _ExerciseDialog({required this.trainerId, this.initial});

  final String trainerId;
  final TrainerExercise? initial;

  @override
  ConsumerState<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends ConsumerState<_ExerciseDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _muscleGroups = TextEditingController();
  final _equipment = TextEditingController();
  final _technique = TextEditingController();
  final List<CoachMediaAttachment> _media = <CoachMediaAttachment>[];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _title.text = initial.title;
      _description.text = initial.description;
      _muscleGroups.text = initial.muscleGroups;
      _equipment.text = initial.equipment;
      _technique.text = initial.techniqueText;
      _media.addAll(initial.media);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _muscleGroups.dispose();
    _equipment.dispose();
    _technique.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty || _isUploading) {
      return;
    }

    Navigator.of(context).pop(
      TrainerExercise(
        id:
            widget.initial?.id ??
            'exercise_${DateTime.now().microsecondsSinceEpoch}',
        trainerId: widget.trainerId,
        title: title,
        description: _description.text.trim(),
        videoUrl: '',
        media: List.unmodifiable(_media),
        muscleGroups: _muscleGroups.text.trim(),
        equipment: _equipment.text.trim(),
        techniqueText: _technique.text.trim(),
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CoachFormDialog(
      title: widget.initial == null
          ? 'Новое упражнение'
          : 'Редактировать упражнение',
      submitLabel: 'Сохранить',
      onSubmit: _submit,
      isBusy: _isUploading,
      children: [
        _TextField(controller: _title, label: 'Название'),
        _TextField(controller: _description, label: 'Описание', maxLines: 2),
        _MediaPickerSection(
          media: _media,
          isUploading: _isUploading,
          onPickImages: _pickImages,
          onPickVideo: _pickVideo,
          onRemove: (item) => setState(() => _media.remove(item)),
        ),
        _TextField(controller: _muscleGroups, label: 'Мышечные группы'),
        _TextField(controller: _equipment, label: 'Оборудование'),
        _TextField(
          controller: _technique,
          label: 'Техника выполнения',
          maxLines: 4,
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    await _pickAndUploadMedia(CoachMediaType.image);
  }

  Future<void> _pickVideo() async {
    await _pickAndUploadMedia(CoachMediaType.video);
  }

  Future<void> _pickAndUploadMedia(CoachMediaType type) async {
    final picker = ImagePicker();
    final existingCount = _media.where((item) => item.type == type).length;
    final limit = type == CoachMediaType.image ? 10 : 3;
    if (existingCount >= limit) {
      return;
    }

    final files = type == CoachMediaType.image
        ? await picker.pickMultiImage(
            limit: limit - existingCount,
            maxWidth: 1800,
            maxHeight: 1800,
            imageQuality: 88,
          )
        : [
            if (await picker.pickVideo(source: ImageSource.gallery)
                case final XFile file)
              file,
          ];
    if (files.isEmpty) {
      return;
    }

    setState(() => _isUploading = true);
    try {
      for (final file in files.take(limit - existingCount)) {
        final attachment = await _uploadCoachMedia(
          ref: ref,
          trainerId: widget.trainerId,
          file: file,
          type: type,
        );
        _media.add(attachment);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_coachMediaUploadError(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

class _RecipeDialog extends ConsumerStatefulWidget {
  const _RecipeDialog({required this.trainerId, this.initial});

  final String trainerId;
  final TrainerRecipe? initial;

  @override
  ConsumerState<_RecipeDialog> createState() => _RecipeDialogState();
}

class _RecipeDialogState extends ConsumerState<_RecipeDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _ingredients = TextEditingController();
  final _proportions = TextEditingController();
  final _guide = TextEditingController();
  final _servingGrams = TextEditingController(text: '100');
  final _calories = TextEditingController();
  final _proteins = TextEditingController();
  final _fats = TextEditingController();
  final _carbs = TextEditingController();
  final List<CoachMediaAttachment> _media = <CoachMediaAttachment>[];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _title.text = initial.nameRu;
      _description.text = initial.description;
      _ingredients.text = initial.ingredientsText;
      _proportions.text = initial.proportionsText;
      _guide.text = initial.guideText;
      _servingGrams.text = initial.servingGrams.toStringAsFixed(0);
      _calories.text = initial.macrosPer100Grams.calories.toStringAsFixed(0);
      _proteins.text = initial.macrosPer100Grams.proteins.toStringAsFixed(1);
      _fats.text = initial.macrosPer100Grams.fats.toStringAsFixed(1);
      _carbs.text = initial.macrosPer100Grams.carbs.toStringAsFixed(1);
      _media.addAll(initial.media);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _ingredients.dispose();
    _proportions.dispose();
    _guide.dispose();
    _servingGrams.dispose();
    _calories.dispose();
    _proteins.dispose();
    _fats.dispose();
    _carbs.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty || _isUploading) {
      return;
    }

    Navigator.of(context).pop(
      TrainerRecipe(
        id:
            widget.initial?.id ??
            'recipe_${DateTime.now().microsecondsSinceEpoch}',
        trainerId: widget.trainerId,
        nameEn: title,
        nameRu: title,
        description: _description.text.trim(),
        ingredientsText: _ingredients.text.trim(),
        proportionsText: _proportions.text.trim(),
        guideText: _guide.text.trim(),
        videoUrl: '',
        media: List.unmodifiable(_media),
        servingGrams: _readDouble(_servingGrams.text, fallback: 100),
        macrosPer100Grams: FoodMacros(
          calories: _readDouble(_calories.text),
          proteins: _readDouble(_proteins.text),
          fats: _readDouble(_fats.text),
          carbs: _readDouble(_carbs.text),
        ),
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CoachFormDialog(
      title: widget.initial == null ? 'Новый рецепт' : 'Редактировать рецепт',
      submitLabel: 'Сохранить',
      onSubmit: _submit,
      isBusy: _isUploading,
      children: [
        _TextField(controller: _title, label: 'Название блюда'),
        _TextField(
          controller: _description,
          label: 'Краткое описание',
          maxLines: 2,
        ),
        _MediaPickerSection(
          media: _media,
          isUploading: _isUploading,
          onPickImages: _pickImages,
          onPickVideo: _pickVideo,
          onRemove: (item) => setState(() => _media.remove(item)),
        ),
        _TextField(controller: _ingredients, label: 'Ингредиенты', maxLines: 3),
        _TextField(controller: _proportions, label: 'Пропорции', maxLines: 3),
        _TextField(controller: _guide, label: 'Полный гайд', maxLines: 5),
        _TextField(
          controller: _servingGrams,
          label: 'Порция, г',
          keyboardType: TextInputType.number,
        ),
        _TextField(
          controller: _calories,
          label: 'Ккал на 100 г',
          keyboardType: TextInputType.number,
        ),
        _TextField(
          controller: _proteins,
          label: 'Белки на 100 г',
          keyboardType: TextInputType.number,
        ),
        _TextField(
          controller: _fats,
          label: 'Жиры на 100 г',
          keyboardType: TextInputType.number,
        ),
        _TextField(
          controller: _carbs,
          label: 'Углеводы на 100 г',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    await _pickAndUploadMedia(CoachMediaType.image);
  }

  Future<void> _pickVideo() async {
    await _pickAndUploadMedia(CoachMediaType.video);
  }

  Future<void> _pickAndUploadMedia(CoachMediaType type) async {
    final picker = ImagePicker();
    final existingCount = _media.where((item) => item.type == type).length;
    final limit = type == CoachMediaType.image ? 10 : 3;
    if (existingCount >= limit) {
      return;
    }

    final files = type == CoachMediaType.image
        ? await picker.pickMultiImage(
            limit: limit - existingCount,
            maxWidth: 1800,
            maxHeight: 1800,
            imageQuality: 88,
          )
        : [
            if (await picker.pickVideo(source: ImageSource.gallery)
                case final XFile file)
              file,
          ];
    if (files.isEmpty) {
      return;
    }

    setState(() => _isUploading = true);
    try {
      for (final file in files.take(limit - existingCount)) {
        final attachment = await _uploadCoachMedia(
          ref: ref,
          trainerId: widget.trainerId,
          file: file,
          type: type,
        );
        _media.add(attachment);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_coachMediaUploadError(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

class _MediaPickerSection extends StatelessWidget {
  const _MediaPickerSection({
    required this.media,
    required this.isUploading,
    required this.onPickImages,
    required this.onPickVideo,
    required this.onRemove,
  });

  final List<CoachMediaAttachment> media;
  final bool isUploading;
  final VoidCallback onPickImages;
  final VoidCallback onPickVideo;
  final ValueChanged<CoachMediaAttachment> onRemove;

  @override
  Widget build(BuildContext context) {
    final images = media.where((item) => item.type == CoachMediaType.image);
    final videos = media.where((item) => item.type == CoachMediaType.video);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Медиа', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: isUploading || images.length >= 10
                  ? null
                  : onPickImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text('Фото ${images.length}/10'),
            ),
            OutlinedButton.icon(
              onPressed: isUploading || videos.length >= 3 ? null : onPickVideo,
              icon: const Icon(Icons.video_library_outlined),
              label: Text('Видео ${videos.length}/3'),
            ),
          ],
        ),
        if (isUploading) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
        if (media.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final item in media)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                item.type == CoachMediaType.image
                    ? Icons.image_outlined
                    : Icons.videocam_outlined,
              ),
              title: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'Убрать',
                onPressed: () => onRemove(item),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
        ],
      ],
    );
  }
}

Future<CoachMediaAttachment> _uploadCoachMedia({
  required WidgetRef ref,
  required String trainerId,
  required XFile file,
  required CoachMediaType type,
}) async {
  final supabaseBootstrap = ref.read(supabaseBootstrapProvider);
  if (!supabaseBootstrap.isConfigured) {
    throw StateError(
      'Supabase Storage is not configured. Pass SUPABASE_URL and '
      'SUPABASE_ANON_KEY with --dart-define.',
    );
  }

  final storagePath =
      'trainers/$trainerId/${type.name}/${DateTime.now().microsecondsSinceEpoch}${_extensionFor(file.name, type)}';
  final contentType = _contentTypeFor(file.name, type);
  final bucket = Supabase.instance.client.storage.from(
    supabaseBootstrap.coachMediaBucket,
  );
  final bytes = await file.readAsBytes().timeout(_coachMediaUploadTimeout);

  await bucket
      .uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(contentType: contentType),
      )
      .timeout(_coachMediaUploadTimeout);

  return CoachMediaAttachment(
    url: bucket.getPublicUrl(storagePath),
    name: file.name,
    type: type,
  );
}

String _extensionFor(String fileName, CoachMediaType type) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex >= 0 && dotIndex < fileName.length - 1) {
    final extension = fileName.substring(dotIndex + 1).toLowerCase();
    if (RegExp(r'^[a-z0-9]+$').hasMatch(extension)) {
      return '.$extension';
    }
  }

  return type == CoachMediaType.image ? '.jpg' : '.mp4';
}

String _contentTypeFor(String fileName, CoachMediaType type) {
  final extension = _extensionFor(fileName, type).substring(1);

  return switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'mov' => 'video/quicktime',
    'webm' => 'video/webm',
    'm4v' => 'video/x-m4v',
    'mp4' => 'video/mp4',
    _ => type == CoachMediaType.image ? 'image/jpeg' : 'video/mp4',
  };
}

String _coachMediaUploadError(Object error) {
  final rawMessage = error.toString();
  final message = rawMessage.toLowerCase();

  if (error is TimeoutException) {
    return 'Загрузка заняла слишком много времени. Проверьте интернет и попробуйте еще раз.';
  }

  if (message.contains('row-level security') ||
      message.contains('unauthorized') ||
      message.contains('permission')) {
    return 'Supabase Storage не разрешает загрузку. Проверьте policy для bucket coach-media.';
  }

  if (message.contains('not found') || message.contains('bucket')) {
    return 'Bucket coach-media не найден в Supabase Storage.';
  }

  if (message.contains('supabase storage is not configured')) {
    return 'Supabase Storage не настроен для этого запуска приложения.';
  }

  return 'Не удалось загрузить медиа: $rawMessage';
}

class _WorkoutTemplateDialog extends StatefulWidget {
  const _WorkoutTemplateDialog({
    required this.trainerId,
    required this.exercises,
    this.initial,
  });

  final String trainerId;
  final List<TrainerExercise> exercises;
  final TrainerWorkoutTemplate? initial;

  @override
  State<_WorkoutTemplateDialog> createState() => _WorkoutTemplateDialogState();
}

class _WorkoutTemplateDialogState extends State<_WorkoutTemplateDialog> {
  final _title = TextEditingController();
  final _goal = TextEditingController();
  final _instructions = TextEditingController();
  final Set<String> _selectedExerciseIds = <String>{};

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _title.text = initial.title;
      _goal.text = initial.goal;
      _instructions.text = initial.instructions;
      _selectedExerciseIds.addAll(initial.exerciseIds);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _goal.dispose();
    _instructions.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      TrainerWorkoutTemplate(
        id:
            widget.initial?.id ??
            'template_${DateTime.now().microsecondsSinceEpoch}',
        trainerId: widget.trainerId,
        title: title,
        goal: _goal.text.trim(),
        instructions: _instructions.text.trim(),
        exerciseIds: _selectedExerciseIds.toList(growable: false),
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CoachFormDialog(
      title: widget.initial == null
          ? 'Новая тренировка'
          : 'Редактировать тренировку',
      submitLabel: 'Сохранить',
      onSubmit: _submit,
      children: [
        _TextField(controller: _title, label: 'Название'),
        _TextField(controller: _goal, label: 'Цель'),
        _TextField(
          controller: _instructions,
          label: 'Инструкция ученику',
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        Text('Упражнения', style: Theme.of(context).textTheme.titleSmall),
        if (widget.exercises.isEmpty)
          const Text('Сначала добавьте упражнения в библиотеку.')
        else
          for (final exercise in widget.exercises)
            CheckboxListTile(
              value: _selectedExerciseIds.contains(exercise.id),
              title: Text(exercise.title),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedExerciseIds.add(exercise.id);
                  } else {
                    _selectedExerciseIds.remove(exercise.id);
                  }
                });
              },
            ),
      ],
    );
  }
}

class _WorkoutAssignmentDialog extends StatefulWidget {
  const _WorkoutAssignmentDialog({
    required this.students,
    required this.template,
  });

  final List<CoachStudent> students;
  final TrainerWorkoutTemplate template;

  @override
  State<_WorkoutAssignmentDialog> createState() =>
      _WorkoutAssignmentDialogState();
}

class _WorkoutAssignmentDialogState extends State<_WorkoutAssignmentDialog> {
  CoachStudent? _student;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _time = TimeOfDay.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _submit() {
    final student = _student;
    if (student == null) {
      return;
    }

    Navigator.of(context).pop(
      _WorkoutAssignmentDraft(
        student: student,
        scheduledAt: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Назначить "${widget.template.title}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<CoachStudent>(
            initialValue: _student,
            decoration: const InputDecoration(labelText: 'Ученик'),
            items: widget.students
                .map(
                  (student) => DropdownMenuItem(
                    value: student,
                    child: Text(student.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _student = value),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_rounded),
            label: Text(DateFormat('dd.MM.yyyy').format(_date)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule_rounded),
            label: Text(_time.format(context)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _student == null ? null : _submit,
          child: const Text('Назначить'),
        ),
      ],
    );
  }
}

class _WorkoutAssignmentDraft {
  const _WorkoutAssignmentDraft({
    required this.student,
    required this.scheduledAt,
  });

  final CoachStudent student;
  final DateTime scheduledAt;
}

class _CoachFormDialog extends StatelessWidget {
  const _CoachFormDialog({
    required this.title,
    required this.submitLabel,
    required this.children,
    required this.onSubmit,
    this.isBusy = false,
  });

  final String title;
  final String submitLabel;
  final List<Widget> children;
  final VoidCallback onSubmit;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LigaPremiumScaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: isBusy ? null : () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                GlassCard(
                  tint: colorScheme.primary.withValues(alpha: 0.10),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final child in children) ...[
                        child,
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isBusy ? null : onSubmit,
                  icon: isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(submitLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _CoachLegacyFormDialog extends StatelessWidget {
  const _CoachLegacyFormDialog({
    required this.title,
    required this.submitLabel,
    required this.children,
    required this.onSubmit,
    this.isBusy = false,
  });

  final String title;
  final String submitLabel;
  final List<Widget> children;
  final VoidCallback onSubmit;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: isBusy ? null : onSubmit,
          child: Text(submitLabel),
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }
}

double _readDouble(String value, {double fallback = 0}) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
}
