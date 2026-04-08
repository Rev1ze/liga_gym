import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/navigation/app_routes.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutStartTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.workoutStartSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<WorkoutType>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: l10n.workoutTypeLabel,
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
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: AppKeys.workoutStartButton,
                        onPressed: _startWorkout,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.workoutStartButton),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
