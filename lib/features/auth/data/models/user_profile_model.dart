import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/gender.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_goal.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.userId,
    required super.email,
    required super.name,
    required super.gender,
    required super.birthDate,
    super.city,
    super.heightCm,
    super.startWeightKg,
    super.currentWeightKg,
    super.targetWeightKg,
    super.goalType,
    super.dailyStepGoal,
    super.dailyCalorieGoal,
  });

  factory UserProfileModel.fromFirestore(
    String userId,
    Map<String, Object?> data,
  ) {
    final birthDateTimestamp = data['birthDate'] as Timestamp?;

    return UserProfileModel(
      userId: userId,
      email: (data['email'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      gender: _parseGender((data['gender'] as String?) ?? ''),
      birthDate:
          birthDateTimestamp?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      city: (data['city'] as String?)?.trim(),
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      startWeightKg: (data['startWeightKg'] as num?)?.toDouble(),
      currentWeightKg: (data['currentWeightKg'] as num?)?.toDouble(),
      targetWeightKg: (data['targetWeightKg'] as num?)?.toDouble(),
      goalType: _parseGoalType((data['goalType'] as String?) ?? ''),
      dailyStepGoal: (data['dailyStepGoal'] as num?)?.toInt() ?? 10000,
      dailyCalorieGoal: (data['dailyCalorieGoal'] as num?)?.toDouble() ?? 2200,
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'email': email,
      'name': name,
      'gender': gender.name,
      'birthDate': Timestamp.fromDate(birthDate),
      'city': city,
      'countryCode': 'RU',
      'heightCm': heightCm,
      'startWeightKg': startWeightKg,
      'currentWeightKg': currentWeightKg,
      'targetWeightKg': targetWeightKg,
      'goalType': goalType.name,
      'dailyStepGoal': dailyStepGoal,
      'dailyCalorieGoal': dailyCalorieGoal,
      'socialScore': FieldValue.increment(0),
      'socialWorkoutsCount': FieldValue.increment(0),
      'socialCaloriesBurned': FieldValue.increment(0),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static Gender _parseGender(String value) {
    return Gender.values.firstWhere(
      (gender) => gender.name == value,
      orElse: () => Gender.other,
    );
  }

  static UserGoalType _parseGoalType(String value) {
    return UserGoalType.values.firstWhere(
      (goalType) => goalType.name == value,
      orElse: () => UserGoalType.maintainWeight,
    );
  }
}
