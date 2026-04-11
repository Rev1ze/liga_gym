import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/interest_chat_room.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateChatDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final currentUser = ref.read(firebaseAuthProvider).currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      final createdChatId = await showDialog<String>(
        context: context,
        builder: (context) {
          bool isSaving = false;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(l10n.chatCreateTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: l10n.chatInterestName,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.chatInterestDescription,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (titleController.text.trim().isEmpty) {
                              return;
                            }
                            setState(() {
                              isSaving = true;
                            });
                            final email = currentUser.email ?? '';
                            final chatId = await ref
                                .read(socialRepositoryProvider)
                                .createInterestChat(
                                  userId: currentUser.uid,
                                  fallbackName:
                                      currentUser.displayName ??
                                      email.split('@').first,
                                  fallbackEmail: email,
                                  title: titleController.text,
                                  description: descriptionController.text,
                                );
                            if (context.mounted) {
                              Navigator.of(context).pop(chatId);
                            }
                          },
                    child: Text(l10n.commonSave),
                  ),
                ],
              );
            },
          );
        },
      );

      if (!mounted || createdChatId == null) {
        return;
      }

      ref.invalidate(interestChatsProvider);
      await Navigator.of(context).pushNamed(
        AppRoutes.chatRoom,
        arguments: ChatRoomRouteArguments(chatId: createdChatId),
      );
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatsState = ref.watch(interestChatsProvider);

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateChatDialog,
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(l10n.chatCreateAction),
      ),
      body: SafeArea(
        child: chatsState.when(
          data: (rooms) {
            final filteredRooms = _filterRooms(rooms);
            if (filteredRooms.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _searchQuery.isEmpty
                        ? l10n.chatDirectoryEmpty
                        : l10n.chatSearchEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRooms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final room = filteredRooms[index];
                return _ChatRoomTile(
                  room: room,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.chatRoom,
                    arguments: ChatRoomRouteArguments(chatId: room.id),
                  ),
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

  List<InterestChatRoom> _filterRooms(List<InterestChatRoom> rooms) {
    if (_searchQuery.isEmpty) {
      return rooms;
    }

    return rooms.where((room) {
      final haystack = '${room.title} ${room.description}'.toLowerCase();
      return haystack.contains(_searchQuery);
    }).toList(growable: false);
  }
}

class _ChatRoomTile extends StatelessWidget {
  const _ChatRoomTile({required this.room, required this.onTap});

  final InterestChatRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          child: Icon(Icons.forum_outlined),
        ),
        title: Text(
          room.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(room.description),
        ),
        trailing: Text(
          l10n.chatMembersCount('${room.memberCount}'),
          textAlign: TextAlign.end,
        ),
      ),
    );
  }
}
