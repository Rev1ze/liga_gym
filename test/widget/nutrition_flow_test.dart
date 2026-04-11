import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/core/constants/app_keys.dart';
import 'package:liga_gym_app/core/navigation/app_routes.dart';
import 'package:liga_gym_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:liga_gym_app/features/nutrition/presentation/providers/nutrition_providers.dart';

import '../support/fakes/in_memory_auth_repository.dart';
import '../support/fakes/in_memory_nutrition_repository.dart';
import '../support/test_app.dart';
import '../support/test_fixtures.dart';

void main() {
  testWidgets('completes manual nutrition flow from diary to saved entry', (
    tester,
  ) async {
    final authRepository = InMemoryAuthRepository();
    final nutritionRepository = InMemoryNutritionRepository();
    final firebaseAuth = buildSignedInFirebaseAuth(
      uid: 'nutrition-user',
      email: 'nutrition@ligagym.dev',
    );
    await tester.binding.setSurfaceSize(const Size(1440, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildRoutedTestApp(
        repository: authRepository,
        initialRoute: AppRoutes.foodDiary,
        overrides: [
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
          nutritionRepositoryProvider.overrideWithValue(nutritionRepository),
        ],
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.foodDiaryAddButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(AppKeys.addFoodNameField), 'Banana');
    await tester.enterText(find.byKey(AppKeys.addFoodCaloriesField), '89');
    await tester.enterText(find.byKey(AppKeys.addFoodProteinsField), '1.1');
    await tester.enterText(find.byKey(AppKeys.addFoodFatsField), '0.3');
    await tester.enterText(find.byKey(AppKeys.addFoodCarbsField), '22.8');
    await tester.enterText(find.byKey(AppKeys.addFoodGramsField), '150');

    await tester.ensureVisible(find.byKey(AppKeys.addFoodContinueButton));
    await tester.tap(find.byKey(AppKeys.addFoodContinueButton));
    await tester.pumpAndSettle();

    expect(find.text('Product details'), findsOneWidget);

    await tester.ensureVisible(find.byKey(AppKeys.productDetailsSaveButton));
    await tester.tap(find.byKey(AppKeys.productDetailsSaveButton));
    await tester.pumpAndSettle();

    final savedProducts = await nutritionRepository.loadSavedProducts(
      userId: 'nutrition-user',
    );

    expect(find.byKey(AppKeys.foodDiaryAddButton), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    expect(savedProducts, hasLength(1));

    await authRepository.dispose();
  });
}
