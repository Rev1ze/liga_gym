import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/workout_type.dart';
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
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    borderRadius: 36,
                    tint: colorScheme.secondary.withValues(alpha: 0.18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
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
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 42,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          l10n.workoutStartSubtitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<WorkoutType>(
                          initialValue: _selectedType,
                          decoration: InputDecoration(
                            labelText: l10n.workoutTypeLabel,
                            prefixIcon: const Icon(
                              Icons.fitness_center_rounded,
                            ),
                          ),
                          items: WorkoutType.values
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
                        const SizedBox(height: 18),
                        HeatmapStrip(
                          values: const [0.7, 0.3, 0.86, 0.52, 0.94, 0.61, 1],
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          key: AppKeys.workoutStartButton,
                          onPressed: _startWorkout,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l10n.workoutStartButton),
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
