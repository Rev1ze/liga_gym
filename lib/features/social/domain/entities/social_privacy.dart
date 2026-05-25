enum SocialPrivacyCategory {
  calendarWorkouts,
  goalProgress,
  dailySteps,
  nutrition,
  bodyMetrics,
  workoutResults,
  friendLeaderboard,
}

extension SocialPrivacyCategoryLabel on SocialPrivacyCategory {
  String label(String languageCode) {
    final isRu = languageCode == 'ru';
    return switch (this) {
      SocialPrivacyCategory.calendarWorkouts =>
        isRu ? 'Тренировки в календаре' : 'Calendar workouts',
      SocialPrivacyCategory.goalProgress =>
        isRu ? 'Выполнение целей' : 'Goal progress',
      SocialPrivacyCategory.dailySteps => isRu ? 'Шаги за день' : 'Daily steps',
      SocialPrivacyCategory.nutrition =>
        isRu ? 'Питание и калории' : 'Nutrition and calories',
      SocialPrivacyCategory.bodyMetrics =>
        isRu ? 'Вес и замеры' : 'Weight and body metrics',
      SocialPrivacyCategory.workoutResults =>
        isRu ? 'Итоги тренировок' : 'Workout results',
      SocialPrivacyCategory.friendLeaderboard =>
        isRu ? 'Место в рейтинге друзей' : 'Friend leaderboard place',
    };
  }
}

class FriendAccessGroup {
  const FriendAccessGroup({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.allowedCategories,
  });

  factory FriendAccessGroup.fromMap(Map<String, Object?> data) {
    return FriendAccessGroup(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      memberIds:
          (data['memberIds'] as List<dynamic>?)?.whereType<String>().toSet() ??
          const <String>{},
      allowedCategories: _parseCategories(data['allowedCategories']),
    );
  }

  final String id;
  final String name;
  final Set<String> memberIds;
  final Set<SocialPrivacyCategory> allowedCategories;

  FriendAccessGroup copyWith({
    String? id,
    String? name,
    Set<String>? memberIds,
    Set<SocialPrivacyCategory>? allowedCategories,
  }) {
    return FriendAccessGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      allowedCategories: allowedCategories ?? this.allowedCategories,
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'memberIds': memberIds.toList(growable: false),
      'allowedCategories': allowedCategories
          .map((category) => category.name)
          .toList(growable: false),
    };
  }
}

class SocialPrivacySettings {
  const SocialPrivacySettings({
    required this.visibleInFriendLeaderboard,
    required this.defaultAllowedCategories,
    required this.groups,
  });

  factory SocialPrivacySettings.defaults() {
    return SocialPrivacySettings(
      visibleInFriendLeaderboard: true,
      defaultAllowedCategories: SocialPrivacyCategory.values.toSet(),
      groups: const <FriendAccessGroup>[],
    );
  }

  factory SocialPrivacySettings.fromMap(Map<String, Object?> data) {
    final groups = (data['groups'] as List<dynamic>?)
        ?.whereType<Map>()
        .map((raw) => FriendAccessGroup.fromMap(Map<String, Object?>.from(raw)))
        .where((group) => group.id.isNotEmpty && group.name.trim().isNotEmpty)
        .toList(growable: false);

    return SocialPrivacySettings(
      visibleInFriendLeaderboard:
          data['visibleInFriendLeaderboard'] as bool? ?? true,
      defaultAllowedCategories: _parseCategories(
        data['defaultAllowedCategories'],
      ),
      groups: groups ?? const <FriendAccessGroup>[],
    );
  }

  final bool visibleInFriendLeaderboard;
  final Set<SocialPrivacyCategory> defaultAllowedCategories;
  final List<FriendAccessGroup> groups;

  SocialPrivacySettings copyWith({
    bool? visibleInFriendLeaderboard,
    Set<SocialPrivacyCategory>? defaultAllowedCategories,
    List<FriendAccessGroup>? groups,
  }) {
    return SocialPrivacySettings(
      visibleInFriendLeaderboard:
          visibleInFriendLeaderboard ?? this.visibleInFriendLeaderboard,
      defaultAllowedCategories:
          defaultAllowedCategories ?? this.defaultAllowedCategories,
      groups: groups ?? this.groups,
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'visibleInFriendLeaderboard': visibleInFriendLeaderboard,
      'defaultAllowedCategories': defaultAllowedCategories
          .map((category) => category.name)
          .toList(growable: false),
      'groups': groups
          .map((group) => group.toFirestore())
          .toList(growable: false),
    };
  }
}

Set<SocialPrivacyCategory> _parseCategories(Object? raw) {
  final names = (raw as List<dynamic>?)?.whereType<String>().toSet();
  if (names == null || names.isEmpty) {
    return SocialPrivacyCategory.values.toSet();
  }

  return names
      .map(
        (name) => SocialPrivacyCategory.values.where(
          (category) => category.name == name,
        ),
      )
      .where((matches) => matches.isNotEmpty)
      .map((matches) => matches.first)
      .toSet();
}
