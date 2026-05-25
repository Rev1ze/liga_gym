import 'gender.dart';
import 'user_goal.dart';

class UserProfileUpdateData {
  const UserProfileUpdateData({
    required this.userId,
    required this.email,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.goalType,
    required this.dailyStepGoal,
    required this.dailyCalorieGoal,
    this.city,
    this.friendCode,
    this.heightCm,
    this.startWeightKg,
    this.currentWeightKg,
    this.targetWeightKg,
  });

  final String userId;
  final String email;
  final String name;
  final Gender gender;
  final DateTime birthDate;
  final String? city;
  final String? friendCode;
  final double? heightCm;
  final double? startWeightKg;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final UserGoalType goalType;
  final int dailyStepGoal;
  final double dailyCalorieGoal;
}
