import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardUser {
  const LeaderboardUser({
    required this.userId,
    required this.displayName,
    required this.city,
    required this.score,
    required this.workoutsCount,
    required this.caloriesBurned,
    required this.stepsCount,
  });

  factory LeaderboardUser.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final displayName =
        (data['displayName'] as String?) ?? (data['name'] as String?);

    return LeaderboardUser(
      userId: document.id,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : 'Athlete',
      city: (data['city'] as String?)?.trim(),
      score:
          (data['score'] as num?)?.toInt() ??
          (data['socialScore'] as num?)?.toInt() ??
          0,
      workoutsCount:
          (data['workoutsCount'] as num?)?.toInt() ??
          (data['socialWorkoutsCount'] as num?)?.toInt() ??
          0,
      caloriesBurned:
          (data['caloriesBurned'] as num?)?.toDouble() ??
          (data['socialCaloriesBurned'] as num?)?.toDouble() ??
          0,
      stepsCount:
          (data['stepsCount'] as num?)?.toInt() ??
          (data['socialStepsCount'] as num?)?.toInt() ??
          0,
    );
  }

  final String userId;
  final String displayName;
  final String? city;
  final int score;
  final int workoutsCount;
  final double caloriesBurned;
  final int stepsCount;
}
