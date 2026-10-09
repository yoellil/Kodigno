import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/ui/anim.dart';
import 'package:kodigno/ui/quiz_screen.dart';
import 'package:kodigno/ui/theme.dart';

Future<void> _pump(WidgetTester t, List<QuizQuestion> questions,
    {QuizFinished? onFinished, String title = 'Calculus'}) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1000, 1000);
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: kTheme(),
    home: Scaffold(
      body: QuizBody(
        title: title,
        questions: questions,
        onFinished: onFinished ?? (_, _, _, _) {},
      ),
    ),
  ));
}

const _two = [
  QuizQuestion(prompt: 'Q1?', choices: ['right', 'wrong'], answerIndex: 0),
  QuizQuestion(prompt: 'Q2?', choices: ['wrong', 'right'], answerIndex: 1, explanation: 'Because.'),
];

void main() {
  testWidgets('select, Next, Finish, then results', (t) async {
    int? savedScore;
    await _pump(t, _two, onFinished: (score, total, seconds, results) => savedScore = score);

    expect(find.text('Q1?'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    await t.tap(find.text('right'));
    await t.pump();
    await t.tap(find.text('Next'));
    await t.pumpAndSettle(); // question slides in

    expect(find.text('Q2?'), findsOneWidget);
    await t.tap(find.text('wrong')); // incorrect on purpose
    await t.pump();
    await t.tap(find.text('Finish'));
    await t.pumpAndSettle(); // percentage rolls up

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1 of 2 correct'), findsOneWidget);
    expect(find.text('Q2?'), findsOneWidget); // listed under "review these"
    expect(savedScore, 1);
  });

  testWidgets('Next stays disabled until an option is chosen', (t) async {
    await _pump(t, const [QuizQuestion(prompt: 'Q?', choices: ['a', 'b'], answerIndex: 0)]);
    await t.tap(find.text('Finish'));
    await t.pump();
    expect(find.text('Q?'), findsOneWidget); // still on the question
    await t.pumpAndSettle(); // let the entrance animation finish (no pending timers)
  });

  testWidgets('confetti only for a good score, and Try again restarts', (t) async {
    await _pump(t, const [QuizQuestion(prompt: 'Q?', choices: ['a', 'b'], answerIndex: 0)]);
    await t.tap(find.text('a')); // correct
    await t.pump();
    await t.tap(find.text('Finish'));
    await t.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(find.byType(Confetti), findsOneWidget);

    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(find.text('Q?'), findsOneWidget);
    expect(find.byType(Confetti), findsNothing);
  });

  testWidgets('a poor score shows no confetti', (t) async {
    await _pump(t, const [QuizQuestion(prompt: 'Q?', choices: ['a', 'b'], answerIndex: 0)]);
    await t.tap(find.text('b')); // wrong
    await t.pump();
    await t.tap(find.text('Finish'));
    await t.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);
    expect(find.byType(Confetti), findsNothing);
  });
}
