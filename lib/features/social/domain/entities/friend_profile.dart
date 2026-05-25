import 'package:cloud_firestore/cloud_firestore.dart';

import 'social_privacy.dart';

class FriendProfile {
  const FriendProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.city,
    required this.score,
    required this.workoutsCount,
    required this.caloriesBurned,
    required this.stepsCount,
    required this.visibleInFriendLeaderboard,
    required this.allowedCategories,
    required this.updatedAt,
  });

  factory FriendProfile.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return FriendProfile(
      userId: document.id,
      displayName: data['displayName'] as String? ?? 'Athlete',
      email: data['email'] as String? ?? '',
      city: (data['city'] as String?)?.trim(),
      score: (data['score'] as num?)?.toInt() ?? 0,
      workoutsCount: (data['workoutsCount'] as num?)?.toInt() ?? 0,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble() ?? 0,
      stepsCount: (data['stepsCount'] as num?)?.toInt() ?? 0,
      visibleInFriendLeaderboard:
          data['visibleInFriendLeaderboard'] as bool? ?? true,
      allowedCategories: _parseAllowedCategories(data['allowedCategories']),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  final String userId;
  final String displayName;
  final String email;
  final String? city;
  final int score;
  final int workoutsCount;
  final double caloriesBurned;
  final int stepsCount;
  final bool visibleInFriendLeaderboard;
  final Set<SocialPrivacyCategory> allowedCategories;
  final DateTime? updatedAt;

  bool canView(SocialPrivacyCategory category) {
    if (category == SocialPrivacyCategory.friendLeaderboard) {
      return visibleInFriendLeaderboard && allowedCategories.contains(category);
    }
    return allowedCategories.contains(category);
  }
}

Set<SocialPrivacyCategory> _parseAllowedCategories(Object? raw) {
  final names = (raw as List<dynamic>?)?.whereType<String>().toSet();
  if (names == null || names.isEmpty) {
    return SocialPrivacyCategory.values.toSet();
  }

  return SocialPrivacyCategory.values
      .where((category) => names.contains(category.name))
      .toSet();
}
