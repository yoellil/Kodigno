import 'dart:convert';

/// The second opinion on a card: the same small model is asked to do the one
/// thing it is reliable at, reading the answer to the question out of the
/// passage, and plain code compares what it read with the card's answer. A
/// model asked "is this answer right?" says yes to nearly anything (measured: a
/// third of wrong answers pass); asked to read the answer back, it never agreed
/// with a wrong or padded one in testing, and read back 95% of the right ones.

String buildReaderPrompt({required String passage, required String question}) => '''
PASSAGE: $passage
QUESTION: $question
Using only the passage, give the exact words from the passage that answer the question. If the passage does not answer it, leave the answer empty.
Reply with JSON only: {"answer": "..."}
''';

Map<String, Object?> readerSchema() => {
      'type': 'object',
      'properties': {
        'answer': {'type': 'string', 'maxLength': 160},
      },
      'required': ['answer'],
    };

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[‘’]'), "'")
    .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// The words the model read out of [passage], or '' if it found nothing or what it
/// gave is not really in the passage (made up). Throws [FormatException] if [raw]
/// is not usable JSON.
String parseReader(String raw, String passage) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) throw const FormatException('no JSON object in reader output');
  final j = jsonDecode(raw.substring(start, end + 1));
  if (j is! Map || j['answer'] is! String) throw const FormatException('reader output has no answer');
  final got = (j['answer'] as String).trim();
  if (got.isEmpty) return '';
  return _norm(passage).contains(_norm(got)) ? got : '';
}

List<String> _content(String s) => [
      for (final t in _norm(s).split(' '))
        if (t.length >= 4 || RegExp(r'^\d+$').hasMatch(t)) t.length > 4 && t.endsWith('s') ? t.substring(0, t.length - 1) : t,
    ];

/// True if the card's [answer] is what the model [read] from the notes. A short
/// answer must lie inside what was read, word for word: a different name or number
/// is not inside it, and neither is an answer that says more than the notes do
/// ("Berlin, as announced in 1999"). A longer answer (five words or more) is often
/// the notes' sentence reworded, so most (70%) of its main words must be in what
/// was read.
bool answerWithin(String answer, String read) {
  final a = _norm(answer);
  final r = _norm(read);
  if (a.isEmpty || r.isEmpty) return false;
  if (RegExp('(^| )${RegExp.escape(a)}( |\$)').hasMatch(r)) return true;
  if (a.split(' ').length < 5) return false;
  final mine = _content(answer);
  final theirs = _content(read).toSet();
  return mine.length >= 3 && mine.where(theirs.contains).length / mine.length >= 0.7;
}
