import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/nutrition_local_data_source.dart';
import '../../data/datasources/nutrition_remote_data_source.dart';
import '../../data/datasources/product_catalog_data_source.dart';
import '../../data/repositories/nutrition_repository_impl.dart';
import '../../data/services/nutrition_offline_sync_service.dart';
import '../../domain/entities/daily_food_diary.dart';
import '../../domain/entities/food_product.dart';
import '../../domain/repositories/nutrition_repository.dart';
import '../../domain/services/nutrition_macro_calculator.dart';
import '../../domain/usecases/add_food_entry_use_case.dart';
import '../../domain/usecases/calculate_macros_use_case.dart';
import '../../domain/usecases/find_product_by_barcode_use_case.dart';
import '../../domain/usecases/load_daily_food_entries_use_case.dart';
import '../../domain/usecases/load_saved_food_products_use_case.dart';
import '../controllers/add_food_controller.dart';
import '../controllers/food_diary_controller.dart';

part 'nutrition_providers.g.dart';

final firebaseNutritionUserProvider = Provider(
  (ref) => ref.watch(firebaseAuthProvider).currentUser,
);

@Riverpod(keepAlive: true)
NutritionLocalDataSource nutritionLocalDataSource(Ref ref) {
  return SqfliteNutritionLocalDataSource();
}

@Riverpod(keepAlive: true)
NutritionRemoteDataSource nutritionRemoteDataSource(Ref ref) {
  final firebaseBootstrap = ref.watch(firebaseBootstrapProvider);
  if (!firebaseBootstrap.isConfigured) {
    return const UnavailableNutritionRemoteDataSource();
  }

  return FirestoreNutritionRemoteDataSource(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@Riverpod(keepAlive: true)
ProductCatalogDataSource productCatalogDataSource(Ref ref) {
  return const InMemoryProductCatalogDataSource();
}

@Riverpod(keepAlive: true)
NutritionMacroCalculator nutritionMacroCalculator(Ref ref) {
  return const NutritionMacroCalculator();
}

final nutritionOfflineSyncServiceProvider =
    Provider<NutritionOfflineSyncService>((ref) {
      return NutritionOfflineSyncService(
        nutritionLocalDataSource: ref.watch(nutritionLocalDataSourceProvider),
        nutritionRemoteDataSource: ref.watch(nutritionRemoteDataSourceProvider),
      );
    });

@Riverpod(keepAlive: true)
NutritionRepository nutritionRepository(Ref ref) {
  return NutritionRepositoryImpl(
    nutritionLocalDataSource: ref.watch(nutritionLocalDataSourceProvider),
    nutritionRemoteDataSource: ref.watch(nutritionRemoteDataSourceProvider),
    productCatalogDataSource: ref.watch(productCatalogDataSourceProvider),
    nutritionMacroCalculator: ref.watch(nutritionMacroCalculatorProvider),
    nutritionOfflineSyncService: ref.watch(nutritionOfflineSyncServiceProvider),
  );
}

@Riverpod(keepAlive: true)
LoadDailyFoodEntriesUseCase loadDailyFoodEntriesUseCase(Ref ref) {
  return LoadDailyFoodEntriesUseCase(ref.watch(nutritionRepositoryProvider));
}

@Riverpod(keepAlive: true)
LoadSavedFoodProductsUseCase loadSavedFoodProductsUseCase(Ref ref) {
  return LoadSavedFoodProductsUseCase(ref.watch(nutritionRepositoryProvider));
}

@Riverpod(keepAlive: true)
AddFoodEntryUseCase addFoodEntryUseCase(Ref ref) {
  return AddFoodEntryUseCase(ref.watch(nutritionRepositoryProvider));
}

@Riverpod(keepAlive: true)
FindProductByBarcodeUseCase findProductByBarcodeUseCase(Ref ref) {
  return FindProductByBarcodeUseCase(ref.watch(nutritionRepositoryProvider));
}

@Riverpod(keepAlive: true)
CalculateMacrosUseCase calculateMacrosUseCase(Ref ref) {
  return CalculateMacrosUseCase(ref.watch(nutritionRepositoryProvider));
}

final foodDiaryControllerProvider =
    NotifierProvider<FoodDiaryController, FoodDiaryState>(
      FoodDiaryController.new,
    );

final addFoodControllerProvider =
    NotifierProvider<AddFoodController, AddFoodState>(AddFoodController.new);

final savedFoodProductsProvider = FutureProvider<List<FoodProduct>>((
  ref,
) async {
  final user = ref.watch(firebaseNutritionUserProvider);
  if (user == null) {
    return const <FoodProduct>[];
  }

  return ref.watch(loadSavedFoodProductsUseCaseProvider).call(userId: user.uid);
});

@riverpod
Future<DailyFoodDiary> todayNutritionDiary(Ref ref) async {
  final user = ref.watch(firebaseNutritionUserProvider);
  if (user == null) {
    return DailyFoodDiary(date: DateTime.now(), entries: const []);
  }

  return ref
      .watch(loadDailyFoodEntriesUseCaseProvider)
      .call(userId: user.uid, date: DateTime.now());
}
