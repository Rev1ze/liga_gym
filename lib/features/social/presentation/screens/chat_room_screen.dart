import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_member_role.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_participant.dart';
import '../providers/social_providers.dart';
import '../utils/chat_room_route_arguments.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.arguments});

  final ChatRoomRouteArguments arguments;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _joinChat() async {
    if (_isJoining) {
      return;
    }

    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (currentUser == null) {
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final email = currentUser.email ?? '';
      await ref.read(socialRepositoryProvider).joinInterestChat(
        chatId: widget.arguments.chatId,
        userId: currentUser.uid,
        fallbackName: currentUser.displayName ?? email.split('@').first,
        fallbackEmail: email,
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
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending) {
      return;
    }

    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (currentUser == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final email = currentUser.email ?? '';
      await ref.read(sendMessageUseCaseProvider).call(
        chatId: widget.arguments.chatId,
        userId: currentUser.uid,
        fallbackName: currentUser.displayName ?? email.split('@').first,
        fallbackEmail: email,
        message: _messageController.text,
      );
      _messageController.clear();
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
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(socialRepositoryProvider).deleteMessage(
        chatId: widget.arguments.chatId,
        messageId: message.id,
      );
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    }
  }

  Future<void> _showParticipantsSheet(
    ChatParticipant currentParticipant,
    List<ChatParticipant> participants,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            builder: (context, controller) {
              return ListView.separated(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: participants.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  final canManage = currentParticipant.isAdmin &&
                      participant.userId != currentParticipant.userId;
                  final canRemove = (currentParticipant.isAdmin ||
                          currentParticipant.canRemoveUsers) &&
                      participant.userId != currentParticipant.userId &&
                      !participant.isAdmin;

                  return ListTile(
                    title: Text(participant.displayName),
                    subtitle: Text(_participantSubtitle(l10n, participant)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canManage)
                          IconButton(
                            onPressed: () =>
                                _showManageParticipantDialog(participant),
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                          ),
                        if (canRemove)
                          IconButton(
                            onPressed: () =>
                                _showRemoveParticipantDialog(participant),
                            icon: const Icon(Icons.person_remove_outlined),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showManageParticipantDialog(ChatParticipant participant) async {
    final l10n = AppLocalizations.of(context)!;
    var role = participant.role;
    var canRemoveMessages = participant.canRemoveMessages;
    var canRemoveUsers = participant.canRemoveUsers;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.chatManageParticipantTitle(participant.displayName)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ChatMemberRole>(
                    initialValue: role,
                    decoration: InputDecoration(labelText: l10n.chatRoleLabel),
                    items: [
                      DropdownMenuItem(
                        value: ChatMemberRole.member,
                        child: Text(_roleLabel(l10n, ChatMemberRole.member)),
                      ),
                      DropdownMenuItem(
                        value: ChatMemberRole.moderator,
                        child: Text(_roleLabel(l10n, ChatMemberRole.moderator)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        role = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: canRemoveMessages,
                    onChanged: (value) {
                      setState(() {
                        canRemoveMessages = value;
                      });
                    },
                    title: Text(l10n.chatCanDeleteMessages),
                  ),
                  SwitchListTile(
                    value: canRemoveUsers,
                    onChanged: (value) {
                      setState(() {
                        canRemoveUsers = value;
                      });
                    },
                    title: Text(l10n.chatCanDeleteUsers),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    try {
      await ref.read(socialRepositoryProvider).updateParticipantPermissions(
        chatId: widget.arguments.chatId,
        targetUserId: participant.userId,
        role: role,
        canRemoveMessages: canRemoveMessages,
        canRemoveUsers: canRemoveUsers,
      );
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    }
  }

  Future<void> _showRemoveParticipantDialog(ChatParticipant participant) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();

    try {
      final shouldRemove = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.chatRemoveParticipantTitle(participant.displayName)),
            content: TextField(
              controller: reasonController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.chatRemoveReasonOptional,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.chatRemoveParticipantAction),
              ),
            ],
          );
        },
      );

      if (shouldRemove != true) {
        return;
      }

      await ref.read(socialRepositoryProvider).removeParticipant(
        chatId: widget.arguments.chatId,
        targetUserId: participant.userId,
        reason: reasonController.text,
      );
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    } finally {
      reasonController.dispose();
    }
  }

  String _roleLabel(AppLocalizations l10n, ChatMemberRole role) {
    return switch (role) {
      ChatMemberRole.admin => l10n.chatRoleAdmin,
      ChatMemberRole.moderator => l10n.chatRoleModerator,
      ChatMemberRole.member => l10n.chatRoleMember,
    };
  }

  String _participantSubtitle(
    AppLocalizations l10n,
    ChatParticipant participant,
  ) {
    return [
      if ((participant.city ?? '').isNotEmpty) participant.city!,
      _roleLabel(l10n, participant.role),
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final roomState = ref.watch(interestChatProvider(widget.arguments.chatId));
    final participantState = ref.watch(
      currentChatParticipantProvider(widget.arguments.chatId),
    );
    final participantsState = ref.watch(
      chatParticipantsProvider(widget.arguments.chatId),
    );
    final messagesState = ref.watch(chatMessagesProvider(widget.arguments.chatId));

    return Scaffold(
      appBar: AppBar(
        title: roomState.when(
          data: (room) => Text(room?.title ?? l10n.chatTitle),
          error: (_, _) => Text(l10n.chatTitle),
          loading: () => Text(l10n.chatTitle),
        ),
        actions: [
          participantsState.when(
            data: (participants) => participantState.when(
              data: (currentParticipant) {
                if (currentParticipant == null ||
                    (!currentParticipant.isAdmin &&
                        !currentParticipant.canRemoveUsers)) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  onPressed: () =>
                      _showParticipantsSheet(currentParticipant, participants),
                  icon: const Icon(Icons.groups_2_outlined),
                );
              },
              error: (_, _) => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
            ),
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            roomState.when(
              data: (room) => room == null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.chatRoomNotFound),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${room.description}\n${l10n.chatMembersCount('${room.memberCount}')}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                    ),
              error: (_, _) => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
            ),
            Expanded(
              child: participantState.when(
                data: (currentParticipant) {
                  if (currentParticipant == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.chatJoinPrompt,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _isJoining ? null : _joinChat,
                              child: Text(l10n.chatJoinAction),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return messagesState.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.chatEmpty,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(
                            _scrollController.position.maxScrollExtent,
                          );
                        }
                      });

                      return ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final canDelete = currentParticipant.isAdmin ||
                              currentParticipant.canRemoveMessages ||
                              message.senderId == currentUserId;
                          return GestureDetector(
                            onLongPress: canDelete
                                ? () => _deleteMessage(message)
                                : null,
                            child: _MessageBubble(
                              message: message,
                              isCurrentUser: message.senderId == currentUserId,
                            ),
                          );
                        },
                      );
                    },
                    error: (error, _) {
                      final message = error is AppException
                          ? error.code.localize(l10n)
                          : l10n.errorUnknown;
                      return Center(child: Text(message));
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  );
                },
                error: (error, _) {
                  final message = error is AppException
                      ? error.code.localize(l10n)
                      : l10n.errorUnknown;
                  return Center(child: Text(message));
                },
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
            participantState.when(
              data: (currentParticipant) {
                if (currentParticipant == null) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration:
                              InputDecoration(hintText: l10n.chatInputHint),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _isSending ? null : _sendMessage,
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.chatSend),
                      ),
                    ],
                  ),
                );
              },
              error: (_, _) => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isCurrentUser});

  final ChatMessage message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timestamp = DateFormat.MMMd(locale).add_Hm().format(message.sentAt);

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isCurrentUser
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? l10n.chatYou : message.senderName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isCurrentUser
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((message.senderCity ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    message.senderCity!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isCurrentUser
                          ? colorScheme.onPrimary.withValues(alpha: 0.8)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  message.message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isCurrentUser
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timestamp,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isCurrentUser
                        ? colorScheme.onPrimary.withValues(alpha: 0.72)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
