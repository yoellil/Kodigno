import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/factcheck.dart';
import 'package:kodigno/domain/judge.dart';

const _passage = 'He wrote the novel Noli Me Tangere in Berlin in 1887.';

void main() {
  test('supported needs a quote that is really in the passage', () {
    final ok = parseJudge('{"verdict":"supported","quote":"wrote the novel Noli Me Tangere in Berlin"}', _passage);
    expect(ok.verdict, Verdict.supported);
    expect(ok.quote, contains('Berlin'));
  });

  test('a quote the model made up downgrades "supported" to unverified', () {
    final r = parseJudge('{"verdict":"supported","quote":"wrote El Filibusterismo in Ghent"}', _passage);
    expect(r.verdict, Verdict.unverified);
    expect(parseJudge('{"verdict":"supported","quote":""}', _passage).verdict, Verdict.unverified);
  });

  test('contradicted and not_stated are read', () {
    expect(parseJudge('{"verdict":"contradicted","quote":"x"}', _passage).verdict, Verdict.contradicted);
    expect(parseJudge('{"verdict":"not_stated","quote":""}', _passage).verdict, Verdict.unverified);
  });

  test('reads JSON wrapped in prose; rejects anything else', () {
    expect(parseJudge('Sure! {"verdict":"not_stated","quote":""} done', _passage).verdict, Verdict.unverified);
    expect(() => parseJudge('no json', _passage), throwsFormatException);
    expect(() => parseJudge('{"verdict":"maybe","quote":""}', _passage), throwsFormatException);
  });

  test('the prompt shows the passage, the question and the answer', () {
    final p = buildJudgePrompt(passage: _passage, question: 'Where?', answer: 'Berlin');
    expect(p, allOf(contains(_passage), contains('QUESTION: Where?'), contains('ANSWER: Berlin')));
  });
}
