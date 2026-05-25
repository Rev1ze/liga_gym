import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../auth/domain/entities/user_goal.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/domain/entities/user_profile_update_data.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/food_macros.dart';
import '../../domain/entities/meal_type.dart';
import '../providers/nutrition_providers.dart';
import '../utils/nutrition_route_arguments.dart';

class FoodDiaryScreen extends ConsumerStatefulWidget {
  const FoodDiaryScreen({super.key});

  @override
  ConsumerState<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends ConsumerState<FoodDiaryScreen> {
  final _weightController = TextEditingController();
  bool _isSavingWeight = false;
  bool _didPopulateWeight = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodDiaryControllerProvider.notifier).loadDailyFoodEntries();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = ref.read(foodDiaryControllerProvider).selectedDate;
    final date = await showDatePicker(
      context: context,
      locale: Localizations.localeOf(context),
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: l10n.foodDiaryPickDate,
      cancelText: l10n.commonCancel,
      confirmText: l10n.commonSave,
    );

    if (date == null || !mounted) {
      return;
    }

    await ref
        .read(foodDiaryControllerProvider.notifier)
        .loadDailyFoodEntries(date);
  }

  Future<void> _openAddFood([MealType mealType = MealType.breakfast]) async {
    final selectedDate = ref.read(foodDiaryControllerProvider).selectedDate;
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.addFood,
      arguments: AddFoodRouteArguments(
        date: selectedDate,
        initialMealType: mealType,
      ),
    );

    if (result == true && mounted) {
      await ref
          .read(foodDiaryControllerProvider.notifier)
          .loadDailyFoodEntries(selectedDate);
      ref.invalidate(todayNutritionDiaryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(foodDiaryControllerProvider);
    final profileState = ref.watch(currentUserProfileProvider);
    final totalMacros = state.diary.totalMacros();
    final isToday = DateUtils.isSameDay(state.selectedDate, DateTime.now());

    return LigaPremiumScaffold(
      appBar: AppBar(
        title: Text(l10n.foodDiaryTitle),
        actions: [
          IconButton(
            key: AppKeys.foodDiaryDateButton,
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            tooltip: l10n.foodDiaryPickDate,
          ),
          IconButton(
            key: AppKeys.foodDiaryAddButton,
            onPressed: _openAddFood,
            icon: const Icon(Icons.add),
            tooltip: l10n.foodDiaryAddFood,
          ),
        ],
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(foodDiaryControllerProvider.notifier)
              .loadDailyFoodEntries(state.selectedDate),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              if (isToday) ...[
                profileState.when(
                  data: (profile) {
                    if (profile == null) {
                      return const SizedBox.shrink();
                    }
                    _populateWeightIfNeeded(profile);
                    return _TodayWeightCard(
                      controller: _weightController,
                      isSaving: _isSavingWeight,
                      onSave: () => _saveTodayWeight(profile),
                    );
                  },
                  error: (_, _) => const SizedBox.shrink(),
                  loading: () => const SkeletonCard(height: 148),
                ),
                const SizedBox(height: 16),
              ],
              GlassCard(
                tint: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: formatLocalizedDate(
                        state.selectedDate,
                        Localizations.localeOf(context),
                      ),
                      subtitle: 'Adaptive nutrition load',
                    ),
                    const SizedBox(height: 16),
                    _MacrosSummary(macros: totalMacros),
                    const SizedBox(height: 14),
                    HeatmapStrip(
                      values: [
                        (totalMacros.proteins / 140).clamp(0, 1).toDouble(),
                        (totalMacros.fats / 80).clamp(0, 1).toDouble(),
                        (totalMacros.carbs / 260).clamp(0, 1).toDouble(),
                        (totalMacros.calories / 2200).clamp(0, 1).toDouble(),
                      ],
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              ).premiumEntrance(),
              if (state.errorCode != null) ...[
                const SizedBox(height: 16),
                GlassCard(
                  tint: Theme.of(context).colorScheme.errorContainer,
                  child: Text(
                    state.errorCode!.localize(l10n),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (state.isLoading) const SkeletonCard(height: 120),
              for (final mealType in MealType.values) ...[
                _MealSectionCard(
                  mealType: mealType,
                  entries: state.diary.entriesForMeal(mealType),
                  macros: state.diary.mealMacros(mealType),
                  onAddPressed: () => _openAddFood(mealType),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _populateWeightIfNeeded(UserProfile profile) {
    if (_didPopulateWeight) {
      return;
    }

    _didPopulateWeight = true;
    if (profile.currentWeightKg != null) {
      _weightController.text = profile.currentWeightKg!
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'\.0$'), '');
    }
  }

  Future<void> _saveTodayWeight(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final parsedWeight = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    if (parsedWeight == null || parsedWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validationInvalidCurrentWeight)),
      );
      return;
    }

    setState(() {
      _isSavingWeight = true;
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
              startWeightKg: profile.goalType == UserGoalType.maintainWeight
                  ? null
                  : profile.startWeightKg,
              currentWeightKg: parsedWeight,
              targetWeightKg: profile.goalType == UserGoalType.maintainWeight
                  ? null
                  : profile.targetWeightKg,
              goalType: profile.goalType,
              dailyStepGoal: profile.dailyStepGoal,
              dailyCalorieGoal: profile.dailyCalorieGoal,
            ),
          );
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(dashboardAnalyticsProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.foodDiaryWeightSaved)));
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
          _isSavingWeight = false;
        });
      }
    }
  }
}

class _TodayWeightCard extends StatelessWidget {
  const _TodayWeightCard({
    required this.controller,
    required this.isSaving,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.foodDiaryTodayWeightTitle,
            subtitle: l10n.foodDiaryTodayWeightSubtitle,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: AppKeys.foodDiaryWeightField,
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.profileCurrentWeight,
                    prefixIcon: const Icon(Icons.monitor_weight_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: AppKeys.foodDiaryWeightSaveButton,
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.commonSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealSectionCard extends StatelessWidget {
  const _MealSectionCard({
    required this.mealType,
    required this.entries,
    required this.macros,
    required this.onAddPressed,
  });

  final MealType mealType;
  final List<FoodEntry> entries;
  final FoodMacros macros;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mealType.localize(l10n),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add_rounded),
                tooltip: l10n.foodDiaryAddFood,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MacrosSummary(macros: macros),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              l10n.foodDiaryEmptySection,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final entry in entries)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  title: Text(entry.localizedName(languageCode)),
                  subtitle: Text(
                    l10n.foodDiaryEntrySubtitle(
                      entry.grams.toStringAsFixed(0),
                      entry.macros.calories.toStringAsFixed(0),
                    ),
                  ),
                  trailing: Text(_formatMacrosInline(context, entry.macros)),
                ),
              ),
        ],
      ),
    );
  }

  String _formatMacrosInline(BuildContext context, FoodMacros macros) {
    final l10n = AppLocalizations.of(context)!;
    return l10n.foodDiaryInlineMacros(
      macros.proteins.toStringAsFixed(1),
      macros.fats.toStringAsFixed(1),
      macros.carbs.toStringAsFixed(1),
    );
  }
}

class _MacrosSummary extends StatelessWidget {
  const _MacrosSummary({required this.macros});

  final FoodMacros macros;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MacroChip(
          label: l10n.foodCalories,
          value: macros.calories.toStringAsFixed(0),
        ),
        _MacroChip(
          label: l10n.foodProteins,
          value: macros.proteins.toStringAsFixed(1),
        ),
        _MacroChip(label: l10n.foodFats, value: macros.fats.toStringAsFixed(1)),
        _MacroChip(
          label: l10n.foodCarbs,
          value: macros.carbs.toStringAsFixed(1),
        ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.bolt_rounded, size: 16),
      label: Text('$label: $value'),
    );
  }
}
