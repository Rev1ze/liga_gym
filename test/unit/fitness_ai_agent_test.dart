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

  test('rejects Russian non fitness questions before calling provider', () async {
    final client = _FakeAiChatClient('unused');
    final agent = FitnessAiAgent(client: client);

    final answer = await agent.answer(
      question: 'Расскажи курс доллара',
      context: context,
      hasFitnessHistory: false,
      languageCode: 'ru',
    );

    expect(answer, contains('могу помогать только с питанием и тренировками'));
    expect(client.callCount, 0);
  });

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
        chatUrl: Uri.parse('https://example.com/openai'),
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
