// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../coach/domain/entities/coach_trainer.dart';
import '../../../coach/domain/entities/student_workout_assignment.dart';
import '../../../coach/domain/entities/trainer_exercise.dart';
import '../../../coach/domain/entities/trainer_recipe.dart';
import '../../../coach/domain/entities/trainer_workout_template.dart';
import '../../../coach/presentation/providers/coach_providers.dart';
import '../../domain/entities/friend_profile.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/entities/leaderboard_user.dart';
import '../../domain/entities/social_privacy.dart';
import '../../domain/services/friend_visibility_service.dart';
import '../providers/social_providers.dart';
import '../utils/chat_room_route_arguments.dart';
import '../utils/trainer_materials_route_arguments.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = _SocialCopy.of(context);
    final friendsState = ref.watch(friendsProvider);
    final currentUser = ref.watch(currentFirebaseUserProvider);
    final leaderboardState = ref.watch(leaderboardProvider);

    return LigaPremiumScaffold(
      appBar: AppBar(
        title: Text(copy.friendLeaderboardTitle),
        actions: [
          IconButton(
            tooltip: _localized(context, ru: 'Настройки', en: 'Settings'),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.leaderboardSettings),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                copy.friendLeaderboardSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: currentUser == null
            ? Center(child: Text(copy.unauthorized))
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: friendsState.when(
                    loading: () => ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                      children: const [SkeletonCard(height: 360)],
                    ),
                    error: (error, _) => ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                      children: [
                        _ErrorCard(message: _leaderboardError(context, error)),
                      ],
                    ),
                    data: (friends) => ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                      children: [
                        leaderboardState.when(
                          data: (users) => _FriendLeaderboardCard(
                            copy: copy,
                            friends: friends,
                            currentUserId: currentUser.uid,
                            currentUser: _currentLeaderboardUser(
                              users,
                              currentUser.uid,
                            ),
                          ),
                          error: (_, _) => _FriendLeaderboardCard(
                            copy: copy,
                            friends: friends,
                            currentUserId: currentUser.uid,
                            currentUser: null,
                          ),
                          loading: () => const SkeletonCard(height: 360),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  static String _leaderboardError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    return error is AppException
        ? error.code.localize(l10n)
        : l10n.errorLeaderboardLoadFailed;
  }

  static LeaderboardUser? _currentLeaderboardUser(
    List<LeaderboardUser> users,
    String currentUserId,
  ) {
    for (final user in users) {
      if (user.userId == currentUserId) {
        return user;
      }
    }
    return null;
  }
}

extension _FriendProfileCopy on _SocialCopy {
  String get friendProfileTapHint => 'Open profile to see shared data';
  String get friendProfileNoSharedData => 'This user has hidden their stats.';
  String get hiddenValue => 'hidden';
  String get stepsTitle => 'Steps';
  String get workoutsTitle => 'Workouts';
  String get progressTitle => 'Progress';
  String get caloriesTitle => 'Calories';
  String get leaderboardAccessTitle => 'Leaderboard';
  String get leaderboardShared => 'shared';
  String get leaderboardYouBadge => isRu ? 'Вы' : 'You';

  String stepsLabel(String value) => '$value steps';
  String workoutsLabel(String value) => '$value workouts';
  String scoreLabel(String value) => '$value pts';
}

class LeaderboardSettingsScreen extends ConsumerWidget {
  const LeaderboardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = _SocialCopy.of(context);
    final currentUser = ref.watch(currentFirebaseUserProvider);
    final privacyState = ref.watch(socialPrivacySettingsProvider);
    final friendsState = ref.watch(friendsProvider);

    return LigaPremiumScaffold(
      appBar: AppBar(
        title: Text(
          _localized(
            context,
            ru: 'Настройки лидерборда',
            en: 'Leaderboard settings',
          ),
        ),
      ),
      child: SafeArea(
        child: currentUser == null
            ? Center(child: Text(copy.unauthorized))
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    children: [
                      privacyState.when(
                        data: (settings) => friendsState.when(
                          data: (friends) => _PrivacyCard(
                            copy: copy,
                            settings: settings,
                            friends: friends,
                            onSave: (next) => _savePrivacy(
                              context,
                              ref,
                              currentUser.uid,
                              next,
                            ),
                          ),
                          error: (error, _) =>
                              _ErrorCard(message: _messageFor(context, error)),
                          loading: () => const SkeletonCard(height: 260),
                        ),
                        error: (error, _) =>
                            _ErrorCard(message: _messageFor(context, error)),
                        loading: () => const SkeletonCard(height: 260),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Text(
                          _localized(
                            context,
                            ru: 'Эти настройки управляют показом вас в лидерборде и доступом друзей к социальным показателям.',
                            en: 'These settings control your leaderboard visibility and friends access to social metrics.',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _savePrivacy(
    BuildContext context,
    WidgetRef ref,
    String userId,
    SocialPrivacySettings settings,
  ) async {
    final copy = _SocialCopy.of(context);
    try {
      await ref
          .read(socialRepositoryProvider)
          .savePrivacySettings(userId: userId, settings: settings);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.settingsSaved)));
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(context, error))));
    }
  }

  static String _messageFor(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    return error is AppException
        ? error.code.localize(l10n)
        : l10n.errorUnknown;
  }
}

class _LeaderboardLoadingList extends StatelessWidget {
  const _LeaderboardLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: const [SkeletonCard(height: 360)],
    );
  }
}

class _LeaderboardStatsStrip extends StatelessWidget {
  const _LeaderboardStatsStrip({
    required this.users,
    required this.currentUserId,
  });

  final List<LeaderboardUser> users;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final currentIndex = users.indexWhere(
      (user) => user.userId == currentUserId,
    );
    final currentUser = currentIndex == -1 ? null : users[currentIndex];
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _CountPill(
            icon: Icons.emoji_events_rounded,
            label: currentIndex == -1
                ? _localized(context, ru: 'Место -', en: 'Rank -')
                : _localized(
                    context,
                    ru: 'Место ${currentIndex + 1}',
                    en: 'Rank ${currentIndex + 1}',
                  ),
            color: Theme.of(context).colorScheme.primary,
          ),
          _CountPill(
            icon: Icons.star_rounded,
            label: formatter.format(currentUser?.score ?? 0),
            color: Theme.of(context).colorScheme.secondary,
          ),
          _CountPill(
            icon: Icons.groups_rounded,
            label: _localized(
              context,
              ru: '${users.length} участников',
              en: '${users.length} athletes',
            ),
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTableCard extends StatelessWidget {
  const _LeaderboardTableCard({
    required this.users,
    required this.currentUserId,
    required this.emptyText,
  });

  final List<LeaderboardUser> users;
  final String currentUserId;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: users.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(emptyText, textAlign: TextAlign.center),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 680) {
                      return Column(
                        children: [
                          for (var i = 0; i < users.length; i++) ...[
                            _LeaderboardMobileRow(
                              position: i + 1,
                              user: users[i],
                              isCurrentUser: users[i].userId == currentUserId,
                            ),
                            if (i != users.length - 1)
                              const Divider(height: 20),
                          ],
                        ],
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 22,
                        headingRowHeight: 38,
                        dataRowMinHeight: 58,
                        dataRowMaxHeight: 68,
                        columns: [
                          DataColumn(label: Text('#')),
                          DataColumn(
                            label: Text(
                              _localized(
                                context,
                                ru: 'Спортсмен',
                                en: 'Athlete',
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              _localized(context, ru: 'Город', en: 'City'),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              _localized(context, ru: 'Очки', en: 'Points'),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              _localized(
                                context,
                                ru: 'Тренировки',
                                en: 'Workouts',
                              ),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              _localized(context, ru: 'Шаги', en: 'Steps'),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              _localized(context, ru: 'Ккал', en: 'Kcal'),
                            ),
                          ),
                        ],
                        rows: [
                          for (var i = 0; i < users.length; i++)
                            _leaderboardDataRow(
                              context,
                              position: i + 1,
                              user: users[i],
                              isCurrentUser: users[i].userId == currentUserId,
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  DataRow _leaderboardDataRow(
    BuildContext context, {
    required int position,
    required LeaderboardUser user,
    required bool isCurrentUser,
  }) {
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final colorScheme = Theme.of(context).colorScheme;
    return DataRow(
      color: WidgetStatePropertyAll(
        isCurrentUser
            ? colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
      ),
      cells: [
        DataCell(Text('$position')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                child: Text(_avatarLabel(user.displayName)),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  isCurrentUser
                      ? '${user.displayName} (${AppLocalizations.of(context)!.leaderboardYou})'
                      : user.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(Text((user.city ?? '').isEmpty ? '-' : user.city!)),
        DataCell(Text(formatter.format(user.score))),
        DataCell(Text(formatter.format(user.workoutsCount))),
        DataCell(Text(formatter.format(user.stepsCount))),
        DataCell(Text(formatter.format(user.caloriesBurned.round()))),
      ],
    );
  }
}

class _LeaderboardMobileRow extends StatelessWidget {
  const _LeaderboardMobileRow({
    required this.position,
    required this.user,
    required this.isCurrentUser,
  });

  final int position;
  final LeaderboardUser user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(child: Text('$position')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrentUser
                        ? '${user.displayName} (${AppLocalizations.of(context)!.leaderboardYou})'
                        : user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      if ((user.city ?? '').isNotEmpty) user.city!,
                      AppLocalizations.of(
                        context,
                      )!.leaderboardPoints(formatter.format(user.score)),
                      AppLocalizations.of(context)!.leaderboardWorkouts(
                        formatter.format(user.workoutsCount),
                      ),
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricChip(
                        icon: Icons.directions_walk_rounded,
                        label: AppLocalizations.of(
                          context,
                        )!.leaderboardSteps(formatter.format(user.stepsCount)),
                      ),
                      _MetricChip(
                        icon: Icons.local_fire_department_rounded,
                        label:
                            '${formatter.format(user.caloriesBurned.round())} kcal',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

String _localized(
  BuildContext context, {
  required String ru,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode == 'ru' ? ru : en;
}

String _avatarLabel(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
}

class SocialHubScreen extends ConsumerStatefulWidget {
  const SocialHubScreen({super.key});

  @override
  ConsumerState<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends ConsumerState<SocialHubScreen> {
  final _inviteController = TextEditingController();
  String? _inviteLink;
  bool _isBusy = false;
  String? _openingFriendId;

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _SocialCopy.of(context);
    final friendsState = ref.watch(friendsProvider);
    final requestsState = ref.watch(incomingFriendRequestsProvider);
    final privacyState = ref.watch(socialPrivacySettingsProvider);
    final trainersState = ref.watch(linkedCoachTrainersProvider);
    final currentUser = ref.watch(currentFirebaseUserProvider);

    return LigaPremiumScaffold(
      appBar: AppBar(
        title: Text(copy.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                copy.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: currentUser == null
            ? Center(child: Text(copy.unauthorized))
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    children: [
                      _SocialHubHeader(
                        copy: copy,
                        friendsCount: friendsState.asData?.value.length ?? 0,
                        trainersCount: trainersState.asData?.value.length ?? 0,
                      ).premiumEntrance(),
                      const SizedBox(height: 12),
                      _InviteCard(
                        copy: copy,
                        inviteLink: _inviteLink,
                        inviteController: _inviteController,
                        isBusy: _isBusy,
                        onCreateInvite: () => _createInvite(currentUser),
                        onSendRequest: () => _sendRequest(currentUser),
                      ).premiumEntrance(),
                      const SizedBox(height: 12),
                      requestsState.when(
                        data: (requests) => _RequestsCard(
                          copy: copy,
                          requests: requests,
                          onAccept: (request) => _acceptRequest(request),
                          onDecline: (request) => _declineRequest(request),
                        ),
                        error: (error, _) =>
                            _ErrorCard(message: _messageFor(error)),
                        loading: () => const SkeletonCard(height: 118),
                      ),
                      const SizedBox(height: 12),
                      friendsState.when(
                        data: (friends) => _FriendsListCard(
                          copy: copy,
                          friends: friends,
                          openingFriendId: _openingFriendId,
                          onMessage: _openFriendChat,
                          onRemove: (friend) =>
                              _removeFriend(currentUser.uid, friend.userId),
                        ),
                        error: (error, _) =>
                            _ErrorCard(message: _messageFor(error)),
                        loading: () => const SkeletonCard(height: 168),
                      ),
                      const SizedBox(height: 12),
                      friendsState.when(
                        data: (friends) => _OpenFriendLeaderboardCard(
                          copy: copy,
                          friendsCount: friends.length,
                          onOpen: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.leaderboard),
                        ),
                        error: (error, _) =>
                            _ErrorCard(message: _messageFor(error)),
                        loading: () => const SkeletonCard(height: 96),
                      ),
                      const SizedBox(height: 12),
                      trainersState.when(
                        data: (trainers) => _TrainersTableCard(
                          copy: copy,
                          trainers: trainers,
                          onOpen: _openTrainerContent,
                        ),
                        error: (error, _) =>
                            _ErrorCard(message: _messageFor(error)),
                        loading: () => const SkeletonCard(height: 168),
                      ),
                      const SizedBox(height: 12),
                      privacyState.when(
                        data: (settings) => friendsState.when(
                          data: (friends) => _PrivacyCard(
                            copy: copy,
                            settings: settings,
                            friends: friends,
                            onSave: _savePrivacy,
                          ),
                          error: (error, _) =>
                              _ErrorCard(message: _messageFor(error)),
                          loading: () => const SkeletonCard(height: 220),
                        ),
                        error: (error, _) =>
                            _ErrorCard(message: _messageFor(error)),
                        loading: () => const SkeletonCard(height: 220),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _createInvite(User currentUser) async {
    final copy = _SocialCopy.of(context);
    final profile = await ref.read(currentUserProfileProvider.future);
    final friendCode = profile?.friendCode?.trim() ?? '';
    if (friendCode.isEmpty) {
      _showSnack(copy.friendCodeMissing);
      return;
    }

    setState(() => _isBusy = true);
    try {
      final email = currentUser.email ?? '';
      final inviteCode = await ref
          .read(socialRepositoryProvider)
          .createFriendInvite(
            userId: currentUser.uid,
            fallbackName: currentUser.displayName ?? email.split('@').first,
            fallbackEmail: email,
          );
      setState(() {
        _inviteLink = 'https://liga.gym/friends/add?invite=$inviteCode';
      });
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _sendRequest(User currentUser) async {
    final value = _inviteController.text.trim();
    if (value.isEmpty) {
      return;
    }
    final copy = _SocialCopy.of(context);

    setState(() => _isBusy = true);
    try {
      final email = currentUser.email ?? '';
      await ref
          .read(socialRepositoryProvider)
          .sendFriendRequest(
            fromUserId: currentUser.uid,
            inviteCodeOrLink: value,
            fallbackName: currentUser.displayName ?? email.split('@').first,
            fallbackEmail: email,
          );
      _inviteController.clear();
      _showSnack(copy.requestSent);
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    final userId = ref.read(currentFirebaseUserProvider)?.uid;
    if (userId == null) {
      return;
    }
    final copy = _SocialCopy.of(context);
    try {
      await ref
          .read(socialRepositoryProvider)
          .acceptFriendRequest(requestId: request.id, userId: userId);
      _showSnack(copy.requestAccepted);
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _declineRequest(FriendRequest request) async {
    final userId = ref.read(currentFirebaseUserProvider)?.uid;
    if (userId == null) {
      return;
    }
    try {
      await ref
          .read(socialRepositoryProvider)
          .declineFriendRequest(requestId: request.id, userId: userId);
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _removeFriend(String userId, String friendId) async {
    try {
      await ref
          .read(socialRepositoryProvider)
          .removeFriend(userId: userId, friendId: friendId);
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _openFriendChat(FriendProfile friend) async {
    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser == null || _openingFriendId != null) {
      return;
    }

    setState(() {
      _openingFriendId = friend.userId;
    });

    try {
      final email = currentUser.email ?? '';
      final chatId = await ref
          .read(socialRepositoryProvider)
          .openFriendChat(
            userId: currentUser.uid,
            friendId: friend.userId,
            friendName: friend.displayName,
            fallbackName: currentUser.displayName ?? email.split('@').first,
            fallbackEmail: email,
          );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushNamed(
        AppRoutes.chatRoom,
        arguments: ChatRoomRouteArguments(
          chatId: chatId,
          title: friend.displayName,
        ),
      );
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _openingFriendId = null;
        });
      }
    }
  }

  Future<void> _savePrivacy(SocialPrivacySettings settings) async {
    final userId = ref.read(currentFirebaseUserProvider)?.uid;
    if (userId == null) {
      return;
    }
    final copy = _SocialCopy.of(context);
    try {
      await ref
          .read(socialRepositoryProvider)
          .savePrivacySettings(userId: userId, settings: settings);
      _showSnack(copy.settingsSaved);
    } on Object catch (error) {
      _showError(error);
    }
  }

  void _openTrainerContent(CoachTrainer trainer) {
    Navigator.of(context).pushNamed(
      AppRoutes.trainerMaterials,
      arguments: TrainerMaterialsRouteArguments(trainer: trainer),
    );
  }

  String _messageFor(Object error) {
    final l10n = AppLocalizations.of(context)!;
    return error is AppException
        ? error.code.localize(l10n)
        : l10n.errorUnknown;
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    _showSnack(_messageFor(error));
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SocialHubHeader extends StatelessWidget {
  const _SocialHubHeader({
    required this.copy,
    required this.friendsCount,
    required this.trainersCount,
  });

  final _SocialCopy copy;
  final int friendsCount;
  final int trainersCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      tint: colorScheme.primary.withValues(alpha: 0.10),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
              child: const Icon(Icons.hub_rounded, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.hubTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CountPill(
                        icon: Icons.group_rounded,
                        label: copy.friendsCount(friendsCount),
                        color: colorScheme.secondary,
                      ),
                      _CountPill(
                        icon: Icons.workspace_premium_rounded,
                        label: copy.trainersCount(trainersCount),
                        color: colorScheme.tertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.copy,
    required this.inviteLink,
    required this.inviteController,
    required this.isBusy,
    required this.onCreateInvite,
    required this.onSendRequest,
  });

  final _SocialCopy copy;
  final String? inviteLink;
  final TextEditingController inviteController;
  final bool isBusy;
  final VoidCallback onCreateInvite;
  final VoidCallback onSendRequest;

  @override
  Widget build(BuildContext context) {
    final link = inviteLink;
    final shareText = link == null
        ? null
        : 'Привет, я пользуюсь приложением liga gym, а ты? $link';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: copy.inviteTitle,
            subtitle: copy.inviteSubtitle,
            action: FilledButton.icon(
              onPressed: isBusy ? null : onCreateInvite,
              icon: const Icon(Icons.qr_code_2_rounded),
              label: Text(copy.createInvite),
            ),
          ),
          if (link != null) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 680;
                final qr = DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: QrImageView(data: link, size: 142),
                  ),
                );
                final actions = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableText(link),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              Clipboard.setData(ClipboardData(text: link)),
                          icon: const Icon(Icons.copy_rounded),
                          label: Text(copy.copyLink),
                        ),
                        FilledButton.icon(
                          onPressed: shareText == null
                              ? null
                              : () => SharePlus.instance.share(
                                  ShareParams(text: shareText),
                                ),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: Text(copy.share),
                        ),
                      ],
                    ),
                  ],
                );
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          qr,
                          const SizedBox(width: 18),
                          Expanded(child: actions),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(alignment: Alignment.centerLeft, child: qr),
                          const SizedBox(height: 14),
                          actions,
                        ],
                      );
              },
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: inviteController,
            decoration: InputDecoration(
              labelText: copy.pasteInvite,
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: IconButton(
                onPressed: isBusy ? null : onSendRequest,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                tooltip: copy.sendRequest,
              ),
            ),
            onSubmitted: (_) => onSendRequest(),
          ),
        ],
      ),
    );
  }
}

class _RequestsCard extends StatelessWidget {
  const _RequestsCard({
    required this.copy,
    required this.requests,
    required this.onAccept,
    required this.onDecline,
  });

  final _SocialCopy copy;
  final List<FriendRequest> requests;
  final ValueChanged<FriendRequest> onAccept;
  final ValueChanged<FriendRequest> onDecline;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: copy.requestsTitle),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            Text(copy.requestsEmpty)
          else
            for (final request in requests) ...[
              _RequestRow(
                request: request,
                copy: copy,
                onAccept: () => onAccept(request),
                onDecline: () => onDecline(request),
              ),
              if (request != requests.last) const Divider(height: 22),
            ],
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.copy,
    required this.onAccept,
    required this.onDecline,
  });

  final FriendRequest request;
  final _SocialCopy copy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(child: Text(request.fromDisplayName.characters.first)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            request.fromDisplayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: copy.decline,
          onPressed: onDecline,
          icon: const Icon(Icons.close_rounded),
        ),
        FilledButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.check_rounded),
          label: Text(copy.accept),
        ),
      ],
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.copy,
    required this.settings,
    required this.friends,
    required this.onSave,
  });

  final _SocialCopy copy;
  final SocialPrivacySettings settings;
  final List<FriendProfile> friends;
  final ValueChanged<SocialPrivacySettings> onSave;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: copy.privacyTitle,
            subtitle: copy.privacySubtitle,
            action: IconButton(
              onPressed: () async {
                final group = await _editGroupDialog(context, copy, friends);
                if (group == null) {
                  return;
                }
                onSave(settings.copyWith(groups: [...settings.groups, group]));
              },
              tooltip: copy.addGroup,
              icon: const Icon(Icons.group_add_rounded),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: settings.visibleInFriendLeaderboard,
            onChanged: (value) =>
                onSave(settings.copyWith(visibleInFriendLeaderboard: value)),
            contentPadding: EdgeInsets.zero,
            title: Text(copy.friendLeaderboardSwitch),
            subtitle: Text(copy.friendLeaderboardHint),
          ),
          const Divider(height: 24),
          Text(
            copy.defaultAccess,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final category in SocialPrivacyCategory.values)
                FilterChip(
                  selected: settings.defaultAllowedCategories.contains(
                    category,
                  ),
                  onSelected: (selected) {
                    final updated = {...settings.defaultAllowedCategories};
                    selected ? updated.add(category) : updated.remove(category);
                    onSave(
                      settings.copyWith(defaultAllowedCategories: updated),
                    );
                  },
                  label: Text(category.label(languageCode)),
                ),
            ],
          ),
          if (settings.groups.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              copy.groupsTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final group in settings.groups) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.48,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_2_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${group.name} · ${copy.peopleCount(group.memberIds.length)}',
                      ),
                    ),
                    IconButton(
                      tooltip: copy.edit,
                      icon: const Icon(Icons.tune_rounded),
                      onPressed: () async {
                        final edited = await _editGroupDialog(
                          context,
                          copy,
                          friends,
                          group: group,
                        );
                        if (edited == null) {
                          return;
                        }
                        onSave(
                          settings.copyWith(
                            groups: [
                              for (final item in settings.groups)
                                if (item.id == group.id) edited else item,
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: copy.delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => onSave(
                        settings.copyWith(
                          groups: settings.groups
                              .where((item) => item.id != group.id)
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (group != settings.groups.last) const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _FriendLeaderboardCard extends StatelessWidget {
  const _FriendLeaderboardCard({
    required this.copy,
    required this.friends,
    required this.currentUserId,
    required this.currentUser,
  });

  final _SocialCopy copy;
  final List<FriendProfile> friends;
  final String currentUserId;
  final LeaderboardUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final visibleFriends = FriendVisibilityService.leaderboardProfiles(friends);
    final entries = <_FriendLeaderboardEntry>[
      for (final friend in visibleFriends)
        if (friend.userId != currentUserId)
          _FriendLeaderboardEntry.friend(friend),
      if (currentUser != null) _FriendLeaderboardEntry.current(currentUser!),
    ]..sort((left, right) => right.score.compareTo(left.score));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: copy.friendLeaderboardTitle,
            subtitle: copy.friendLeaderboardSubtitle,
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(copy.friendLeaderboardEmpty)
          else
            for (var i = 0; i < entries.length; i++) ...[
              _LeaderboardFriendRow(
                copy: copy,
                position: i + 1,
                entry: entries[i],
              ),
              if (i != entries.length - 1) const Divider(height: 22),
            ],
        ],
      ),
    );
  }
}

class _FriendLeaderboardEntry {
  const _FriendLeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.score,
    required this.workoutsCount,
    required this.stepsCount,
    required this.isCurrentUser,
  });

  factory _FriendLeaderboardEntry.friend(VisibleFriendProfile friend) {
    return _FriendLeaderboardEntry(
      displayName: friend.displayName,
      userId: friend.userId,
      score: friend.score ?? 0,
      workoutsCount: friend.workoutsCount,
      stepsCount: friend.stepsCount,
      isCurrentUser: false,
    );
  }

  factory _FriendLeaderboardEntry.current(LeaderboardUser user) {
    return _FriendLeaderboardEntry(
      displayName: user.displayName,
      userId: user.userId,
      score: user.score,
      workoutsCount: user.workoutsCount,
      stepsCount: user.stepsCount,
      isCurrentUser: true,
    );
  }

  final String displayName;
  final String userId;
  final int score;
  final int? workoutsCount;
  final int? stepsCount;
  final bool isCurrentUser;
}

class _LeaderboardFriendRow extends StatelessWidget {
  const _LeaderboardFriendRow({
    required this.copy,
    required this.position,
    required this.entry,
  });

  final _SocialCopy copy;
  final int position;
  final _FriendLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Row(
      children: [
        CircleAvatar(child: Text('$position')),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (entry.isCurrentUser) ...[
                const SizedBox(height: 4),
                _CurrentUserBadge(label: copy.leaderboardYouBadge),
              ],
              const SizedBox(height: 4),
              Text(
                copy.friendLeaderboardMeta(
                  score: formatter.format(entry.score),
                  workouts: entry.workoutsCount == null
                      ? copy.hiddenValue
                      : formatter.format(entry.workoutsCount),
                  steps: entry.stepsCount == null
                      ? copy.hiddenValue
                      : formatter.format(entry.stepsCount),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentUserBadge extends StatelessWidget {
  const _CurrentUserBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FriendsListCard extends StatelessWidget {
  const _FriendsListCard({
    required this.copy,
    required this.friends,
    required this.openingFriendId,
    required this.onMessage,
    required this.onRemove,
  });

  final _SocialCopy copy;
  final List<FriendProfile> friends;
  final String? openingFriendId;
  final ValueChanged<FriendProfile> onMessage;
  final ValueChanged<FriendProfile> onRemove;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: copy.friendsTitle),
          const SizedBox(height: 12),
          if (friends.isEmpty)
            Text(copy.friendsEmpty)
          else
            for (final friend in friends) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _showFriendProfile(context, copy, friend),
                leading: CircleAvatar(
                  child: Text(_avatarLabel(friend.displayName)),
                ),
                title: Text(
                  friend.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: _FriendListSubtitle(copy: copy, friend: friend),
                trailing: Wrap(
                  spacing: 2,
                  children: [
                    IconButton(
                      tooltip: copy.messageFriend,
                      onPressed: openingFriendId == null
                          ? () => onMessage(friend)
                          : null,
                      icon: openingFriendId == friend.userId
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_bubble_outline_rounded),
                    ),
                    IconButton(
                      tooltip: copy.removeFriend,
                      onPressed: () => onRemove(friend),
                      icon: const Icon(Icons.person_remove_alt_1_rounded),
                    ),
                  ],
                ),
              ),
              if (friend != friends.last) const Divider(height: 24),
            ],
        ],
      ),
    );
  }

  Future<void> _showFriendProfile(
    BuildContext context,
    _SocialCopy copy,
    FriendProfile friend,
  ) {
    final visible = FriendVisibilityService.visibleProfile(friend);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              child: _FriendProfileSheet(copy: copy, friend: visible),
            ),
          ),
        );
      },
    );
  }
}

class _FriendListSubtitle extends StatelessWidget {
  const _FriendListSubtitle({required this.copy, required this.friend});

  final _SocialCopy copy;
  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    final visible = FriendVisibilityService.visibleProfile(friend);
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final parts = [
      if ((visible.city ?? '').isNotEmpty) visible.city!,
      if (visible.stepsCount != null)
        copy.stepsLabel(formatter.format(visible.stepsCount)),
      if (visible.workoutsCount != null)
        copy.workoutsLabel(formatter.format(visible.workoutsCount)),
      if (visible.score != null)
        copy.scoreLabel(formatter.format(visible.score)),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        parts.isEmpty ? copy.friendProfileTapHint : parts.join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _FriendProfileSheet extends StatelessWidget {
  const _FriendProfileSheet({required this.copy, required this.friend});

  final _SocialCopy copy;
  final VisibleFriendProfile friend;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final metricTiles = <Widget>[
      if (friend.stepsCount != null)
        _FriendMetricTile(
          icon: Icons.directions_walk_rounded,
          label: copy.stepsTitle,
          value: formatter.format(friend.stepsCount),
        ),
      if (friend.workoutsCount != null)
        _FriendMetricTile(
          icon: Icons.fitness_center_rounded,
          label: copy.workoutsTitle,
          value: formatter.format(friend.workoutsCount),
        ),
      if (friend.score != null)
        _FriendMetricTile(
          icon: Icons.trending_up_rounded,
          label: copy.progressTitle,
          value: formatter.format(friend.score),
        ),
      if (friend.caloriesBurned != null)
        _FriendMetricTile(
          icon: Icons.local_fire_department_rounded,
          label: copy.caloriesTitle,
          value: formatter.format(friend.caloriesBurned!.round()),
        ),
      if (friend.visibleInLeaderboard)
        _FriendMetricTile(
          icon: Icons.leaderboard_rounded,
          label: copy.leaderboardAccessTitle,
          value: copy.leaderboardShared,
        ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Text(_avatarLabel(friend.displayName)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((friend.city ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(friend.city!),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (metricTiles.isEmpty)
            Text(copy.friendProfileNoSharedData)
          else
            for (final tile in metricTiles) ...[
              tile,
              if (tile != metricTiles.last) const Divider(height: 18),
            ],
        ],
      ),
    );
  }
}

class _FriendMetricTile extends StatelessWidget {
  const _FriendMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _OpenFriendLeaderboardCard extends StatelessWidget {
  const _OpenFriendLeaderboardCard({
    required this.copy,
    required this.friendsCount,
    required this.onOpen,
  });

  final _SocialCopy copy;
  final int friendsCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
            child: Icon(Icons.leaderboard_rounded, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.friendLeaderboardTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy.friendLeaderboardEntrySubtitle(friendsCount),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(copy.openLeaderboard),
          ),
        ],
      ),
    );
  }
}

class _TrainersTableCard extends StatelessWidget {
  const _TrainersTableCard({
    required this.copy,
    required this.trainers,
    required this.onOpen,
  });

  final _SocialCopy copy;
  final List<CoachTrainer> trainers;
  final ValueChanged<CoachTrainer> onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: copy.trainersTitle,
            subtitle: copy.trainersSubtitle,
          ),
          const SizedBox(height: 12),
          if (trainers.isEmpty)
            Text(copy.trainersEmpty)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                headingRowHeight: 38,
                dataRowMinHeight: 54,
                dataRowMaxHeight: 64,
                columns: [
                  DataColumn(label: Text(copy.trainerColumnName)),
                  DataColumn(label: Text(copy.trainerColumnEmail)),
                  DataColumn(label: Text(copy.trainerColumnMaterials)),
                ],
                rows: [
                  for (final trainer in trainers)
                    DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded),
                              const SizedBox(width: 8),
                              Text(trainer.name),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(trainer.email.isEmpty ? '-' : trainer.email),
                        ),
                        DataCell(
                          IconButton.filledTonal(
                            tooltip: copy.viewTrainerMaterials,
                            onPressed: () => onOpen(trainer),
                            icon: const Icon(Icons.folder_special_rounded),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrainerContentSheet extends ConsumerWidget {
  const _TrainerContentSheet({required this.trainer});

  final CoachTrainer trainer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = _SocialCopy.of(context);
    final state = ref.watch(trainerSharedContentProvider(trainer.id));
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
              ),
            ],
          ),
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(18),
              children: [_ErrorCard(message: error.toString())],
            ),
            data: (content) => _TrainerContentList(
              copy: copy,
              trainer: trainer,
              content: content,
              controller: scrollController,
            ),
          ),
        );
      },
    );
  }
}

class _TrainerContentList extends StatelessWidget {
  const _TrainerContentList({
    required this.copy,
    required this.trainer,
    required this.content,
    required this.controller,
  });

  final _SocialCopy copy;
  final CoachTrainer trainer;
  final TrainerSharedContent content;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SectionHeader(
          title: trainer.name,
          subtitle: trainer.email.isEmpty
              ? copy.trainerMaterials
              : trainer.email,
          action: IconButton(
            tooltip: copy.close,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        const SizedBox(height: 12),
        _TrainerContentStats(content: content, copy: copy),
        const SizedBox(height: 12),
        _TrainerAssignedWorkoutsSection(
          copy: copy,
          workouts: content.assignedWorkouts,
        ),
        _TrainerRecipesSection(
          title: copy.assignedRecipesTitle,
          emptyText: copy.assignedRecipesEmpty,
          recipes: content.assignedRecipes,
        ),
        _TrainerTemplatesSection(
          copy: copy,
          title: copy.workoutTemplatesTitle,
          emptyText: copy.workoutTemplatesEmpty,
          templates: content.workoutTemplates,
          exercises: content.exercises,
        ),
        _TrainerRecipesSection(
          title: copy.recipeLibraryTitle,
          emptyText: copy.recipeLibraryEmpty,
          recipes: content.recipes,
        ),
        _TrainerExercisesSection(copy: copy, exercises: content.exercises),
      ],
    );
  }
}

class _TrainerContentStats extends StatelessWidget {
  const _TrainerContentStats({required this.content, required this.copy});

  final TrainerSharedContent content;
  final _SocialCopy copy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CountPill(
          icon: Icons.event_available_rounded,
          label: copy.workoutsCount(content.assignedWorkouts.length),
          color: Theme.of(context).colorScheme.primary,
        ),
        _CountPill(
          icon: Icons.restaurant_menu_rounded,
          label: copy.recipesCount(content.assignedRecipes.length),
          color: Theme.of(context).colorScheme.secondary,
        ),
        _CountPill(
          icon: Icons.fitness_center_rounded,
          label: copy.exercisesCount(content.exercises.length),
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _TrainerAssignedWorkoutsSection extends StatelessWidget {
  const _TrainerAssignedWorkoutsSection({
    required this.copy,
    required this.workouts,
  });

  final _SocialCopy copy;
  final List<StudentWorkoutAssignment> workouts;

  @override
  Widget build(BuildContext context) {
    return _TrainerContentSection(
      title: copy.assignedWorkoutsTitle,
      emptyText: copy.assignedWorkoutsEmpty,
      children: [
        for (final workout in workouts)
          _TrainerContentTile(
            icon: Icons.event_available_rounded,
            title: workout.title,
            subtitle: [
              if (workout.goal.isNotEmpty) workout.goal,
              DateFormat('dd.MM.yyyy HH:mm').format(workout.scheduledAt),
              if (workout.instructions.isNotEmpty) workout.instructions,
            ].join('\n'),
          ),
      ],
    );
  }
}

class _TrainerTemplatesSection extends StatelessWidget {
  const _TrainerTemplatesSection({
    required this.copy,
    required this.title,
    required this.emptyText,
    required this.templates,
    required this.exercises,
  });

  final _SocialCopy copy;
  final String title;
  final String emptyText;
  final List<TrainerWorkoutTemplate> templates;
  final List<TrainerExercise> exercises;

  @override
  Widget build(BuildContext context) {
    final exerciseById = {
      for (final exercise in exercises) exercise.id: exercise,
    };

    return _TrainerContentSection(
      title: title,
      emptyText: emptyText,
      children: [
        for (final template in templates)
          _TrainerContentTile(
            icon: Icons.assignment_rounded,
            title: template.title,
            subtitle: [
              if (template.goal.isNotEmpty) template.goal,
              if (template.exerciseIds.isNotEmpty)
                template.exerciseIds
                    .map(
                      (id) => exerciseById[id]?.title ?? copy.deletedExercise,
                    )
                    .join(' • '),
              if (template.instructions.isNotEmpty) template.instructions,
            ].join('\n'),
          ),
      ],
    );
  }
}

class _TrainerRecipesSection extends StatelessWidget {
  const _TrainerRecipesSection({
    required this.title,
    required this.emptyText,
    required this.recipes,
  });

  final String title;
  final String emptyText;
  final List<TrainerRecipe> recipes;

  @override
  Widget build(BuildContext context) {
    return _TrainerContentSection(
      title: title,
      emptyText: emptyText,
      children: [
        for (final recipe in recipes)
          _TrainerContentTile(
            icon: Icons.restaurant_menu_rounded,
            title: recipe.nameRu,
            subtitle: [
              '${recipe.servingMacros.calories.toStringAsFixed(0)} kcal',
              if (recipe.description.isNotEmpty) recipe.description,
              if (recipe.proportionsText.isNotEmpty) recipe.proportionsText,
            ].join('\n'),
          ),
      ],
    );
  }
}

class _TrainerExercisesSection extends StatelessWidget {
  const _TrainerExercisesSection({required this.copy, required this.exercises});

  final _SocialCopy copy;
  final List<TrainerExercise> exercises;

  @override
  Widget build(BuildContext context) {
    return _TrainerContentSection(
      title: copy.exerciseLibraryTitle,
      emptyText: copy.exerciseLibraryEmpty,
      children: [
        for (final exercise in exercises)
          _TrainerContentTile(
            icon: Icons.fitness_center_rounded,
            title: exercise.title,
            subtitle: [
              if (exercise.muscleGroups.isNotEmpty) exercise.muscleGroups,
              if (exercise.equipment.isNotEmpty) exercise.equipment,
              if (exercise.techniqueText.isNotEmpty) exercise.techniqueText,
            ].join('\n'),
          ),
      ],
    );
  }
}

class _TrainerContentSection extends StatelessWidget {
  const _TrainerContentSection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (children.isEmpty)
              Text(emptyText)
            else
              for (final child in children) ...[
                child,
                if (child != children.last) const Divider(height: 18),
              ],
          ],
        ),
      ),
    );
  }
}

class _TrainerContentTile extends StatelessWidget {
  const _TrainerContentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 4, overflow: TextOverflow.ellipsis),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Text(message, textAlign: TextAlign.center));
  }
}

Future<FriendAccessGroup?> _editGroupDialog(
  BuildContext context,
  _SocialCopy copy,
  List<FriendProfile> friends, {
  FriendAccessGroup? group,
}) {
  final languageCode = Localizations.localeOf(context).languageCode;
  final nameController = TextEditingController(text: group?.name ?? '');
  var selectedMembers = {...?group?.memberIds};
  var selectedCategories =
      group?.allowedCategories ?? <SocialPrivacyCategory>{};

  return showDialog<FriendAccessGroup>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(group == null ? copy.addGroup : copy.editGroup),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: copy.groupName),
                    ),
                    const SizedBox(height: 16),
                    Text(copy.groupPeople),
                    const SizedBox(height: 8),
                    for (final friend in friends)
                      CheckboxListTile(
                        value: selectedMembers.contains(friend.userId),
                        onChanged: (selected) {
                          setState(() {
                            selected == true
                                ? selectedMembers.add(friend.userId)
                                : selectedMembers.remove(friend.userId);
                          });
                        },
                        title: Text(friend.displayName),
                        contentPadding: EdgeInsets.zero,
                      ),
                    const SizedBox(height: 12),
                    Text(copy.groupAccess),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in SocialPrivacyCategory.values)
                          FilterChip(
                            selected: selectedCategories.contains(category),
                            onSelected: (selected) {
                              setState(() {
                                final next = {...selectedCategories};
                                selected
                                    ? next.add(category)
                                    : next.remove(category);
                                selectedCategories = next;
                              });
                            },
                            label: Text(category.label(languageCode)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(copy.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    return;
                  }
                  Navigator.of(context).pop(
                    FriendAccessGroup(
                      id:
                          group?.id ??
                          DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name,
                      memberIds: selectedMembers,
                      allowedCategories: selectedCategories,
                    ),
                  );
                },
                child: Text(copy.save),
              ),
            ],
          );
        },
      );
    },
  );
}

class _SocialCopy {
  const _SocialCopy(this.isRu);

  factory _SocialCopy.of(BuildContext context) {
    return _SocialCopy(Localizations.localeOf(context).languageCode == 'ru');
  }

  final bool isRu;

  String get title => isRu ? 'Друзья' : 'Friends';
  String get subtitle => isRu
      ? 'Добавляйте друзей и показывайте только то, что выбрали сами.'
      : 'Add friends and share only the profile data you choose.';
  String get unauthorized => isRu ? 'Войдите в аккаунт.' : 'Sign in first.';
  String get inviteTitle => isRu ? 'Добавить друга' : 'Add a friend';
  String get inviteSubtitle => isRu
      ? 'Отправьте ссылку, покажите QR-код или вставьте приглашение друга.'
      : 'Share a link, show a QR code, or paste a friend invite.';
  String get createInvite => isRu ? 'Создать ссылку' : 'Create link';
  String get copyLink => isRu ? 'Копировать' : 'Copy';
  String get share => isRu ? 'Поделиться' : 'Share';
  String get pasteInvite =>
      isRu ? 'Ссылка или код друга' : 'Friend link or code';
  String get sendRequest => isRu ? 'Отправить запрос' : 'Send request';
  String get requestSent => isRu ? 'Запрос отправлен.' : 'Request sent.';
  String get requestAccepted => isRu ? 'Друг добавлен.' : 'Friend added.';
  String get friendCodeMissing => isRu
      ? 'Сначала задайте код друга в профиле.'
      : 'Set your friend code in profile first.';
  String get requestsTitle => isRu ? 'Запросы в друзья' : 'Friend requests';
  String get requestsEmpty => isRu ? 'Новых запросов нет.' : 'No new requests.';
  String get accept => isRu ? 'Принять' : 'Accept';
  String get decline => isRu ? 'Отклонить' : 'Decline';
  String get privacyTitle => isRu ? 'Приватность профиля' : 'Profile privacy';
  String get privacySubtitle => isRu
      ? 'Общие разрешения действуют для всех друзей, группы могут расширять доступ.'
      : 'Default permissions apply to all friends; groups can grant extra access.';
  String get friendLeaderboardSwitch => isRu
      ? 'Показывать меня в рейтинге друзей'
      : 'Show me in friends leaderboard';
  String get friendLeaderboardHint => isRu
      ? 'Можно скрыться из рейтинга, но продолжать делиться выбранными результатами.'
      : 'You can hide from ranking while still sharing selected results.';
  String get defaultAccess =>
      isRu ? 'Доступ для всех друзей' : 'Access for all friends';
  String get groupsTitle =>
      isRu ? 'Группы с отдельным доступом' : 'Groups with custom access';
  String get addGroup => isRu ? 'Добавить группу' : 'Add group';
  String get editGroup => isRu ? 'Настроить группу' : 'Edit group';
  String get groupName => isRu ? 'Название группы' : 'Group name';
  String get groupPeople => isRu ? 'Люди в группе' : 'People in group';
  String get groupAccess =>
      isRu ? 'Что видит группа' : 'What this group can see';
  String get peopleCountLabel => isRu ? 'чел.' : 'people';
  String get edit => isRu ? 'Изменить' : 'Edit';
  String get delete => isRu ? 'Удалить' : 'Delete';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get cancel => isRu ? 'Отмена' : 'Cancel';
  String get settingsSaved => isRu ? 'Настройки сохранены.' : 'Settings saved.';
  String get friendLeaderboardTitle =>
      isRu ? 'Лидеры среди друзей' : 'Friends leaderboard';
  String get friendLeaderboardSubtitle => isRu
      ? 'Только друзья, которые разрешили показываться здесь.'
      : 'Only friends who allow appearing here.';
  String get friendLeaderboardEmpty => isRu
      ? 'Пока никто из друзей не делится местом в рейтинге.'
      : 'No friends are sharing leaderboard placement yet.';
  String get openLeaderboard => isRu ? 'Открыть' : 'Open';
  String friendLeaderboardEntrySubtitle(int count) => isRu
      ? 'Рейтинг будет считаться только среди ваших друзей: $count.'
      : 'Ranking includes only your friends: $count.';
  String get friendsTitle => isRu ? 'Мои друзья' : 'My friends';
  String get friendsEmpty =>
      isRu ? 'Список друзей пока пуст.' : 'Your friend list is empty.';
  String get messageFriend => isRu ? 'Написать' : 'Message';
  String get removeFriend => isRu ? 'Удалить из друзей' : 'Remove friend';

  String get hubTitle => isRu ? 'Друзья и тренеры' : 'Friends and coaches';
  String get trainersTitle => isRu ? 'Тренеры' : 'Coaches';
  String get trainersSubtitle => isRu
      ? 'Отдельная таблица подключенных тренеров и их материалов.'
      : 'A separate table for connected coaches and their materials.';
  String get trainersEmpty =>
      isRu ? 'Подключенных тренеров пока нет.' : 'No connected coaches yet.';
  String get trainerColumnName => isRu ? 'Тренер' : 'Coach';
  String get trainerColumnEmail => isRu ? 'Email' : 'Email';
  String get trainerColumnMaterials => isRu ? 'Материалы' : 'Materials';
  String get viewTrainerMaterials =>
      isRu ? 'Посмотреть материалы тренера' : 'View coach materials';
  String get trainerMaterials => isRu
      ? 'Все упражнения, рецепты и комплексы'
      : 'Exercises, recipes, and plans';
  String get close => isRu ? 'Закрыть' : 'Close';
  String get assignedWorkoutsTitle =>
      isRu ? 'Назначенные комплексы' : 'Assigned workout plans';
  String get assignedWorkoutsEmpty => isRu
      ? 'Этот тренер еще не назначал комплексы.'
      : 'No assigned workout plans yet.';
  String get assignedRecipesTitle =>
      isRu ? 'Назначенные рецепты' : 'Assigned recipes';
  String get assignedRecipesEmpty => isRu
      ? 'Этот тренер еще не назначал рецепты.'
      : 'No assigned recipes yet.';
  String get workoutTemplatesTitle =>
      isRu ? 'Комплексы упражнений' : 'Workout plan library';
  String get workoutTemplatesEmpty => isRu
      ? 'В библиотеке тренера пока нет комплексов.'
      : 'No workout plans in this coach library.';
  String get recipeLibraryTitle => isRu ? 'Рецепты тренера' : 'Coach recipes';
  String get recipeLibraryEmpty => isRu
      ? 'В библиотеке тренера пока нет рецептов.'
      : 'No recipes in this coach library.';
  String get exerciseLibraryTitle =>
      isRu ? 'Упражнения тренера' : 'Coach exercises';
  String get exerciseLibraryEmpty => isRu
      ? 'В библиотеке тренера пока нет упражнений.'
      : 'No exercises in this coach library.';
  String get deletedExercise =>
      isRu ? 'Упражнение удалено' : 'Deleted exercise';

  String peopleCount(int value) =>
      isRu ? '$value $peopleCountLabel' : '$value $peopleCountLabel';
  String friendsCount(int value) => isRu ? '$value друзей' : '$value friends';
  String trainersCount(int value) =>
      isRu ? '$value тренеров' : '$value coaches';
  String friendLeaderboardMeta({
    required String score,
    required String workouts,
    required String steps,
  }) => isRu
      ? '$score очков • $workouts тренировок • $steps шагов'
      : '$score pts • $workouts workouts • $steps steps';
  String workoutsCount(int value) =>
      isRu ? '$value комплексов' : '$value plans';
  String recipesCount(int value) => isRu ? '$value рецептов' : '$value recipes';
  String exercisesCount(int value) =>
      isRu ? '$value упражнений' : '$value exercises';
}
