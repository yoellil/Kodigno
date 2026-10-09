import 'dart:math';

import 'hygiene.dart';
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
  final hits = words.where((w) => _inText(w, src)).length;
  return hits / words.length >= minRatio;
}

/// [word] is in [src] (lower case), also as its singular ("professionals" ~ "professional").
bool _inText(String word, String src) =>
    src.contains(word) || (word.endsWith('s') && src.contains(word.substring(0, word.length - 1)));

/// True if [answer] says something stated in [fact] and not just repeated from
/// [question]: it is found word for word in the fact, or the words it adds beyond
/// the question are (at least 70%) found there. Catches answers a small model
/// made up or padded ("The first principle states that ...").
bool answerInFact(String answer, String fact, String question) {
  final a = answer.toLowerCase().trim().replaceAll(RegExp(r'[.!?;,]+$'), '');
  if (a.isEmpty) return false;
  final q = question.toLowerCase();
  final f = fact.toLowerCase();
  if (RegExp(r'\b' '${RegExp.escape(a)}' r'\b').hasMatch(q)) return false; // just repeats the question
  if (f.contains(a)) return true;
  final asked = _words(question);
  final added = _words(answer).where((w) => !asked.contains(w)).toList();
  if (added.isEmpty) return false;
  return added.where((w) => _inText(w, f)).length / added.length >= 0.7;
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
bool isVague(String s) =>
    RegExp(r'^\s*(the\s+)?(importance|significance|role|reasons?|concept|overview|impact|meaning|purpose)\s+(of|behind|why)\b',
            caseSensitive: false)
        .hasMatch(s) ||
    // A question that points at something the student cannot see.
    RegExp(r'\b(?:this|these|the)\s+(?:text|passage|document|slide|lecture|section|chapter|reading|notes)\b|\b(?:the following|the above|mentioned above|as described|in the notes)\b',
            caseSensitive: false)
        .hasMatch(s);

/// True if [answer] is stated in [source]: found verbatim, or most of its
/// longer words are. Catches answers a small model made up.
bool answerInNotes(String answer, String source) {
  final a = answer.toLowerCase().trim().replaceAll(RegExp(r'[.!?;,]+$'), '');
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
- Skip references, citations, bibliography entries, links and author lists.
- Keep the exact names, terms and numbers of the notes. Never combine two separate things (a date or event, and a rule) into one fact.
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
          'items': {'type': 'string', 'minLength': 25, 'maxLength': 400},
        },
      },
      'required': ['facts'],
    };

/// Pass 2: one study question and short answer per fact.
String buildQaPrompt(List<String> facts) => '''
For each numbered fact below, write one study question that the fact answers, and its short answer (1 to 8 words: a name, date, number or term taken from the fact). If the question asks for several things ("the three principles"), the answer lists every one, numbered like "1. ... 2. ... 3. ...", each in a few words.
Rules:
- The question must make sense on its own, without seeing the fact, and ask for one specific thing. It names its subject in full, with the exact names used in the fact, so no one has to guess what it is about.
- Use only that one fact. Never mix in anything from another fact, and never join a date or event with a rule.
- Take the answer word for word from the fact, with its exact terms. Add nothing the fact does not say, and do not repeat the question inside the answer.
- The question must not contain the answer, or any number or key word from the answer.
- Never write vague labels such as "The importance of X".
- The answer is only the answer itself: never the word "answer", and never a sentence such as "The answer is ...".
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
              'answer': {'type': 'string', 'minLength': 1, 'maxLength': 300},
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
- The three must be different from each other.
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
/// are skipped, since they give themselves away. So are rewordings of the
/// correct answer, statements the [fact] itself makes (also true, so not
/// wrong), and choices that say the same as one already picked. For a phrase
/// answer the [pool] comes before [preferred].
/// May return fewer than 3.
List<String> pickDistractors(String correct, List<String> pool, Random random,
    {List<String> preferred = const [], String question = '', String fact = ''}) {
  final c = normalizeChoice(correct).toLowerCase();
  final q = question.toLowerCase();
  final numeric = _numeric.hasMatch(c);
  final seen = <String>{c};
  final mine = _stems(c);
  final factStems = _stems(fact);
  final candidates = <(String, double)>[];
  void add(String a, double rank) {
    a = normalizeChoice(a);
    final l = a.toLowerCase();
    if (l.isEmpty ||
        isPlaceholderAnswer(l) ||
        RegExp(r'^(?:an? |the )?(?:random|unknown|different|other|another|some|any|unrelated|various)\b').hasMatch(l) ||
        looksLikeCitation(l) ||
        (_wordCount(c) >= 4 && _wordCount(l) * 2 < _wordCount(c)) || // a short choice next to a long answer stands out

        l.contains(c) ||
        c.contains(l) ||
        q.contains(l) ||
        _numeric.hasMatch(l) != numeric ||
        _wordCount(l) > min(14, 2 * _wordCount(c) + 1) || // a long choice stands out
        !seen.add(l)) {
      return;
    }
    final all = _stems(l);
    if (all.isNotEmpty) {
      final own = all.difference(mine);
      if (own.isEmpty) return; // the correct answer in other words
      if (factStems.isNotEmpty && own.every(factStems.contains)) return; // the fact says this too
    }
    // A choice built like the answer ("To ...", "The ...") does not stand out.
    final shape = _shape(l) == _shape(c) ? 0 : 3;
    candidates.add((a, rank + shape + (_wordCount(l) - _wordCount(c)).abs() + random.nextDouble()));
  }

  // For a name, date or term the model's wrong answers are good. For a phrase a
  // small model only rewords the right answer, so other true statements from the
  // notes (the pool) come first: on topic, clearly different, and wrong here.
  final phrase = _wordCount(c) >= 3 && !numeric;
  for (final a in preferred) {
    add(a, phrase ? 200 : 0);
  }
  for (final a in nearbyNumbers(correct, 3, random)) {
    add(a, 100);
  }
  for (final a in pool) {
    add(a, phrase ? 0 : 200);
  }
  candidates.sort((x, y) => x.$2.compareTo(y.$2));
  // Three choices that say one thing are one choice: keep those that differ.
  final picked = <String>[];
  final pickedOwn = <Set<String>>[];
  for (final (a, _) in candidates) {
    if (picked.length == 3) break;
    final own = _stems(a).difference(mine);
    final repeats = own.isNotEmpty &&
        pickedOwn.any((p) => p.isNotEmpty && own.intersection(p).length * 2 >= min(own.length, p.length));
    if (repeats) continue;
    picked.add(a);
    pickedOwn.add(own);
  }
  return picked;
}

String _shape(String lower) {
  final first = lower.split(' ').first;
  if (first == 'to') return 'to';
  if (const {'the', 'a', 'an'}.contains(first)) return 'noun';
  if (first.endsWith('ing')) return 'ing';
  return 'other';
}

/// Longer words of [s] with a plural "s" taken off, for comparing meaning.
Set<String> _stems(String s) => {
      for (final w in _words(s)) w.endsWith('s') && w.length > 5 ? w.substring(0, w.length - 1) : w,
    };
