import 'gender.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.name,
    required this.gender,
    required this.birthDate,
  });

  final String userId;
  final String email;
  final String name;
  final Gender gender;
  final DateTime birthDate;
}
