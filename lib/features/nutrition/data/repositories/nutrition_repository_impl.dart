import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/daily_food_diary.dart';
import '../../domain/entities/food_entry_draft.dart';
import '../../domain/entities/food_macros.dart';
import '../../domain/entities/food_product.dart';
import '../../domain/repositories/nutrition_repository.dart';
import '../../domain/services/nutrition_macro_calculator.dart';
import '../datasources/nutrition_local_data_source.dart';
import '../datasources/nutrition_remote_data_source.dart';
import '../datasources/product_catalog_data_source.dart';
import '../models/food_entry_model.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  const NutritionRepositoryImpl({
    required NutritionLocalDataSource nutritionLocalDataSource,
    required NutritionRemoteDataSource nutritionRemoteDataSource,
    required ProductCatalogDataSource productCatalogDataSource,
    required NutritionMacroCalculator nutritionMacroCalculator,
  }) : _nutritionLocalDataSource = nutritionLocalDataSource,
       _nutritionRemoteDataSource = nutritionRemoteDataSource,
       _productCatalogDataSource = productCatalogDataSource,
       _nutritionMacroCalculator = nutritionMacroCalculator;

  final NutritionLocalDataSource _nutritionLocalDataSource;
  final NutritionRemoteDataSource _nutritionRemoteDataSource;
  final ProductCatalogDataSource _productCatalogDataSource;
  final NutritionMacroCalculator _nutritionMacroCalculator;

  @override
  Future<DailyFoodDiary> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final localEntries = await _nutritionLocalDataSource.loadDailyFoodEntries(
        userId: userId,
        date: date,
      );

      if (localEntries.isNotEmpty) {
        return DailyFoodDiary(date: date, entries: localEntries);
      }

      try {
        final remoteEntries = await _nutritionRemoteDataSource
            .loadDailyFoodEntries(userId: userId, date: date);

        if (remoteEntries.isNotEmpty) {
          await _nutritionLocalDataSource.saveFoodEntries(
            remoteEntries
                .map((entry) => entry.withSyncStatus(true))
                .toList(growable: false),
          );
        }

        return DailyFoodDiary(date: date, entries: remoteEntries);
      } on AppException {
        return DailyFoodDiary(date: date, entries: localEntries);
      }
    } catch (_) {
      throw const NutritionException(AppErrorCode.nutritionDiaryLoadFailed);
    }
  }

  @override
  Future<void> addFoodEntry({
    required String userId,
    required FoodEntryDraft draft,
  }) async {
    final entryId =
        'food_${draft.loggedAt.microsecondsSinceEpoch}_${draft.mealType.name}';
    final macros = calculateMacros(product: draft.product, grams: draft.grams);
    final entryModel = FoodEntryModel.fromDraft(
      entryId: entryId,
      userId: userId,
      mealType: draft.mealType,
      product: draft.product,
      grams: draft.grams,
      macros: macros,
      loggedAt: draft.loggedAt,
      inputMethod: draft.inputMethod,
    );

    try {
      await _nutritionLocalDataSource.saveFoodEntry(entryModel);
    } catch (_) {
      throw const NutritionException(AppErrorCode.nutritionEntrySaveFailed);
    }

    try {
      await _nutritionRemoteDataSource.saveFoodEntry(entryModel);
      await _nutritionLocalDataSource.markFoodEntrySynced(entryModel.id);
    } on AppException {
      // Оставляем запись локально, если удалённая синхронизация недоступна.
    } catch (_) {
      // Не роняем сценарий добавления еды из-за ошибки фоновой синхронизации.
    }
  }

  @override
  Future<FoodProduct> findProductByBarcode(String barcode) async {
    final product = await _productCatalogDataSource.findByBarcode(barcode);
    if (product == null) {
      throw const NutritionException(AppErrorCode.foodProductNotFound);
    }

    return product;
  }

  @override
  FoodMacros calculateMacros({
    required FoodProduct product,
    required double grams,
  }) {
    return _nutritionMacroCalculator.calculate(product: product, grams: grams);
  }
}
