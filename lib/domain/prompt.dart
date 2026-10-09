import 'dart:math';

import 'models.dart';

/// Splits [text] into chunks of at most [maxChars], preferring paragraph and
/// sentence boundaries. Never drops words.
List<String> chunkText(String text, int maxChars) {
  final pieces = <String>[];
  for (final p in text.split('\n')) {
    var s = p.trim();
    while (s.length > maxChars) {
      var cut = s.lastIndexOf(RegExp(r'[.!?]\s'), maxChars - 2) + 1;
      if (cut <= 0) cut = s.lastIndexOf(' ', maxChars);
      if (cut <= 0) cut = maxChars;
      pieces.add(s.substring(0, cut).trim());
      s = s.substring(cut).trim();
    }
    if (s.isNotEmpty) pieces.add(s);
  }

  final chunks = <String>[];
  var cur = '';
  for (final piece in pieces) {
    if (cur.isEmpty) {
      cur = piece;
    } else if (cur.length + 1 + piece.length <= maxChars) {
      cur = '$cur\n$piece';
    } else {
      chunks.add(cur);
      cur = piece;
    }
  }
  if (cur.isNotEmpty) chunks.add(cur);
  return chunks;
}

/// Drops lines that repeat 3+ times (slide footers, page numbers) so the model
/// is not fed boilerplate. Numbers are ignored when comparing, so footers that
/// end in a page number ("... Confidential 12", "... 13") count as repeats.
/// Keeps the first line order of everything else.
String dropRepeatedLines(String text) {
  String key(String l) => l.trim().toLowerCase().replaceAll(RegExp(r'\d+'), '#');
  final lines = text.split('\n');
  final count = <String, int>{};
  for (final l in lines) {
    final k = key(l);
    if (k.isNotEmpty) count[k] = (count[k] ?? 0) + 1;
  }
  return lines.where((l) => (count[key(l)] ?? 0) < 3).join('\n');
}

const _stop = {
  'which', 'following', 'common', 'found', 'about', 'their', 'there', 'these',
  'those', 'where', 'would', 'could', 'should', 'being', 'other', 'right',
  'wrong', 'false', 'correct', 'answer', 'question', 'statement',
};

Set<String> _words(String s) => {
      for (final m in RegExp(r'[a-z]{5,}|\d{3,}').allMatches(s.toLowerCase()))
        if (!_stop.contains(m[0]!)) m[0]!,
    };

/// True if enough of [text]'s longer words appear in [source]. Catches items a
/// small model made up instead of taking from the notes. With no longer words
/// there is nothing to judge, so it passes.
bool isGrounded(String text, String source, {double minRatio = 0.4}) {
  final words = _words(text);
  if (words.isEmpty) return true;
  final src = source.toLowerCase();
  final hits = words.where(src.contains).length;
  return hits / words.length >= minRatio;
}

/// The chunks of [notes] that best match [query] (by shared words), joined in
/// their original order, up to [maxChars]. Used to give the chat tutor context.
String pickContext(String notes, String query, {required int maxChars, int chunkChars = 600}) {
  if (notes.length <= maxChars) return notes;
  final chunks = chunkText(notes, chunkChars);
  final q = _words(query);
  final scored = [
    for (var i = 0; i < chunks.length; i++)
      (i, _words(chunks[i]).where(q.contains).length),
  ]..sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1));
  final picked = <int>[];
  var used = 0;
  for (final (i, _) in scored) {
    if (used + chunks[i].length > maxChars) continue;
    picked.add(i);
    used += chunks[i].length + 1;
  }
  picked.sort();
  return picked.map((i) => chunks[i]).join('\n');
}


/// Topic labels ("The importance of X") instead of a question or a fact.
bool isVague(String s) => RegExp(
        r'^\s*(the\s+)?(importance|significance|role|reasons?|concept|overview|impact|meaning|purpose)\s+(of|behind|why)\b',
        caseSensitive: false)
    .hasMatch(s);

/// True if [answer] is stated in [source]: found verbatim, or most of its
/// longer words are. Catches answers a small model made up.
bool answerInNotes(String answer, String source) {
  final a = answer.toLowerCase().trim();
  if (a.isEmpty) return false;
  if (source.toLowerCase().contains(a)) return true;
  final w = _words(a);
  return w.isNotEmpty && isGrounded(a, source, minRatio: 0.6);
}

/// Pass 1: pull the key facts out of a section of notes.
String buildFactsPrompt(String notes, {required int facts}) => '''
You are a study assistant. Read the notes below and list up to $facts key facts a student should remember.
Rules:
- Each fact is one complete sentence that states a specific name, date, number, definition or reason from the notes.
- Use only the notes. Never invent facts.
- Skip headings, page footers, course admin and vague statements.
Reply with JSON only: an object with one key "facts", a list of the fact sentences.

NOTES:
$notes
''';

Map<String, Object?> factsSchema(int facts) => {
      'type': 'object',
      'properties': {
        'facts': {
          'type': 'array',
          'minItems': 1,
          'maxItems': facts,
          'items': {'type': 'string', 'minLength': 25, 'maxLength': 250},
        },
      },
      'required': ['facts'],
    };

/// Pass 2: one study question and short answer per fact.
String buildQaPrompt(List<String> facts) => '''
For each numbered fact below, write one study question that the fact answers, and its short answer (1 to 8 words: a name, date, number or term taken from the fact).
Rules:
- The question must make sense on its own, without seeing the fact, and ask for one specific thing.
- The question must not contain the answer, or any number or key word from the answer.
- Never write vague labels such as "The importance of X".
Example: fact "Water boils at 100 degrees Celsius at sea level." gives question "At what temperature does water boil at sea level?" and answer "100 degrees Celsius".
Reply with JSON only: an object with one key "items", a list with one object per fact, each with a "question" and an "answer".

FACTS:
${[for (var i = 0; i < facts.length; i++) '${i + 1}. ${facts[i]}'].join('\n')}
''';

Map<String, Object?> qaSchema(int items) => {
      'type': 'object',
      'properties': {
        'items': {
          'type': 'array',
          'minItems': items, // one per fact; the model tends to stop early
          'maxItems': items,
          'items': {
            'type': 'object',
            'properties': {
              'question': {'type': 'string', 'minLength': 10, 'maxLength': 200},
              'answer': {'type': 'string', 'minLength': 1, 'maxLength': 200},
            },
            'required': ['question', 'answer'],
          },
        },
      },
      'required': ['items'],
    };

/// A standalone number ("1789", "17,000"), not digits inside "H2O".
final _number = RegExp(r'\b(?:\d{1,3}(?:,\d{3})+|\d+)\b');

/// [question] with any number from [answer] (and the little word before it,
/// as in "in 1792") taken out, or null if it still gives the answer away.
String? unleak(String question, String answer) {
  final numbers = [for (final m in _number.allMatches(answer)) m[0]!];
  var q = question;
  for (final n in numbers) {
    q = q.replaceAll(
        RegExp(r'\b(?:(?:in|on|at|of|during|by|from|since|around)\s+)?' '${RegExp.escape(n)}' r'\b,?',
            caseSensitive: false),
        '');
  }
  q = q
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAllMapped(RegExp(r'\s+([?.,!])'), (m) => m[1]!)
      .trim();
  if (q.split(' ').length < 3) return null; // nothing left to ask
  q = q[0].toUpperCase() + q.substring(1);
  // In a short answer like "100 degrees Celsius" the words are units, not the answer.
  if (numbers.isNotEmpty && _wordCount(answer) <= 3) return q;

  final a = answer.toLowerCase().replaceAll(RegExp(r'^(?:the|an?)\s+|[.!?\s]+$'), '');
  if (a.isNotEmpty && RegExp(r'\b' '${RegExp.escape(a)}' r'\b').hasMatch(q.toLowerCase())) return null;
  final w = _words(a);
  if (w.isNotEmpty && w.where(_words(q).contains).length * 2 >= w.length) return null;
  return q;
}

/// Pass 3: believable wrong answers for each question, for quiz choices.
String buildWrongPrompt(List<QaItem> items) => '''
For each numbered question below, write 3 wrong answers for a multiple-choice quiz.
Rules:
- Each wrong answer is the same kind of thing as the correct answer: a person for a person, a place for a place, a year for a year, a term for a term.
- Take them from the same subject as the question, so a student who did not study could pick one.
- Make them about as long as the correct answer.
- Never repeat the correct answer or say it another way.
Example: question "Which planet is closest to the Sun?" with correct answer "Mercury" gives wrong answers "Venus", "Mars", "Jupiter".
Reply with JSON only: an object with one key "items", a list with one object per question, each with a "wrong" list of 3 answers.

QUESTIONS:
${[for (var i = 0; i < items.length; i++) '${i + 1}. ${items[i].question} Correct answer: ${items[i].answer}'].join('\n')}
''';

Map<String, Object?> wrongSchema(int items) => {
      'type': 'object',
      'properties': {
        'items': {
          'type': 'array',
          'minItems': items,
          'maxItems': items,
          'items': {
            'type': 'object',
            'properties': {
              'wrong': {
                'type': 'array',
                'minItems': 3,
                'maxItems': 3,
                'items': {'type': 'string', 'minLength': 1, 'maxLength': 150},
              },
            },
            'required': ['wrong'],
          },
        },
      },
      'required': ['items'],
    };

/// The fact in [facts] that shares the most longer words with [text]
/// (the first one on a tie), or '' if there are none.
String bestFact(List<String> facts, String text) {
  final t = _words(text);
  var best = '';
  var bestScore = -1;
  for (final f in facts) {
    final score = _words(f).where(t.contains).length;
    if (score > bestScore) {
      best = f;
      bestScore = score;
    }
  }
  return best;
}

final _numeric = RegExp(r'\d');

int _wordCount(String s) => s.split(RegExp(r'\s+')).length;

/// [count] copies of [answer] with its last number moved a little: years by
/// a few years, bigger numbers by a few steps of their second digit.
/// Empty if [answer] has no number.
List<String> nearbyNumbers(String answer, int count, Random random) {
  final m = _number.allMatches(answer).lastOrNull;
  final digits = m?[0]!.replaceAll(',', '') ?? '';
  final v = int.tryParse(digits);
  if (m == null || v == null) return const [];
  final commas = m[0]!.contains(',');
  final year = !commas && v >= 1000 && v <= 2100;
  final step = year || digits.length < 3 ? 1 : pow(10, digits.length - 2).toInt();
  final offsets = [for (var d = 1; d <= 6; d++) ...[d, -d]]..shuffle(random);
  final values = [for (final o in offsets) v + o * step].where((n) => n > 0).take(count);
  return [
    for (final n in values)
      answer.replaceRange(m.start, m.end,
          commas ? '$n'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',') : '$n'),
  ];
}

/// Three wrong choices for [correct], never of a different kind (number vs
/// words): the model's own [preferred] ones first, then nearby numbers, then
/// other answers in [pool] of similar length. Choices named in [question]
/// are skipped, since they give themselves away. May return fewer than 3.
List<String> pickDistractors(String correct, List<String> pool, Random random,
    {List<String> preferred = const [], String question = ''}) {
  final c = correct.trim().toLowerCase();
  final q = question.toLowerCase();
  final numeric = _numeric.hasMatch(c);
  final seen = <String>{c};
  final candidates = <(String, double)>[];
  void add(String a, double rank) {
    final l = a.trim().toLowerCase();
    if (l.isEmpty ||
        l.contains(c) ||
        c.contains(l) ||
        q.contains(l) ||
        _numeric.hasMatch(l) != numeric ||
        _wordCount(l) > min(14, 2 * _wordCount(c) + 1) || // a long choice stands out
        !seen.add(l)) {
      return;
    }
    candidates.add((a.trim(), rank + (_wordCount(l) - _wordCount(c)).abs() + random.nextDouble()));
  }

  for (final a in preferred) {
    add(a, 0);
  }
  for (final a in nearbyNumbers(correct, 3, random)) {
    add(a, 100);
  }
  for (final a in pool) {
    add(a, 200);
  }
  candidates.sort((x, y) => x.$2.compareTo(y.$2));
  return [for (final x in candidates.take(3)) x.$1];
}
