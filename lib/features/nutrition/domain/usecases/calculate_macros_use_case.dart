import '../entities/food_macros.dart';
import '../entities/food_product.dart';
import '../repositories/nutrition_repository.dart';

class CalculateMacrosUseCase {
  const CalculateMacrosUseCase(this._nutritionRepository);

  final NutritionRepository _nutritionRepository;

  FoodMacros call({required FoodProduct product, required double grams}) {
    return _nutritionRepository.calculateMacros(product: product, grams: grams);
  }
}
