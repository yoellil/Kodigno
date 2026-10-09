import 'dart:math';

import 'nlp.dart' as nlp;
import 'prompt.dart' show isGrounded;
import 'summary.dart' show figuresInSource, namesInSource;

/// Checks a question and its answer against the notes they came from, with no
/// model: the passage that settles the question is found with BM25, and the
/// answer must be stated in that one passage, with the question's subject, its
/// years and figures and its names. Plain Dart, so it costs next to nothing and
/// works the same on every device.

/// One stretch of the notes: a line or sentence, or a short heading with the line under it.
class Passage {
  Passage(this.text) : stems = nlp.terms(text);
  final String text;
  final List<String> stems;
}

/// The passages of [notes], best searched with [NoteIndex.search].
class NoteIndex {
  NoteIndex(String notes) : passages = _build(notes) {
    var total = 0;
    for (final p in passages) {
      total += p.stems.length;
      for (final t in p.stems.toSet()) {
        _df[t] = (_df[t] ?? 0) + 1;
      }
    }
    _avgLen = passages.isEmpty ? 1 : max(1, total / passages.length);
  }

  final List<Passage> passages;
  final _df = <String, int>{};
  late final double _avgLen;

  static List<Passage> _build(String notes) {
    final items = nlp.textItems(notes);
    final out = <Passage>[];
    for (var i = 0; i < items.length; i++) {
      out.add(Passage(items[i]));
      // A line often leans on the one before it ("He wrote the novel...") and a slide
      // title says what the line under it is about: keep neighbours together.
      if (i > 0) out.add(Passage('${items[i - 1]} ${items[i]}'));
    }
    return out;
  }

  /// The [k] passages that best match [query]: BM25 over word stems, with extra
  /// weight for years, figures and names, which settle most facts.
  List<Passage> search(String query, {int k = 3}) {
    final q = nlp.terms(query).toSet();
    final figures = RegExp(r'\d[\d,.]*\d|\d').allMatches(query).map((m) => m[0]!).toSet();
    final names = RegExp(r'\b(?:[A-Z][a-z]{3,}|[A-Z]{2,})\b').allMatches(query).map((m) => m[0]!).toSet();
    final n = passages.length;
    final scored = <(Passage, double)>[];
    for (final p in passages) {
      var score = 0.0;
      for (final t in q) {
        final tf = p.stems.where((x) => x == t).length;
        if (tf == 0) continue;
        final df = _df[t] ?? 0;
        final idf = log(1 + (n - df + 0.5) / (df + 0.5));
        score += idf * (tf * 2.2) / (tf + 1.2 * (0.25 + 0.75 * p.stems.length / _avgLen));
      }
      for (final f in figures) {
        if (RegExp('(?<![\\d,.])${RegExp.escape(f)}(?![\\d])').hasMatch(p.text)) score += 1.5;
      }
      for (final nm in names) {
        if (p.text.contains(nm)) score += 0.4;
      }
      if (score > 0) scored.add((p, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored.take(k)) s.$1];
  }
}

enum Verdict { supported, contradicted, unverified }

final _yesNo = RegExp(r'^\s*(?:is|are|was|were|do|does|did|can|could|will|would|has|have|had|should)\b', caseSensitive: false);
final _asksNumber = RegExp(
    r'\b(?:how many|how much|how long|how old|how far|what year|which year|what date|what number|what percentage|what age|what century|when)\b',
    caseSensitive: false);
final _numberWord = RegExp(
    r'\d|\b(?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|hundred|thousand|million|january|february|march|april|may|june|july|august|september|october|november|december|century|decade)\b',
    caseSensitive: false);

/// Why [answer] cannot be the kind of answer [question] asks for, or null. A small
/// model writes "What instruments did the laboratory have?" with the answer "300".
String? answerTypeProblem(String question, String answer) {
  final a = answer.trim();
  // "He" answers nothing once the card is away from the notes.
  if (RegExp(r"^(?:he|she|they|it|him|her|them|his|hers|its|their)\.?$", caseSensitive: false).hasMatch(a)) {
    return 'a pronoun is not an answer';
  }
  if (_yesNo.hasMatch(question)) return 'a yes/no question teaches little and can be guessed';
  final numeric = RegExp(r'^[\d][\d,.\s]*$').hasMatch(a);
  final wantsNumber = _asksNumber.hasMatch(question) ||
      RegExp(r'\b(?:number|age|year|date|percent|total|amount|count|cost|price|many|much)\b', caseSensitive: false)
          .hasMatch(question);
  if (numeric && !wantsNumber) return 'the question does not ask for a number';
  if (_asksNumber.hasMatch(question) && !_numberWord.hasMatch(a)) return 'the question asks for a number or date';
  if (RegExp(r'^\s*(?:who|whom|whose)\b', caseSensitive: false).hasMatch(question) && RegExp(r'^\d').hasMatch(a)) {
    return 'the question asks who';
  }
  return null;
}

class FactCheck {
  const FactCheck(this.verdict, this.reason, {this.quote, this.passage, this.exact = false});
  final Verdict verdict;
  final String reason;

  /// The passage the answer was found in, for a second opinion.
  final String? passage;

  /// The answer is in the notes word for word, so no judge is needed.
  final bool exact;

  /// The sentence of the notes that states the answer.
  final String? quote;
  bool get ok => verdict == Verdict.supported;
}

/// "not", "never"...: a question and the sentence it comes from must agree on it.
/// A small model turns "BART did not know of this" into "Who was aware of this?".
final _polarity = RegExp(r"\b(?:not|never|cannot|neither|nor|without)\b|n['\u2019]t\b", caseSensitive: false);

final _negation = RegExp(
    r"\b(?:not|no|never|cannot|without|neither|nor|none)\b|n['’]t\b",
    caseSensitive: false);

String _plain(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[‘’]'), "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'^(?:the|an?)\s+|[.!?;,:\s]+$'), '')
    .trim();

/// How much of [answer] [passage] states: 1 if it is there word for word,
/// otherwise the share of the answer's words that are (0 if it has too few
/// words to judge by).
double _stated(String answer, String passage) {
  final a = _plain(answer);
  if (a.isEmpty) return 0;
  final p = _plain(passage);
  if (RegExp('(?<![a-z0-9])${RegExp.escape(a)}(?![a-z0-9])').hasMatch(p)) return 1;
  final w = nlp.terms(answer).toSet();
  if (w.length < 2) return 0;
  final have = nlp.terms(passage).toSet();
  // never 1: only a word-for-word match is exact
  return min(0.99, w.where(have.contains).length / w.length);
}

/// The sentence of [passage] that says most of [answer].
String _quoteFor(String answer, String passage) {
  final sentences = passage.split(RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9])'));
  final w = nlp.terms(answer).toSet();
  var best = sentences.first;
  var bestScore = -1.0;
  for (final s in sentences) {
    final t = nlp.terms(s).toSet();
    final score = w.isEmpty
        ? (_plain(s).contains(_plain(answer)) ? 1.0 : 0.0)
        : w.where(t.contains).length / w.length;
    if (score > bestScore) {
      best = s;
      bestScore = score;
    }
  }
  final q = best.trim();
  return q.length <= 240 ? q : '${q.substring(0, 237).trimRight()}…';
}

/// Is [answer] to [question] stated in the notes? It must be found, nearly word
/// for word, in one passage that also has the question's subject, years, figures
/// and names. That is what stops a small model joining a date from one slide
/// with a rule from another, or inventing a year or a name.
FactCheck checkQa(NoteIndex index, String question, String answer) {
  final wrongKind = answerTypeProblem(question, answer);
  if (wrongKind != null) return FactCheck(Verdict.unverified, wrongKind);
  final hits = index.search('$question $answer', k: 4);
  if (hits.isEmpty) return const FactCheck(Verdict.unverified, 'nothing in the notes matches');
  var reason = 'the answer is not stated in the notes';
  for (final h in hits) {
    final said = _stated(answer, h.text);
    if (said < 0.8) continue;
    if (!isGrounded(question, h.text, minRatio: 0.5)) {
      reason = 'the answer and the question come from different places';
      continue;
    }
    if (!figuresInSource('$question $answer', h.text) || !namesInSource(answer, h.text)) {
      reason = 'a year, figure or name is not in the same passage';
      continue;
    }
    final quote = _quoteFor(answer, h.text);
    // An answer that is not word for word may have flipped the meaning.
    if (said < 1 && !_negation.hasMatch(question) && _negation.hasMatch(quote) != _negation.hasMatch(answer)) {
      return FactCheck(Verdict.contradicted, 'the notes say the opposite', quote: quote, passage: h.text);
    }
    if (_polarity.hasMatch(question) != _polarity.hasMatch(quote)) {
      reason = 'the question and the notes disagree on "not"';
      continue;
    }
    return FactCheck(Verdict.supported, said == 1 ? 'stated word for word' : 'stated in other words',
        quote: quote, passage: h.text, exact: said == 1);
  }
  return FactCheck(Verdict.unverified, reason);
}

final _personPronoun = RegExp(r"\b(?:he|she|they|him|her|hers|his|their|theirs|them)\b", caseSensitive: false);

/// A question that points at someone it never names: "When did he become an
/// interno?". Away from the notes nobody knows who "he" is. "What did Rizal give
/// to his mother?" is fine, since a name comes before the pronoun.
bool hasLooseReference(String question) {
  final m = _personPronoun.firstMatch(question);
  if (m == null) return false;
  final before = question.substring(0, m.start).replaceFirst(RegExp(r'^\W*\w+'), ''); // not the first word
  return !RegExp(r'\b(?:[A-Z][a-z]{2,}|[A-Z]{2,})\b').hasMatch(before);
}

/// True if two questions ask for the same thing: the same answer and mostly the same words.
bool sameQuestion(String q1, String a1, String q2, String a2) {
  if (_plain(a1) != _plain(a2)) return false;
  final t1 = nlp.terms(q1).toSet();
  final t2 = nlp.terms(q2).toSet();
  if (t1.isEmpty || t2.isEmpty) return false;
  return t1.intersection(t2).length / min(t1.length, t2.length) >= 0.6;
}
