import 'food_input_method.dart';
import 'food_product.dart';
import 'meal_type.dart';

class FoodEntryDraft {
  const FoodEntryDraft({
    required this.product,
    required this.mealType,
    required this.grams,
    required this.loggedAt,
    required this.inputMethod,
  });

  final FoodProduct product;
  final MealType mealType;
  final double grams;
  final DateTime loggedAt;
  final FoodInputMethod inputMethod;
}
