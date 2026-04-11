import '../../domain/entities/food_input_method.dart';
import '../../domain/entities/food_product.dart';
import '../../domain/entities/meal_type.dart';

class AddFoodRouteArguments {
  const AddFoodRouteArguments({
    required this.date,
    this.initialMealType = MealType.breakfast,
  });

  final DateTime date;
  final MealType initialMealType;
}

class ProductDetailsRouteArguments {
  const ProductDetailsRouteArguments({
    required this.items,
    required this.mealType,
    required this.loggedAt,
    required this.inputMethod,
  }) : assert(items.length > 0);

  factory ProductDetailsRouteArguments.single({
    required FoodProduct product,
    required MealType mealType,
    required double grams,
    required DateTime loggedAt,
    required FoodInputMethod inputMethod,
  }) {
    return ProductDetailsRouteArguments(
      items: [ProductDetailsItemArguments(product: product, grams: grams)],
      mealType: mealType,
      loggedAt: loggedAt,
      inputMethod: inputMethod,
    );
  }

  final List<ProductDetailsItemArguments> items;
  final MealType mealType;
  final DateTime loggedAt;
  final FoodInputMethod inputMethod;

  bool get isMultiple => items.length > 1;
  FoodProduct get product => items.single.product;
  double get grams => items.single.grams;
}

class ProductDetailsItemArguments {
  const ProductDetailsItemArguments({
    required this.product,
    required this.grams,
  });

  final FoodProduct product;
  final double grams;
}
