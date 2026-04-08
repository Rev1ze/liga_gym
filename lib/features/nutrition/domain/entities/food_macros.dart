class FoodMacros {
  const FoodMacros({
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  const FoodMacros.zero() : calories = 0, proteins = 0, fats = 0, carbs = 0;

  final double calories;
  final double proteins;
  final double fats;
  final double carbs;

  FoodMacros operator +(FoodMacros other) {
    return FoodMacros(
      calories: calories + other.calories,
      proteins: proteins + other.proteins,
      fats: fats + other.fats,
      carbs: carbs + other.carbs,
    );
  }
}
