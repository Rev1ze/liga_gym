import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/nutrition/presentation/screens/add_food_screen.dart';
import '../../features/nutrition/presentation/screens/food_diary_screen.dart';
import '../../features/nutrition/presentation/screens/product_details_screen.dart';
import '../../features/nutrition/presentation/utils/nutrition_route_arguments.dart';
import '../../features/workout/presentation/screens/active_workout_screen.dart';
import '../../features/workout/presentation/screens/start_workout_screen.dart';
import '../../features/workout/presentation/screens/workout_list_screen.dart';
import '../../features/workout/presentation/screens/workout_result_screen.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);
      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);
      case AppRoutes.register:
        return _buildRoute(const RegisterScreen(), settings);
      case AppRoutes.profileSetup:
        return _buildRoute(const ProfileSetupScreen(), settings);
      case AppRoutes.dashboard:
        return _buildRoute(const DashboardScreen(), settings);
      case AppRoutes.workoutList:
        return _buildRoute(const WorkoutListScreen(), settings);
      case AppRoutes.startWorkout:
        return _buildRoute(const StartWorkoutScreen(), settings);
      case AppRoutes.activeWorkout:
        return _buildRoute(const ActiveWorkoutScreen(), settings);
      case AppRoutes.workoutResult:
        return _buildRoute(const WorkoutResultScreen(), settings);
      case AppRoutes.foodDiary:
        return _buildRoute(const FoodDiaryScreen(), settings);
      case AppRoutes.addFood:
        final arguments =
            settings.arguments as AddFoodRouteArguments? ??
            AddFoodRouteArguments(date: DateTime.now());
        return _buildRoute(AddFoodScreen(arguments: arguments), settings);
      case AppRoutes.productDetails:
        final arguments = settings.arguments as ProductDetailsRouteArguments;
        return _buildRoute(
          ProductDetailsScreen(arguments: arguments),
          settings,
        );
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  static MaterialPageRoute<void> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
