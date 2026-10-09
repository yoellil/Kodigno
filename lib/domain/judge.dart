import 'dart:convert';

import 'factcheck.dart' show Verdict;

/// The judge: the same small model that writes the cards reads one passage of
/// the notes with a question and its answer, and says whether the passage
/// settles it. Its reply is trusted only if the quote it gives really is in the
/// passage, so it cannot make up its own evidence.

String buildJudgePrompt({required String passage, required String question, required String answer}) => '''
You check a study card against a passage from the student's notes. Use only the passage.
PASSAGE: $passage
QUESTION: $question
ANSWER: $answer
Is the ANSWER a correct answer to the QUESTION according to the PASSAGE?
- "supported": the passage states it.
- "contradicted": the passage says something that conflicts with it.
- "not_stated": the passage does not say.
Reply with JSON only: {"verdict": "supported" | "contradicted" | "not_stated", "quote": "the exact words of the passage that show it, empty if not_stated"}
''';

Map<String, Object?> judgeSchema() => {
      'type': 'object',
      'properties': {
        'verdict': {
          'type': 'string',
          'enum': ['supported', 'contradicted', 'not_stated'],
        },
        'quote': {'type': 'string', 'maxLength': 300},
      },
      'required': ['verdict', 'quote'],
    };

class JudgeResult {
  const JudgeResult(this.verdict, this.quote);
  final Verdict verdict;
  final String quote;
}

String _flat(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[‘’]'), "'")
    .replaceAll(RegExp(r'[“”]'), '"')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// The judge's verdict from [raw], with "supported" kept only if its quote is
/// in [passage] word for word. Throws [FormatException] if [raw] is not usable.
JudgeResult parseJudge(String raw, String passage) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) throw const FormatException('no JSON object in judge output');
  final j = jsonDecode(raw.substring(start, end + 1));
  if (j is! Map) throw const FormatException('judge output is not an object');
  final quote = (j['quote'] is String ? j['quote'] as String : '').trim();
  switch (j['verdict']) {
    case 'supported':
      final q = _flat(quote).replaceAll(RegExp(r'^\W+|\W+$'), '');
      final ok = q.length >= 4 && _flat(passage).contains(q);
      return JudgeResult(ok ? Verdict.supported : Verdict.unverified, ok ? quote : '');
    case 'contradicted':
      return JudgeResult(Verdict.contradicted, quote);
    case 'not_stated':
      return const JudgeResult(Verdict.unverified, '');
  }
  throw const FormatException('unknown verdict');
}
