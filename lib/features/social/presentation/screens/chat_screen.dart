import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/friend_profile.dart';
import '../providers/social_providers.dart';
import '../utils/chat_room_route_arguments.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _openingFriendId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFriendChat(FriendProfile friend) async {
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    final l10n = AppLocalizations.of(context)!;
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
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    } finally {
      if (mounted) {
        setState(() {
          _openingFriendId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friendsState = ref.watch(friendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatDirectoryTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.chatDirectorySubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.chatSearchHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: friendsState.when(
          data: (friends) {
            final filteredFriends = _filterFriends(friends);
            if (filteredFriends.isEmpty) {
              return _EmptyFriendChats(
                message: _searchQuery.isEmpty
                    ? l10n.chatDirectoryEmpty
                    : l10n.chatSearchEmpty,
                showAddFriendsAction: _searchQuery.isEmpty,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredFriends.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final friend = filteredFriends[index];
                return _FriendChatTile(
                  friend: friend,
                  isOpening: _openingFriendId == friend.userId,
                  onTap: () => _openFriendChat(friend),
                );
              },
            );
          },
          error: (error, _) {
            final message = error is AppException
                ? error.code.localize(l10n)
                : l10n.errorUnknown;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(message, textAlign: TextAlign.center),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  List<FriendProfile> _filterFriends(List<FriendProfile> friends) {
    if (_searchQuery.isEmpty) {
      return friends;
    }

    return friends
        .where((friend) {
          final haystack =
              '${friend.displayName} ${friend.email} ${friend.city ?? ''}'
                  .toLowerCase();
          return haystack.contains(_searchQuery);
        })
        .toList(growable: false);
  }
}

class _EmptyFriendChats extends StatelessWidget {
  const _EmptyFriendChats({
    required this.message,
    required this.showAddFriendsAction,
  });

  final String message;
  final bool showAddFriendsAction;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_chat_unread_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (showAddFriendsAction) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.friends),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(isRu ? 'Добавить друзей' : 'Add friends'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FriendChatTile extends StatelessWidget {
  const _FriendChatTile({
    required this.friend,
    required this.isOpening,
    required this.onTap,
  });

  final FriendProfile friend;
  final bool isOpening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final subtitle = [
      if ((friend.city ?? '').isNotEmpty) friend.city!,
      isRu ? 'Личный чат' : 'Private chat',
    ].join(' - ');

    return Card(
      child: ListTile(
        onTap: isOpening ? null : onTap,
        leading: CircleAvatar(child: Text(_avatarLabel(friend.displayName))),
        title: Text(
          friend.displayName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: isOpening
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  String _avatarLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.characters.first.toUpperCase();
  }
}
