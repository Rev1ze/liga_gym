import 'food_input_method.dart';
import 'food_macros.dart';
import 'meal_type.dart';

class FoodEntry {
  const FoodEntry({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.productNameEn,
    required this.productNameRu,
    required this.grams,
    required this.macros,
    required this.loggedAt,
    required this.inputMethod,
    this.barcode,
    this.isSynced = false,
  });

  final String id;
  final String userId;
  final MealType mealType;
  final String productNameEn;
  final String productNameRu;
  final double grams;
  final FoodMacros macros;
  final DateTime loggedAt;
  final FoodInputMethod inputMethod;
  final String? barcode;
  final bool isSynced;

  String localizedName(String languageCode) {
    return languageCode == 'ru' ? productNameRu : productNameEn;
  }
}
