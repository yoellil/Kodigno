import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/prompt.dart';

void main() {
  test('empty or whitespace text gives no chunks', () {
    expect(chunkText('', 100), isEmpty);
    expect(chunkText('  \n\n  ', 100), isEmpty);
  });

  test('short text is one chunk', () {
    expect(chunkText('Cells are small.', 100), ['Cells are small.']);
  });

  test('chunks respect max size and lose no words', () {
    final text = List.generate(40, (i) => 'Sentence number $i is here.').join(' ');
    final chunks = chunkText(text, 120);
    expect(chunks.length, greaterThan(1));
    expect(chunks.every((c) => c.length <= 120), isTrue);
    final rejoined = chunks.join(' ').split(RegExp(r'\s+'));
    expect(rejoined, text.split(RegExp(r'\s+')));
  });

  test('a single unbroken string longer than max is hard-cut', () {
    final chunks = chunkText('a' * 250, 100);
    expect(chunks.map((c) => c.length), [100, 100, 50]);
  });

  test('prompt contains notes, counts and JSON shape', () {
    final p = buildPrompt('Mitosis notes', questions: 3, cards: 2);
    expect(p, contains('Mitosis notes'));
    expect(p, contains('3 multiple-choice questions'));
    expect(p, contains('2 flashcards'));
    expect(p, contains('"answer_index"'));
  });

  test('prompt shows a concrete example, not "..." placeholders', () {
    final p = buildPrompt('n', questions: 1, cards: 1);
    expect(p, isNot(contains('...')));
    expect(p, contains('exactly 4 choices'));
  });
}
