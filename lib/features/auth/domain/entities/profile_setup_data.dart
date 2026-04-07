import 'gender.dart';

class ProfileSetupData {
  const ProfileSetupData({
    required this.name,
    required this.gender,
    required this.birthDate,
  });

  final String name;
  final Gender gender;
  final DateTime birthDate;
}
