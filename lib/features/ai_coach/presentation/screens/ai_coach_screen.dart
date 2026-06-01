import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../auth/domain/entities/user_goal.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../nutrition/domain/entities/daily_food_diary.dart';
import '../../../nutrition/domain/entities/food_macros.dart';
import '../../../nutrition/presentation/providers/nutrition_providers.dart';
import '../../domain/entities/ai_coach_message.dart';
import '../../domain/services/fitness_ai_agent.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _agent = FitnessAiAgent();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<AiCoachMessage> _messages = <AiCoachMessage>[];
  bool _isThinking = false;
  bool _hasFitnessHistory = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(FitnessAiContext fitnessContext) async {
    final question = _messageController.text.trim();
    if (question.isEmpty || _isThinking) {
      return;
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final history = List<AiCoachMessage>.of(_messages);

    setState(() {
      _messages.add(
        AiCoachMessage(text: question, isUser: true, createdAt: DateTime.now()),
      );
      _messageController.clear();
      _isThinking = true;
    });
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 360));

    final answer = await _agent.answer(
      question: question,
      context: fitnessContext,
      hasFitnessHistory: _hasFitnessHistory,
      languageCode: languageCode,
      history: history,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(
        AiCoachMessage(text: answer, isUser: false, createdAt: DateTime.now()),
      );
      _hasFitnessHistory = !_isOutOfScopeAnswer(answer);
      _isThinking = false;
    });
    _scrollToBottom();
  }

  void _useSuggestion(String text, FitnessAiContext context) {
    _messageController.text = text;
    _messageController.selection = TextSelection.collapsed(
      offset: _messageController.text.length,
    );
    _sendMessage(context);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: LigaMotion.medium,
        curve: LigaMotion.easeOut,
      );
    });
  }

  bool _isOutOfScopeAnswer(String value) {
    return value.contains('не входит в мои знания') ||
        value.contains('outside my knowledge');
  }

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final diaryState = ref.watch(todayNutritionDiaryProvider);
    final analyticsState = ref.watch(dashboardAnalyticsProvider);
    final contextData = _buildFitnessContext(diaryState, analyticsState);

    return LigaPremiumScaffold(
      extendBody: false,
      appBar: AppBar(
        title: Text(isRu ? 'AI фитнес-агент' : 'AI Fitness Agent'),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: _AgentHeader(
                    isRu: isRu,
                    contextData: contextData,
                    onSuggestionTap: (text) =>
                        _useSuggestion(text, contextData),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    itemCount: _messages.length + 1 + (_isThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _AssistantMessage(
                          text: isRu
                              ? 'Привет. Я отвечаю только по питанию и тренировкам. Можете написать, что ели, спросить почему это не очень, или подобрать нагрузку.'
                              : 'Hi. I answer only about nutrition and training. Tell me what you ate, ask why it may be suboptimal, or choose a workout.',
                        );
                      }

                      final messageIndex = index - 1;
                      if (messageIndex >= _messages.length) {
                        return const _ThinkingBubble();
                      }

                      final message = _messages[messageIndex];
                      return message.isUser
                          ? _UserMessage(text: message.text)
                          : _AssistantMessage(text: message.text);
                    },
                  ),
                ),
                _MessageComposer(
                  controller: _messageController,
                  isRu: isRu,
                  isSending: _isThinking,
                  onSend: () => _sendMessage(contextData),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  FitnessAiContext _buildFitnessContext(
    AsyncValue<DailyFoodDiary> diaryState,
    AsyncValue<dynamic> analyticsState,
  ) {
    final diary = diaryState.asData?.value;
    final analytics = analyticsState.asData?.value;
    final macros =
        diary?.totalMacros() ??
        FoodMacros(
          calories: analytics?.weeklyStats.today.calories ?? 0,
          proteins: analytics?.proteins ?? 0,
          fats: analytics?.fats ?? 0,
          carbs: analytics?.carbs ?? 0,
        );

    return FitnessAiContext(
      entries: diary?.entries ?? const [],
      totalMacros: macros,
      calorieGoal: analytics?.goals.calorieGoal ?? 2200,
      stepGoal: analytics?.goals.stepGoal ?? 10000,
      goalType: analytics?.goals.goalType ?? UserGoalType.maintainWeight,
      currentWeightKg: analytics?.goals.currentWeightKg,
      targetWeightKg: analytics?.goals.targetWeightKg,
    );
  }
}

class _AgentHeader extends StatelessWidget {
  const _AgentHeader({
    required this.isRu,
    required this.contextData,
    required this.onSuggestionTap,
  });

  final bool isRu;
  final FitnessAiContext contextData;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final macros = contextData.totalMacros;

    return GlassCard(
      borderRadius: 20,
      tint: colorScheme.secondary.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [colorScheme.secondary, colorScheme.tertiary],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liga AI',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isRu
                          ? '${macros.calories.toStringAsFixed(0)} / ${contextData.calorieGoal.toStringAsFixed(0)} ккал сегодня'
                          : '${macros.calories.toStringAsFixed(0)} / ${contextData.calorieGoal.toStringAsFixed(0)} kcal today',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SuggestionChip(
                label: isRu ? 'Я ел пиццу. Это плохо?' : 'I ate pizza. Bad?',
                onTap: () => onSuggestionTap(
                  isRu ? 'Я ел пиццу. Это плохо?' : 'I ate pizza. Bad?',
                ),
              ),
              _SuggestionChip(
                label: isRu ? 'Почему?' : 'Why?',
                onTap: () => onSuggestionTap(isRu ? 'Почему?' : 'Why?'),
              ),
              _SuggestionChip(
                label: isRu
                    ? 'Какие тренировки мне делать?'
                    : 'What workouts should I do?',
                onTap: () => onSuggestionTap(
                  isRu
                      ? 'Какие тренировки мне делать?'
                      : 'What workouts should I do?',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.bolt_rounded, size: 18),
      onPressed: onTap,
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _MessageBubble(text: text, isUser: false);
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _MessageBubble(text: text, isUser: true);
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary
              : colorScheme.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: isUser
            ? Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  height: 1.35,
                ),
              )
            : _AiMessageContent(text: text),
      ),
    );
  }
}

class _AiMessageContent extends StatelessWidget {
  const _AiMessageContent({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final segments = _AiMessageFormatter.parse(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          segments[i].build(context),
          if (i != segments.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

@visibleForTesting
class AiCoachMessagePreview extends StatelessWidget {
  const AiCoachMessagePreview({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _AiMessageContent(text: text);
  }
}

abstract class _AiMessageSegment {
  const _AiMessageSegment();

  Widget build(BuildContext context);
}

class _ParagraphSegment extends _AiMessageSegment {
  const _ParagraphSegment(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return _InlineFormattedText(text: text);
  }
}

class _HeadingSegment extends _AiMessageSegment {
  const _HeadingSegment(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text.rich(
      _AiMessageFormatter.inlineSpan(
        text,
        Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1.22,
            ) ??
            TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1.22,
            ),
      ),
    );
  }
}

class _BulletSegment extends _AiMessageSegment {
  const _BulletSegment(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(child: _InlineFormattedText(text: text)),
      ],
    );
  }
}

class _TableSegment extends _AiMessageSegment {
  const _TableSegment(this.table);

  final _ParsedMarkdownTable table;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: table.headers.length > 3,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.72,
                      ),
                    ),
                    children: [
                      for (final header in table.headers)
                        _TableCellText(text: header, isHeader: true),
                    ],
                  ),
                  for (final row in table.rows)
                    TableRow(
                      children: [
                        for (var i = 0; i < table.headers.length; i++)
                          _TableCellText(text: i < row.length ? row[i] : ''),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableCellText extends StatelessWidget {
  const _TableCellText({required this.text, this.isHeader = false});

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: isHeader ? FontWeight.w900 : FontWeight.w600,
          height: 1.25,
        ) ??
        TextStyle(
          color: colorScheme.onSurface,
          fontWeight: isHeader ? FontWeight.w900 : FontWeight.w600,
          height: 1.25,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        _AiMessageFormatter.cleanInline(text),
        style: style,
        softWrap: true,
      ),
    );
  }
}

class _InlineFormattedText extends StatelessWidget {
  const _InlineFormattedText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          height: 1.38,
        ) ??
        TextStyle(color: colorScheme.onSurface, height: 1.38);

    return Text.rich(_AiMessageFormatter.inlineSpan(text, style));
  }
}

class _AiMessageFormatter {
  const _AiMessageFormatter._();

  static List<_AiMessageSegment> parse(String rawText) {
    final normalized = rawText.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const <_AiMessageSegment>[];
    }

    final lines = normalized.split('\n');
    final segments = <_AiMessageSegment>[];
    var index = 0;

    while (index < lines.length) {
      final line = lines[index].trimRight();
      if (line.trim().isEmpty) {
        index += 1;
        continue;
      }

      if (_startsTable(lines, index)) {
        final tableLines = <String>[];
        while (index < lines.length && _looksLikeTableLine(lines[index])) {
          tableLines.add(lines[index]);
          index += 1;
        }
        final table = _ParsedMarkdownTable.fromLines(tableLines);
        if (table != null) {
          segments.add(_TableSegment(table));
          continue;
        }
      }

      final heading = RegExp(r'^\s{0,3}#{1,6}\s+(.+)$').firstMatch(line);
      if (heading != null) {
        segments.add(_HeadingSegment(cleanInline(heading.group(1)!)));
        index += 1;
        continue;
      }

      final bullet = RegExp(r'^\s*(?:[-*•]|\d+[.)])\s+(.+)$').firstMatch(line);
      if (bullet != null) {
        segments.add(_BulletSegment(cleanInline(bullet.group(1)!)));
        index += 1;
        continue;
      }

      final paragraphLines = <String>[line.trim()];
      index += 1;
      while (index < lines.length &&
          lines[index].trim().isNotEmpty &&
          !_startsTable(lines, index) &&
          !RegExp(r'^\s{0,3}#{1,6}\s+').hasMatch(lines[index]) &&
          !RegExp(r'^\s*(?:[-*•]|\d+[.)])\s+').hasMatch(lines[index])) {
        paragraphLines.add(lines[index].trim());
        index += 1;
      }

      segments.add(_ParagraphSegment(paragraphLines.join(' ')));
    }

    return segments;
  }

  static InlineSpan inlineSpan(String rawText, TextStyle baseStyle) {
    final text = cleanInline(rawText);
    final spans = <TextSpan>[];
    final pattern = RegExp(r'(\*\*|__)(.+?)\1|`([^`]+)`');
    var cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      final boldText = match.group(2);
      final codeText = match.group(3);
      if (boldText != null) {
        spans.add(
          TextSpan(
            text: cleanInline(boldText),
            style: baseStyle.copyWith(fontWeight: FontWeight.w900),
          ),
        );
      } else if (codeText != null) {
        spans.add(
          TextSpan(
            text: codeText,
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  static String cleanInline(String value) {
    return value
        .replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*'), '')
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1)!)
        .replaceAllMapped(RegExp(r'__(.*?)__'), (match) => match.group(1)!)
        .replaceAll('*', '')
        .trim();
  }

  static bool _startsTable(List<String> lines, int index) {
    if (index + 1 >= lines.length) {
      return false;
    }

    return _looksLikeTableLine(lines[index]) &&
        _isTableSeparator(lines[index + 1]);
  }

  static bool _looksLikeTableLine(String line) {
    return line.contains('|') && line.split('|').length >= 3;
  }

  static bool _isTableSeparator(String line) {
    final cleaned = line.replaceAll('|', '').replaceAll(':', '').trim();
    return cleaned.isNotEmpty && RegExp(r'^[-\s]+$').hasMatch(cleaned);
  }
}

class _ParsedMarkdownTable {
  const _ParsedMarkdownTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  static _ParsedMarkdownTable? fromLines(List<String> lines) {
    if (lines.length < 2) {
      return null;
    }

    final headers = _cells(lines.first);
    final rows = <List<String>>[];

    for (final line in lines.skip(2)) {
      final cells = _cells(line);
      if (cells.isNotEmpty) {
        rows.add(cells);
      }
    }

    if (headers.isEmpty || rows.isEmpty) {
      return null;
    }

    return _ParsedMarkdownTable(headers: headers, rows: rows);
  }

  static List<String> _cells(String line) {
    final rawCells = line.split('|').map((cell) => cell.trim()).toList();
    if (rawCells.isNotEmpty && rawCells.first.isEmpty) {
      rawCells.removeAt(0);
    }
    if (rawCells.isNotEmpty && rawCells.last.isEmpty) {
      rawCells.removeLast();
    }

    return rawCells;
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 74,
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ThinkingDot(delay: 0),
            _ThinkingDot(delay: 110),
            _ThinkingDot(delay: 220),
          ],
        ),
      ),
    );
  }
}

class _ThinkingDot extends StatefulWidget {
  const _ThinkingDot({required this.delay});

  final int delay;

  @override
  State<_ThinkingDot> createState() => _ThinkingDotState();
}

class _ThinkingDotState extends State<_ThinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.32, end: 1).animate(_controller),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isRu,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isRu;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: AppKeys.aiCoachMessageField,
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: isRu
                          ? 'Спросите про питание или тренировку'
                          : 'Ask about nutrition or training',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: AppKeys.aiCoachSendButton,
                  tooltip: isRu ? 'Отправить' : 'Send',
                  onPressed: isSending ? null : onSend,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
