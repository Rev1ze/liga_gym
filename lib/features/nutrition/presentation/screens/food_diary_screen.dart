import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/localization_extensions.dart';
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
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodDiaryControllerProvider.notifier).loadDailyFoodEntries();
    });
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
    final totalMacros = state.diary.totalMacros();

    return Scaffold(
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(foodDiaryControllerProvider.notifier)
              .loadDailyFoodEntries(state.selectedDate),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatLocalizedDate(
                          state.selectedDate,
                          Localizations.localeOf(context),
                        ),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _MacrosSummary(macros: totalMacros),
                    ],
                  ),
                ),
              ),
              if (state.errorCode != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      state.errorCode!.localize(l10n),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mealType.localize(l10n),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onAddPressed,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: l10n.foodDiaryAddFood,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _MacrosSummary(macros: macros),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(l10n.foodDiaryEmptySection)
            else
              for (final entry in entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.localizedName(languageCode)),
                  subtitle: Text(
                    l10n.foodDiaryEntrySubtitle(
                      entry.grams.toStringAsFixed(0),
                      entry.macros.calories.toStringAsFixed(0),
                    ),
                  ),
                  trailing: Text(_formatMacrosInline(context, entry.macros)),
                ),
          ],
        ),
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
    return Chip(label: Text('$label: $value'));
  }
}
