import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/social_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_isSending) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.read(firebaseAuthProvider).currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrorCode.unauthorized.localize(l10n))),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final email = currentUser.email ?? '';
      await ref
          .read(sendMessageUseCaseProvider)
          .call(
            userId: currentUser.uid,
            fallbackName: currentUser.displayName ?? email.split('@').first,
            fallbackEmail: email,
            message: _messageController.text,
          );

      _messageController.clear();
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messagesState = ref.watch(chatMessagesProvider);
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.chatSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesState.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.chatEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
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
                      return _MessageBubble(
                        message: message,
                        isCurrentUser: message.senderId == currentUserId,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: AppKeys.chatMessageField,
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(hintText: l10n.chatInputHint),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: AppKeys.chatSendButton,
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
