import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/friend_profile.dart';
import '../../domain/entities/friend_request.dart';
import '../../domain/entities/social_privacy.dart';
import '../providers/social_providers.dart';

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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                    children: [
                      _InviteCard(
                        copy: copy,
                        inviteLink: _inviteLink,
                        inviteController: _inviteController,
                        isBusy: _isBusy,
                        onCreateInvite: () => _createInvite(currentUser),
                        onSendRequest: () => _sendRequest(currentUser),
                      ).premiumEntrance(),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
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
                          loading: () => const SkeletonCard(height: 260),
                        ),
                        error: (error, _) =>
                            _ErrorCard(message: _messageFor(error)),
                        loading: () => const SkeletonCard(height: 260),
                      ),
                      const SizedBox(height: 16),
                      friendsState.when(
                        data: (friends) => Column(
                          children: [
                            _FriendLeaderboardCard(
                              copy: copy,
                              friends: friends,
                            ),
                            const SizedBox(height: 16),
                            _FriendsListCard(
                              copy: copy,
                              friends: friends,
                              onRemove: (friend) =>
                                  _removeFriend(currentUser.uid, friend.userId),
                            ),
                          ],
                        ),
                        error: (error, _) =>
                            _ErrorCard(message: _messageFor(error)),
                        loading: () => const SkeletonCard(height: 240),
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
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 680;
                final qr = DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(data: link, size: 168),
                  ),
                );
                final actions = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableText(link),
                    const SizedBox(height: 12),
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
          const SizedBox(height: 18),
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

  String peopleCount(int value) =>
      isRu ? '$value $peopleCountLabel' : '$value $peopleCountLabel';
}
