import '../entities/food_product.dart';
import '../repositories/nutrition_repository.dart';

class LoadSavedFoodProductsUseCase {
  const LoadSavedFoodProductsUseCase(this._nutritionRepository);

  final NutritionRepository _nutritionRepository;

  Future<List<FoodProduct>> call({required String userId}) {
    return _nutritionRepository.loadSavedProducts(userId: userId);
  }
}
