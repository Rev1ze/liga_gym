import '../../domain/entities/food_macros.dart';
import '../../domain/entities/food_product.dart';

class FoodProductModel extends FoodProduct {
  const FoodProductModel({
    required super.id,
    required super.nameEn,
    required super.nameRu,
    required super.macrosPer100Grams,
    super.barcode,
    this.updatedAt,
    this.lastUsedAt,
  });

  final DateTime? updatedAt;
  final DateTime? lastUsedAt;

  factory FoodProductModel.fromCatalogMap(Map<String, Object?> json) {
    return FoodProductModel(
      id: json['id']! as String,
      nameEn: json['name_en']! as String,
      nameRu: json['name_ru']! as String,
      barcode: json['barcode'] as String?,
      macrosPer100Grams: FoodMacros(
        calories: (json['calories']! as num).toDouble(),
        proteins: (json['proteins']! as num).toDouble(),
        fats: (json['fats']! as num).toDouble(),
        carbs: (json['carbs']! as num).toDouble(),
      ),
    );
  }

  factory FoodProductModel.fromSavedProductFirestore(
    String id,
    Map<String, Object?> json,
  ) {
    return FoodProductModel(
      id: id,
      nameEn: json['name_en']! as String,
      nameRu: json['name_ru']! as String,
      barcode: json['barcode'] as String?,
      macrosPer100Grams: FoodMacros(
        calories: (json['calories']! as num).toDouble(),
        proteins: (json['proteins']! as num).toDouble(),
        fats: (json['fats']! as num).toDouble(),
        carbs: (json['carbs']! as num).toDouble(),
      ),
      updatedAt: _readDateTime(json['updated_at']),
      lastUsedAt: _readDateTime(json['last_used_at']),
    );
  }

  Map<String, Object?> toFirestore({required DateTime timestamp}) {
    return <String, Object?>{
      'name_en': nameEn,
      'name_ru': nameRu,
      'barcode': barcode,
      'calories': macrosPer100Grams.calories,
      'proteins': macrosPer100Grams.proteins,
      'fats': macrosPer100Grams.fats,
      'carbs': macrosPer100Grams.carbs,
      'updated_at': timestamp,
      'last_used_at': timestamp,
    };
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
