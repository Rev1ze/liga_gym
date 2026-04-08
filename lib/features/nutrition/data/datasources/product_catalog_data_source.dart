import '../models/food_product_model.dart';
import '../../domain/entities/food_macros.dart';

abstract interface class ProductCatalogDataSource {
  Future<FoodProductModel?> findByBarcode(String barcode);
}

class InMemoryProductCatalogDataSource implements ProductCatalogDataSource {
  const InMemoryProductCatalogDataSource();

  static final List<FoodProductModel> _products = <FoodProductModel>[
    FoodProductModel(
      id: 'greek-yogurt',
      barcode: '4607002010012',
      nameEn: 'Greek Yogurt',
      nameRu: 'Греческий йогурт',
      macrosPer100Grams: FoodMacros(
        calories: 73,
        proteins: 10,
        fats: 2,
        carbs: 3.8,
      ),
    ),
    FoodProductModel(
      id: 'protein-bar',
      barcode: '4820001234567',
      nameEn: 'Protein Bar',
      nameRu: 'Протеиновый батончик',
      macrosPer100Grams: FoodMacros(
        calories: 360,
        proteins: 25,
        fats: 12,
        carbs: 35,
      ),
    ),
    FoodProductModel(
      id: 'oatmeal',
      barcode: '4601234567890',
      nameEn: 'Oatmeal',
      nameRu: 'Овсяные хлопья',
      macrosPer100Grams: FoodMacros(
        calories: 352,
        proteins: 12.3,
        fats: 6.1,
        carbs: 59.5,
      ),
    ),
    FoodProductModel(
      id: 'chicken-breast',
      barcode: '4601111111111',
      nameEn: 'Chicken Breast',
      nameRu: 'Куриная грудка',
      macrosPer100Grams: FoodMacros(
        calories: 165,
        proteins: 31,
        fats: 3.6,
        carbs: 0,
      ),
    ),
  ];

  @override
  Future<FoodProductModel?> findByBarcode(String barcode) async {
    try {
      return _products.firstWhere((product) => product.barcode == barcode);
    } on StateError {
      return null;
    }
  }
}
