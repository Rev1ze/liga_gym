import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:liga_gym_app/features/auth/domain/entities/user_goal.dart';
import 'package:liga_gym_app/features/dashboard/domain/entities/dashboard_analytics.dart';

MockFirebaseAuth buildSignedInFirebaseAuth({
  required String uid,
  required String email,
  String displayName = 'Test User',
}) {
  return MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: uid, email: email, displayName: displayName),
  );
}

DashboardAnalytics buildDashboardAnalyticsFixture({DateTime? now}) {
  final today = DateTime(
    (now ?? DateTime.now()).year,
    (now ?? DateTime.now()).month,
    (now ?? DateTime.now()).day,
  );
  final days = List<DashboardDaySummary>.generate(7, (index) {
    final day = today.subtract(Duration(days: 6 - index));
    final steps = 4200 + (index * 700);
    final calories = 1650 + (index * 110);
    final progress = DashboardGoalProgress(
      steps: (steps / 10000).clamp(0, 1).toDouble(),
      calories: (calories / 2200).clamp(0, 1).toDouble(),
      overall: (((steps / 10000) + (calories / 2200)) / 2)
          .clamp(0, 1)
          .toDouble(),
    );

    return DashboardDaySummary(
      date: day,
      steps: steps,
      calories: calories.toDouble(),
      progress: progress,
    );
  });

  final todaySummary = days.last;
  return DashboardAnalytics(
    weeklyStats: DashboardWeeklyStats(days: days),
    progress: todaySummary.progress,
    goals: const DashboardUserGoals(
      stepGoal: 10000,
      calorieGoal: 2200,
      goalType: UserGoalType.loseWeight,
      currentWeightKg: 82.4,
      targetWeightKg: 76.0,
    ),
    weightAnalytics: const DashboardWeightAnalytics(
      goalType: UserGoalType.loseWeight,
      startWeightKg: 86.0,
      currentWeightKg: 82.4,
      targetWeightKg: 76.0,
      weeklyChangeKg: 0.8,
      totalChangeKg: 3.6,
      remainingToGoalKg: 6.4,
      goalProgress: 0.36,
    ),
    proteins: 132.5,
    fats: 58.0,
    carbs: 201.3,
  );
}
