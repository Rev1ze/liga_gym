import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../coach/domain/entities/coach_media_attachment.dart';
import '../../../coach/domain/entities/coach_trainer.dart';
import '../../../coach/domain/entities/student_workout_assignment.dart';
import '../../../coach/domain/entities/trainer_exercise.dart';
import '../../../coach/domain/entities/trainer_recipe.dart';
import '../../../coach/domain/entities/trainer_workout_template.dart';
import '../../../coach/presentation/providers/coach_providers.dart';
import '../utils/trainer_materials_route_arguments.dart';

class TrainerMaterialsScreen extends ConsumerWidget {
  const TrainerMaterialsScreen({required this.arguments, super.key});

  final TrainerMaterialsRouteArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = _TrainerMaterialsCopy.of(context);
    final trainer = arguments.trainer;
    final state = ref.watch(trainerSharedContentProvider(trainer.id));

    return LigaPremiumScaffold(
      appBar: AppBar(title: Text(copy.title)),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [GlassCard(child: Text(error.toString()))],
              ),
              data: (content) => _TrainerMaterialsContent(
                trainer: trainer,
                content: content,
                copy: copy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TrainerMaterialDetailsScreen extends StatelessWidget {
  const TrainerMaterialDetailsScreen({required this.arguments, super.key});

  final TrainerMaterialDetailsRouteArguments arguments;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LigaPremiumScaffold(
      appBar: AppBar(title: Text(arguments.title)),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                GlassCard(
                  tint: colorScheme.primary.withValues(alpha: 0.10),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: Icon(
                          IconData(
                            arguments.iconCodePoint,
                            fontFamily: 'MaterialIcons',
                          ),
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              arguments.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            if (arguments.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                arguments.subtitle,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (arguments.media.any(_hasViewableMediaUrl)) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: _MediaGallery(media: arguments.media),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final section in arguments.sections) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        if (section.chips.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final chip in section.chips)
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(chip),
                                ),
                            ],
                          ),
                        ],
                        if (section.body.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(section.body),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainerMaterialsContent extends StatelessWidget {
  const _TrainerMaterialsContent({
    required this.trainer,
    required this.content,
    required this.copy,
  });

  final CoachTrainer trainer;
  final TrainerSharedContent content;
  final _TrainerMaterialsCopy copy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        _TrainerHero(
          trainer: trainer,
          content: content,
          copy: copy,
        ).premiumEntrance(),
        const SizedBox(height: 12),
        _AssignedWorkoutsSection(
          copy: copy,
          workouts: content.assignedWorkouts,
        ).premiumEntrance(delayMs: 70),
        _RecipesSection(
          title: copy.assignedRecipesTitle,
          emptyText: copy.assignedRecipesEmpty,
          recipes: content.assignedRecipes,
          copy: copy,
        ).premiumEntrance(delayMs: 100),
        _TemplatesSection(
          copy: copy,
          title: copy.workoutTemplatesTitle,
          emptyText: copy.workoutTemplatesEmpty,
          templates: content.workoutTemplates,
          exercises: content.exercises,
        ).premiumEntrance(delayMs: 130),
        _RecipesSection(
          title: copy.recipeLibraryTitle,
          emptyText: copy.recipeLibraryEmpty,
          recipes: content.recipes,
          copy: copy,
        ).premiumEntrance(delayMs: 160),
        _ExercisesSection(
          copy: copy,
          exercises: content.exercises,
        ).premiumEntrance(delayMs: 190),
      ],
    );
  }
}

class _TrainerHero extends StatelessWidget {
  const _TrainerHero({
    required this.trainer,
    required this.content,
    required this.copy,
  });

  final CoachTrainer trainer;
  final TrainerSharedContent content;
  final _TrainerMaterialsCopy copy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      tint: colorScheme.secondary.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [colorScheme.secondary, colorScheme.tertiary],
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trainer.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (trainer.email.isNotEmpty) Text(trainer.email),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(
                icon: Icons.event_available_rounded,
                label: copy.workoutsCount(content.assignedWorkouts.length),
              ),
              _StatPill(
                icon: Icons.restaurant_menu_rounded,
                label: copy.recipesCount(content.assignedRecipes.length),
              ),
              _StatPill(
                icon: Icons.fitness_center_rounded,
                label: copy.exercisesCount(content.exercises.length),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaterialSection extends StatelessWidget {
  const _MaterialSection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (children.isEmpty)
              Text(emptyText)
            else
              for (final child in children) ...[
                child,
                if (child != children.last) const Divider(height: 18),
              ],
          ],
        ),
      ),
    );
  }
}

class _AssignedWorkoutsSection extends StatelessWidget {
  const _AssignedWorkoutsSection({required this.copy, required this.workouts});

  final _TrainerMaterialsCopy copy;
  final List<StudentWorkoutAssignment> workouts;

  @override
  Widget build(BuildContext context) {
    return _MaterialSection(
      title: copy.assignedWorkoutsTitle,
      emptyText: copy.assignedWorkoutsEmpty,
      children: [
        for (final workout in workouts)
          _MaterialTile(
            icon: Icons.event_available_rounded,
            title: workout.title,
            subtitle: DateFormat(
              'dd.MM.yyyy HH:mm',
            ).format(workout.scheduledAt),
            onTap: () => _openDetails(
              context,
              TrainerMaterialDetailsRouteArguments(
                title: workout.title,
                subtitle: DateFormat(
                  'dd.MM.yyyy HH:mm',
                ).format(workout.scheduledAt),
                iconCodePoint: Icons.event_available_rounded.codePoint,
                sections: [
                  TrainerMaterialDetailSection(
                    title: copy.goalTitle,
                    body: workout.goal,
                    chips: [workout.status],
                  ),
                  TrainerMaterialDetailSection(
                    title: copy.instructionsTitle,
                    body: workout.instructions,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TemplatesSection extends StatelessWidget {
  const _TemplatesSection({
    required this.copy,
    required this.title,
    required this.emptyText,
    required this.templates,
    required this.exercises,
  });

  final _TrainerMaterialsCopy copy;
  final String title;
  final String emptyText;
  final List<TrainerWorkoutTemplate> templates;
  final List<TrainerExercise> exercises;

  @override
  Widget build(BuildContext context) {
    final exerciseById = {
      for (final exercise in exercises) exercise.id: exercise,
    };

    return _MaterialSection(
      title: title,
      emptyText: emptyText,
      children: [
        for (final template in templates)
          _MaterialTile(
            icon: Icons.assignment_rounded,
            title: template.title,
            subtitle: template.goal,
            onTap: () => _openDetails(
              context,
              TrainerMaterialDetailsRouteArguments(
                title: template.title,
                subtitle: template.goal,
                iconCodePoint: Icons.assignment_rounded.codePoint,
                sections: [
                  TrainerMaterialDetailSection(
                    title: copy.exerciseListTitle,
                    body: template.exerciseIds
                        .map(
                          (id) =>
                              exerciseById[id]?.title ?? copy.deletedExercise,
                        )
                        .join('\n'),
                  ),
                  TrainerMaterialDetailSection(
                    title: copy.instructionsTitle,
                    body: template.instructions,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RecipesSection extends StatelessWidget {
  const _RecipesSection({
    required this.title,
    required this.emptyText,
    required this.recipes,
    required this.copy,
  });

  final String title;
  final String emptyText;
  final List<TrainerRecipe> recipes;
  final _TrainerMaterialsCopy copy;

  @override
  Widget build(BuildContext context) {
    return _MaterialSection(
      title: title,
      emptyText: emptyText,
      children: [
        for (final recipe in recipes)
          _MaterialTile(
            icon: Icons.restaurant_menu_rounded,
            title: recipe.nameRu,
            subtitle:
                '${recipe.servingMacros.calories.toStringAsFixed(0)} kcal',
            onTap: () => _openDetails(
              context,
              TrainerMaterialDetailsRouteArguments(
                title: recipe.nameRu,
                subtitle:
                    '${recipe.servingGrams.toStringAsFixed(0)} g · ${recipe.servingMacros.calories.toStringAsFixed(0)} kcal',
                iconCodePoint: Icons.restaurant_menu_rounded.codePoint,
                media: recipe.media,
                sections: [
                  TrainerMaterialDetailSection(
                    title: copy.descriptionTitle,
                    body: recipe.description,
                    chips: [
                      'P ${recipe.servingMacros.proteins.toStringAsFixed(1)}',
                      'F ${recipe.servingMacros.fats.toStringAsFixed(1)}',
                      'C ${recipe.servingMacros.carbs.toStringAsFixed(1)}',
                    ],
                  ),
                  TrainerMaterialDetailSection(
                    title: copy.ingredientsTitle,
                    body: recipe.ingredientsText,
                  ),
                  TrainerMaterialDetailSection(
                    title: copy.proportionsTitle,
                    body: recipe.proportionsText,
                  ),
                  TrainerMaterialDetailSection(
                    title: copy.guideTitle,
                    body: recipe.guideText,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ExercisesSection extends StatelessWidget {
  const _ExercisesSection({required this.copy, required this.exercises});

  final _TrainerMaterialsCopy copy;
  final List<TrainerExercise> exercises;

  @override
  Widget build(BuildContext context) {
    return _MaterialSection(
      title: copy.exerciseLibraryTitle,
      emptyText: copy.exerciseLibraryEmpty,
      children: [
        for (final exercise in exercises)
          _MaterialTile(
            icon: Icons.fitness_center_rounded,
            title: exercise.title,
            subtitle: exercise.muscleGroups,
            onTap: () => _openDetails(
              context,
              TrainerMaterialDetailsRouteArguments(
                title: exercise.title,
                subtitle: exercise.muscleGroups,
                iconCodePoint: Icons.fitness_center_rounded.codePoint,
                media: exercise.media,
                sections: [
                  TrainerMaterialDetailSection(
                    title: copy.descriptionTitle,
                    body: exercise.description,
                    chips: [
                      if (exercise.equipment.isNotEmpty) exercise.equipment,
                    ],
                  ),
                  TrainerMaterialDetailSection(
                    title: copy.techniqueTitle,
                    body: exercise.techniqueText,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _MediaGallery extends StatelessWidget {
  const _MediaGallery({required this.media});

  final List<CoachMediaAttachment> media;

  @override
  Widget build(BuildContext context) {
    final images = media
        .where(
          (item) =>
              item.type == CoachMediaType.image && _hasViewableMediaUrl(item),
        )
        .toList(growable: false);
    final videos = media
        .where(
          (item) =>
              item.type == CoachMediaType.video && _hasViewableMediaUrl(item),
        )
        .toList(growable: false);

    if (images.isEmpty && videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final image = images[index];
              final tag = '${image.url}-$index';
              return _MediaThumbnail(
                image: image,
                heroTag: tag,
                onTap: () => _openImagePreview(context, image, tag),
              );
            },
          ),
        if (images.isNotEmpty && videos.isNotEmpty) const SizedBox(height: 10),
        for (final video in videos) ...[
          _VideoTile(video: video),
          if (video != videos.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({
    required this.image,
    required this.heroTag,
    required this.onTap,
  });

  final CoachMediaAttachment image;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          child: Hero(
            tag: heroTag,
            child: Image.network(
              image.url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video});

  final CoachMediaAttachment video;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        child: InkWell(
          onTap: () => _openVideoPreview(context, video),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    video.name.isEmpty ? 'Video' : video.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: colorScheme.primary),
            const SizedBox(width: 7),
            Text(label),
          ],
        ),
      ),
    );
  }
}

void _openDetails(
  BuildContext context,
  TrainerMaterialDetailsRouteArguments arguments,
) {
  Navigator.of(
    context,
  ).pushNamed(AppRoutes.trainerMaterialDetails, arguments: arguments);
}

void _openImagePreview(
  BuildContext context,
  CoachMediaAttachment image,
  String heroTag,
) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Hero(
                tag: heroTag,
                child: Image.network(
                  image.url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _openVideoPreview(BuildContext context, CoachMediaAttachment video) {
  showDialog<void>(
    context: context,
    builder: (context) => _VideoPreviewDialog(video: video),
  );
}

bool _hasViewableMediaUrl(CoachMediaAttachment item) {
  final uri = Uri.tryParse(item.url);
  return uri != null &&
      uri.hasAbsolutePath &&
      (uri.scheme == 'https' || uri.scheme == 'http');
}

class _VideoPreviewDialog extends StatefulWidget {
  const _VideoPreviewDialog({required this.video});

  final CoachMediaAttachment video;

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeVideo;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.url));
    _initializeVideo = _controller.initialize().then((_) {
      _controller.play();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: FutureBuilder<void>(
              future: _initializeVideo,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError || !_controller.value.isInitialized) {
                  return const Icon(
                    Icons.video_file_outlined,
                    color: Colors.white70,
                    size: 48,
                  );
                }

                return AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                );
              },
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    color: Colors.white,
                    iconSize: 36,
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerMaterialsCopy {
  const _TrainerMaterialsCopy(this.isRu);

  factory _TrainerMaterialsCopy.of(BuildContext context) {
    return _TrainerMaterialsCopy(
      Localizations.localeOf(context).languageCode == 'ru',
    );
  }

  final bool isRu;

  String get title => isRu ? 'Материалы тренера' : 'Coach materials';
  String get assignedWorkoutsTitle =>
      isRu ? 'Назначенные комплексы' : 'Assigned workout plans';
  String get assignedWorkoutsEmpty =>
      isRu ? 'Назначенных комплексов пока нет.' : 'No assigned workout plans.';
  String get assignedRecipesTitle =>
      isRu ? 'Назначенные рецепты' : 'Assigned recipes';
  String get assignedRecipesEmpty =>
      isRu ? 'Назначенных рецептов пока нет.' : 'No assigned recipes.';
  String get workoutTemplatesTitle =>
      isRu ? 'Библиотека комплексов' : 'Workout plan library';
  String get workoutTemplatesEmpty =>
      isRu ? 'Комплексов пока нет.' : 'No workout plans yet.';
  String get recipeLibraryTitle => isRu ? 'Рецепты' : 'Recipes';
  String get recipeLibraryEmpty => isRu ? 'Рецептов пока нет.' : 'No recipes.';
  String get exerciseLibraryTitle => isRu ? 'Упражнения' : 'Exercises';
  String get exerciseLibraryEmpty =>
      isRu ? 'Упражнений пока нет.' : 'No exercises.';
  String get deletedExercise =>
      isRu ? 'Упражнение удалено' : 'Deleted exercise';
  String get goalTitle => isRu ? 'Цель' : 'Goal';
  String get instructionsTitle => isRu ? 'Инструкция' : 'Instructions';
  String get exerciseListTitle => isRu ? 'Упражнения' : 'Exercises';
  String get descriptionTitle => isRu ? 'Описание' : 'Description';
  String get ingredientsTitle => isRu ? 'Ингредиенты' : 'Ingredients';
  String get proportionsTitle => isRu ? 'Пропорции' : 'Proportions';
  String get guideTitle => isRu ? 'Гайд' : 'Guide';
  String get techniqueTitle => isRu ? 'Техника' : 'Technique';

  String workoutsCount(int value) =>
      isRu ? '$value комплексов' : '$value plans';
  String recipesCount(int value) => isRu ? '$value рецептов' : '$value recipes';
  String exercisesCount(int value) =>
      isRu ? '$value упражнений' : '$value exercises';
}
