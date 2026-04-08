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
