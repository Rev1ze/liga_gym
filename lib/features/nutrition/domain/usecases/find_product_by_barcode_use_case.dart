import '../entities/food_product.dart';
import '../repositories/nutrition_repository.dart';

class FindProductByBarcodeUseCase {
  const FindProductByBarcodeUseCase(this._nutritionRepository);

  final NutritionRepository _nutritionRepository;

  Future<FoodProduct> call(String barcode) {
    return _nutritionRepository.findProductByBarcode(barcode);
  }
}
