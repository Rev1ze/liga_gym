import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/food_entry_draft.dart';
import '../../domain/entities/food_macros.dart';
import '../providers/nutrition_providers.dart';
import '../utils/nutrition_route_arguments.dart';

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({required this.arguments, super.key});

  final ProductDetailsRouteArguments arguments;

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await ref
          .read(addFoodControllerProvider.notifier)
          .addFoodEntry(
            FoodEntryDraft(
              product: arguments.product,
              mealType: arguments.mealType,
              grams: arguments.grams,
              loggedAt: arguments.loggedAt,
              inputMethod: arguments.inputMethod,
            ),
          );

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final state = ref.watch(addFoodControllerProvider);
    final macros = ref
        .read(calculateMacrosUseCaseProvider)
        .call(product: arguments.product, grams: arguments.grams);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.productDetailsTitle)),
      body: SafeArea(
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
                      arguments.product.localizedName(languageCode),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.productDetailsMeal(
                        arguments.mealType.localize(l10n),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.productDetailsPortion(
                        arguments.grams.toStringAsFixed(0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _MacrosCard(
              title: l10n.productDetailsPer100,
              macros: arguments.product.macrosPer100Grams,
            ),
            const SizedBox(height: 12),
            _MacrosCard(
              title: l10n.productDetailsPortionMacros,
              macros: macros,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: AppKeys.productDetailsSaveButton,
              onPressed: state.isLoading ? null : () => _save(context, ref),
              child: Text(l10n.productDetailsSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacrosCard extends StatelessWidget {
  const _MacrosCard({required this.title, required this.macros});

  final String title;
  final FoodMacros macros;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('${l10n.foodCalories}: ${macros.calories.toStringAsFixed(0)}'),
            Text('${l10n.foodProteins}: ${macros.proteins.toStringAsFixed(1)}'),
            Text('${l10n.foodFats}: ${macros.fats.toStringAsFixed(1)}'),
            Text('${l10n.foodCarbs}: ${macros.carbs.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }
}
