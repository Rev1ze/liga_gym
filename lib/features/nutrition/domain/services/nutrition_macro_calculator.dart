import '../entities/food_macros.dart';
import '../entities/food_product.dart';

class NutritionMacroCalculator {
  const NutritionMacroCalculator();

  FoodMacros calculate({required FoodProduct product, required double grams}) {
    final multiplier = grams / 100;

    // Пересчитываем БЖУ и калории из значения на 100 грамм в фактическую порцию.
    return FoodMacros(
      calories: product.macrosPer100Grams.calories * multiplier,
      proteins: product.macrosPer100Grams.proteins * multiplier,
      fats: product.macrosPer100Grams.fats * multiplier,
      carbs: product.macrosPer100Grams.carbs * multiplier,
    );
  }
}

// 4607002010012 -> Greek Yogurt
// 4820001234567 -> Protein Bar
// 4601234567890 -> Oatmeal
// 4601111111111 -> Chicken Breast
