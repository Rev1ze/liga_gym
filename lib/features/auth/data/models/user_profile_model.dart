import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.userId,
    required super.email,
    required super.name,
    required super.gender,
    required super.birthDate,
  });

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'email': email,
      'name': name,
      'gender': gender.name,
      'birthDate': Timestamp.fromDate(birthDate),
      'socialScore': FieldValue.increment(0),
      'socialWorkoutsCount': FieldValue.increment(0),
      'socialCaloriesBurned': FieldValue.increment(0),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
