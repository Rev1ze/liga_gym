import '../../domain/entities/food_macros.dart';
import '../../domain/entities/food_product.dart';

class FoodProductModel extends FoodProduct {
  const FoodProductModel({
    required super.id,
    required super.nameEn,
    required super.nameRu,
    required super.macrosPer100Grams,
    super.barcode,
  });

  factory FoodProductModel.fromFirestore(Map<String, Object?> json) {
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
}
