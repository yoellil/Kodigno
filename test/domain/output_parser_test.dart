import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/output_parser.dart';

void main() {
  test('parseFacts reads JSON wrapped in prose and drops placeholders', () {
    final f = parseFacts('Sure!\n{"facts":["<fact 1> Fact one.","<fact 2>"," "]}\nDone.');
    expect(f, ['Fact one.']);
  });

  test('parseQa keeps complete pairs only', () {
    final q = parseQa('{"items":[{"question":"Q?","answer":"A"},'
        '{"question":"Q2?","answer":""},{"question":"<question>","answer":"<answer>"}]}');
    expect(q.map((i) => i.question), ['Q?']);
    expect(q.single.answer, 'A');
  });

  test('parseWrong reads one list of wrong answers per question, in order', () {
    final w = parseWrong('{"items":[{"wrong":["A","<wrong 2>"," B "]},{"wrong":[]},{"x":1}]}');
    expect(w, [
      ['A', 'B'],
      <String>[],
      <String>[],
    ]);
    expect(() => parseWrong('{"items":[]}'), throwsFormatException);
  });

  test('throw when nothing usable, not JSON, or truncated', () {
    expect(() => parseFacts('{"facts":[]}'), throwsFormatException);
    expect(() => parseQa('{"items":[]}'), throwsFormatException);
    expect(() => parseFacts('I cannot do that'), throwsFormatException);
    expect(() => parseQa('{"items":[{"question":"Q"'), throwsFormatException);
  });

  test('parseQa and parseWrong drop placeholder answers and strip "The answer is"', () {
    final qa = parseQa('{"items":['
        '{"question":"Where was Rizal born?","answer":"The answer is Calamba"},'
        '{"question":"Who wrote it?","answer":"answer"},'
        '{"question":"When did he die?","answer":"N/A"}]}');
    expect(qa.map((i) => i.answer), ['Calamba']);
    final wrong = parseWrong('{"items":[{"wrong":["Manila","Answer","None of the above","Cebu"]}]}');
    expect(wrong.single, ['Manila', 'Cebu']);
  });
}
