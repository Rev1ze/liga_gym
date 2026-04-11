import 'gender.dart';
import 'user_goal.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.name,
    required this.gender,
    required this.birthDate,
    this.city,
    this.heightCm,
    this.startWeightKg,
    this.currentWeightKg,
    this.targetWeightKg,
    this.goalType = UserGoalType.maintainWeight,
    this.dailyStepGoal = 10000,
    this.dailyCalorieGoal = 2200,
  });

  final String userId;
  final String email;
  final String name;
  final Gender gender;
  final DateTime birthDate;
  final String? city;
  final double? heightCm;
  final double? startWeightKg;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final UserGoalType goalType;
  final int dailyStepGoal;
  final double dailyCalorieGoal;
}
