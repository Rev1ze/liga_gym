import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liga_gym_app/features/ai_coach/presentation/screens/ai_coach_screen.dart';

void main() {
  testWidgets('AI coach renders markdown emphasis without raw placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiCoachMessagePreview(
            text:
                '**Белок** важен\n## План\n| День | Еда |\n| --- | --- |\n| 1 | Творог |',
          ),
        ),
      ),
    );

    expect(find.textContaining(r'$1'), findsNothing);
    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('##'), findsNothing);
    expect(find.textContaining('Белок'), findsWidgets);
    expect(find.text('День'), findsOneWidget);
    expect(find.text('Творог'), findsOneWidget);
  });
}
