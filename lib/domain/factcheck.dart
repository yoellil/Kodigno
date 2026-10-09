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
    return FactCheck(Verdict.supported, said == 1 ? 'stated word for word' : 'stated in other words',
        quote: quote, passage: h.text, exact: said == 1);
  }
  return FactCheck(Verdict.unverified, reason);
}
