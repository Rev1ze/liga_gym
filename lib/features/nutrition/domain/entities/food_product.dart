import 'food_macros.dart';

class FoodProduct {
  const FoodProduct({
    required this.id,
    required this.nameEn,
    required this.nameRu,
    required this.macrosPer100Grams,
    this.barcode,
  });

  final String id;
  final String nameEn;
  final String nameRu;
  final String? barcode;
  final FoodMacros macrosPer100Grams;

  String localizedName(String languageCode) {
    return languageCode == 'ru' ? nameRu : nameEn;
  }
}
