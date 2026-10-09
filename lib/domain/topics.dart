import 'dart:math' show max;

import 'nlp.dart';
import 'source_ref.dart' show PageText;

/// The pages of one topic, ready to be explained in one go.
class SlideGroup {
  const SlideGroup(this.text, {this.title, this.titles = const []});

  /// The topic's heading as the slides write it, or null if there is no single
  /// one: several topics were joined, or the slides have no headings.
  final String? title;

  /// Every page heading in the topic, in order.
  final List<String> titles;

  /// All of the topic's pages, an empty line between pages.
  final String text;
}

const _small = {
  'a', 'an', 'the', 'of', 'and', 'or', 'in', 'on', 'for', 'to', 'with', 'by', 'at', 'from', 'vs',
  'is', 'are', 'between', 'about', 'as',
};

final _bulletOrNumber = RegExp('^(?:[•●❑❒▪■◦‣·–—*>✓-]|\\d+[.)])');

/// True if [line] reads as a slide heading: short, no closing full stop, not a
/// bullet, and made of capitalised words ("Copyright Term", "ECONOMIC
/// DEVELOPMENT", "Are IT Workers Professionals?"). With [continued], the line
/// may start in lower case, as the second line of a wrapped heading does.
bool isHeadingLine(String line, {bool continued = false}) {
  final t = line.trim();
  if (t.isEmpty || t.length > 90) return false;
  if (RegExp(r'[.;,:]$').hasMatch(t) || _bulletOrNumber.hasMatch(t)) return false;
  if (!continued && !RegExp(r'^[A-Z(]').hasMatch(t)) return false;
  final words = t.split(RegExp(r'\s+'));
  if (words.length > 12 || t.replaceAll(RegExp(r'[^A-Za-z]'), '').length < 3) return false;
  final big = words.where((w) => !_small.contains(w.toLowerCase())).toList();
  if (big.isEmpty) return false;
  final caps = big.where((w) => RegExp(r'^[A-Z(\d]').hasMatch(w)).length;
  return caps / big.length >= 0.7;
}

final _ordinal = RegExp(r'\b\d+(?:st|nd|rd|th)\b');

/// A heading with its words run together by the PDF ("TheDigitalMillennium
/// CopyrightAct(1998)", "Tariffsand Trade") put right, using words that
/// [vocab] (the lowercase words of the notes) knows; and "ECONOMIC
/// DEVELOPMENT" as "Economic Development".
String tidyHeading(String h, {Set<String> vocab = const {}}) {
  final s = h.replaceAll(RegExp(r'\s+'), ' ').trim();
  // "...OF THE 19th CENTURY" is still all capitals.
  final letters = s.replaceAll(_ordinal, '');
  if (letters == letters.toUpperCase()) return titleCase(s);
  // Words joined by a capital letter first, then small words glued on to a known
  // word, then capital runs ("WTOTRIPSAgreement") and brackets.
  final apart = s.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  return [
    for (final w in apart.split(' '))
      for (final piece in _unglue(w, vocab))
        piece
            .replaceAllMapped(RegExp(r'([A-Z]{2,})([A-Z][a-z])'), (m) => '${m[1]} ${m[2]}')
            .replaceAllMapped(RegExp(r'([A-Za-z])\('), (m) => '${m[1]} ('),
  ].join(' ');
}

const _joiners = ['and', 'the', 'for', 'of', 'on', 'to', 'in'];

/// "Tariffsand" as "Tariffs and", "Protectionandthe" as "Protection and the":
/// a word that is not known but is a known word followed only by small joining
/// words. The longest known word wins, so "Protection" does not lose its "on".
List<String> _unglue(String w, Set<String> vocab) {
  if (w.length < 6 || vocab.contains(w.toLowerCase())) return [w];
  for (var i = w.length - 2; i >= 3; i--) {
    var rest = w.substring(i).toLowerCase();
    if (!vocab.contains(w.substring(0, i).toLowerCase())) continue;
    final joined = <String>[];
    while (rest.isNotEmpty) {
      final j = _joiners.where(rest.startsWith).firstOrNull;
      if (j == null) break;
      joined.add(j);
      rest = rest.substring(j.length);
    }
    if (rest.isEmpty && joined.isNotEmpty) return [w.substring(0, i), ...joined];
  }
  return [w];
}

/// "THE CAVITE MUTINY (1872)" as "The Cavite Mutiny (1872)".
String titleCase(String title) {
  String cap(String w) {
    if (RegExp(r'^\d+(?:st|nd|rd|th)$', caseSensitive: false).hasMatch(w)) return w.toLowerCase();
    final i = w.indexOf(RegExp(r'[A-Za-z]'));
    return i < 0 ? w : w.substring(0, i) + w[i].toUpperCase() + w.substring(i + 1).toLowerCase();
  }

  final words = title.trim().split(RegExp(r'\s+'));
  return [
    for (var i = 0; i < words.length; i++)
      i > 0 && _small.contains(words[i].toLowerCase()) ? words[i].toLowerCase() : cap(words[i]),
  ].join(' ');
}

/// Two headings are the same topic if their letters match.
String _key(String heading) => heading.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Headings that only say where in the course a page is.
final _navigation = RegExp(
    r'^(?:(?:sub)?topic|module|chapter|unit|lesson|week|part)\s*\d+\b|\bmodule\s*\d+\b',
    caseSensitive: false);

/// Headings of pages that state what the lesson is for, not teach it.
final _aims = RegExp(
    r'^(?:intended\s+)?(?:learning\s+)?(?:outcomes?|objectives?)$|^(?:outline|agenda)$',
    caseSensitive: false);

/// Headings of the pages at the end that only list sources.
final _sources = RegExp(r'^(?:references?|bibliography|sources?|credits?)$', caseSensitive: false);

/// True for a heading about the course and not the subject: "Intended Learning
/// Outcomes", "Module 3", "References".
bool isCourseHeading(String heading) {
  final h = heading.trim();
  return _navigation.hasMatch(h) || _aims.hasMatch(h) || _sources.hasMatch(h);
}

/// What two headings are compared by: their letters and digits, lower case.
String headingKey(String heading) => _key(heading);

/// The headings of the pages of [notes] (pages are an empty line apart), tidied,
/// as [headingKey]s. Notes with no headings give none.
Set<String> pageHeadingKeys(String notes) {
  final raw = <_Page>[];
  for (final r in notes.replaceAll('\r', '').split(RegExp(r'\n[ \t]*\n'))) {
    final lines = [
      for (final l in r.split('\n'))
        if (l.trim().isNotEmpty) _Line(l.trim(), l.endsWith(' ')),
    ];
    if (lines.isNotEmpty) raw.add(_splitPage(lines));
  }
  final vocab = {
    for (final p in raw)
      for (final l in [...p.lines.map((l) => l.text), ?p.heading])
        for (final m in RegExp(r'[A-Za-z]{3,}').allMatches(l)) m[0]!.toLowerCase(),
  };
  return {
    for (final p in raw)
      if (p.heading != null) _key(tidyHeading(p.heading!, vocab: vocab)),
  };
}

/// The heading each page falls under, by page number, as [headingKey]s: the
/// page's own heading, or the one before it if it has none (a slide that carries
/// on the last one). Pages before the first heading are left out.
Map<int, String> headingKeyByPage(List<PageText> pages) {
  final raw = <(int, _Page)>[];
  for (final p in pages) {
    final lines = [
      for (final l in p.text.split('\n'))
        if (l.trim().isNotEmpty) _Line(l.trim(), l.endsWith(' ')),
    ];
    if (lines.isNotEmpty) raw.add((p.number, _splitPage(lines)));
  }
  final vocab = {
    for (final (_, p) in raw)
      for (final l in [...p.lines.map((l) => l.text), ?p.heading])
        for (final m in RegExp(r'[A-Za-z]{3,}').allMatches(l)) m[0]!.toLowerCase(),
  };
  final out = <int, String>{};
  String? current;
  for (final (number, p) in raw) {
    if (p.heading != null) {
      final h = tidyHeading(p.heading!, vocab: vocab);
      // A page about the course ("Intended Learning Outcomes") starts no topic.
      current = isCourseHeading(h) ? null : _key(h);
    }
    if (current != null) out[number] = current;
  }
  return out;
}

class _Line {
  _Line(this.text, this.wrapped);
  final String text;

  /// The PDF reader leaves a space at the end of a line that wraps onto the next.
  final bool wrapped;
}

class _Page {
  _Page(this.heading, this.lines);
  String? heading;
  List<_Line> lines;
}

/// A page's heading and the rest of its lines. The heading is the first lines of
/// the page, or if there are none, the last lines: the PDF reader sometimes
/// puts a slide's title after its bullets. A heading takes a second line only
/// if the first one wraps onto it.
_Page _splitPage(List<_Line> lines) {
  var lead = 0;
  while (lead < lines.length && lead < 3) {
    final ok = lead == 0
        ? isHeadingLine(lines[0].text)
        : lines[lead - 1].wrapped && isHeadingLine(lines[lead].text, continued: true);
    if (!ok) break;
    lead++;
  }
  if (lead > 0 && lead < lines.length) {
    return _Page(lines.take(lead).map((l) => l.text).join(' '), lines.skip(lead).toList());
  }
  if (lead == lines.length && lines.isNotEmpty) {
    return _Page(lines.map((l) => l.text).join(' '), []); // a divider or cover page
  }
  // No heading at the top: the last line may be one (with the wrapped lines before it).
  var start = lines.length - 1;
  if (start > 0 && isHeadingLine(lines[start].text, continued: lines[start - 1].wrapped)) {
    while (start > 0 &&
        lines[start - 1].wrapped &&
        isHeadingLine(lines[start - 1].text) &&
        lines.length - start < 3) {
      start--;
    }
    if (start > 0) {
      return _Page(lines.skip(start).map((l) => l.text).join(' '), lines.take(start).toList());
    }
  }
  return _Page(null, lines);
}

class _Topic {
  _Topic(String? heading, this.key, String body)
      : headings = [?heading],
        pages = [body];
  final String? key;
  final List<String> headings;
  final List<String> pages;

  String get text => pages.join('\n\n');
  int get size => text.replaceAll(RegExp(r'\s'), '').length;

  /// Joins another topic: its headings count as headings of this one.
  void join(_Topic o) {
    for (final h in o.headings) {
      if (!headings.map(_key).contains(_key(h))) headings.add(h);
    }
    pages.addAll(o.pages);
  }

  /// Takes in a label or cover that has nothing to teach: its text stays, but
  /// it is not a heading of this topic.
  void absorb(_Topic o) {
    pages.add([...o.headings, o.text].where((s) => s.isNotEmpty).join('\n'));
  }
}

const _tinyChars = 60;

/// "Credit: Course Technology/Cengage Learning." and "Source Line: ...": where a
/// picture came from, not what the slide teaches.
final _credit = RegExp(r'^(?:credit|source(?:\s+line)?)\s*:', caseSensitive: false);

/// True if [line] is a title or label rather than a statement: no closing
/// punctuation and mostly capitalised words, however long ("Distinguishing the
/// Difference Between Bribes and Gifts Relationships Between IT Professionals and
/// Suppliers").
bool looksLikeLabel(String line) {
  final t = line.trim();
  if (RegExp(r'[.!?:;,]$').hasMatch(t)) return false;
  final big = t.split(RegExp(r'\s+')).where((w) => !_small.contains(w.toLowerCase())).toList();
  if (big.length < 2) return false;
  return big.where((w) => RegExp(r'^[A-Z(\d]').hasMatch(w)).length / big.length >= 0.6;
}

/// Splits slide notes into topics. Pages are told apart by empty lines; a page's
/// heading names its topic, and consecutive pages with the same heading, or no
/// heading, are one topic. Topics are then joined, small and alike ones first,
/// until about one per 1,500 characters are left (at least 5, at most
/// [maxGroups]); a topic much bigger than the rest is split at page boundaries.
/// Returns null if the notes do not look like paged slides with headings.
List<SlideGroup>? groupSlides(String notes, {required int maxGroups}) {
  final rawPages = notes.replaceAll('\r', '').split(RegExp(r'\n[ \t]*\n'));
  final raw = <_Page>[];
  for (final r in rawPages) {
    final lines = [
      for (final l in r.split('\n'))
        if (l.trim().isNotEmpty && !_credit.hasMatch(l.trim())) _Line(l.trim(), l.endsWith(' ')),
    ];
    if (lines.isNotEmpty) raw.add(_splitPage(lines));
  }
  if (raw.length < 3) return null;

  final vocab = {
    for (final p in raw)
      for (final l in [...p.lines.map((l) => l.text), if (p.heading != null) p.heading!])
        for (final m in RegExp(r'[A-Za-z]{3,}').allMatches(l)) m[0]!.toLowerCase(),
  };
  String tidy(String h) => tidyHeading(h, vocab: vocab);

  // A heading on many pages is a running title or footer, not a topic. The real
  // heading, if there is one, is the next heading on the page.
  final seen = <String, int>{};
  for (final p in raw) {
    if (p.heading != null) seen[_key(tidy(p.heading!))] = (seen[_key(tidy(p.heading!))] ?? 0) + 1;
  }
  // Only if most of those pages have another heading under it; a heading that
  // stands alone on that many pages is one very long topic.
  final running = <String>{};
  for (final e in seen.entries) {
    if (raw.length < 6 || e.value <= raw.length * 0.4) continue;
    final pagesWith = [for (final p in raw) if (p.heading != null && _key(tidy(p.heading!)) == e.key) p];
    final withNext = pagesWith.where((p) => _splitPage(p.lines).heading != null).length;
    if (withNext * 2 >= pagesWith.length) running.add(e.key);
  }
  for (final p in raw) {
    if (p.heading != null && running.contains(_key(tidy(p.heading!)))) {
      final again = _splitPage(p.lines);
      p.heading = again.heading;
      p.lines = again.lines;
    }
  }

  final pages = <_Page>[];
  var inSources = false;
  for (final p in raw) {
    final h = p.heading == null ? null : tidy(p.heading!);
    if (h != null && _sources.hasMatch(h)) {
      inSources = true; // the pages that follow only list sources
      continue;
    }
    if (inSources && h == null) continue;
    inSources = false;
    final skipHeading = h != null && (_navigation.hasMatch(h) || _aims.hasMatch(h));
    pages.add(_Page(skipHeading ? null : h, p.lines));
  }
  if (pages.length < 3 || pages.every((p) => p.heading == null)) return null;

  // Lines that come back on three or more pages are footers.
  String norm(String l) => l.toLowerCase().replaceAll(RegExp(r'\d+'), '#');
  final lineCount = <String, int>{};
  for (final p in pages) {
    for (final l in p.lines) {
      lineCount[norm(l.text)] = (lineCount[norm(l.text)] ?? 0) + 1;
    }
  }

  var topics = <_Topic>[];
  for (final p in pages) {
    final key = p.heading == null ? null : _key(p.heading!);
    final body = [for (final l in p.lines) if (lineCount[norm(l.text)]! < 3) l.text].join('\n');
    if (topics.isNotEmpty && (key == null || key == topics.last.key)) {
      topics.last.pages.add(body);
    } else {
      topics.add(_Topic(p.heading, key, body));
    }
  }

  // A cover or a label with nothing to teach goes to its neighbour: a label to
  // the topic before it, an untitled start (cover, aims) to the first real topic.
  final merged = <_Topic>[];
  for (final t in topics) {
    if (t.size < _tinyChars && merged.isNotEmpty) {
      merged.last.absorb(t);
    } else {
      merged.add(t);
    }
  }
  if (merged.length > 1 && merged.first.key == null) {
    merged[1].pages.insertAll(0, merged.first.pages);
    merged.removeAt(0);
  }
  if (merged.length > 1 && merged.first.size < _tinyChars) merged.removeAt(0);
  topics = merged.where((t) => t.size > 0).toList();
  if (topics.length < 2) return null;

  final total = topics.fold<int>(0, (n, t) => n + t.size);
  // Fewer, balanced topics: about one per 1,500 characters, never more than [maxGroups].
  final want = (total / 1500).round().clamp(5, maxGroups);
  final target = max(total / want, 900.0);
  final idf = idfOf([for (final t in topics) t.text]);
  while (topics.length > want) {
    var at = 0;
    var best = double.negativeInfinity;
    for (var i = 0; i + 1 < topics.length; i++) {
      final combined = topics[i].size + topics[i + 1].size;
      // Alike topics first, but never lopsided ones: a big topic stays apart.
      final s = similarity(topics[i].text, topics[i + 1].text, idf) - 0.6 * combined / target;
      if (s > best) {
        best = s;
        at = i;
      }
    }
    topics[at].join(topics[at + 1]);
    topics.removeAt(at + 1);
  }

  // A topic much bigger than the rest is split in two at a page boundary, the
  // biggest first, with a few sections of room beyond the cap for this.
  final parts = [for (final t in topics) [t.pages]];
  int sizeOf(List<String> pages) => pages.join().replaceAll(RegExp(r'\s'), '').length;
  while (parts.fold<int>(0, (n, p) => n + p.length) < maxGroups + 4) {
    var at = -1;
    var biggest = max(1.6 * target, 1800.0);
    for (var i = 0; i < topics.length; i++) {
      for (var j = 0; j < parts[i].length; j++) {
        if (parts[i][j].length > 1 && sizeOf(parts[i][j]) > biggest) {
          biggest = sizeOf(parts[i][j]).toDouble();
          at = i * 1000 + j;
        }
      }
    }
    if (at < 0) break;
    final i = at ~/ 1000, j = at % 1000;
    final halves = _splitPages(parts[i][j], 2);
    if (halves.length < 2) break;
    parts[i].replaceRange(j, j + 1, halves);
  }

  final out = <SlideGroup>[];
  for (var i = 0; i < topics.length; i++) {
    final t = topics[i];
    final one = t.headings.length == 1 ? tidy(t.headings.first) : null;
    for (var j = 0; j < parts[i].length; j++) {
      out.add(SlideGroup(parts[i][j].join('\n\n'),
          title: one == null ? null : parts[i].length == 1 ? one : '$one (${j + 1} of ${parts[i].length})',
          titles: [for (final h in t.headings) tidy(h)]));
    }
  }
  return out;
}

/// [pages] cut into [k] runs of about equal length, in order.
List<List<String>> _splitPages(List<String> pages, int k) {
  final total = pages.fold<int>(0, (n, p) => n + p.length);
  final runs = <List<String>>[[]];
  var used = 0;
  for (final p in pages) {
    if (runs.last.isNotEmpty && runs.length < k && used >= total * runs.length / k) {
      runs.add([]);
    }
    runs.last.add(p);
    used += p.length;
  }
  return runs;
}
