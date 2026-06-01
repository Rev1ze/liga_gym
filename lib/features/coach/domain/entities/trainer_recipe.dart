import '../../../nutrition/domain/entities/food_macros.dart';
import '../../../nutrition/domain/entities/food_product.dart';
import 'coach_media_attachment.dart';

class TrainerRecipe extends FoodProduct {
  TrainerRecipe({
    required super.id,
    required super.nameEn,
    required super.nameRu,
    required super.macrosPer100Grams,
    required this.trainerId,
    required this.description,
    required this.ingredientsText,
    required this.proportionsText,
    required this.guideText,
    required this.videoUrl,
    required this.media,
    required this.servingGrams,
    required this.createdAt,
    this.assignmentId,
    this.studentId,
    this.trainerName,
  }) : super(
         isTrainerProvided: true,
         sourceTrainerId: trainerId,
         sourceTrainerName: trainerName,
         sourceVideoUrl: videoUrl,
         sourceMediaUrls: media.map((item) => item.url).toList(growable: false),
         sourceGuideText: guideText,
         sourceProportionsText: proportionsText,
         sourceServingGrams: servingGrams,
       );

  final String trainerId;
  final String description;
  final String ingredientsText;
  final String proportionsText;
  final String guideText;
  final String videoUrl;
  final List<CoachMediaAttachment> media;
  final double servingGrams;
  final DateTime createdAt;
  final String? assignmentId;
  final String? studentId;
  final String? trainerName;

  FoodMacros get servingMacros {
    return FoodMacros(
      calories: macrosPer100Grams.calories * servingGrams / 100,
      proteins: macrosPer100Grams.proteins * servingGrams / 100,
      fats: macrosPer100Grams.fats * servingGrams / 100,
      carbs: macrosPer100Grams.carbs * servingGrams / 100,
    );
  }
}
