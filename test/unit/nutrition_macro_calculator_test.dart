import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_macros.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_product.dart';
import 'package:liga_gym_app/features/nutrition/domain/services/nutrition_macro_calculator.dart';

void main() {
  group('NutritionMacroCalculator', () {
    test('корректно пересчитывает БЖУ и калории на порцию', () {
      const calculator = NutritionMacroCalculator();
      const product = FoodProduct(
        id: 'oatmeal',
        nameEn: 'Oatmeal',
        nameRu: 'Овсянка',
        macrosPer100Grams: FoodMacros(
          calories: 352,
          proteins: 12,
          fats: 6,
          carbs: 60,
        ),
      );

      final result = calculator.calculate(product: product, grams: 50);

      expect(result.calories, 176);
      expect(result.proteins, 6);
      expect(result.fats, 3);
      expect(result.carbs, 30);
    });
  });
}
