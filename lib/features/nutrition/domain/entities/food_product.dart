import 'food_macros.dart';

class FoodProduct {
  const FoodProduct({
    required this.id,
    required this.nameEn,
    required this.nameRu,
    required this.macrosPer100Grams,
    this.barcode,
    this.isTrainerProvided = false,
    this.sourceTrainerId,
    this.sourceTrainerName,
    this.sourceVideoUrl,
    this.sourceMediaUrls = const <String>[],
    this.sourceGuideText,
    this.sourceProportionsText,
    this.sourceServingGrams,
  });

  final String id;
  final String nameEn;
  final String nameRu;
  final String? barcode;
  final FoodMacros macrosPer100Grams;
  final bool isTrainerProvided;
  final String? sourceTrainerId;
  final String? sourceTrainerName;
  final String? sourceVideoUrl;
  final List<String> sourceMediaUrls;
  final String? sourceGuideText;
  final String? sourceProportionsText;
  final double? sourceServingGrams;

  String localizedName(String languageCode) {
    return languageCode == 'ru' ? nameRu : nameEn;
  }
}
