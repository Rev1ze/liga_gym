import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liga_gym_app/features/ai_coach/domain/services/fitness_ai_agent.dart';
import 'package:liga_gym_app/features/auth/domain/entities/user_goal.dart';
import 'package:liga_gym_app/features/nutrition/domain/entities/food_macros.dart';

void main() {
  const context = FitnessAiContext(
    entries: [],
    totalMacros: FoodMacros(calories: 760, proteins: 42, fats: 28, carbs: 86),
    calorieGoal: 2200,
    stepGoal: 10000,
    goalType: UserGoalType.loseWeight,
  );

  test('rejects non fitness questions before calling provider', () async {
    final client = _FakeAiChatClient('unused');
    final agent = FitnessAiAgent(client: client);

    final answer = await agent.answer(
      question: 'Tell me the dollar exchange rate',
      context: context,
      hasFitnessHistory: false,
      languageCode: 'en',
    );

    expect(answer, contains('only help with nutrition and training'));
    expect(client.callCount, 0);
  });

  test(
    'sends fitness questions to provider with system prompt and context',
    () async {
      final client = _FakeAiChatClient('Real AI answer');
      final agent = FitnessAiAgent(client: client);

      final answer = await agent.answer(
        question: 'I ate pizza. Is that bad?',
        context: context,
        hasFitnessHistory: false,
        languageCode: 'en',
      );

      expect(answer, 'Real AI answer');
      expect(client.callCount, 1);
      expect(client.lastMessages.first.role, 'system');
      expect(client.lastMessages.first.content, contains('Liga Gym'));
      expect(client.lastMessages[1].content, contains('760'));
    },
  );

  test('sends Russian fitness questions to provider', () async {
    final client = _FakeAiChatClient('Нормальный ответ');
    final agent = FitnessAiAgent(client: client);

    final answer = await agent.answer(
      question: 'Я ел пиццу. Это плохо?',
      context: context,
      hasFitnessHistory: false,
      languageCode: 'ru',
    );

    expect(answer, 'Нормальный ответ');
    expect(client.callCount, 1);
    expect(client.lastMessages.first.content, contains('Liga Gym'));
    expect(client.lastMessages[1].content, contains('Контекст пользователя'));
    expect(client.lastMessages[1].content, contains('снижение веса'));
  });

  test(
    'rejects Russian non fitness questions before calling provider',
    () async {
      final client = _FakeAiChatClient('unused');
      final agent = FitnessAiAgent(client: client);

      final answer = await agent.answer(
        question: 'Расскажи курс доллара',
        context: context,
        hasFitnessHistory: false,
        languageCode: 'ru',
      );

      expect(
        answer,
        contains('могу помогать только с питанием и тренировками'),
      );
      expect(client.callCount, 0);
    },
  );

  test('allows why follow up after fitness history', () async {
    final client = _FakeAiChatClient('Because balance matters');
    final agent = FitnessAiAgent(client: client);

    final answer = await agent.answer(
      question: 'Why?',
      context: context,
      hasFitnessHistory: true,
      languageCode: 'en',
    );

    expect(answer, 'Because balance matters');
    expect(client.callCount, 1);
  });

  test(
    'reports provider issue when free provider says already queued',
    () async {
      final client = _ThrowingAiChatClient(
        const AiProviderException('already queued'),
      );
      final agent = FitnessAiAgent(client: client);

      final answer = await agent.answer(
        question: 'I ate pizza. Is that bad?',
        context: context,
        hasFitnessHistory: false,
        languageCode: 'en',
      );

      expect(answer, contains('neural model did not respond'));
      expect(answer, contains('already queued'));
      expect(answer, isNot(contains('quick local answer')));
      expect(client.callCount, 1);
    },
  );

  test('reports provider issue when provider returns HTTP 414', () async {
    final client = _ThrowingAiChatClient(
      const AiProviderException('HTTP 414: URI Too Long'),
    );
    final agent = FitnessAiAgent(client: client);

    final answer = await agent.answer(
      question: 'Какие тренировки мне делать?',
      context: context,
      hasFitnessHistory: false,
      languageCode: 'ru',
    );

    expect(answer, contains('Нейросеть сейчас не ответила'));
    expect(answer, contains('414'));
    expect(answer, isNot(contains('быстрый ответ локально')));
    expect(client.callCount, 1);
  });

  test(
    'pollinations client retries with openai when model is malformed',
    () async {
      final triedModels = <String>[];
      final client = PollinationsAiClient(
        chatUrl: Uri.parse('https://example.com/openai'),
        model: 'openaiflutter',
        apiKey: '',
        httpClient: MockClient((request) async {
          final body = request.body;
          triedModels.add(body);

          if (body.contains('"model":"openai"')) {
            return http.Response(
              '{"choices":[{"message":{"content":"ok"}}]}',
              200,
            );
          }

          return http.Response(
            '{"error":"Model not found: openaiflutter"}',
            404,
          );
        }),
      );

      final answer = await client.complete(
        messages: const [AiApiMessage(role: 'user', content: 'Hi')],
      );

      expect(answer, 'ok');
      expect(triedModels.first, contains('"model":"openai"'));
    },
  );

  test('pollinations client reads alternate completion shapes', () async {
    final client = PollinationsAiClient(
      chatUrl: Uri.parse('https://example.com/openai'),
      model: 'openai',
      apiKey: '',
      httpClient: MockClient((request) async {
        return http.Response('{"choices":[{"text":"plain text answer"}]}', 200);
      }),
    );

    final answer = await client.complete(
      messages: const [AiApiMessage(role: 'user', content: 'Hi')],
    );

    expect(answer, 'plain text answer');
  });

  test(
    'pollinations client falls back to text endpoint after empty completions',
    () async {
      var callCount = 0;
      final client = PollinationsAiClient(
        chatUrl: Uri.parse('https://text.pollinations.ai/openai'),
        model: 'openai',
        apiKey: '',
        httpClient: MockClient((request) async {
          callCount += 1;
          if (request.method == 'GET') {
            return http.Response('fallback answer', 200);
          }

          return http.Response('{"choices":[{"message":{"content":""}}]}', 200);
        }),
      );

      final answer = await client.complete(
        messages: const [AiApiMessage(role: 'user', content: 'Hi')],
      );

      expect(answer, 'fallback answer');
      expect(callCount, greaterThan(1));
    },
  );

  test(
    'pollinations client treats already queued payloads as retryable',
    () async {
      var callCount = 0;
      final client = PollinationsAiClient(
        chatUrl: Uri.parse('https://text.pollinations.ai/openai'),
        model: 'openai',
        apiKey: '',
        httpClient: MockClient((request) async {
          callCount += 1;
          if (request.method == 'GET') {
            return http.Response('fallback answer', 200);
          }

          return http.Response('already queued', 200);
        }),
      );

      final answer = await client.complete(
        messages: const [AiApiMessage(role: 'user', content: 'Hi')],
      );

      expect(answer, 'fallback answer');
      expect(callCount, greaterThan(1));
    },
  );

  test(
    'pollinations text fallback follows gen endpoint when using api key',
    () async {
      final requestedUrls = <Uri>[];
      final authHeaders = <String?>[];
      final client = PollinationsAiClient(
        chatUrl: Uri.parse('https://gen.pollinations.ai/v1/chat/completions'),
        model: 'openai',
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          requestedUrls.add(request.url);
          authHeaders.add(request.headers['Authorization']);

          if (request.method == 'GET') {
            return http.Response('fallback answer', 200);
          }

          return http.Response('{"choices":[{"message":{"content":""}}]}', 200);
        }),
      );

      final answer = await client.complete(
        messages: const [AiApiMessage(role: 'user', content: 'Hi')],
      );

      expect(answer, 'fallback answer');
      expect(requestedUrls.last.host, 'gen.pollinations.ai');
      expect(requestedUrls.last.path, startsWith('/text/'));
      expect(authHeaders.last, 'Bearer test-key');
    },
  );

  test(
    'pollinations text fallback compacts long prompts to avoid 414',
    () async {
      Uri? fallbackUrl;
      final longQuestion = 'пицца и тренировка ' * 500;
      final client = PollinationsAiClient(
        chatUrl: Uri.parse('https://text.pollinations.ai/openai'),
        model: 'openai',
        apiKey: '',
        httpClient: MockClient((request) async {
          if (request.method == 'GET') {
            fallbackUrl = request.url;
            return http.Response('fallback answer', 200);
          }

          return http.Response('{"error":"too many requests"}', 429);
        }),
      );

      final answer = await client.complete(
        messages: [
          const AiApiMessage(
            role: 'system',
            content: FitnessAiAgent.systemPrompt,
          ),
          AiApiMessage(role: 'system', content: 'Контекст: $longQuestion'),
          AiApiMessage(role: 'user', content: longQuestion),
        ],
      );

      expect(answer, 'fallback answer');
      expect(fallbackUrl, isNotNull);
      expect(fallbackUrl.toString().length, lessThanOrEqualTo(7600));
    },
  );

  test(
    'openai compatible api does not use pollinations text fallback',
    () async {
      var callCount = 0;
      final client = PollinationsAiClient(
        chatUrl: Uri.parse('https://api.openai.com/v1/chat/completions'),
        model: 'gpt-4.1-mini',
        apiKey: 'openai-key',
        httpClient: MockClient((request) async {
          callCount += 1;
          expect(request.method, 'POST');
          expect(request.headers['Authorization'], 'Bearer openai-key');
          return http.Response('{"error":"rate limit"}', 429);
        }),
      );

      await expectLater(
        client.complete(
          messages: const [AiApiMessage(role: 'user', content: 'Hi')],
        ),
        throwsA(isA<AiProviderException>()),
      );
      expect(callCount, 1);
    },
  );
}

class _FakeAiChatClient implements AiChatClient {
  _FakeAiChatClient(this.response);

  final String response;
  int callCount = 0;
  List<AiApiMessage> lastMessages = const [];

  @override
  Future<String> complete({required List<AiApiMessage> messages}) async {
    callCount += 1;
    lastMessages = messages;
    return response;
  }
}

class _ThrowingAiChatClient implements AiChatClient {
  _ThrowingAiChatClient(this.error);

  final Object error;
  int callCount = 0;

  @override
  Future<String> complete({required List<AiApiMessage> messages}) async {
    callCount += 1;
    throw error;
  }
}
