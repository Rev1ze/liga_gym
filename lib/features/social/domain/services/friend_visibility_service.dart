import '../entities/friend_profile.dart';
import '../entities/social_privacy.dart';

enum FriendDataType {
  steps,
  calories,
  workouts,
  water,
  weight,
  progress,
  achievements,
  dailySummary,
  leaderboardScore,
  streak,
  goals,
  activityStatus,
}

class VisibleFriendProfile {
  const VisibleFriendProfile({
    required this.userId,
    required this.displayName,
    required this.city,
    required this.score,
    required this.workoutsCount,
    required this.caloriesBurned,
    required this.stepsCount,
    required this.visibleInLeaderboard,
  });

  final String userId;
  final String displayName;
  final String? city;
  final int? score;
  final int? workoutsCount;
  final double? caloriesBurned;
  final int? stepsCount;
  final bool visibleInLeaderboard;

  bool get hasVisibleStats =>
      score != null ||
      workoutsCount != null ||
      caloriesBurned != null ||
      stepsCount != null;
}

abstract final class FriendVisibilityService {
  static bool canView(FriendProfile friend, FriendDataType dataType) {
    return switch (dataType) {
      FriendDataType.steps => _has(friend, SocialPrivacyCategory.dailySteps),
      FriendDataType.calories => _has(friend, SocialPrivacyCategory.nutrition),
      FriendDataType.workouts =>
        _has(friend, SocialPrivacyCategory.workoutResults) ||
            _has(friend, SocialPrivacyCategory.calendarWorkouts),
      FriendDataType.water => _has(friend, SocialPrivacyCategory.nutrition),
      FriendDataType.weight => _has(friend, SocialPrivacyCategory.bodyMetrics),
      FriendDataType.progress ||
      FriendDataType.goals ||
      FriendDataType.streak => _has(friend, SocialPrivacyCategory.goalProgress),
      FriendDataType.achievements =>
        _has(friend, SocialPrivacyCategory.workoutResults) ||
            _has(friend, SocialPrivacyCategory.goalProgress),
      FriendDataType.dailySummary =>
        _has(friend, SocialPrivacyCategory.dailySteps) &&
            _has(friend, SocialPrivacyCategory.workoutResults) &&
            _has(friend, SocialPrivacyCategory.nutrition),
      FriendDataType.activityStatus =>
        _has(friend, SocialPrivacyCategory.dailySteps) ||
            _has(friend, SocialPrivacyCategory.workoutResults) ||
            _has(friend, SocialPrivacyCategory.goalProgress),
      FriendDataType.leaderboardScore =>
        friend.visibleInFriendLeaderboard &&
            _has(friend, SocialPrivacyCategory.friendLeaderboard) &&
            _has(friend, SocialPrivacyCategory.goalProgress),
    };
  }

  static VisibleFriendProfile visibleProfile(FriendProfile friend) {
    return VisibleFriendProfile(
      userId: friend.userId,
      displayName: friend.displayName,
      city: friend.city,
      score: canView(friend, FriendDataType.progress) ? friend.score : null,
      workoutsCount: canView(friend, FriendDataType.workouts)
          ? friend.workoutsCount
          : null,
      caloriesBurned: canView(friend, FriendDataType.calories)
          ? friend.caloriesBurned
          : null,
      stepsCount: canView(friend, FriendDataType.steps)
          ? friend.stepsCount
          : null,
      visibleInLeaderboard: canView(friend, FriendDataType.leaderboardScore),
    );
  }

  static List<VisibleFriendProfile> leaderboardProfiles(
    List<FriendProfile> friends,
  ) {
    final visible = friends
        .where((friend) => canView(friend, FriendDataType.leaderboardScore))
        .map(visibleProfile)
        .where((friend) => friend.score != null)
        .toList(growable: false);
    return visible..sort((left, right) => right.score!.compareTo(left.score!));
  }

  static bool _has(FriendProfile friend, SocialPrivacyCategory category) {
    return friend.allowedCategories.contains(category);
  }
}
