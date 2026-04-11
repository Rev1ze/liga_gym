import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_entry_draft.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_input_method.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_macros.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_product.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/meal_type.dart';
import 'package:liga_gym_app/features/nutrition/presentation/providers/nutrition_providers.dart';

import '../support/fakes/in_memory_nutrition_repository.dart';
import '../support/test_fixtures.dart';

void main() {
  group('FoodDiaryController', () {
    test(
      'loads saved entries for the signed-in user on the selected date',
      () async {
        final date = DateTime(2026, 4, 11);
        final firebaseAuth = buildSignedInFirebaseAuth(
          uid: 'nutrition-user',
          email: 'nutrition@ligagym.dev',
        );
        final repository = InMemoryNutritionRepository();
        final container = ProviderContainer(
          overrides: [
            firebaseAuthProvider.overrideWithValue(firebaseAuth),
            nutritionRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        await repository.addFoodEntry(
          userId: 'nutrition-user',
          draft: FoodEntryDraft(
            product: const FoodProduct(
              id: 'banana',
              nameEn: 'Banana',
              nameRu: 'Banana',
              barcode: '1234567890123',
              macrosPer100Grams: FoodMacros(
                calories: 89,
                proteins: 1.1,
                fats: 0.3,
                carbs: 22.8,
              ),
            ),
            mealType: MealType.breakfast,
            grams: 150,
            loggedAt: date,
            inputMethod: FoodInputMethod.manual,
          ),
        );

        await container
            .read(foodDiaryControllerProvider.notifier)
            .loadDailyFoodEntries(date);

        final state = container.read(foodDiaryControllerProvider);
        expect(state.selectedDate, date);
        expect(state.diary.entries, hasLength(1));
        expect(state.diary.entries.single.productNameEn, 'Banana');
        expect(state.errorCode, isNull);
      },
    );
  });
}
