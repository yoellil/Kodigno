import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/output_parser.dart';

const _valid = '''
{"questions":[{"prompt":"Capital of France?","choices":["Paris","Rome","Madrid","Bonn"],"answer_index":0,"explanation":"It is Paris."}],
 "flashcards":[{"front":"H2O","back":"Water"}]}
''';

void main() {
  test('parses valid JSON wrapped in prose', () {
    final s = parseGeneratedSet('Sure! Here you go:\n$_valid\nHope it helps.');
    expect(s.questions.single.prompt, 'Capital of France?');
    expect(s.questions.single.answerIndex, 0);
    expect(s.flashcards.single.back, 'Water');
  });

  test('skips a question whose answer_index is out of range', () {
    final s = parseGeneratedSet(
        '{"questions":[{"prompt":"Q","choices":["a","b"],"answer_index":5}],'
        '"flashcards":[{"front":"f","back":"b"}]}');
    expect(s.questions, isEmpty);
    expect(s.flashcards, hasLength(1));
  });

  test('skips questions with fewer than 2 choices or empty prompt', () {
    final s = parseGeneratedSet(
        '{"questions":[{"prompt":"Q","choices":["a"],"answer_index":0},'
        '{"prompt":" ","choices":["a","b"],"answer_index":0}],'
        '"flashcards":[{"front":"f","back":"b"}]}');
    expect(s.questions, isEmpty);
  });

  test('throws when nothing valid', () {
    expect(() => parseGeneratedSet('{"questions":[],"flashcards":[]}'),
        throwsFormatException);
  });

  test('throws on non-JSON', () {
    expect(() => parseGeneratedSet('I cannot do that'), throwsFormatException);
  });

  test('throws on truncated JSON', () {
    expect(() => parseGeneratedSet('{"questions":[{"prompt":"Q"'),
        throwsFormatException);
  });
}
