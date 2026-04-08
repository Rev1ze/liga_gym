import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/food_input_method.dart';
import '../../domain/entities/food_macros.dart';
import '../../domain/entities/food_product.dart';
import '../../domain/entities/meal_type.dart';
import '../providers/nutrition_providers.dart';
import '../utils/nutrition_route_arguments.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({required this.arguments, super.key});

  final AddFoodRouteArguments arguments;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _carbsController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');

  late MealType _selectedMealType;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.arguments.initialMealType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(addFoodControllerProvider.notifier);
    final state = ref.read(addFoodControllerProvider);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      late final FoodProduct product;
      if (state.inputMethod == FoodInputMethod.barcode) {
        product = await controller.findProductByBarcode(
          _barcodeController.text.trim(),
        );
      } else {
        product = _buildManualProduct();
      }

      final grams = double.parse(_gramsController.text.trim());
      final now = DateTime.now();
      final loggedAt = DateTime(
        widget.arguments.date.year,
        widget.arguments.date.month,
        widget.arguments.date.day,
        now.hour,
        now.minute,
        now.second,
      );

      // Считаем макросы до перехода на экран деталей, чтобы пользователь сразу видел итог по порции.
      controller.calculateMacros(product: product, grams: grams);

      if (!mounted) {
        return;
      }

      final result = await Navigator.of(context).pushNamed(
        AppRoutes.productDetails,
        arguments: ProductDetailsRouteArguments(
          product: product,
          mealType: _selectedMealType,
          grams: grams,
          loggedAt: loggedAt,
          inputMethod: state.inputMethod,
        ),
      );

      if (result == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    }
  }

  FoodProduct _buildManualProduct() {
    final macros = FoodMacros(
      calories: double.parse(_caloriesController.text.trim()),
      proteins: double.parse(_proteinsController.text.trim()),
      fats: double.parse(_fatsController.text.trim()),
      carbs: double.parse(_carbsController.text.trim()),
    );

    return FoodProduct(
      id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
      nameEn: _nameController.text.trim(),
      nameRu: _nameController.text.trim(),
      macrosPer100Grams: macros,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(addFoodControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addFoodTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<FoodInputMethod>(
                  segments: <ButtonSegment<FoodInputMethod>>[
                    ButtonSegment(
                      value: FoodInputMethod.manual,
                      label: Text(l10n.addFoodManual),
                    ),
                    ButtonSegment(
                      value: FoodInputMethod.barcode,
                      label: Text(l10n.addFoodBarcode),
                    ),
                  ],
                  selected: <FoodInputMethod>{state.inputMethod},
                  onSelectionChanged: (selection) {
                    ref
                        .read(addFoodControllerProvider.notifier)
                        .setInputMethod(selection.first);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MealType>(
                  key: AppKeys.addFoodMealTypeField,
                  initialValue: _selectedMealType,
                  decoration: InputDecoration(
                    labelText: l10n.foodDiaryMealType,
                  ),
                  items: MealType.values
                      .map(
                        (mealType) => DropdownMenuItem<MealType>(
                          value: mealType,
                          child: Text(mealType.localize(l10n)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedMealType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (state.inputMethod == FoodInputMethod.manual) ...[
                  TextFormField(
                    key: AppKeys.addFoodNameField,
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l10n.addFoodName),
                    validator: (_) => _validateName(context),
                  ),
                  const SizedBox(height: 16),
                  _NutritionNumberField(
                    fieldKey: AppKeys.addFoodCaloriesField,
                    controller: _caloriesController,
                    label: l10n.foodCaloriesPer100,
                    errorCode: AppErrorCode.invalidCalories,
                    allowZero: true,
                  ),
                  const SizedBox(height: 16),
                  _NutritionNumberField(
                    fieldKey: AppKeys.addFoodProteinsField,
                    controller: _proteinsController,
                    label: l10n.foodProteinsPer100,
                    errorCode: AppErrorCode.invalidProteins,
                    allowZero: true,
                  ),
                  const SizedBox(height: 16),
                  _NutritionNumberField(
                    fieldKey: AppKeys.addFoodFatsField,
                    controller: _fatsController,
                    label: l10n.foodFatsPer100,
                    errorCode: AppErrorCode.invalidFats,
                    allowZero: true,
                  ),
                  const SizedBox(height: 16),
                  _NutritionNumberField(
                    fieldKey: AppKeys.addFoodCarbsField,
                    controller: _carbsController,
                    label: l10n.foodCarbsPer100,
                    errorCode: AppErrorCode.invalidCarbs,
                    allowZero: true,
                  ),
                ] else ...[
                  TextFormField(
                    key: AppKeys.addFoodBarcodeField,
                    controller: _barcodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.addFoodBarcodeLabel,
                    ),
                    validator: (_) => _validateBarcode(context),
                  ),
                ],
                const SizedBox(height: 16),
                _NutritionNumberField(
                  fieldKey: AppKeys.addFoodGramsField,
                  controller: _gramsController,
                  label: l10n.addFoodGrams,
                  errorCode: AppErrorCode.invalidFoodWeight,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: AppKeys.addFoodContinueButton,
                  onPressed: state.isLoading ? null : _continue,
                  child: Text(l10n.commonContinue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      return AppErrorCode.emptyFoodName.localize(l10n);
    }

    return null;
  }

  String? _validateBarcode(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_barcodeController.text.trim().isEmpty) {
      return AppErrorCode.emptyBarcode.localize(l10n);
    }

    return null;
  }
}

class _NutritionNumberField extends StatelessWidget {
  const _NutritionNumberField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.errorCode,
    this.allowZero = false,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final AppErrorCode errorCode;
  final bool allowZero;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (_) {
        final parsed = double.tryParse(controller.text.trim());

        // Для веса требуем число больше нуля, а для БЖУ допускаем нулевые значения.
        final isInvalid =
            parsed == null || (allowZero ? parsed < 0 : parsed <= 0);
        if (isInvalid) {
          return errorCode.localize(l10n);
        }

        return null;
      },
    );
  }
}
