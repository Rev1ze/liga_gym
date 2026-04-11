import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/food_entry_model.dart';
import '../models/food_product_model.dart';
import '../../domain/entities/food_product.dart';

abstract interface class NutritionRemoteDataSource {
  Future<List<FoodEntryModel>> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  });

  Future<FoodEntryModel?> loadFoodEntryById({
    required String userId,
    required String entryId,
  });

  Future<void> saveFoodEntry(FoodEntryModel entry);

  Future<List<FoodProductModel>> loadSavedProducts({required String userId});

  Future<void> saveSavedProduct({
    required String userId,
    required FoodProduct product,
  });
}

class UnavailableNutritionRemoteDataSource
    implements NutritionRemoteDataSource {
  const UnavailableNutritionRemoteDataSource();

  @override
  Future<List<FoodEntryModel>> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  }) async {
    throw const NutritionException(AppErrorCode.firebaseConfigurationMissing);
  }

  @override
  Future<FoodEntryModel?> loadFoodEntryById({
    required String userId,
    required String entryId,
  }) async {
    throw const NutritionException(AppErrorCode.firebaseConfigurationMissing);
  }

  @override
  Future<void> saveFoodEntry(FoodEntryModel entry) async {
    throw const NutritionException(AppErrorCode.firebaseConfigurationMissing);
  }

  @override
  Future<List<FoodProductModel>> loadSavedProducts({required String userId}) {
    throw const NutritionException(AppErrorCode.firebaseConfigurationMissing);
  }

  @override
  Future<void> saveSavedProduct({
    required String userId,
    required FoodProduct product,
  }) async {
    throw const NutritionException(AppErrorCode.firebaseConfigurationMissing);
  }
}

class FirestoreNutritionRemoteDataSource implements NutritionRemoteDataSource {
  const FirestoreNutritionRemoteDataSource({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';
  static const _foodEntriesCollection = 'food_entries';
  static const _savedProductsCollection = 'saved_food_products';

  @override
  Future<List<FoodEntryModel>> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  }) async {
    final querySnapshot = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_foodEntriesCollection)
        .where('date_key', isEqualTo: buildDateKey(date))
        .orderBy('logged_at')
        .get();

    return querySnapshot.docs
        .map(
          (document) => FoodEntryModel.fromFirestore(
            document.id,
            userId,
            document.data(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<FoodEntryModel?> loadFoodEntryById({
    required String userId,
    required String entryId,
  }) async {
    final snapshot = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_foodEntriesCollection)
        .doc(entryId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return FoodEntryModel.fromFirestore(
      snapshot.id,
      userId,
      snapshot.data() ?? <String, Object?>{},
    );
  }

  @override
  Future<void> saveFoodEntry(FoodEntryModel entry) {
    return _firestore
        .collection(_usersCollection)
        .doc(entry.userId)
        .collection(_foodEntriesCollection)
        .doc(entry.id)
        .set(entry.toFirestore());
  }

  @override
  Future<List<FoodProductModel>> loadSavedProducts({
    required String userId,
  }) async {
    final querySnapshot = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_savedProductsCollection)
        .orderBy('last_used_at', descending: true)
        .get();

    return querySnapshot.docs
        .map(
          (document) => FoodProductModel.fromSavedProductFirestore(
            document.id,
            document.data(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveSavedProduct({
    required String userId,
    required FoodProduct product,
  }) {
    final timestamp = DateTime.now();
    final model = FoodProductModel(
      id: product.id,
      nameEn: product.nameEn,
      nameRu: product.nameRu,
      barcode: product.barcode,
      macrosPer100Grams: product.macrosPer100Grams,
      updatedAt: timestamp,
      lastUsedAt: timestamp,
    );

    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_savedProductsCollection)
        .doc(product.id)
        .set(model.toFirestore(timestamp: timestamp), SetOptions(merge: true));
  }
}
