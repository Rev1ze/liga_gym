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
import '../services/nutrition_offline_sync_service.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  const NutritionRepositoryImpl({
    required NutritionLocalDataSource nutritionLocalDataSource,
    required NutritionRemoteDataSource nutritionRemoteDataSource,
    required ProductCatalogDataSource productCatalogDataSource,
    required NutritionMacroCalculator nutritionMacroCalculator,
    required NutritionOfflineSyncService nutritionOfflineSyncService,
  }) : _nutritionLocalDataSource = nutritionLocalDataSource,
       _nutritionRemoteDataSource = nutritionRemoteDataSource,
       _productCatalogDataSource = productCatalogDataSource,
       _nutritionMacroCalculator = nutritionMacroCalculator,
       _nutritionOfflineSyncService = nutritionOfflineSyncService;

  final NutritionLocalDataSource _nutritionLocalDataSource;
  final NutritionRemoteDataSource _nutritionRemoteDataSource;
  final ProductCatalogDataSource _productCatalogDataSource;
  final NutritionMacroCalculator _nutritionMacroCalculator;
  final NutritionOfflineSyncService _nutritionOfflineSyncService;

  @override
  Future<DailyFoodDiary> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  }) async {
    List<FoodEntryModel> localEntries;
    try {
      localEntries = await _nutritionLocalDataSource.loadDailyFoodEntries(
        userId: userId,
        date: date,
      );
    } catch (_) {
      throw const NutritionException(AppErrorCode.nutritionDiaryLoadFailed);
    }

    try {
      await _nutritionOfflineSyncService.syncDataWithServer(userId: userId);
      final refreshedLocalEntries = await _nutritionLocalDataSource
          .loadDailyFoodEntries(userId: userId, date: date);
      if (refreshedLocalEntries.isNotEmpty) {
        localEntries = refreshedLocalEntries;
      }
    } catch (_) {
      // The diary should remain available from the local cache.
    }

    try {
      final remoteEntries = await _nutritionRemoteDataSource
          .loadDailyFoodEntries(userId: userId, date: date);
      final mergedEntries = _mergeFoodEntries(
        localEntries: localEntries,
        remoteEntries: remoteEntries,
      );

      await _nutritionLocalDataSource.saveFoodEntries(mergedEntries);
      return DailyFoodDiary(date: date, entries: mergedEntries);
    } on AppException {
      return DailyFoodDiary(date: date, entries: localEntries);
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
      await _nutritionOfflineSyncService.syncDataWithServer(userId: userId);
    } catch (_) {
      // The entry is already stored locally and will sync on the next attempt.
    }

    try {
      await saveSavedProduct(userId: userId, product: draft.product);
    } catch (_) {
      // The diary entry should stay saved even if quick access refresh fails.
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
  Future<List<FoodProduct>> loadSavedProducts({required String userId}) async {
    try {
      return _nutritionRemoteDataSource.loadSavedProducts(userId: userId);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const NutritionException(AppErrorCode.nutritionDiaryLoadFailed);
    }
  }

  @override
  Future<void> saveSavedProduct({
    required String userId,
    required FoodProduct product,
  }) async {
    try {
      await _nutritionRemoteDataSource.saveSavedProduct(
        userId: userId,
        product: product,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const NutritionException(AppErrorCode.nutritionEntrySaveFailed);
    }
  }

  @override
  FoodMacros calculateMacros({
    required FoodProduct product,
    required double grams,
  }) {
    return _nutritionMacroCalculator.calculate(product: product, grams: grams);
  }

  List<FoodEntryModel> _mergeFoodEntries({
    required List<FoodEntryModel> localEntries,
    required List<FoodEntryModel> remoteEntries,
  }) {
    final localById = {for (final entry in localEntries) entry.id: entry};

    final mergedEntries = <FoodEntryModel>[
      for (final remoteEntry in remoteEntries)
        _resolveFoodEntry(
          localEntry: localById.remove(remoteEntry.id),
          remoteEntry: remoteEntry,
        ),
      ...localById.values,
    ];

    mergedEntries.sort(
      (left, right) => left.loggedAt.compareTo(right.loggedAt),
    );
    return mergedEntries;
  }

  FoodEntryModel _resolveFoodEntry({
    required FoodEntryModel? localEntry,
    required FoodEntryModel remoteEntry,
  }) {
    final local = localEntry;
    if (local == null) {
      return remoteEntry.withSyncStatus(true);
    }

    final resolvedEntry = _nutritionOfflineSyncService.resolveConflicts(
      localRecord: local,
      remoteRecord: remoteEntry,
    );

    if (identical(resolvedEntry, remoteEntry)) {
      return remoteEntry.withSyncStatus(true);
    }

    return resolvedEntry;
  }
}
