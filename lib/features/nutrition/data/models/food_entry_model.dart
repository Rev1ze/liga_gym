import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/food_entry.dart';
import '../../domain/entities/food_input_method.dart';
import '../../domain/entities/food_macros.dart';
import '../../domain/entities/food_product.dart';
import '../../domain/entities/meal_type.dart';

class FoodEntryModel extends FoodEntry {
  const FoodEntryModel({
    required super.id,
    required super.userId,
    required super.mealType,
    required super.productNameEn,
    required super.productNameRu,
    required super.grams,
    required super.macros,
    required super.loggedAt,
    required super.inputMethod,
    super.barcode,
    super.isSynced,
  });

  factory FoodEntryModel.fromEntity(FoodEntry entry) {
    return FoodEntryModel(
      id: entry.id,
      userId: entry.userId,
      mealType: entry.mealType,
      productNameEn: entry.productNameEn,
      productNameRu: entry.productNameRu,
      grams: entry.grams,
      macros: entry.macros,
      loggedAt: entry.loggedAt,
      inputMethod: entry.inputMethod,
      barcode: entry.barcode,
      isSynced: entry.isSynced,
    );
  }

  factory FoodEntryModel.fromLocalMap(Map<String, Object?> map) {
    return FoodEntryModel(
      id: map['id']! as String,
      userId: map['user_id']! as String,
      mealType: MealType.values.byName(map['meal_type']! as String),
      productNameEn: map['product_name_en']! as String,
      productNameRu: map['product_name_ru']! as String,
      grams: (map['grams']! as num).toDouble(),
      macros: FoodMacros(
        calories: (map['calories']! as num).toDouble(),
        proteins: (map['proteins']! as num).toDouble(),
        fats: (map['fats']! as num).toDouble(),
        carbs: (map['carbs']! as num).toDouble(),
      ),
      loggedAt: DateTime.fromMillisecondsSinceEpoch(map['logged_at']! as int),
      inputMethod: FoodInputMethod.values.byName(
        map['input_method']! as String,
      ),
      barcode: map['barcode'] as String?,
      isSynced: (map['is_synced']! as int) == 1,
    );
  }

  factory FoodEntryModel.fromFirestore(
    String id,
    String userId,
    Map<String, Object?> json,
  ) {
    return FoodEntryModel(
      id: id,
      userId: userId,
      mealType: MealType.values.byName(json['meal_type']! as String),
      productNameEn: json['product_name_en']! as String,
      productNameRu: json['product_name_ru']! as String,
      grams: (json['grams']! as num).toDouble(),
      macros: FoodMacros(
        calories: (json['calories']! as num).toDouble(),
        proteins: (json['proteins']! as num).toDouble(),
        fats: (json['fats']! as num).toDouble(),
        carbs: (json['carbs']! as num).toDouble(),
      ),
      loggedAt: (json['logged_at']! as Timestamp).toDate(),
      inputMethod: FoodInputMethod.values.byName(
        json['input_method']! as String,
      ),
      barcode: json['barcode'] as String?,
      isSynced: true,
    );
  }

  Map<String, Object?> toLocalMap() {
    return <String, Object?>{
      'id': id,
      'user_id': userId,
      'meal_type': mealType.name,
      'date_key': buildDateKey(loggedAt),
      'product_name_en': productNameEn,
      'product_name_ru': productNameRu,
      'barcode': barcode,
      'grams': grams,
      'calories': macros.calories,
      'proteins': macros.proteins,
      'fats': macros.fats,
      'carbs': macros.carbs,
      'logged_at': loggedAt.millisecondsSinceEpoch,
      'input_method': inputMethod.name,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'id': id,
      'meal_type': mealType.name,
      'date_key': buildDateKey(loggedAt),
      'product_name_en': productNameEn,
      'product_name_ru': productNameRu,
      'barcode': barcode,
      'grams': grams,
      'calories': macros.calories,
      'proteins': macros.proteins,
      'fats': macros.fats,
      'carbs': macros.carbs,
      'logged_at': Timestamp.fromDate(loggedAt),
      'input_method': inputMethod.name,
    };
  }

  FoodEntryModel withSyncStatus(bool isSynced) {
    return FoodEntryModel(
      id: id,
      userId: userId,
      mealType: mealType,
      productNameEn: productNameEn,
      productNameRu: productNameRu,
      grams: grams,
      macros: macros,
      loggedAt: loggedAt,
      inputMethod: inputMethod,
      barcode: barcode,
      isSynced: isSynced,
    );
  }

  static FoodEntryModel fromDraft({
    required String entryId,
    required String userId,
    required MealType mealType,
    required FoodProduct product,
    required double grams,
    required FoodMacros macros,
    required DateTime loggedAt,
    required FoodInputMethod inputMethod,
  }) {
    return FoodEntryModel(
      id: entryId,
      userId: userId,
      mealType: mealType,
      productNameEn: product.nameEn,
      productNameRu: product.nameRu,
      grams: grams,
      macros: macros,
      loggedAt: loggedAt,
      inputMethod: inputMethod,
      barcode: product.barcode,
      isSynced: false,
    );
  }
}

String buildDateKey(DateTime date) {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final month = normalizedDate.month.toString().padLeft(2, '0');
  final day = normalizedDate.day.toString().padLeft(2, '0');
  return '${normalizedDate.year}-$month-$day';
}
