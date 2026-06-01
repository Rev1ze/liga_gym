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
      return isRu
          ? 'Не удалось получить ответ AI: ${error.message}'
          : 'Could not get an AI response: ${error.message}';
    } on Object {
      return isRu
          ? 'Не удалось связаться с бесплатной AI-моделью. Проверьте интернет и попробуйте ещё раз.'
          : 'Could not reach the free AI model. Check your internet connection and try again.';
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
    return PollinationsAiClient(
      chatUrl: Uri.parse(
        const String.fromEnvironment(
          'AI_CHAT_URL',
          defaultValue: 'https://text.pollinations.ai/openai',
        ),
      ),
      model: const String.fromEnvironment('AI_MODEL', defaultValue: 'openai'),
      apiKey: const String.fromEnvironment('POLLINATIONS_API_KEY'),
    );
  }

  final Uri chatUrl;
  final String model;
  final String apiKey;
  final http.Client _httpClient;

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

    try {
      return await _completeWithTextEndpoint(messages: messages);
    } on AiProviderException catch (error) {
      lastError = error;
    }

    throw lastError;
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

    final response = await _httpClient
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiProviderException(_errorMessage(response));
    }

    final content = _extractContent(utf8.decode(response.bodyBytes));

    if (content.trim().isEmpty) {
      throw const AiProviderException('empty completion response');
    }

    return content.trim();
  }

  Future<String> _completeWithTextEndpoint({
    required List<AiApiMessage> messages,
  }) async {
    final prompt = _plainPrompt(messages);
    final query = <String, String>{'model': 'openai', 'json': 'false'};
    if (apiKey.isNotEmpty) {
      query['token'] = apiKey;
    }
    final fallbackUrl = Uri.parse(
      'https://text.pollinations.ai/${Uri.encodeComponent(prompt)}',
    ).replace(queryParameters: query);
    final response = await _httpClient
        .get(
          fallbackUrl,
          headers: const <String, String>{'Accept': 'text/plain'},
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiProviderException(_errorMessage(response));
    }

    final content = utf8.decode(response.bodyBytes).trim();
    if (content.isEmpty) {
      throw const AiProviderException('empty text response');
    }

    return content;
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

  String _plainPrompt(List<AiApiMessage> messages) {
    final buffer = StringBuffer();
    for (final message in messages) {
      final label = switch (message.role) {
        'system' => 'Инструкция',
        'assistant' => 'Ассистент',
        _ => 'Пользователь',
      };
      buffer.writeln('$label: ${message.content}');
    }
    buffer.writeln('Ассистент:');
    return buffer.toString();
  }

  List<String> _modelsToTry(String configuredModel) {
    final normalizedModel = _normalizeModel(configuredModel);
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
        normalized.contains('too many requests') ||
        normalized.contains('timeout');
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
