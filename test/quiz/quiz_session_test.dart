import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/quiz/quiz_session.dart';

void main() {
  final qs = [
    const QuizQuestion(prompt: 'A', choices: ['x', 'y'], answerIndex: 0),
    const QuizQuestion(prompt: 'B', choices: ['x', 'y'], answerIndex: 1),
  ];

  test('scores and records results', () {
    final s = QuizSession(qs);
    expect(s.current.prompt, 'A');
    s.answer(0); // correct
    s.answer(0); // wrong
    expect(s.isDone, isTrue);
    expect(s.score, 1);
    expect(s.results, [
      {'q': 0, 'chosen': 0, 'correct': true},
      {'q': 1, 'chosen': 0, 'correct': false},
    ]);
  });

  test('answering after done throws', () {
    final s = QuizSession(qs)..answer(0)..answer(1);
    expect(() => s.answer(0), throwsStateError);
  });
}
