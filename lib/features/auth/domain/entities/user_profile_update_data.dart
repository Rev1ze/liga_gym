import 'gender.dart';
import 'user_goal.dart';

class UserProfileUpdateData {
  const UserProfileUpdateData({
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.goalType,
    required this.dailyStepGoal,
    required this.dailyCalorieGoal,
    this.heightCm,
    this.currentWeightKg,
    this.targetWeightKg,
  });

  final String name;
  final Gender gender;
  final DateTime birthDate;
  final double? heightCm;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final UserGoalType goalType;
  final int dailyStepGoal;
  final double dailyCalorieGoal;
}
