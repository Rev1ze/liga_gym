import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food_entry_draft.dart';
import '../../domain/entities/food_input_method.dart';
import '../../domain/entities/food_macros.dart';
import '../../domain/entities/food_product.dart';
import '../providers/nutrition_providers.dart';

@immutable
class AddFoodState {
  const AddFoodState({
    this.isLoading = false,
    this.inputMethod = FoodInputMethod.manual,
    this.selectedProduct,
    this.calculatedMacros = const FoodMacros.zero(),
  });

  final bool isLoading;
  final FoodInputMethod inputMethod;
  final FoodProduct? selectedProduct;
  final FoodMacros calculatedMacros;

  AddFoodState copyWith({
    bool? isLoading,
    FoodInputMethod? inputMethod,
    Object? selectedProduct = _sentinel,
    FoodMacros? calculatedMacros,
  }) {
    return AddFoodState(
      isLoading: isLoading ?? this.isLoading,
      inputMethod: inputMethod ?? this.inputMethod,
      selectedProduct: selectedProduct == _sentinel
          ? this.selectedProduct
          : selectedProduct as FoodProduct?,
      calculatedMacros: calculatedMacros ?? this.calculatedMacros,
    );
  }
}

const Object _sentinel = Object();

class AddFoodController extends Notifier<AddFoodState> {
  @override
  AddFoodState build() => const AddFoodState();

  void setInputMethod(FoodInputMethod method) {
    state = state.copyWith(inputMethod: method);
  }

  Future<FoodProduct> findProductByBarcode(String barcode) async {
    state = state.copyWith(isLoading: true);
    try {
      final product = await ref
          .read(findProductByBarcodeUseCaseProvider)
          .call(barcode);
      state = state.copyWith(isLoading: false, selectedProduct: product);
      return product;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  FoodMacros calculateMacros({
    required FoodProduct product,
    required double grams,
  }) {
    final macros = ref
        .read(calculateMacrosUseCaseProvider)
        .call(product: product, grams: grams);
    state = state.copyWith(selectedProduct: product, calculatedMacros: macros);
    return macros;
  }

  Future<void> addFoodEntry(FoodEntryDraft draft) async {
    final user = ref.read(firebaseNutritionUserProvider);
    if (user == null) {
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      await ref
          .read(addFoodEntryUseCaseProvider)
          .call(userId: user.uid, draft: draft);
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}
