import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_analytics_details_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/goal_settings_screen.dart';
import '../../features/dashboard/presentation/screens/today_overview_screen.dart';
import '../../features/dashboard/presentation/utils/goal_settings_route_arguments.dart';
import '../../features/nutrition/presentation/screens/add_food_screen.dart';
import '../../features/nutrition/presentation/screens/food_diary_screen.dart';
import '../../features/nutrition/presentation/screens/product_details_screen.dart';
import '../../features/nutrition/presentation/utils/nutrition_route_arguments.dart';
import '../../features/social/presentation/screens/chat_screen.dart';
import '../../features/social/presentation/screens/chat_room_screen.dart';
import '../../features/social/presentation/screens/leaderboard_screen.dart';
import '../../features/social/presentation/utils/chat_room_route_arguments.dart';
import '../../features/steps/presentation/screens/step_counter_screen.dart';
import '../../features/steps/presentation/screens/step_settings_screen.dart';
import '../../features/workout/presentation/screens/active_workout_screen.dart';
import '../../features/workout/presentation/screens/start_workout_screen.dart';
import '../../features/workout/presentation/screens/workout_history_screen.dart';
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
      case AppRoutes.profile:
        return _buildRoute(const ProfileScreen(), settings);
      case AppRoutes.dashboard:
        return _buildRoute(const DashboardScreen(), settings);
      case AppRoutes.todayOverview:
        return _buildRoute(const TodayOverviewScreen(), settings);
      case AppRoutes.goalSettings:
        final arguments =
            settings.arguments as GoalSettingsRouteArguments? ??
            const GoalSettingsRouteArguments(
              section: GoalSettingsSection.progress,
            );
        return _buildRoute(GoalSettingsScreen(arguments: arguments), settings);
      case AppRoutes.dashboardAnalyticsDetails:
        return _buildRoute(const DashboardAnalyticsDetailsScreen(), settings);
      case AppRoutes.chat:
        return _buildRoute(const ChatScreen(), settings);
      case AppRoutes.chatRoom:
        final arguments = settings.arguments as ChatRoomRouteArguments;
        return _buildRoute(ChatRoomScreen(arguments: arguments), settings);
      case AppRoutes.leaderboard:
        return _buildRoute(const LeaderboardScreen(), settings);
      case AppRoutes.workoutList:
        return _buildRoute(const WorkoutListScreen(), settings);
      case AppRoutes.workoutHistory:
        return _buildRoute(const WorkoutHistoryScreen(), settings);
      case AppRoutes.startWorkout:
        return _buildRoute(const StartWorkoutScreen(), settings);
      case AppRoutes.activeWorkout:
        return _buildRoute(const ActiveWorkoutScreen(), settings);
      case AppRoutes.workoutResult:
        return _buildRoute(const WorkoutResultScreen(), settings);
      case AppRoutes.foodDiary:
        return _buildRoute(const FoodDiaryScreen(), settings);
      case AppRoutes.stepCounter:
        return _buildRoute(const StepCounterScreen(), settings);
      case AppRoutes.stepSettings:
        return _buildRoute(const StepSettingsScreen(), settings);
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

  static PageRouteBuilder<void> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.025, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
