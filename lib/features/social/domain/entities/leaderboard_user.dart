import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardUser {
  const LeaderboardUser({
    required this.userId,
    required this.displayName,
    required this.score,
    required this.workoutsCount,
    required this.caloriesBurned,
  });

  factory LeaderboardUser.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return LeaderboardUser(
      userId: document.id,
      displayName: data['displayName'] as String? ?? 'Athlete',
      score: (data['score'] as num?)?.toInt() ?? 0,
      workoutsCount: (data['workoutsCount'] as num?)?.toInt() ?? 0,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble() ?? 0,
    );
  }

  final String userId;
  final String displayName;
  final int score;
  final int workoutsCount;
  final double caloriesBurned;
}
