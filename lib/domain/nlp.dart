import 'dart:math';

/// Plain-Dart language helpers for condensing slides before a model sees them:
/// key phrases (RAKE), the most central sentences (TextRank over TF-IDF
/// vectors), topic similarity (cosine) and a copy check (shared word 4-grams).
/// No packages and no model are involved, so they cost almost nothing and work
/// the same on every device.

const _stop = {
  'a', 'about', 'above', 'after', 'again', 'against', 'all', 'also', 'am', 'an', 'and', 'any',
  'are', 'as', 'at', 'be', 'because', 'been', 'before', 'being', 'below', 'between', 'both',
  'but', 'by', 'can', 'could', 'did', 'do', 'does', 'doing', 'down', 'during', 'each', 'few',
  'for', 'from', 'further', 'had', 'has', 'have', 'having', 'he', 'her', 'here', 'hers', 'him',
  'his', 'how', 'however', 'i', 'if', 'in', 'into', 'is', 'it', 'its', 'itself', 'just', 'may',
  'me', 'might', 'more', 'most', 'must', 'my', 'no', 'nor', 'not', 'now', 'of', 'off', 'on',
  'once', 'only', 'or', 'other', 'our', 'ours', 'out', 'over', 'own', 'same', 'shall', 'she',
  'should', 'so', 'some', 'such', 'than', 'that', 'the', 'their', 'theirs', 'them', 'then',
  'there', 'these', 'they', 'this', 'those', 'through', 'thus', 'to', 'too', 'under', 'until',
  'up', 'upon', 'very', 'via', 'was', 'we', 'were', 'what', 'when', 'where', 'whether', 'which',
  'while', 'who', 'whom', 'whose', 'why', 'will', 'with', 'within', 'without', 'would', 'you',
  'your', 'yours', 'etc', 'eg', 'ie', 'per', 'among', 'often', 'usually', 'generally',
  'http', 'https', 'www', 'htm', 'html', 'edu', 'com', 'org', 'pdf',
  'understand', 'explain', 'used', 'using', 'making', 'people', 'include', 'includes', 'provide',
  'provides', 'provided',
  'like', 'many', 'several', 'various', 'different', 'certain', 'specific', 'make', 'makes',
  'made', 'take', 'takes', 'taken', 'try', 'tries', 'good', 'main', 'following', 'including',
  // common Filipino function words
  'ang', 'ng', 'sa', 'na', 'mga', 'ay', 'si', 'ni', 'kay', 'para', 'ito', 'iyon', 'isang',
  'ko', 'mo', 'niya', 'kanila', 'nito', 'dito', 'doon', 'pero', 'kung', 'din', 'rin',
};

final _word = RegExp(r"[A-Za-z][A-Za-z'’-]*");

/// A crude stem, only so "copyrights" and "copyright" count as one term.
String stem(String w) {
  var s = w.replaceAll(RegExp("['’]s\$"), '');
  if (s.length > 4 && s.endsWith('ies')) return '${s.substring(0, s.length - 3)}y';
  if (s.length > 5 && s.endsWith('ing')) {
    s = s.substring(0, s.length - 3);
  } else if (s.length > 4 && s.endsWith('ed')) {
    s = s.substring(0, s.length - 2);
  } else if (s.length > 3 && s.endsWith('s') && !s.endsWith('ss')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// The meaningful words of [s], stemmed: no stop words, no tiny words.
List<String> terms(String s) => [
      for (final m in _word.allMatches(s.toLowerCase()))
        if (m[0]!.length >= 3 && !_stop.contains(m[0]!)) stem(m[0]!),
    ];

/// How rare each term is across [docs] (higher = more particular to few docs).
Map<String, double> idfOf(List<String> docs) {
  final df = <String, int>{};
  for (final d in docs) {
    for (final t in terms(d).toSet()) {
      df[t] = (df[t] ?? 0) + 1;
    }
  }
  return {for (final e in df.entries) e.key: log((docs.length + 1) / (e.value + 1)) + 1};
}

Map<String, double> _tfidf(String s, Map<String, double> idf) {
  final tf = <String, double>{};
  for (final t in terms(s)) {
    tf[t] = (tf[t] ?? 0) + 1;
  }
  return {for (final e in tf.entries) e.key: e.value * (idf[e.key] ?? 1)};
}

double _cosine(Map<String, double> a, Map<String, double> b) {
  var dot = 0.0, na = 0.0, nb = 0.0;
  for (final e in a.entries) {
    na += e.value * e.value;
    final o = b[e.key];
    if (o != null) dot += e.value * o;
  }
  for (final v in b.values) {
    nb += v * v;
  }
  return na == 0 || nb == 0 ? 0 : dot / (sqrt(na) * sqrt(nb));
}

/// A text as weighted terms, to compare it with many others without reading
/// each again.
Map<String, double> vectorOf(String s, Map<String, double> idf) => _tfidf(s, idf);

/// How alike two [vectorOf] vectors are, 0 to 1.
double cosineOf(Map<String, double> a, Map<String, double> b) => _cosine(a, b);

/// How alike two texts are in their vocabulary, 0 (nothing shared) to 1.
double similarity(String a, String b, Map<String, double> idf) =>
    _cosine(_tfidf(a, idf), _tfidf(b, idf));

/// Runs of meaningful words between stop words and punctuation: the candidate phrases.
List<List<String>> _phrases(String text) {
  final out = <List<String>>[];
  for (final part in text.split(RegExp('[\n.;:!?()\\[\\],–—•❑✓]|\\s-\\s'))) {
    var cur = <String>[];
    for (final m in _word.allMatches(part)) {
      final w = m[0]!.toLowerCase();
      if (w.length < 3 || _stop.contains(w)) {
        if (cur.isNotEmpty) out.add(cur);
        cur = [];
      } else {
        cur.add(w);
      }
    }
    if (cur.isNotEmpty) out.add(cur);
  }
  return [for (final p in out) if (p.length <= 3) p];
}

/// Phrases that belong to the course, not to what it teaches.
final _admin = RegExp(r'learning outcome|source line|cengage|course technology|\bmodule\b|subtopic|\bcredit');

/// The [n] phrases that best say what [text] is about (RAKE: a word that keeps
/// company with other content words scores high, and so does a phrase that
/// repeats; one that appears once counts for much less). With [idf], words
/// particular to this text count for more, and phrases made of words in
/// [boost] (such as the slides' headings) count for more still.
List<String> keyTerms(String text, {int n = 5, Map<String, double>? idf, String boost = ''}) {
  final boosted = terms(boost).toSet();
  final phrases = _phrases(text);
  final freq = <String, int>{}, degree = <String, int>{};
  for (final p in phrases) {
    for (final w in p) {
      freq[w] = (freq[w] ?? 0) + 1;
      degree[w] = (degree[w] ?? 0) + p.length;
    }
  }
  final count = <String, int>{};
  for (final p in phrases) {
    count[p.join(' ')] = (count[p.join(' ')] ?? 0) + 1;
  }
  final scored = <(String, double)>[];
  for (final e in count.entries) {
    final words = e.key.split(' ');
    var score = 0.0;
    for (final w in words) {
      score += degree[w]! / freq[w]!;
    }
    score *= e.value == 1 ? 0.35 : 1 + log(e.value);
    if (boosted.isNotEmpty && words.every((w) => boosted.contains(stem(w)))) score *= 1.8;
    if (idf != null) {
      score *= words.map((w) => idf[stem(w)] ?? 1).reduce((a, b) => a + b) / words.length;
    }
    scored.add((e.key, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  final picked = <String>[];
  // Phrases that come back are the subject; ones seen once only fill what is left.
  for (final repeated in [true, false]) {
    for (final (p, _) in scored) {
      if ((count[p]! > 1) != repeated || _admin.hasMatch(p)) continue;
      // "copyright" next to "copyright infringement" says the same thing once.
      if (picked.any((q) => q.contains(p) || p.contains(q))) continue;
      picked.add(p);
      if (picked.length == n) return picked;
    }
  }
  return picked;
}

/// [text] cut into one item per bullet or sentence: wrapped lines are joined,
/// bullets and capital-letter headings start a new item, an empty line ends one.
List<String> textItems(String text) {
  final bullet = RegExp('^(?:[•●❑❒▪■◦‣·–—\u2713\u2714*>-]+|\\d+(?:\\.\\d+)+|\\d+[.)])\\s*');
  final items = <String>[];
  var cur = '';
  var prevCaps = false;
  void flush() {
    if (cur.trim().isNotEmpty) items.add(cur.trim());
    cur = '';
  }

  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) {
      flush();
      prevCaps = false;
      continue;
    }
    final starts = bullet.hasMatch(line);
    final body = line.replaceFirst(bullet, '');
    final caps = body == body.toUpperCase() && RegExp(r'[A-Z]{3}').hasMatch(body);
    if (cur.isEmpty || starts || caps || prevCaps || RegExp(r'[.!?:]$').hasMatch(cur)) {
      flush();
      cur = body;
    } else {
      cur = '$cur $body';
    }
    prevCaps = caps;
  }
  flush();
  // A long item with several sentences is several items.
  return [
    for (final it in items)
      if (it.length > 260)
        ...it.split(RegExp(r'(?<=[.!?])\s+(?=[A-Z])')).where((s) => s.isNotEmpty)
      else
        it,
  ];
}

/// The most central of [items] that fit in [maxChars], in their original order.
/// Centrality is TextRank: an item is important if other important items share
/// its vocabulary. Items that carry one of [keyTerms] get a small lift. If
/// everything fits, everything is returned.
List<String> condense(
  List<String> items, {
  required int maxChars,
  List<String> keyTerms = const [],
  Map<String, double>? idf,
}) {
  final total = items.fold<int>(0, (n, s) => n + s.length + 1);
  if (total <= maxChars) return items;
  final score = centrality(items, keyTerms: keyTerms, idf: idf);
  final n = items.length;
  final order = List.generate(n, (i) => i)..sort((a, b) => score[b].compareTo(score[a]));
  final picked = <int>[];
  var used = 0;
  for (final i in order) {
    if (used + items[i].length + 1 > maxChars) {
      // Leftover room is not worth filling with a line that ranks lower.
      if (picked.length >= 2) break;
      continue;
    }
    picked.add(i);
    used += items[i].length + 1;
  }
  if (picked.isEmpty) picked.add(order.first);
  picked.sort();
  return [for (final i in picked) items[i]];
}

/// How central each of [items] is, about 0 to 1.25 (TextRank over TF-IDF
/// vectors, plus a small lift for items that carry one of [keyTerms]).
List<double> centrality(List<String> items, {List<String> keyTerms = const [], Map<String, double>? idf}) {
  if (items.isEmpty) return const [];
  final idfMap = idf ?? const <String, double>{};
  final vectors = [for (final it in items) _tfidf(it, idfMap)];
  final n = items.length;

  final sim = List.generate(n, (_) => List.filled(n, 0.0));
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      sim[i][j] = sim[j][i] = _cosine(vectors[i], vectors[j]);
    }
  }
  final out = [for (var i = 0; i < n; i++) sim[i].fold<double>(0, (a, b) => a + b)];
  var rank = List.filled(n, 1.0 / n);
  for (var iter = 0; iter < 30; iter++) {
    final next = List.filled(n, 0.15 / n);
    for (var j = 0; j < n; j++) {
      if (out[j] == 0) continue;
      for (var i = 0; i < n; i++) {
        if (sim[j][i] > 0) next[i] += 0.85 * sim[j][i] / out[j] * rank[j];
      }
    }
    rank = next;
  }

  final best = rank.reduce(max);
  final lowered = [for (final it in items) it.toLowerCase()];
  return [
    for (var i = 0; i < n; i++)
      (best == 0 ? 0 : rank[i] / best) +
          0.25 * min(2, keyTerms.where((t) => lowered[i].contains(t)).length) / 2,
  ];
}

/// True if [given] (the model's own answer) says what [key] says: it has every
/// number of the key, and one holds the other or it has at least half of the
/// key's meaningful words. "His mother" is not "Leon Monroy".
bool sameAnswer(String given, String key) {
  String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  final g = norm(given), k = norm(key);
  if (g.isEmpty || k.isEmpty) return false;
  if (!RegExp(r'\d+').allMatches(k).every((n) => RegExp('\\b${n[0]}\\b').hasMatch(g))) return false;
  final mine = terms(given).toSet(), keys = terms(key).toSet();
  if (g == k || ((' $g '.contains(' $k ') || ' $k '.contains(' $g ')) && mine.isNotEmpty)) return true;
  return keys.isNotEmpty && mine.intersection(keys).length * 2 >= keys.length;
}

/// The [k] of [items] most alike [query] in vocabulary (TF-IDF cosine), best
/// first. Only items that share something with it. The passages a fact check reads.
List<String> retrieve(String query, List<String> items, Map<String, double> idf, {int k = 4}) {
  final q = _tfidf(query, idf);
  final scored = [for (final it in items) (it, _cosine(q, _tfidf(it, idf)))]
    ..sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final (it, s) in scored.take(k)) if (s > 0) it];
}

final _negation = RegExp(
    r"\b(?:not|no|never|cannot|without|neither|nor|unable|none)\b|n['\u2019]t\b",
    caseSensitive: false);

/// True if [claim] says the opposite of the line of [sourceItems] it is closest
/// to: one has a "not" (or "no", "never"...) and the other does not. A small
/// model often turns "IT workers are not recognized as professionals" into
/// "IT workers are recognized as professionals", which no word-overlap check sees.
bool contradicts(String claim, List<String> sourceItems) {
  final c = terms(claim).toSet();
  if (c.length < 3) return false;
  String? best;
  var bestScore = 0.0;
  for (final it in sourceItems) {
    final t = terms(it).toSet();
    final score = c.where(t.contains).length / c.length;
    if (score > bestScore) {
      bestScore = score;
      best = it;
    }
  }
  if (best == null || bestScore < 0.45) return false;
  if (c.intersection(terms(best).toSet()).length < 3) return false;
  return _negation.hasMatch(claim) != _negation.hasMatch(best);
}

/// Only the plain negators: "without" ("...without asking the owner") and
/// "unable" do not flip a statement the way these do.
final _plainNegation = RegExp(r"\b(?:not|no|never|cannot|neither|nor)\b|n['’]t\b", caseSensitive: false);

/// True if exactly one of [a] and [b] has a plain "not", "no" or "never". Two
/// statements about the same thing that differ in this are likely opposites.
bool plainNegationDiffers(String a, String b) => _plainNegation.hasMatch(a) != _plainNegation.hasMatch(b);

/// The line of [sourceItems] that [claim] seems to say the opposite of, or null.
/// Stricter than [contradicts], for telling a student something about their own
/// words: the claim must share at least 5 of its meaningful words with the line
/// and be mostly made of that line's words, and only a plain "not", "no" or
/// "never" on one side and not the other counts.
String? oppositeLine(String claim, List<String> sourceItems) {
  final c = terms(claim).toSet();
  if (c.length < 5) return null;
  String? best;
  var bestScore = 0.0;
  var bestShared = 0;
  for (final it in sourceItems) {
    final t = terms(it).toSet();
    final shared = c.where(t.contains).length;
    final score = shared / c.length;
    if (score > bestScore) {
      bestScore = score;
      bestShared = shared;
      best = it;
    }
  }
  if (best == null || bestScore < 0.5 || bestShared < 5) return null;
  return _plainNegation.hasMatch(claim) != _plainNegation.hasMatch(best) ? best : null;
}

List<String> _wordsOf(String s) =>
    [for (final m in _word.allMatches(s.toLowerCase())) m[0]!];

Set<String> _fourGrams(List<String> w) =>
    {for (var i = 0; i + 4 <= w.length; i++) w.sublist(i, i + 4).join(' ')};

/// How much of [text] is lifted from [source]: the share of its four-word runs
/// that also appear in [source]. 0 = all its own words, 1 = copied.
double copyRatio(String text, String source) {
  final grams = _fourGrams(_wordsOf(text));
  if (grams.isEmpty) return 0;
  final src = _fourGrams(_wordsOf(source));
  return grams.where(src.contains).length / grams.length;
}
