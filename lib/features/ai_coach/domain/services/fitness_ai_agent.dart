import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../auth/domain/entities/user_goal.dart';
import '../../../nutrition/domain/entities/food_entry.dart';
import '../../../nutrition/domain/entities/food_macros.dart';
import '../entities/ai_coach_message.dart';

class FitnessAiContext {
  const FitnessAiContext({
    required this.entries,
    required this.totalMacros,
    required this.calorieGoal,
    required this.stepGoal,
    required this.goalType,
    this.currentWeightKg,
    this.targetWeightKg,
  });

  final List<FoodEntry> entries;
  final FoodMacros totalMacros;
  final double calorieGoal;
  final int stepGoal;
  final UserGoalType goalType;
  final double? currentWeightKg;
  final double? targetWeightKg;
}

class FitnessAiAgent {
  FitnessAiAgent({AiChatClient? client})
    : _client = client ?? PollinationsAiClient.fromEnvironment();

  final AiChatClient _client;

  static const systemPrompt = '''
Ты фитнес-AI агент Liga Gym.
Ты обязательный помощник только по питанию, продуктам, калориям, БЖУ, тренировкам, упражнениям, восстановлению и фитнес-целям.
Если пользователь спрашивает не по теме фитнеса, питания или тренировок, отвечай коротко: "Я не знаю: это не входит в мои знания. Я могу помогать только с питанием и тренировками."
Если пользователь пишет, что он ел, оцени еду мягко и практично: что хорошо, что не очень, почему, и какой следующий шаг лучше.
Если пользователь спрашивает, какие тренировки делать или не делать, учитывай цель, текущую активность и безопасность.
Не давай медицинские диагнозы и не назначай лечение. При боли, травмах, беременности, хронических заболеваниях или резком ухудшении самочувствия рекомендуй консультацию специалиста.
''';

  Future<String> answer({
    required String question,
    required FitnessAiContext context,
    required bool hasFitnessHistory,
    required String languageCode,
    List<AiCoachMessage> history = const [],
  }) async {
    final normalized = question.trim().toLowerCase();
    final isRu = languageCode == 'ru';

    if (normalized.isEmpty) {
      return isRu
          ? 'Спросите про питание, продукт или тренировку.'
          : 'Ask me about nutrition, a food choice, or training.';
    }

    final isFollowUp = _isFollowUpQuestion(normalized) && hasFitnessHistory;
    if (!_isFitnessQuestion(normalized) && !isFollowUp) {
      return _outOfScope(isRu);
    }

    try {
      return await _client.complete(
        messages: _buildMessages(
          question: question,
          context: context,
          history: history,
          languageCode: languageCode,
        ),
      );
    } on AiProviderException catch (error) {
      return _providerUnavailableMessage(error.message, isRu);
    } on Object {
      return _providerUnavailableMessage('network error', isRu);
    }
  }

  List<AiApiMessage> _buildMessages({
    required String question,
    required FitnessAiContext context,
    required List<AiCoachMessage> history,
    required String languageCode,
  }) {
    final isRu = languageCode == 'ru';
    final messages = <AiApiMessage>[
      const AiApiMessage(role: 'system', content: systemPrompt),
      AiApiMessage(role: 'system', content: _contextPrompt(context, isRu)),
    ];
    final recentHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;

    for (final message in recentHistory) {
      messages.add(
        AiApiMessage(
          role: message.isUser ? 'user' : 'assistant',
          content: message.text,
        ),
      );
    }

    messages.add(AiApiMessage(role: 'user', content: question));
    return messages;
  }

  String _contextPrompt(FitnessAiContext context, bool isRu) {
    final macros = context.totalMacros;
    final goal = switch (context.goalType) {
      UserGoalType.loseWeight => isRu ? 'снижение веса' : 'fat loss',
      UserGoalType.maintainWeight => isRu ? 'поддержание веса' : 'maintenance',
      UserGoalType.gainWeight => isRu ? 'набор массы' : 'muscle gain',
    };
    final foods = context.entries
        .take(8)
        .map((entry) => entry.localizedName(isRu ? 'ru' : 'en'))
        .where((name) => name.trim().isNotEmpty)
        .join(', ');

    if (isRu) {
      return 'Контекст пользователя Liga Gym: цель - $goal; дневная цель калорий - ${context.calorieGoal.toStringAsFixed(0)} ккал; цель шагов - ${context.stepGoal}; сегодня в дневнике: ${macros.calories.toStringAsFixed(0)} ккал, белки ${macros.proteins.toStringAsFixed(0)} г, жиры ${macros.fats.toStringAsFixed(0)} г, углеводы ${macros.carbs.toStringAsFixed(0)} г. Записи еды: ${foods.isEmpty ? 'пока нет' : foods}. Отвечай на русском, кратко, практически и строго в рамках питания и тренировок.';
    }

    return 'Liga Gym user context: goal - $goal; daily calorie target - ${context.calorieGoal.toStringAsFixed(0)} kcal; step target - ${context.stepGoal}; today diary: ${macros.calories.toStringAsFixed(0)} kcal, protein ${macros.proteins.toStringAsFixed(0)} g, fats ${macros.fats.toStringAsFixed(0)} g, carbs ${macros.carbs.toStringAsFixed(0)} g. Food entries: ${foods.isEmpty ? 'none yet' : foods}. Answer in English, briefly, practically, and strictly within nutrition and training.';
  }

  bool _isFitnessQuestion(String value) {
    const keywords = <String>[
      'еда',
      'ел',
      'ела',
      'съел',
      'съела',
      'ем',
      'есть',
      'питание',
      'рацион',
      'калор',
      'ккал',
      'бжу',
      'белок',
      'жир',
      'углевод',
      'продукт',
      'завтрак',
      'обед',
      'ужин',
      'перекус',
      'сладк',
      'пицц',
      'бургер',
      'газиров',
      'трен',
      'упраж',
      'зал',
      'спорт',
      'фитнес',
      'кардио',
      'силов',
      'бег',
      'ходьб',
      'шаг',
      'вес',
      'похуд',
      'набрать',
      'масса',
      'мышц',
      'восстанов',
      'растяж',
      'nutrition',
      'food',
      'meal',
      'calorie',
      'protein',
      'carb',
      'workout',
      'training',
      'exercise',
      'fitness',
      'cardio',
      'strength',
      'running',
      'walking',
      'weight',
      'muscle',
      'recovery',
      'who are you',
    ];

    return keywords.any(value.contains) ||
        RegExp(r'\b(eat|ate|fat)\b').hasMatch(value);
  }

  bool _isWhyQuestion(String value) {
    return value.contains('почему') ||
        value.contains('зачем') ||
        value.contains('why') ||
        value.contains('объясни');
  }

  bool _isFollowUpQuestion(String value) {
    return _isWhyQuestion(value) ||
        value.contains('а что лучше') ||
        value.contains('что именно') ||
        value.contains('как исправить') ||
        value.contains('а если');
  }

  String _outOfScope(bool isRu) {
    return isRu
        ? 'Я не знаю: это не входит в мои знания. Я могу помогать только с питанием и тренировками.'
        : 'I do not know: this is outside my knowledge. I can only help with nutrition and training.';
  }

  String _providerUnavailableMessage(String message, bool isRu) {
    final detail = message.trim().isEmpty ? 'unknown error' : message.trim();
    return isRu
        ? 'Нейросеть сейчас не ответила: $detail. Бесплатный провайдер может быть занят. Для стабильной работы можно запустить приложение с OPENAI_API_KEY.'
        : 'The neural model did not respond: $detail. The free provider may be busy. For stable AI, run the app with OPENAI_API_KEY.';
  }
}

class AiApiMessage {
  const AiApiMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, String> toJson() => <String, String>{
    'role': role,
    'content': content,
  };
}

abstract class AiChatClient {
  Future<String> complete({required List<AiApiMessage> messages});
}

class PollinationsAiClient implements AiChatClient {
  PollinationsAiClient({
    required this.chatUrl,
    required this.model,
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  factory PollinationsAiClient.fromEnvironment() {
    const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
    const pollinationsApiKey = String.fromEnvironment('POLLINATIONS_API_KEY');
    const configuredChatUrl = String.fromEnvironment('AI_CHAT_URL');
    const configuredModel = String.fromEnvironment('AI_MODEL');
    final apiKey = openAiApiKey.isNotEmpty ? openAiApiKey : pollinationsApiKey;
    final defaultChatUrl = openAiApiKey.isNotEmpty
        ? 'https://api.openai.com/v1/chat/completions'
        : pollinationsApiKey.isNotEmpty
        ? 'https://gen.pollinations.ai/v1/chat/completions'
        : 'https://text.pollinations.ai/openai';
    final defaultModel = openAiApiKey.isNotEmpty ? 'gpt-4.1-mini' : 'openai';

    return PollinationsAiClient(
      chatUrl: Uri.parse(
        configuredChatUrl.isEmpty ? defaultChatUrl : configuredChatUrl,
      ),
      model: configuredModel.isEmpty ? defaultModel : configuredModel,
      apiKey: apiKey,
    );
  }

  final Uri chatUrl;
  final String model;
  final String apiKey;
  final http.Client _httpClient;
  static const int _maxTextFallbackUrlLength = 7600;

  bool get _supportsTextFallback =>
      chatUrl.host == 'text.pollinations.ai' ||
      chatUrl.host == 'gen.pollinations.ai';

  @override
  Future<String> complete({required List<AiApiMessage> messages}) async {
    final modelsToTry = _modelsToTry(model);
    AiProviderException? lastError;

    for (final candidateModel in modelsToTry) {
      try {
        return await _completeWithModel(
          messages: messages,
          candidateModel: candidateModel,
        );
      } on AiProviderException catch (error) {
        lastError = error;
        if (!_isRetryable(error.message)) {
          rethrow;
        }
      }
    }

    if (_supportsTextFallback) {
      try {
        return await _completeWithTextEndpoint(messages: messages);
      } on AiProviderException catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? const AiProviderException('AI model is not configured');
  }

  Future<String> _completeWithModel({
    required List<AiApiMessage> messages,
    required String candidateModel,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final http.Response response;
    try {
      response = await _httpClient
          .post(
            chatUrl,
            headers: headers,
            body: jsonEncode(<String, Object?>{
              'model': candidateModel,
              'messages': messages.map((message) => message.toJson()).toList(),
              'temperature': 0.35,
              'top_p': 0.8,
              'max_tokens': 700,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const AiProviderException('timeout');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiProviderException(_errorMessage(response));
    }

    final content = _extractContent(utf8.decode(response.bodyBytes)).trim();

    if (content.isEmpty) {
      throw const AiProviderException('empty completion response');
    }
    if (_isProviderQueueMessage(content)) {
      throw AiProviderException(content);
    }

    return content;
  }

  Future<String> _completeWithTextEndpoint({
    required List<AiApiMessage> messages,
  }) async {
    final query = <String, String>{'model': 'openai', 'json': 'false'};
    final usesGenApi = chatUrl.host == 'gen.pollinations.ai';
    if (apiKey.isNotEmpty && !usesGenApi) {
      query['token'] = apiKey;
    }
    final fallbackUrl = _buildTextFallbackUrl(
      messages: messages,
      usesGenApi: usesGenApi,
      query: query,
    );
    final headers = <String, String>{'Accept': 'text/plain'};
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    final http.Response response;
    try {
      response = await _httpClient
          .get(fallbackUrl, headers: headers)
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const AiProviderException('timeout');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiProviderException(_errorMessage(response));
    }

    final content = utf8.decode(response.bodyBytes).trim();
    if (content.isEmpty) {
      throw const AiProviderException('empty text response');
    }
    if (_isProviderQueueMessage(content)) {
      throw AiProviderException(content);
    }

    return content;
  }

  Uri _buildTextFallbackUrl({
    required List<AiApiMessage> messages,
    required bool usesGenApi,
    required Map<String, String> query,
  }) {
    final compactPrompt = _textFallbackPrompt(messages);
    final compactUrl = _textFallbackUrl(
      prompt: compactPrompt,
      usesGenApi: usesGenApi,
      query: query,
    );
    if (compactUrl.toString().length <= _maxTextFallbackUrlLength) {
      return compactUrl;
    }

    final shortestPrompt = _textFallbackPrompt(
      messages,
      includeContext: false,
      maxUserChars: 360,
      maxAssistantChars: 0,
    );
    final shortestUrl = _textFallbackUrl(
      prompt: shortestPrompt,
      usesGenApi: usesGenApi,
      query: query,
    );
    if (shortestUrl.toString().length <= _maxTextFallbackUrlLength) {
      return shortestUrl;
    }

    throw const AiProviderException('text fallback prompt too long');
  }

  Uri _textFallbackUrl({
    required String prompt,
    required bool usesGenApi,
    required Map<String, String> query,
  }) {
    final fallbackBaseUrl = usesGenApi
        ? 'https://gen.pollinations.ai/text/${Uri.encodeComponent(prompt)}'
        : 'https://text.pollinations.ai/${Uri.encodeComponent(prompt)}';
    return Uri.parse(fallbackBaseUrl).replace(queryParameters: query);
  }

  String _extractContent(String responseBody) {
    final trimmed = responseBody.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    Object? payload;
    try {
      payload = jsonDecode(trimmed);
    } on Object {
      return trimmed;
    }

    if (payload is String) {
      return payload;
    }
    if (payload is! Map) {
      return trimmed;
    }

    final directContent =
        payload['content'] ?? payload['text'] ?? payload['response'];
    final direct = _contentToText(directContent);
    if (direct.trim().isNotEmpty) {
      return direct;
    }

    final choices = payload['choices'];
    if (choices is List && choices.isNotEmpty) {
      final firstChoice = choices.first;
      if (firstChoice is Map) {
        final message = firstChoice['message'];
        if (message is Map) {
          final content = _contentToText(message['content']);
          if (content.trim().isNotEmpty) {
            return content;
          }
        }

        final text = _contentToText(firstChoice['text']);
        if (text.trim().isNotEmpty) {
          return text;
        }
      }
    }

    return '';
  }

  String _contentToText(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    if (value is List) {
      return value
          .map((item) {
            if (item is String) {
              return item;
            }
            if (item is Map) {
              return item['text'] ?? item['content'] ?? '';
            }
            return '';
          })
          .where((part) => part.toString().trim().isNotEmpty)
          .join('\n');
    }

    return value.toString();
  }

  String _textFallbackPrompt(
    List<AiApiMessage> messages, {
    bool includeContext = true,
    int maxUserChars = 900,
    int maxAssistantChars = 360,
  }) {
    final lastUser = messages.lastWhere(
      (message) => message.role == 'user',
      orElse: () => messages.last,
    );
    final contextMessages = messages
        .where((message) => message.role == 'system')
        .skip(1)
        .map((message) => message.content)
        .where((content) => content.trim().isNotEmpty)
        .toList(growable: false);
    final previousAnswers = messages
        .where((message) => message.role == 'assistant')
        .map((message) => message.content)
        .where((content) => content.trim().isNotEmpty)
        .toList(growable: false);
    final previousAssistant = previousAnswers.isEmpty
        ? null
        : previousAnswers.last;

    final buffer = StringBuffer()
      ..writeln(
        'You are Liga Gym AI. Answer only about nutrition, workouts, recovery, and fitness goals. Be brief and practical. Match the user language.',
      );
    if (includeContext && contextMessages.isNotEmpty) {
      buffer.writeln('Context: ${_ellipsize(contextMessages.last, 520)}');
    }
    if (maxAssistantChars > 0 && previousAssistant != null) {
      buffer.writeln(
        'Previous answer: ${_ellipsize(previousAssistant, maxAssistantChars)}',
      );
    }
    buffer
      ..writeln('User: ${_ellipsize(lastUser.content, maxUserChars)}')
      ..write('Assistant:');

    return buffer.toString();
  }

  String _ellipsize(String value, int maxChars) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxChars) {
      return normalized;
    }

    return '${normalized.substring(0, maxChars).trimRight()}...';
  }

  List<String> _modelsToTry(String configuredModel) {
    final normalizedModel = _normalizeModel(configuredModel);
    final isPollinations =
        chatUrl.host == 'text.pollinations.ai' ||
        chatUrl.host == 'gen.pollinations.ai';
    if (!isPollinations) {
      return normalizedModel.isEmpty
          ? const <String>[]
          : <String>[normalizedModel];
    }

    return <String>{
      normalizedModel,
      'openai',
      'openai-fast',
    }.where((model) => model.isNotEmpty).toList(growable: false);
  }

  String _normalizeModel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'openaiflutter') {
      return 'openai';
    }
    if (normalized.endsWith('flutter')) {
      return normalized.substring(0, normalized.length - 'flutter'.length);
    }

    return normalized;
  }

  bool _isRetryable(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('model not found') ||
        normalized.contains('empty completion') ||
        normalized.contains('empty text') ||
        normalized.contains('429') ||
        normalized.contains('500') ||
        normalized.contains('502') ||
        normalized.contains('503') ||
        normalized.contains('504') ||
        normalized.contains('414') ||
        normalized.contains('already queued') ||
        normalized.contains('already in queue') ||
        normalized.contains('queue') ||
        normalized.contains('queued') ||
        normalized.contains('uri too long') ||
        normalized.contains('prompt too long') ||
        normalized.contains('rate limit') ||
        normalized.contains('too many requests') ||
        normalized.contains('timeout');
  }

  bool _isProviderQueueMessage(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.contains('already queued') ||
        normalized.contains('already in queue') ||
        normalized.contains('queue is full') ||
        normalized.contains('too many requests') ||
        normalized.contains('rate limit');
  }

  String _errorMessage(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (body.trim().isEmpty) {
      return 'HTTP ${response.statusCode}';
    }

    try {
      final payload = jsonDecode(body);
      if (payload is Map) {
        final message =
            payload['message'] ??
            payload['error_description'] ??
            payload['error'];
        if (message != null) {
          return 'HTTP ${response.statusCode}: $message';
        }
      }
    } on Object {
      // Keep the raw body below.
    }

    return 'HTTP ${response.statusCode}: $body';
  }
}

class AiProviderException implements Exception {
  const AiProviderException(this.message);

  final String message;
}
