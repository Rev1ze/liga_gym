import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../models/food_entry_model.dart';

abstract interface class NutritionRemoteDataSource {
  Future<List<FoodEntryModel>> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  });

  Future<void> saveFoodEntry(FoodEntryModel entry);
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
  Future<void> saveFoodEntry(FoodEntryModel entry) async {
    throw const NutritionException(AppErrorCode.firebaseConfigurationMissing);
  }
}

class FirestoreNutritionRemoteDataSource implements NutritionRemoteDataSource {
  const FirestoreNutritionRemoteDataSource({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<List<FoodEntryModel>> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  }) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('food_entries')
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
  Future<void> saveFoodEntry(FoodEntryModel entry) {
    return _firestore
        .collection('users')
        .doc(entry.userId)
        .collection('food_entries')
        .doc(entry.id)
        .set(entry.toFirestore());
  }
}
