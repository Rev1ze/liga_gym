import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liga_gym_app/core/constants/app_keys.dart';
import 'package:liga_gym_app/core/navigation/app_routes.dart';
import 'package:liga_gym_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:liga_gym_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:liga_gym_app/features/nutrition/presentation/providers/nutrition_providers.dart';

import '../test/support/fakes/in_memory_auth_repository.dart';
import '../test/support/fakes/in_memory_nutrition_repository.dart';
import '../test/support/test_app.dart';
import '../test/support/test_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'completes the nutrition flow from dashboard to saved diary entry',
    (tester) async {
      final authRepository = InMemoryAuthRepository();
      final nutritionRepository = InMemoryNutritionRepository();
      final firebaseAuth = buildSignedInFirebaseAuth(
        uid: 'nutrition-user',
        email: 'nutrition@ligagym.dev',
      );

      await tester.pumpWidget(
        buildRoutedTestApp(
          repository: authRepository,
          initialRoute: AppRoutes.dashboard,
          overrides: [
            firebaseAuthProvider.overrideWithValue(firebaseAuth),
            nutritionRepositoryProvider.overrideWithValue(nutritionRepository),
            dashboardAnalyticsProvider.overrideWith(
              (ref) async => buildDashboardAnalyticsFixture(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.dashboardNutritionDiaryButton));
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

      await tester.tap(find.byKey(AppKeys.productDetailsSaveButton));
      await tester.pumpAndSettle();

      final savedProducts = await nutritionRepository.loadSavedProducts(
        userId: 'nutrition-user',
      );

      expect(find.text('Food diary'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(savedProducts, hasLength(1));

      await authRepository.dispose();
    },
  );
}
