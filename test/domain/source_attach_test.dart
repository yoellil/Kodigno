import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/source_attach.dart';
import 'package:kodigno/domain/source_ref.dart';

final _locator = SourceLocator(parsePages([
  pageMarker(2),
  'Trade secret\n- Information used in business that is generally unknown to the public.',
  '',
  pageMarker(4),
  'Whistle-blowing\n- Attracts attention to a negligent, illegal, unethical, abusive, or dangerous act that threatens the public interest.',
].join('\n')));

void main() {
  const set = GeneratedSet([
    QuizQuestion(
      prompt: 'Which term is this? Information used in business that is generally unknown to the public.',
      choices: ['Trade secret', 'Fraud', 'Bribery'],
      answerIndex: 0,
      explanation: 'Trade secret: Information used in business that is generally unknown to the public.',
    ),
    QuizQuestion(prompt: 'What does whistle-blowing attract attention to?', choices: ['An illegal act', 'A holiday', 'A prize'], answerIndex: 0),
  ], [
    Flashcard(front: 'Trade secret', back: 'Information used in business that is generally unknown to the public.'),
    Flashcard(front: 'What does whistle-blowing draw attention to?', back: 'A dangerous or illegal act'),
    Flashcard(front: 'Which planet is closest to the Sun?', back: 'Mercury'),
  ]);

  test('each flashcard and question gets the page it rests on', () {
    final out = attachSources(set, _locator);
    // a definition taken word for word is a copy
    expect(out.flashcards[0].source!.kind, SourceKind.copied);
    expect(out.flashcards[0].source!.page, 2);
    expect(out.questions[0].source!.kind, SourceKind.copied);
    expect(out.questions[0].source!.page, 2);
    // a question the AI made is matched to the closest page
    expect(out.flashcards[1].source!.kind, SourceKind.explained);
    expect(out.flashcards[1].source!.page, 4);
    expect(out.questions[1].source!.page, 4); // no explanation: the question with its right answer
    // one that no page supports is flagged
    expect(out.flashcards[2].source!.kind, SourceKind.unmatched);
  });

  test('the cards and questions themselves are not changed', () {
    final out = attachSources(set, _locator);
    expect([for (final c in out.flashcards) c.front], [for (final c in set.flashcards) c.front]);
    expect([for (final q in out.questions) q.choices], [for (final q in set.questions) q.choices]);
    expect(out.questions.first.answerIndex, 0);
  });

  test('without pages (a Word file, plain text) the set is returned as it is', () {
    expect(identical(attachSources(set, null), set), isTrue);
  });
}
