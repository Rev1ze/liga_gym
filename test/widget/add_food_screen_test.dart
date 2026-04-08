import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/core/constants/app_keys.dart';
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
  });
}
