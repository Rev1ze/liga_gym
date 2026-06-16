import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/domain/entities/daily_profile_metrics.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../exercises/domain/entities/custom_exercise.dart';
import '../../../exercises/presentation/providers/exercise_library_providers.dart';
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    await _sendText(_messageController.text, clearComposer: true);
  }

  Future<void> _sendText(
    String message, {
    required bool clearComposer,
    Map<String, Object?>? metadata,
  }) async {
    if (_isSending) {
      return;
    }

    final currentUser = ref.read(currentFirebaseUserProvider);
    final l10n = AppLocalizations.of(context)!;
    if (currentUser == null) {
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
            chatId: widget.arguments.chatId,
            userId: currentUser.uid,
            fallbackName: currentUser.displayName ?? email.split('@').first,
            fallbackEmail: email,
            message: message,
            metadata: metadata,
          );
      if (clearComposer) {
        _messageController.clear();
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

  void _appendEmoji(String emoji) {
    final selection = _messageController.selection;
    final text = _messageController.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final nextText = text.replaceRange(start, end, emoji);
    final nextOffset = start + emoji.length;
    _messageController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }

  Future<void> _showShareResultSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final metricsProvider = dailyProfileMetricsProvider(
      DateUtils.dateOnly(DateTime.now()),
    );

    try {
      final metrics = await ref.read(metricsProvider.future);
      if (!mounted) {
        return;
      }
      final options = _buildResultShareOptions(metrics, isRu: isRu);
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (bottomSheetContext) {
          return SafeArea(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: options.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final option = options[index];
                return ListTile(
                  leading: Icon(option.icon),
                  title: Text(option.title),
                  subtitle: Text(option.message),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _sendText(
                      option.message,
                      clearComposer: false,
                      metadata: option.metadata,
                    );
                  },
                );
              },
            ),
          );
        },
      );
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.code.localize(l10n))));
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRu
                ? 'Не получилось подготовить результаты.'
                : 'Could not prepare your results.',
          ),
        ),
      );
    }
  }

  Future<void> _showShareExerciseSheet() async {
    final exercises = ref.read(exerciseLibraryProvider);
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRu
                ? 'Сначала добавь упражнение в библиотеку.'
                : 'Add an exercise to your library first.',
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: exercises.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ListTile(
                leading: Icon(_sharedExerciseIcon(exercise.iconName)),
                title: Text(exercise.title),
                subtitle: Text(
                  [
                    _sharedExerciseCategoryLabel(exercise.defaultCategory),
                    if (exercise.customCategory.isNotEmpty)
                      exercise.customCategory,
                    if (exercise.muscleGroups.isNotEmpty) exercise.muscleGroups,
                  ].join(' · '),
                ),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _shareExercise(exercise);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _shareExercise(CustomExercise exercise) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final message = isRu
        ? 'Поделился упражнением: ${exercise.title}'
        : 'Shared an exercise: ${exercise.title}';
    return _sendText(
      message,
      clearComposer: false,
      metadata: _buildSharedExerciseMetadata(exercise),
    );
  }

  Map<String, Object?> _buildSharedExerciseMetadata(CustomExercise exercise) {
    final avatarDataUrl = _compactDataUrl(exercise.avatarDataUrl);
    final photoDataUrls = _compactDataUrls(exercise.photoDataUrls);
    return <String, Object?>{
      'type': ChatMessageType.sharedExercise.firestoreName,
      'sharedExercise': <String, Object?>{
        'sourceExerciseId': exercise.id,
        'title': exercise.title,
        'description': exercise.description,
        'muscleGroups': exercise.muscleGroups,
        'equipment': exercise.equipment,
        'techniqueText': exercise.techniqueText,
        'defaultCategory': exercise.defaultCategory,
        'customCategory': exercise.customCategory,
        'avatarDataUrl': avatarDataUrl,
        'iconName': exercise.iconName,
        'photoDataUrls': photoDataUrls,
      },
    };
  }

  String _compactDataUrl(String dataUrl) {
    const maxLength = 180000;
    if (dataUrl.length > maxLength) {
      return '';
    }

    return dataUrl;
  }

  List<String> _compactDataUrls(List<String> dataUrls) {
    const maxTotalLength = 260000;
    final result = <String>[];
    var totalLength = 0;
    for (final dataUrl in dataUrls) {
      if (dataUrl.length > maxTotalLength) {
        continue;
      }
      if (totalLength + dataUrl.length > maxTotalLength) {
        break;
      }
      result.add(dataUrl);
      totalLength += dataUrl.length;
    }
    return result;
  }

  List<_ResultShareOption> _buildResultShareOptions(
    DailyProfileMetrics metrics, {
    required bool isRu,
  }) {
    final progressPercent = (metrics.progress.overall * 100).round();
    final minutes = metrics.totalWorkoutDuration.inMinutes;

    if (isRu) {
      return <_ResultShareOption>[
        _ResultShareOption(
          icon: Icons.directions_walk_rounded,
          title: 'Шаги сегодня',
          message: '💪 Мой результат сегодня: ${metrics.steps} шагов',
          metadata: _buildSharedResultMetadata(metrics, 'Шаги сегодня'),
        ),
        _ResultShareOption(
          icon: Icons.local_fire_department_rounded,
          title: 'Калории',
          message:
              '🔥 Сегодня: ${metrics.caloriesBurned.round()} ккал сожжено, ${metrics.caloriesConsumed.round()} ккал в питании',
          metadata: _buildSharedResultMetadata(metrics, 'Калории'),
        ),
        _ResultShareOption(
          icon: Icons.fitness_center_rounded,
          title: 'Тренировки',
          message:
              '🏋️ Сегодня: ${metrics.workoutsCount} тренировок, $minutes мин',
          metadata: _buildSharedResultMetadata(metrics, 'Тренировки'),
        ),
        _ResultShareOption(
          icon: Icons.flag_rounded,
          title: 'Цели',
          message: '🎯 Выполнение целей сегодня: $progressPercent%',
          metadata: _buildSharedResultMetadata(metrics, 'Цели'),
        ),
        _ResultShareOption(
          icon: Icons.restaurant_rounded,
          title: 'БЖУ',
          message:
              '🍽️ БЖУ сегодня: белки ${metrics.proteins.round()} г, жиры ${metrics.fats.round()} г, углеводы ${metrics.carbs.round()} г',
          metadata: _buildSharedResultMetadata(metrics, 'БЖУ'),
        ),
      ];
    }

    return <_ResultShareOption>[
      _ResultShareOption(
        icon: Icons.directions_walk_rounded,
        title: 'Steps today',
        message: '💪 My result today: ${metrics.steps} steps',
        metadata: _buildSharedResultMetadata(metrics, 'Steps today'),
      ),
      _ResultShareOption(
        icon: Icons.local_fire_department_rounded,
        title: 'Calories',
        message:
            '🔥 Today: ${metrics.caloriesBurned.round()} kcal burned, ${metrics.caloriesConsumed.round()} kcal eaten',
        metadata: _buildSharedResultMetadata(metrics, 'Calories'),
      ),
      _ResultShareOption(
        icon: Icons.fitness_center_rounded,
        title: 'Workouts',
        message: '🏋️ Today: ${metrics.workoutsCount} workouts, $minutes min',
        metadata: _buildSharedResultMetadata(metrics, 'Workouts'),
      ),
      _ResultShareOption(
        icon: Icons.flag_rounded,
        title: 'Goals',
        message: '🎯 Goal progress today: $progressPercent%',
        metadata: _buildSharedResultMetadata(metrics, 'Goals'),
      ),
      _ResultShareOption(
        icon: Icons.restaurant_rounded,
        title: 'Macros',
        message:
            '🍽️ Macros today: protein ${metrics.proteins.round()} g, fat ${metrics.fats.round()} g, carbs ${metrics.carbs.round()} g',
        metadata: _buildSharedResultMetadata(metrics, 'Macros'),
      ),
    ];
  }

  Map<String, Object?> _buildSharedResultMetadata(
    DailyProfileMetrics metrics,
    String title,
  ) {
    return <String, Object?>{
      'type': ChatMessageType.dailyResult.firestoreName,
      'sharedResult': <String, Object?>{
        'title': title,
        'date': Timestamp.fromDate(DateUtils.dateOnly(metrics.date)),
        'steps': metrics.steps,
        'caloriesBurned': metrics.caloriesBurned,
        'caloriesConsumed': metrics.caloriesConsumed,
        'workoutsCount': metrics.workoutsCount,
        'workoutMinutes': metrics.totalWorkoutDuration.inMinutes,
        'progressPercent': (metrics.progress.overall * 100).round(),
        'proteins': metrics.proteins,
        'fats': metrics.fats,
        'carbs': metrics.carbs,
      },
    };
  }

  Future<void> _openSharedResultDetails(SharedChatResult result) async {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final date = DateFormat.yMMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(result.date);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        final theme = Theme.of(bottomSheetContext);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              Text(
                result.title.isEmpty
                    ? (isRu ? 'Результат' : 'Result')
                    : result.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(date, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              _SharedResultDetailTile(
                icon: Icons.directions_walk_rounded,
                title: isRu ? 'Шаги' : 'Steps',
                value: '${result.steps}',
              ),
              _SharedResultDetailTile(
                icon: Icons.local_fire_department_rounded,
                title: isRu ? 'Сожжено' : 'Burned',
                value: isRu
                    ? '${result.caloriesBurned.round()} ккал'
                    : '${result.caloriesBurned.round()} kcal',
              ),
              _SharedResultDetailTile(
                icon: Icons.restaurant_rounded,
                title: isRu ? 'Питание' : 'Nutrition',
                value: isRu
                    ? '${result.caloriesConsumed.round()} ккал'
                    : '${result.caloriesConsumed.round()} kcal',
              ),
              _SharedResultDetailTile(
                icon: Icons.fitness_center_rounded,
                title: isRu ? 'Тренировки' : 'Workouts',
                value: isRu
                    ? '${result.workoutsCount}, ${result.workoutMinutes} мин'
                    : '${result.workoutsCount}, ${result.workoutMinutes} min',
              ),
              _SharedResultDetailTile(
                icon: Icons.flag_rounded,
                title: isRu ? 'Цели' : 'Goals',
                value: '${result.progressPercent}%',
              ),
              _SharedResultDetailTile(
                icon: Icons.restaurant_menu_rounded,
                title: isRu ? 'БЖУ' : 'Macros',
                value: isRu
                    ? 'Б ${result.proteins.round()} г, Ж ${result.fats.round()} г, У ${result.carbs.round()} г'
                    : 'P ${result.proteins.round()} g, F ${result.fats.round()} g, C ${result.carbs.round()} g',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveSharedExercise(SharedChatExercise exercise) async {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    if (exercise.title.trim().isEmpty) {
      return;
    }

    await ref
        .read(exerciseLibraryProvider.notifier)
        .saveExercise(
          CustomExercise(
            id: 'shared_${exercise.sourceExerciseId}_${DateTime.now().microsecondsSinceEpoch}',
            title: exercise.title.trim(),
            description: exercise.description.trim(),
            muscleGroups: exercise.muscleGroups.trim(),
            equipment: exercise.equipment.trim(),
            techniqueText: exercise.techniqueText.trim(),
            defaultCategory: exercise.defaultCategory.trim().isEmpty
                ? 'strength'
                : exercise.defaultCategory.trim(),
            customCategory: exercise.customCategory.trim(),
            avatarDataUrl: exercise.avatarDataUrl,
            iconName: exercise.iconName.trim().isEmpty
                ? 'dumbbell'
                : exercise.iconName.trim(),
            photoDataUrls: exercise.photoDataUrls,
            isFavorite: false,
            createdAt: DateTime.now(),
          ),
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRu
              ? '${exercise.title} добавлено в твои упражнения.'
              : '${exercise.title} was added to your exercises.',
        ),
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(socialRepositoryProvider)
          .deleteMessage(
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
                  final canManage =
                      currentParticipant.isAdmin &&
                      participant.userId != currentParticipant.userId;
                  final canRemove =
                      (currentParticipant.isAdmin ||
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
              title: Text(
                l10n.chatManageParticipantTitle(participant.displayName),
              ),
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
      await ref
          .read(socialRepositoryProvider)
          .updateParticipantPermissions(
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
            title: Text(
              l10n.chatRemoveParticipantTitle(participant.displayName),
            ),
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

      await ref
          .read(socialRepositoryProvider)
          .removeParticipant(
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
    final currentUserId = ref.watch(currentFirebaseUserProvider)?.uid;
    final roomState = ref.watch(friendChatProvider(widget.arguments.chatId));
    final participantState = ref.watch(
      currentChatParticipantProvider(widget.arguments.chatId),
    );
    final participantsState = ref.watch(
      chatParticipantsProvider(widget.arguments.chatId),
    );
    final messagesState = ref.watch(
      chatMessagesProvider(widget.arguments.chatId),
    );

    return LigaPremiumScaffold(
      appBar: AppBar(
        title: roomState.when(
          data: (room) =>
              Text(widget.arguments.title ?? room?.title ?? l10n.chatTitle),
          error: (_, _) => Text(widget.arguments.title ?? l10n.chatTitle),
          loading: () => Text(widget.arguments.title ?? l10n.chatTitle),
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
      child: SafeArea(
        child: Column(
          children: [
            roomState.when(
              data: (room) => room == null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.chatRoomNotFound),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${room.description}\n${l10n.chatMembersCount('${room.memberCount}')}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
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
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.chatRoomNotFound,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return messagesState.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
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
                          final canDelete =
                              currentParticipant.isAdmin ||
                              currentParticipant.canRemoveMessages ||
                              message.senderId == currentUserId;
                          return GestureDetector(
                            onLongPress: canDelete
                                ? () => _deleteMessage(message)
                                : null,
                            child: _MessageBubble(
                              message: message,
                              isCurrentUser: message.senderId == currentUserId,
                              onOpenSharedResult: _openSharedResultDetails,
                              onSaveSharedExercise: _saveSharedExercise,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EmojiBar(onEmojiSelected: _appendEmoji),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton.filledTonal(
                            onPressed: _isSending
                                ? null
                                : _showShareResultSheet,
                            icon: const Icon(Icons.ios_share_rounded),
                            tooltip:
                                Localizations.localeOf(context).languageCode ==
                                    'ru'
                                ? 'Поделиться результатом'
                                : 'Share a result',
                          ),
                          IconButton.filledTonal(
                            onPressed: _isSending
                                ? null
                                : _showShareExerciseSheet,
                            icon: const Icon(Icons.fitness_center_rounded),
                            tooltip:
                                Localizations.localeOf(context).languageCode ==
                                    'ru'
                                ? 'Поделиться упражнением'
                                : 'Share an exercise',
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: l10n.chatInputHint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _isSending ? null : _sendMessage,
                            child: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.chatSend),
                          ),
                        ],
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

class _EmojiBar extends StatelessWidget {
  const _EmojiBar({required this.onEmojiSelected});

  final ValueChanged<String> onEmojiSelected;

  static const _emojis = <String>['💪', '🔥', '🎯', '👏', '😄', '❤️'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _emojis.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final emoji = _emojis[index];
          return ActionChip(
            label: Text(emoji, style: Theme.of(context).textTheme.titleMedium),
            onPressed: () => onEmojiSelected(emoji),
          );
        },
      ),
    );
  }
}

class _ResultShareOption {
  const _ResultShareOption({
    required this.icon,
    required this.title,
    required this.message,
    required this.metadata,
  });

  final IconData icon;
  final String title;
  final String message;
  final Map<String, Object?> metadata;
}

class _SharedResultCard extends StatelessWidget {
  const _SharedResultCard({
    required this.result,
    required this.isCurrentUser,
    required this.onTap,
  });

  final SharedChatResult result;
  final bool isCurrentUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isCurrentUser
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final muted = foreground.withValues(alpha: 0.74);
    final background = isCurrentUser
        ? colorScheme.onPrimary.withValues(alpha: 0.12)
        : colorScheme.primaryContainer.withValues(alpha: 0.48);
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(result.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: foreground.withValues(alpha: 0.18)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_rounded, size: 20, color: foreground),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.title.isEmpty
                            ? (isRu ? 'Результат' : 'Result')
                            : result.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: foreground,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(color: muted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SharedResultPill(
                      label: isRu
                          ? '${result.steps} шагов'
                          : '${result.steps} steps',
                      color: foreground,
                    ),
                    _SharedResultPill(
                      label: isRu
                          ? '${result.caloriesBurned.round()} ккал'
                          : '${result.caloriesBurned.round()} kcal',
                      color: foreground,
                    ),
                    _SharedResultPill(
                      label: isRu
                          ? '${result.workoutsCount} трен.'
                          : '${result.workoutsCount} workouts',
                      color: foreground,
                    ),
                    _SharedResultPill(
                      label: '${result.progressPercent}%',
                      color: foreground,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isRu ? 'Подробнее' : 'Details',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: muted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SharedResultPill extends StatelessWidget {
  const _SharedResultPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SharedResultDetailTile extends StatelessWidget {
  const _SharedResultDetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SharedExerciseCard extends StatelessWidget {
  const _SharedExerciseCard({
    required this.exercise,
    required this.isCurrentUser,
    required this.canSave,
    required this.onSave,
  });

  final SharedChatExercise exercise;
  final bool isCurrentUser;
  final bool canSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isCurrentUser
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final muted = foreground.withValues(alpha: 0.74);
    final background = isCurrentUser
        ? colorScheme.onPrimary.withValues(alpha: 0.12)
        : colorScheme.secondaryContainer.withValues(alpha: 0.42);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SharedExerciseAvatar(
                  avatarDataUrl: exercise.avatarDataUrl,
                  iconName: exercise.iconName,
                  color: foreground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          _sharedExerciseCategoryLabel(
                            exercise.defaultCategory,
                          ),
                          if (exercise.customCategory.isNotEmpty)
                            exercise.customCategory,
                        ].join(' · '),
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (exercise.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                exercise.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: foreground),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (exercise.muscleGroups.isNotEmpty)
                  _SharedExercisePill(
                    label: exercise.muscleGroups,
                    color: foreground,
                  ),
                if (exercise.equipment.isNotEmpty)
                  _SharedExercisePill(
                    label: exercise.equipment,
                    color: foreground,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: canSave ? onSave : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                canSave
                    ? (isRu ? 'Добавить себе' : 'Add to my exercises')
                    : (isRu ? 'Уже у тебя' : 'Already yours'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: foreground.withValues(alpha: 0.32)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedExerciseAvatar extends StatelessWidget {
  const _SharedExerciseAvatar({
    required this.avatarDataUrl,
    required this.iconName,
    required this.color,
  });

  final String avatarDataUrl;
  final String iconName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeDataUrl(avatarDataUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: 52,
        child: bytes == null
            ? DecoratedBox(
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12)),
                child: Icon(_sharedExerciseIcon(iconName), color: color),
              )
            : Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }
}

class _SharedExercisePill extends StatelessWidget {
  const _SharedExercisePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.onOpenSharedResult,
    required this.onSaveSharedExercise,
  });

  final ChatMessage message;
  final bool isCurrentUser;
  final ValueChanged<SharedChatResult> onOpenSharedResult;
  final ValueChanged<SharedChatExercise> onSaveSharedExercise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timestamp = DateFormat.MMMd(locale).add_Hm().format(message.sentAt);
    final sharedResult = message.type == ChatMessageType.dailyResult
        ? message.sharedResult
        : null;
    final sharedExercise = message.type == ChatMessageType.sharedExercise
        ? message.sharedExercise
        : null;

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
                if (sharedResult != null) ...[
                  const SizedBox(height: 10),
                  _SharedResultCard(
                    result: sharedResult,
                    isCurrentUser: isCurrentUser,
                    onTap: () => onOpenSharedResult(sharedResult),
                  ),
                ],
                if (sharedExercise != null) ...[
                  const SizedBox(height: 10),
                  _SharedExerciseCard(
                    exercise: sharedExercise,
                    isCurrentUser: isCurrentUser,
                    canSave: !isCurrentUser,
                    onSave: () => onSaveSharedExercise(sharedExercise),
                  ),
                ],
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

IconData _sharedExerciseIcon(String? iconName) {
  return switch (iconName) {
    'run' => Icons.directions_run_rounded,
    'heart' => Icons.favorite_rounded,
    'bolt' => Icons.bolt_rounded,
    'mobility' => Icons.self_improvement_rounded,
    'core' => Icons.accessibility_new_rounded,
    'timer' => Icons.timer_rounded,
    _ => Icons.fitness_center_rounded,
  };
}

String _sharedExerciseCategoryLabel(String category) {
  return switch (category) {
    'strength' => 'Силовое',
    'cardio' => 'Кардио',
    'mobility' => 'Мобильность',
    'recovery' => 'Восстановление',
    _ => category,
  };
}

Uint8List? _decodeDataUrl(String value) {
  if (value.isEmpty) {
    return null;
  }

  final commaIndex = value.indexOf(',');
  final payload = commaIndex == -1 ? value : value.substring(commaIndex + 1);
  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}
