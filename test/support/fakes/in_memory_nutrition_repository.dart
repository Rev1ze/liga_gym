import 'package:liga_gym_app/core/errors/app_exception.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/daily_food_diary.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_entry.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_entry_draft.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_input_method.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_macros.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_product.dart';
import 'package:liga_gym_app/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:liga_gym_app/features/nutrition/domain/services/nutrition_macro_calculator.dart';

class InMemoryNutritionRepository implements NutritionRepository {
  InMemoryNutritionRepository();

  final NutritionMacroCalculator _calculator = const NutritionMacroCalculator();
  final List<FoodEntry> _entries = <FoodEntry>[];
  final Map<String, FoodProduct> _savedProducts = <String, FoodProduct>{};
  final Map<String, FoodProduct> _productsByBarcode = <String, FoodProduct>{
    '4607002010012': FoodProduct(
      id: 'greek-yogurt',
      nameEn: 'Greek Yogurt',
      nameRu: 'Греческий йогурт',
      barcode: '4607002010012',
      macrosPer100Grams: FoodMacros(
        calories: 73,
        proteins: 10,
        fats: 2,
        carbs: 3.8,
      ),
    ),
  };

  @override
  Future<void> addFoodEntry({
    required String userId,
    required FoodEntryDraft draft,
  }) async {
    await saveSavedProduct(userId: userId, product: draft.product);

    _entries.add(
      FoodEntry(
        id: 'entry_${_entries.length + 1}',
        userId: userId,
        mealType: draft.mealType,
        productNameEn: draft.product.nameEn,
        productNameRu: draft.product.nameRu,
        grams: draft.grams,
        macros: calculateMacros(product: draft.product, grams: draft.grams),
        loggedAt: draft.loggedAt,
        inputMethod: draft.inputMethod,
        barcode: draft.inputMethod == FoodInputMethod.barcode
            ? draft.product.barcode
            : null,
      ),
    );
  }

  @override
  FoodMacros calculateMacros({
    required FoodProduct product,
    required double grams,
  }) {
    return _calculator.calculate(product: product, grams: grams);
  }

  @override
  Future<FoodProduct> findProductByBarcode(String barcode) async {
    final product = _productsByBarcode[barcode];
    if (product == null) {
      throw const NutritionException(AppErrorCode.foodProductNotFound);
    }

    return product;
  }

  @override
  Future<DailyFoodDiary> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  }) async {
    final entriesForDay = _entries
        .where((entry) {
          return entry.userId == userId &&
              entry.loggedAt.year == date.year &&
              entry.loggedAt.month == date.month &&
              entry.loggedAt.day == date.day;
        })
        .toList(growable: false);

    return DailyFoodDiary(date: date, entries: entriesForDay);
  }

  @override
  Future<List<FoodProduct>> loadSavedProducts({required String userId}) async {
    return _savedProducts.values.toList(growable: false);
  }

  @override
  Future<void> saveSavedProduct({
    required String userId,
    required FoodProduct product,
  }) async {
    _savedProducts[product.id] = product;
  }
}
