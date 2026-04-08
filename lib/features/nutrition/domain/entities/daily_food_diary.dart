import 'food_entry.dart';
import 'food_macros.dart';
import 'meal_type.dart';

class DailyFoodDiary {
  const DailyFoodDiary({required this.date, required this.entries});

  final DateTime date;
  final List<FoodEntry> entries;

  List<FoodEntry> entriesForMeal(MealType mealType) {
    return entries
        .where((entry) => entry.mealType == mealType)
        .toList(growable: false);
  }

  FoodMacros totalMacros() {
    return entries.fold(
      const FoodMacros.zero(),
      (total, entry) => total + entry.macros,
    );
  }

  FoodMacros mealMacros(MealType mealType) {
    return entriesForMeal(
      mealType,
    ).fold(const FoodMacros.zero(), (total, entry) => total + entry.macros);
  }
}
