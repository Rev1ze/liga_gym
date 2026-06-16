import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/features/social/domain/entities/friend_profile.dart';
import 'package:liga_gym_app/features/social/domain/entities/social_privacy.dart';
import 'package:liga_gym_app/features/social/domain/services/friend_visibility_service.dart';

void main() {
  group('FriendVisibilityService', () {
    test('shows all shared metrics when categories allow them', () {
      final friend = _friend(
        allowedCategories: SocialPrivacyCategory.values.toSet(),
      );

      final visible = FriendVisibilityService.visibleProfile(friend);

      expect(visible.stepsCount, 12000);
      expect(visible.workoutsCount, 4);
      expect(visible.caloriesBurned, 640);
      expect(visible.score, 92);
      expect(visible.visibleInLeaderboard, isTrue);
    });

    test('hides steps without replacing them with zero', () {
      final friend = _friend(
        allowedCategories: {
          SocialPrivacyCategory.friendLeaderboard,
          SocialPrivacyCategory.goalProgress,
          SocialPrivacyCategory.workoutResults,
          SocialPrivacyCategory.nutrition,
        },
      );

      final visible = FriendVisibilityService.visibleProfile(friend);

      expect(visible.stepsCount, isNull);
      expect(visible.workoutsCount, 4);
      expect(visible.caloriesBurned, 640);
      expect(visible.score, 92);
    });

    test('hides workouts and their counters when workout data is private', () {
      final friend = _friend(
        allowedCategories: {
          SocialPrivacyCategory.friendLeaderboard,
          SocialPrivacyCategory.goalProgress,
          SocialPrivacyCategory.dailySteps,
        },
      );

      final visible = FriendVisibilityService.visibleProfile(friend);

      expect(visible.workoutsCount, isNull);
      expect(visible.stepsCount, 12000);
    });

    test('uses safe defaults when a friend has no privacy categories', () {
      final friend = _friend(allowedCategories: const {});

      final visible = FriendVisibilityService.visibleProfile(friend);

      expect(visible.displayName, 'Mira');
      expect(visible.stepsCount, isNull);
      expect(visible.workoutsCount, isNull);
      expect(visible.caloriesBurned, isNull);
      expect(visible.score, isNull);
      expect(visible.visibleInLeaderboard, isFalse);
    });

    test('excludes friends from leaderboard when score would be hidden', () {
      final visibleFriend = _friend(
        userId: 'visible',
        score: 40,
        allowedCategories: {
          SocialPrivacyCategory.friendLeaderboard,
          SocialPrivacyCategory.goalProgress,
        },
      );
      final hiddenScoreFriend = _friend(
        userId: 'hidden-score',
        score: 100,
        allowedCategories: {
          SocialPrivacyCategory.friendLeaderboard,
          SocialPrivacyCategory.dailySteps,
        },
      );
      final hiddenLeaderboardFriend = _friend(
        userId: 'hidden-leaderboard',
        score: 200,
        visibleInFriendLeaderboard: false,
        allowedCategories: {
          SocialPrivacyCategory.friendLeaderboard,
          SocialPrivacyCategory.goalProgress,
        },
      );

      final leaderboard = FriendVisibilityService.leaderboardProfiles([
        hiddenScoreFriend,
        visibleFriend,
        hiddenLeaderboardFriend,
      ]);

      expect(leaderboard.map((friend) => friend.userId), ['visible']);
      expect(leaderboard.single.score, 40);
    });
  });
}

FriendProfile _friend({
  String userId = 'friend-1',
  int score = 92,
  bool visibleInFriendLeaderboard = true,
  required Set<SocialPrivacyCategory> allowedCategories,
}) {
  return FriendProfile(
    userId: userId,
    displayName: 'Mira',
    email: 'mira@example.com',
    city: 'Kazan',
    score: score,
    workoutsCount: 4,
    caloriesBurned: 640,
    stepsCount: 12000,
    visibleInFriendLeaderboard: visibleInFriendLeaderboard,
    allowedCategories: allowedCategories,
    updatedAt: DateTime(2026, 6, 9),
  );
}
