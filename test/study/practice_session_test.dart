import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/study/practice_session.dart';
import 'package:kodigno/study/session_plan.dart';

PracticeItem _card(int id) => PracticeItem(
    kind: ItemKind.card, itemId: id, setId: 1, setTitle: 'Set', prompt: 'front $id', answer: 'back $id');

PracticeItem _q(int id, {int answer = 1}) => PracticeItem(
      kind: ItemKind.question,
      itemId: id,
      setId: 1,
      setTitle: 'Set',
      prompt: 'question $id',
      answer: ['a', 'b', 'c'][answer],
      choices: const ['a', 'b', 'c'],
      answerIndex: answer,
    );

class _Rec {
  final calls = <(int, bool, int?)>[];
  Future<void> call(PracticeItem item, bool correct, int? chosen) async => calls.add((item.itemId, correct, chosen));
}

void main() {
  test('a card is answered right or wrong, recorded at once, and stays on screen until next', () async {
    final rec = _Rec();
    final s = PracticeSession([_card(1), _card(2)], rec.call);
    expect(s.current.itemId, 1);
    expect(s.answered, isFalse);
    expect(s.lastCorrect, isNull);

    await s.answer(correct: true);
    expect(rec.calls, [(1, true, null)]);
    expect(s.answered, isTrue);
    expect(s.lastCorrect, isTrue);
    expect(s.current.itemId, 1); // still the same item, showing its result
    expect(s.correctCount, 1);

    s.next();
    expect(s.current.itemId, 2);
    expect(s.answered, isFalse);
    expect(s.lastCorrect, isNull);
  });

  test('a question is judged by the choice picked, and the choice is kept', () async {
    final rec = _Rec();
    final s = PracticeSession([_q(1, answer: 1), _q(2, answer: 2)], rec.call);
    await s.choose(1);
    expect(s.lastCorrect, isTrue);
    expect(s.lastChosen, 1);
    s.next();
    await s.choose(0);
    expect(s.lastCorrect, isFalse);
    expect(s.lastChosen, 0);
    expect(rec.calls, [(1, true, 1), (2, false, 0)]);
  });

  test('the score and the missed items are tracked, and the session ends after the last item', () async {
    final s = PracticeSession([_card(1), _q(2), _card(3)], _Rec().call);
    expect(s.isDone, isFalse);
    expect(s.total, 3);
    await s.answer(correct: true);
    s.next();
    await s.choose(0); // wrong: the answer is 1
    s.next();
    await s.answer(correct: false);
    s.next();
    expect(s.isDone, isTrue);
    expect(s.correctCount, 1);
    expect([for (final m in s.missed) m.itemId], [2, 3]);
  });

  test('a second answer to the same item is ignored, so a double tap cannot count twice', () async {
    final rec = _Rec();
    final s = PracticeSession([_card(1), _card(2)], rec.call);
    await Future.wait([s.answer(correct: true), s.answer(correct: true), s.answer(correct: false)]);
    expect(rec.calls, hasLength(1));
    expect(s.correctCount, 1);
    expect(s.missed, isEmpty);
    await s.answer(correct: false); // and later too, until next
    expect(rec.calls, hasLength(1));
  });

  test('next does nothing until the item is answered, and nothing after the end', () async {
    final s = PracticeSession([_card(1)], _Rec().call);
    s.next();
    expect(s.index, 0);
    await s.answer(correct: true);
    s.next();
    expect(s.isDone, isTrue);
    s.next();
    expect(s.index, 1);
    await s.answer(correct: true); // nothing to answer
    expect(s.correctCount, 1);
  });

  test('if an answer cannot be saved, the session carries on and says so', () async {
    final s = PracticeSession([_card(1), _card(2)], (_, _, _) async => throw StateError('disk full'));
    await s.answer(correct: true);
    expect(s.saveFailed, isTrue);
    expect(s.answered, isTrue);
    expect(s.correctCount, 1);
    s.next();
    expect(s.current.itemId, 2);
  });

  test('an empty session is done at once', () {
    final s = PracticeSession(const [], _Rec().call);
    expect(s.isDone, isTrue);
    expect(s.total, 0);
  });

  test('listeners hear about each change', () async {
    final s = PracticeSession([_card(1), _card(2)], _Rec().call);
    var n = 0;
    s.addListener(() => n++);
    await s.answer(correct: true);
    expect(n, greaterThanOrEqualTo(1));
    final before = n;
    s.next();
    expect(n, before + 1);
  });

  test('the missed list cannot be changed from outside', () async {
    final s = PracticeSession([_card(1)], _Rec().call);
    await s.answer(correct: false);
    expect(() => s.missed.add(_card(9)), throwsUnsupportedError);
  });
}
