import '../entities/daily_food_diary.dart';
import '../entities/food_entry_draft.dart';
import '../entities/food_product.dart';
import '../entities/food_macros.dart';

abstract interface class NutritionRepository {
  Future<DailyFoodDiary> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  });

  Future<void> addFoodEntry({
    required String userId,
    required FoodEntryDraft draft,
  });

  Future<FoodProduct> findProductByBarcode(String barcode);

  Future<List<FoodProduct>> loadSavedProducts({required String userId});

  Future<void> saveSavedProduct({
    required String userId,
    required FoodProduct product,
  });

  FoodMacros calculateMacros({
    required FoodProduct product,
    required double grams,
  });
}
