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
import '../../domain/entities/social_privacy.dart';
import '../providers/social_providers.dart';
import '../utils/trainer_materials_route_arguments.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final _inviteController = TextEditingController();
  String? _inviteLink;
  bool _isBusy = false;

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
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;

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
                          onRemove: (friend) =>
                              _removeFriend(currentUser.uid, friend.userId),
                        ),
                        error: (error, _) =>
                            _ErrorCard(message: _messageFor(error)),
                        loading: () => const SkeletonCard(height: 168),
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
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
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
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
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

  Future<void> _savePrivacy(SocialPrivacySettings settings) async {
    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
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
  const _FriendLeaderboardCard({required this.copy, required this.friends});

  final _SocialCopy copy;
  final List<FriendProfile> friends;

  @override
  Widget build(BuildContext context) {
    final visibleFriends =
        friends
            .where(
              (friend) =>
                  friend.canView(SocialPrivacyCategory.friendLeaderboard),
            )
            .toList(growable: false)
          ..sort((left, right) => right.score.compareTo(left.score));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: copy.friendLeaderboardTitle,
            subtitle: copy.friendLeaderboardSubtitle,
          ),
          const SizedBox(height: 12),
          if (visibleFriends.isEmpty)
            Text(copy.friendLeaderboardEmpty)
          else
            for (var i = 0; i < visibleFriends.length; i++) ...[
              _LeaderboardFriendRow(position: i + 1, friend: visibleFriends[i]),
              if (i != visibleFriends.length - 1) const Divider(height: 22),
            ],
        ],
      ),
    );
  }
}

class _LeaderboardFriendRow extends StatelessWidget {
  const _LeaderboardFriendRow({required this.position, required this.friend});

  final int position;
  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(child: Text('$position')),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friend.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${friend.score} pts · ${friend.workoutsCount} workouts · ${friend.stepsCount} steps',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendsListCard extends StatelessWidget {
  const _FriendsListCard({
    required this.copy,
    required this.friends,
    required this.onRemove,
  });

  final _SocialCopy copy;
  final List<FriendProfile> friends;
  final ValueChanged<FriendProfile> onRemove;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    child: Text(friend.displayName.characters.first),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final category
                                in SocialPrivacyCategory.values.where(
                                  friend.canView,
                                ))
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(category.label(languageCode)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: copy.removeFriend,
                    onPressed: () => onRemove(friend),
                    icon: const Icon(Icons.person_remove_alt_1_rounded),
                  ),
                ],
              ),
              if (friend != friends.last) const Divider(height: 24),
            ],
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
  String get friendsTitle => isRu ? 'Мои друзья' : 'My friends';
  String get friendsEmpty =>
      isRu ? 'Список друзей пока пуст.' : 'Your friend list is empty.';
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
  String workoutsCount(int value) =>
      isRu ? '$value комплексов' : '$value plans';
  String recipesCount(int value) => isRu ? '$value рецептов' : '$value recipes';
  String exercisesCount(int value) =>
      isRu ? '$value упражнений' : '$value exercises';
}
