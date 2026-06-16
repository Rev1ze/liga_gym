import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user_goal.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/domain/entities/user_profile_update_data.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/reminder_settings_providers.dart';
import '../../../steps/presentation/providers/step_providers.dart';
import '../providers/dashboard_providers.dart';
import '../utils/goal_settings_route_arguments.dart';

class GoalSettingsScreen extends ConsumerStatefulWidget {
  const GoalSettingsScreen({super.key, required this.arguments});

  final GoalSettingsRouteArguments arguments;

  @override
  ConsumerState<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends ConsumerState<GoalSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stepGoalController = TextEditingController();
  final _calorieGoalController = TextEditingController();
  final _startWeightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  UserGoalType _selectedGoalType = UserGoalType.maintainWeight;
  bool _isSaving = false;
  bool _didPopulate = false;

  @override
  void dispose() {
    _stepGoalController.dispose();
    _calorieGoalController.dispose();
    _startWeightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(currentUserProfileProvider);
    final reminderSettings = ref.watch(reminderSettingsControllerProvider);
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    return LigaPremiumScaffold(
      appBar: AppBar(title: Text(l10n.goalSettingsTitle)),
      child: SafeArea(
        child: profileState.when(
          data: (profile) {
            if (profile == null) {
              return Center(child: Text(l10n.errorUnauthorized));
            }

            _populateFormIfNeeded(profile);

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      _subtitleForSection(l10n, widget.arguments.section),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.arguments.section ==
                                  GoalSettingsSection.steps ||
                              widget.arguments.section ==
                                  GoalSettingsSection.progress)
                            _GoalSectionCard(
                              title: l10n.dashboardAnalyticsSteps,
                              highlighted:
                                  widget.arguments.section ==
                                  GoalSettingsSection.steps,
                              child: TextFormField(
                                controller: _stepGoalController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: l10n.profileDailyStepGoal,
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse(
                                    (value ?? '').trim(),
                                  );
                                  if (parsed == null || parsed <= 0) {
                                    return l10n.validationInvalidStepGoal;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          if (widget.arguments.section ==
                                  GoalSettingsSection.steps ||
                              widget.arguments.section ==
                                  GoalSettingsSection.progress)
                            const SizedBox(height: 12),
                          if (widget.arguments.section ==
                                  GoalSettingsSection.calories ||
                              widget.arguments.section ==
                                  GoalSettingsSection.progress)
                            _GoalSectionCard(
                              title: l10n.dashboardAnalyticsCalories,
                              highlighted:
                                  widget.arguments.section ==
                                  GoalSettingsSection.calories,
                              child: _DecimalGoalField(
                                controller: _calorieGoalController,
                                label: l10n.profileDailyCalorieGoal,
                                validatorMessage:
                                    l10n.validationInvalidCalorieGoal,
                              ),
                            ),
                          if (widget.arguments.section ==
                                  GoalSettingsSection.calories ||
                              widget.arguments.section ==
                                  GoalSettingsSection.progress)
                            const SizedBox(height: 12),
                          _GoalSectionCard(
                            title: l10n.dashboardAnalyticsProgress,
                            highlighted:
                                widget.arguments.section ==
                                GoalSettingsSection.progress,
                            child: Column(
                              children: [
                                DropdownButtonFormField<UserGoalType>(
                                  initialValue: _selectedGoalType,
                                  decoration: InputDecoration(
                                    labelText: l10n.profileGoalType,
                                  ),
                                  items: UserGoalType.values
                                      .map(
                                        (goal) =>
                                            DropdownMenuItem<UserGoalType>(
                                              value: goal,
                                              child: Text(goal.localize(l10n)),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: _isSaving
                                      ? null
                                      : (value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setState(() {
                                            _selectedGoalType = value;
                                          });
                                        },
                                ),
                                const SizedBox(height: 12),
                                _DecimalGoalField(
                                  controller: _currentWeightController,
                                  label: l10n.profileCurrentWeight,
                                  validatorMessage:
                                      l10n.validationInvalidCurrentWeight,
                                ),
                                if (_selectedGoalType !=
                                    UserGoalType.maintainWeight) ...[
                                  const SizedBox(height: 12),
                                  _DecimalGoalField(
                                    controller: _startWeightController,
                                    label: l10n.profileStartWeight,
                                    validatorMessage:
                                        l10n.validationInvalidCurrentWeight,
                                  ),
                                  const SizedBox(height: 12),
                                  _DecimalGoalField(
                                    controller: _targetWeightController,
                                    label: l10n.profileTargetWeight,
                                    validatorMessage:
                                        l10n.validationInvalidTargetWeight,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _NotificationSettingsCard(
                            settings: reminderSettings,
                            isRu: isRu,
                            onMasterChanged: (value) => ref
                                .read(
                                  reminderSettingsControllerProvider.notifier,
                                )
                                .setMasterEnabled(value),
                            onWorkoutChanged: (value) => ref
                                .read(
                                  reminderSettingsControllerProvider.notifier,
                                )
                                .setWorkoutEnabled(value),
                            onWaterChanged: (value) => ref
                                .read(
                                  reminderSettingsControllerProvider.notifier,
                                )
                                .setWaterEnabled(value),
                            onDailySummaryChanged: (value) => ref
                                .read(
                                  reminderSettingsControllerProvider.notifier,
                                )
                                .setDailySummaryEnabled(value),
                            onWorkoutTimeChanged: (value) => ref
                                .read(
                                  reminderSettingsControllerProvider.notifier,
                                )
                                .setWorkoutTime(value),
                            onWaterTimeChanged: (value) => ref
                                .read(
                                  reminderSettingsControllerProvider.notifier,
                                )
                                .setWaterTime(value),
                            onDailySummaryTimeChanged: (value) => ref
                                .read(
                                  reminderSettingsControllerProvider.notifier,
                                )
                                .setDailySummaryTime(value),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : () => _save(profile),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(l10n.profileSaveButton),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error is AppException
                    ? error.code.localize(l10n)
                    : l10n.errorUnknown,
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _save(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(updateUserProfileUseCaseProvider)
          .call(
            UserProfileUpdateData(
              userId: profile.userId,
              email: profile.email,
              name: profile.name,
              gender: profile.gender,
              birthDate: profile.birthDate,
              city: profile.city,
              heightCm: profile.heightCm,
              startWeightKg: _selectedGoalType == UserGoalType.maintainWeight
                  ? null
                  : _parseDouble(_startWeightController.text),
              currentWeightKg: _parseDouble(_currentWeightController.text),
              targetWeightKg: _selectedGoalType == UserGoalType.maintainWeight
                  ? null
                  : _parseDouble(_targetWeightController.text),
              goalType: _selectedGoalType,
              dailyStepGoal:
                  int.tryParse(_stepGoalController.text.trim()) ??
                  profile.dailyStepGoal,
              dailyCalorieGoal:
                  _parseDouble(_calorieGoalController.text) ??
                  profile.dailyCalorieGoal,
            ),
          );
      await ref
          .read(stepTrackingServiceProvider)
          .saveDailyGoal(
            userId: profile.userId,
            goal:
                int.tryParse(_stepGoalController.text.trim()) ??
                profile.dailyStepGoal,
          );
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(dashboardAnalyticsProvider);
      ref.invalidate(stepGoalProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileSavedMessage)));
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _populateFormIfNeeded(UserProfile profile) {
    if (_didPopulate) {
      return;
    }

    _didPopulate = true;
    _selectedGoalType = profile.goalType;
    _stepGoalController.text = profile.dailyStepGoal.toString();
    _calorieGoalController.text = _formatDouble(
      profile.dailyCalorieGoal,
      fractionDigits: 0,
    );
    _startWeightController.text = _formatDouble(profile.startWeightKg);
    _currentWeightController.text = _formatDouble(profile.currentWeightKg);
    _targetWeightController.text = _formatDouble(profile.targetWeightKg);
  }

  String _subtitleForSection(
    AppLocalizations l10n,
    GoalSettingsSection section,
  ) {
    return switch (section) {
      GoalSettingsSection.steps => l10n.goalSettingsStepsSubtitle,
      GoalSettingsSection.calories => l10n.goalSettingsCaloriesSubtitle,
      GoalSettingsSection.progress => l10n.goalSettingsProgressSubtitle,
    };
  }

  String _formatDouble(double? value, {int fractionDigits = 1}) {
    if (value == null) {
      return '';
    }

    return value
        .toStringAsFixed(fractionDigits)
        .replaceAll(RegExp(r'\.0$'), '');
  }

  double? _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }

    return double.tryParse(normalized);
  }
}

class _NotificationSettingsCard extends StatelessWidget {
  const _NotificationSettingsCard({
    required this.settings,
    required this.isRu,
    required this.onMasterChanged,
    required this.onWorkoutChanged,
    required this.onWaterChanged,
    required this.onDailySummaryChanged,
    required this.onWorkoutTimeChanged,
    required this.onWaterTimeChanged,
    required this.onDailySummaryTimeChanged,
  });

  final ReminderSettingsState settings;
  final bool isRu;
  final ValueChanged<bool> onMasterChanged;
  final ValueChanged<bool> onWorkoutChanged;
  final ValueChanged<bool> onWaterChanged;
  final ValueChanged<bool> onDailySummaryChanged;
  final ValueChanged<TimeOfDay> onWorkoutTimeChanged;
  final ValueChanged<TimeOfDay> onWaterTimeChanged;
  final ValueChanged<TimeOfDay> onDailySummaryTimeChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRu ? 'Уведомления' : 'Notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: settings.enabled,
              onChanged: onMasterChanged,
              title: Text(isRu ? 'Включить уведомления' : 'Enable reminders'),
              subtitle: Text(
                isRu
                    ? 'Локальные напоминания на устройстве'
                    : 'Local reminders on this device',
              ),
            ),
            _ReminderRow(
              enabled: settings.enabled && settings.workoutEnabled,
              title: isRu ? 'Тренировка' : 'Workout',
              subtitle: isRu
                  ? 'Не забудь выполнить тренировку сегодня'
                  : 'Do not forget today workout',
              time: settings.workoutTime,
              onEnabledChanged: settings.enabled ? onWorkoutChanged : null,
              onTimeChanged: settings.enabled ? onWorkoutTimeChanged : null,
            ),
            _ReminderRow(
              enabled: settings.enabled && settings.waterEnabled,
              title: isRu ? 'Вода' : 'Water',
              subtitle: isRu
                  ? 'Выпей воды, организм скажет спасибо'
                  : 'Drink water, your body will thank you',
              time: settings.waterTime,
              onEnabledChanged: settings.enabled ? onWaterChanged : null,
              onTimeChanged: settings.enabled ? onWaterTimeChanged : null,
            ),
            _ReminderRow(
              enabled: settings.enabled && settings.dailySummaryEnabled,
              title: isRu ? 'Итог дня' : 'Day summary',
              subtitle: isRu
                  ? 'Посмотри свой итог дня'
                  : 'Review your day summary',
              time: settings.dailySummaryTime,
              onEnabledChanged: settings.enabled ? onDailySummaryChanged : null,
              onTimeChanged: settings.enabled
                  ? onDailySummaryTimeChanged
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onEnabledChanged,
    required this.onTimeChanged,
  });

  final bool enabled;
  final String title;
  final String subtitle;
  final TimeOfDay time;
  final ValueChanged<bool>? onEnabledChanged;
  final ValueChanged<TimeOfDay>? onTimeChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: enabled,
      onChanged: onEnabledChanged,
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: OutlinedButton.icon(
        onPressed: onTimeChanged == null
            ? null
            : () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (picked != null) {
                  onTimeChanged!(picked);
                }
              },
        icon: const Icon(Icons.schedule_rounded),
        label: Text(time.format(context)),
      ),
    );
  }
}

class _GoalSectionCard extends StatelessWidget {
  const _GoalSectionCard({
    required this.title,
    required this.child,
    required this.highlighted,
  });

  final String title;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      tint: highlighted ? colorScheme.primary.withValues(alpha: 0.12) : null,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (highlighted) ...[
                  Icon(Icons.radio_button_checked, color: colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DecimalGoalField extends StatelessWidget {
  const _DecimalGoalField({
    required this.controller,
    required this.label,
    required this.validatorMessage,
  });

  final TextEditingController controller;
  final String label;
  final String validatorMessage;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final normalized = (value ?? '').trim().replaceAll(',', '.');
        if (normalized.isEmpty) {
          return null;
        }

        final parsed = double.tryParse(normalized);
        if (parsed == null || parsed <= 0) {
          return validatorMessage;
        }

        return null;
      },
    );
  }
}
