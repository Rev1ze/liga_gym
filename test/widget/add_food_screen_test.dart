import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/core/constants/app_keys.dart';
import 'package:liga_gym_app/core/navigation/app_router.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_macros.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_product.dart';
import 'package:liga_gym_app/features/nutrition/presentation/providers/nutrition_providers.dart';
import 'package:liga_gym_app/features/nutrition/presentation/screens/add_food_screen.dart';
import 'package:liga_gym_app/features/nutrition/presentation/utils/nutrition_route_arguments.dart';

import '../support/fakes/in_memory_auth_repository.dart';
import '../support/fakes/in_memory_nutrition_repository.dart';
import '../support/test_app.dart';

void main() {
  group('AddFoodScreen', () {
    testWidgets('показывает ошибки валидации для ручного ввода', (
      tester,
    ) async {
      final authRepository = InMemoryAuthRepository();
      final nutritionRepository = InMemoryNutritionRepository();

      await tester.pumpWidget(
        buildTestApp(
          repository: authRepository,
          overrides: [
            nutritionRepositoryProvider.overrideWithValue(nutritionRepository),
          ],
          home: AddFoodScreen(
            arguments: AddFoodRouteArguments(date: DateTime(2026, 4, 9)),
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(AppKeys.addFoodContinueButton));
      await tester.tap(find.byKey(AppKeys.addFoodContinueButton));
      await tester.pump();

      expect(find.text('Enter the product name.'), findsOneWidget);
      expect(find.text('Enter valid calories per 100 g.'), findsOneWidget);
      expect(find.text('Enter a valid portion in grams.'), findsNothing);

      await authRepository.dispose();
    });

    testWidgets('показывает ошибку пустого штрихкода в barcode-режиме', (
      tester,
    ) async {
      final authRepository = InMemoryAuthRepository();
      final nutritionRepository = InMemoryNutritionRepository();

      await tester.pumpWidget(
        buildTestApp(
          repository: authRepository,
          overrides: [
            nutritionRepositoryProvider.overrideWithValue(nutritionRepository),
          ],
          home: AddFoodScreen(
            arguments: AddFoodRouteArguments(date: DateTime(2026, 4, 9)),
          ),
        ),
      );

      await tester.tap(find.text('Barcode'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(AppKeys.addFoodContinueButton));
      await tester.tap(find.byKey(AppKeys.addFoodContinueButton));
      await tester.pump();

      expect(find.text('Enter a barcode.'), findsOneWidget);

      await authRepository.dispose();
    });

    testWidgets('позволяет выбрать несколько продуктов из быстрого доступа', (
      tester,
    ) async {
      final authRepository = InMemoryAuthRepository();
      final nutritionRepository = InMemoryNutritionRepository();
      final savedProducts = [
        const FoodProduct(
          id: 'greek-yogurt',
          nameEn: 'Greek Yogurt',
          nameRu: 'Greek Yogurt',
          barcode: '4607002010012',
          macrosPer100Grams: FoodMacros(
            calories: 73,
            proteins: 10,
            fats: 2,
            carbs: 3.8,
          ),
        ),
        const FoodProduct(
          id: 'oatmeal',
          nameEn: 'Oatmeal',
          nameRu: 'Oatmeal',
          barcode: '4601234567890',
          macrosPer100Grams: FoodMacros(
            calories: 352,
            proteins: 12.3,
            fats: 6.1,
            carbs: 59.5,
          ),
        ),
      ];

      await tester.pumpWidget(
        buildTestApp(
          repository: authRepository,
          overrides: [
            nutritionRepositoryProvider.overrideWithValue(nutritionRepository),
            savedFoodProductsProvider.overrideWith(
              (ref) async => savedProducts,
            ),
          ],
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: AddFoodScreen(
            arguments: AddFoodRouteArguments(date: DateTime(2026, 4, 9)),
          ),
        ),
      );

      await tester.tap(find.text('Quick access'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Greek Yogurt'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('quickAccessGrams_greek-yogurt')),
        '150',
      );

      await tester.tap(find.text('Oatmeal'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('quickAccessGrams_oatmeal')),
        '80',
      );

      await tester.ensureVisible(find.byKey(AppKeys.addFoodContinueButton));
      await tester.tap(find.byKey(AppKeys.addFoodContinueButton));
      await tester.pumpAndSettle();

      expect(find.text('Selected products'), findsOneWidget);
      expect(find.text('Selected products: 2'), findsOneWidget);
      expect(find.text('Greek Yogurt'), findsOneWidget);
      expect(find.text('Oatmeal'), findsOneWidget);

      await authRepository.dispose();
    });
  });
}
