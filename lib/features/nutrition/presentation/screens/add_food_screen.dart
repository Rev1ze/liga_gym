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
  final Set<String> _selectedQuickAccessProductIds = <String>{};
  final Map<String, TextEditingController> _quickAccessGramControllers =
      <String, TextEditingController>{};

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
    for (final controller in _quickAccessGramControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(addFoodControllerProvider.notifier);
    final state = ref.read(addFoodControllerProvider);

    if (state.inputMethod == FoodInputMethod.quickAccess &&
        _selectedQuickAccessProductIds.isEmpty) {
      _showSnackBar(l10n.addFoodQuickAccessChooseProducts);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      late final ProductDetailsRouteArguments routeArguments;

      switch (state.inputMethod) {
        case FoodInputMethod.barcode:
          final product = await controller.findProductByBarcode(
            _barcodeController.text.trim(),
          );
          final grams = double.parse(_gramsController.text.trim());
          controller.calculateMacros(product: product, grams: grams);
          routeArguments = ProductDetailsRouteArguments.single(
            product: product,
            mealType: _selectedMealType,
            grams: grams,
            loggedAt: _buildLoggedAt(),
            inputMethod: state.inputMethod,
          );
          break;
        case FoodInputMethod.manual:
          final product = _buildManualProduct(state.editingProduct);
          final grams = double.parse(_gramsController.text.trim());
          controller.calculateMacros(product: product, grams: grams);
          routeArguments = ProductDetailsRouteArguments.single(
            product: product,
            mealType: _selectedMealType,
            grams: grams,
            loggedAt: _buildLoggedAt(),
            inputMethod: state.inputMethod,
          );
          break;
        case FoodInputMethod.quickAccess:
          final savedProducts = await ref.read(
            savedFoodProductsProvider.future,
          );
          final selectedItems = _buildSelectedQuickAccessItems(savedProducts);
          if (selectedItems.isEmpty) {
            _showSnackBar(l10n.addFoodQuickAccessChooseProducts);
            return;
          }

          if (selectedItems.length == 1) {
            controller.calculateMacros(
              product: selectedItems.single.product,
              grams: selectedItems.single.grams,
            );
          }

          routeArguments = ProductDetailsRouteArguments(
            items: selectedItems,
            mealType: _selectedMealType,
            loggedAt: _buildLoggedAt(),
            inputMethod: state.inputMethod,
          );
          break;
      }

      if (!mounted) {
        return;
      }

      final result = await Navigator.of(
        context,
      ).pushNamed(AppRoutes.productDetails, arguments: routeArguments);

      if (result == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(error.code.localize(l10n));
    }
  }

  DateTime _buildLoggedAt() {
    final now = DateTime.now();
    return DateTime(
      widget.arguments.date.year,
      widget.arguments.date.month,
      widget.arguments.date.day,
      now.hour,
      now.minute,
      now.second,
    );
  }

  FoodProduct _buildManualProduct(FoodProduct? editingProduct) {
    final macros = FoodMacros(
      calories: double.parse(_caloriesController.text.trim()),
      proteins: double.parse(_proteinsController.text.trim()),
      fats: double.parse(_fatsController.text.trim()),
      carbs: double.parse(_carbsController.text.trim()),
    );

    final trimmedName = _nameController.text.trim();
    return FoodProduct(
      id: editingProduct?.id ?? _buildManualProductId(trimmedName),
      nameEn: trimmedName,
      nameRu: trimmedName,
      barcode: editingProduct?.barcode,
      macrosPer100Grams: macros,
    );
  }

  String _buildManualProductId(String name) {
    final normalized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9а-яА-Я]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (normalized.isEmpty) {
      return 'manual_${DateTime.now().microsecondsSinceEpoch}';
    }

    return 'manual_$normalized';
  }

  void _startEditingProduct(FoodProduct product) {
    _nameController.text = product.localizedName(
      Localizations.localeOf(context).languageCode,
    );
    _caloriesController.text = product.macrosPer100Grams.calories
        .toStringAsFixed(0);
    _proteinsController.text = product.macrosPer100Grams.proteins
        .toStringAsFixed(1);
    _fatsController.text = product.macrosPer100Grams.fats.toStringAsFixed(1);
    _carbsController.text = product.macrosPer100Grams.carbs.toStringAsFixed(1);

    ref.read(addFoodControllerProvider.notifier).startEditingProduct(product);
  }

  void _resetManualDraft() {
    _nameController.clear();
    _caloriesController.clear();
    _proteinsController.clear();
    _fatsController.clear();
    _carbsController.clear();
    ref.read(addFoodControllerProvider.notifier).clearEditingProduct();
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  TextEditingController _quickAccessGramsController(FoodProduct product) {
    return _quickAccessGramControllers.putIfAbsent(
      product.id,
      () => TextEditingController(text: '100'),
    );
  }

  List<ProductDetailsItemArguments> _buildSelectedQuickAccessItems(
    List<FoodProduct> products,
  ) {
    return [
      for (final product in products)
        if (_selectedQuickAccessProductIds.contains(product.id))
          ProductDetailsItemArguments(
            product: product,
            grams: double.parse(
              _quickAccessGramsController(product).text.trim(),
            ),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(addFoodControllerProvider);
    final savedProductsAsync = ref.watch(savedFoodProductsProvider);

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
                      label: Text(
                        l10n.addFoodManual,
                        key: AppKeys.addFoodManualTab,
                      ),
                    ),
                    ButtonSegment(
                      value: FoodInputMethod.barcode,
                      label: Text(
                        l10n.addFoodBarcode,
                        key: AppKeys.addFoodBarcodeTab,
                      ),
                    ),
                    ButtonSegment(
                      value: FoodInputMethod.quickAccess,
                      label: Text(
                        l10n.addFoodQuickAccess,
                        key: AppKeys.addFoodQuickAccessTab,
                      ),
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
                  if (state.editingProduct != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.addFoodEditingProductTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.editingProduct!.localizedName(
                                Localizations.localeOf(context).languageCode,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _resetManualDraft,
                              child: Text(l10n.addFoodCreateNewProduct),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                ] else if (state.inputMethod == FoodInputMethod.barcode) ...[
                  TextFormField(
                    key: AppKeys.addFoodBarcodeField,
                    controller: _barcodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.addFoodBarcodeLabel,
                    ),
                    validator: (_) => _validateBarcode(context),
                  ),
                ] else ...[
                  savedProductsAsync.when(
                    data: (products) {
                      if (products.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(l10n.addFoodQuickAccessEmpty),
                        );
                      }

                      return Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.addFoodQuickAccessSelectedCount(
                                _selectedQuickAccessProductIds.length,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final product in products) ...[
                            _QuickAccessProductTile(
                              product: product,
                              selected: _selectedQuickAccessProductIds.contains(
                                product.id,
                              ),
                              gramsController: _quickAccessGramsController(
                                product,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedQuickAccessProductIds.add(
                                      product.id,
                                    );
                                  } else {
                                    _selectedQuickAccessProductIds.remove(
                                      product.id,
                                    );
                                  }
                                });
                              },
                              onEdit: () => _startEditingProduct(product),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.errorNutritionDiaryLoadFailed),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref.invalidate(savedFoodProductsProvider);
                          },
                          child: Text(l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state.inputMethod != FoodInputMethod.quickAccess) ...[
                  const SizedBox(height: 16),
                  _NutritionNumberField(
                    fieldKey: AppKeys.addFoodGramsField,
                    controller: _gramsController,
                    label: l10n.addFoodGrams,
                    errorCode: AppErrorCode.invalidFoodWeight,
                  ),
                ],
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

class _QuickAccessProductTile extends StatelessWidget {
  const _QuickAccessProductTile({
    required this.product,
    required this.selected,
    required this.gramsController,
    required this.onSelected,
    required this.onEdit,
  });

  final FoodProduct product;
  final bool selected;
  final TextEditingController gramsController;
  final ValueChanged<bool> onSelected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return Card(
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) => onSelected(value ?? false),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => onSelected(!selected),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.localizedName(languageCode)),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.foodCalories}: ${product.macrosPer100Grams.calories.toStringAsFixed(0)} • '
                            '${l10n.foodProteins}: ${product.macrosPer100Grams.proteins.toStringAsFixed(1)} • '
                            '${l10n.foodFats}: ${product.macrosPer100Grams.fats.toStringAsFixed(1)} • '
                            '${l10n.foodCarbs}: ${product.macrosPer100Grams.carbs.toStringAsFixed(1)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.addFoodQuickAccessEdit,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              _NutritionNumberField(
                fieldKey: ValueKey<String>('quickAccessGrams_${product.id}'),
                controller: gramsController,
                label: l10n.addFoodGrams,
                errorCode: AppErrorCode.invalidFoodWeight,
              ),
            ],
          ],
        ),
      ),
    );
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
