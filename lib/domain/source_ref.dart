import 'dart:convert';

import 'nlp.dart';

/// How well a piece of material is backed by the student's own pages.
enum SourceKind {
  /// Taken word for word from the pages.
  copied,

  /// Written by the AI, and the closest page supports it.
  explained,

  /// Written by the AI, and no page supports it well. Shown flagged, not hidden.
  unmatched,
}

/// One page (slide) of the student's file, as its text.
class PageText {
  const PageText(this.number, this.text);

  /// The page number in the file, counting from 1. Pages with no text are
  /// skipped, so the numbers can have gaps.
  final int number;
  final String text;
}

/// Where a piece of material comes from: the page or pages, how sure the match
/// is, and the line of the page to point at.
class SourceRef {
  const SourceRef({
    required this.kind,
    this.pages = const [],
    this.score = 0,
    this.quote = '',
    this.file = 0,
  });

  final SourceKind kind;

  /// Page numbers, best first. Empty if nothing in the file resembles the text.
  final List<int> pages;

  /// 0 to 1: 1 for a word-for-word copy, otherwise how alike the text and the page are.
  final double score;

  /// The line of the page the text rests on, so the viewer can highlight it.
  final String quote;

  /// Which of the set's files, when there are several. Counting from 0.
  final int file;

  int? get page => pages.isEmpty ? null : pages.first;

  Map<String, Object?> toJson() => {
        'k': kind.name[0], // c | e | u
        'p': pages,
        's': double.parse(score.toStringAsFixed(3)),
        if (quote.isNotEmpty) 'q': quote,
        if (file != 0) 'f': file,
      };

  factory SourceRef.fromJson(Map<String, dynamic> j) => SourceRef(
        kind: switch (j['k']) {
          'c' => SourceKind.copied,
          'e' => SourceKind.explained,
          _ => SourceKind.unmatched,
        },
        pages: [for (final p in (j['p'] as List? ?? const [])) if (p is int) p],
        score: (j['s'] as num?)?.toDouble() ?? 0,
        quote: j['q'] as String? ?? '',
        file: j['f'] as int? ?? 0,
      );

  String encode() => jsonEncode(toJson());

  /// A saved reference, or null if [saved] is empty or unreadable.
  static SourceRef? decode(String saved) {
    if (saved.isEmpty) return null;
    try {
      return SourceRef.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

/// The marker line that starts each page in the notes: "--- Page 7 ---". It keeps
/// the true page number, and survives the student editing the notes.
String pageMarker(int number) => '--- Page $number ---';

final _marker = RegExp('^[ \\t]*[-\u2013\u2014]{2,}[ \\t]*Page[ \\t]+(\\d+)[ \\t]*[-\u2013\u2014]{2,}[ \\t\\r]*\$', multiLine: true);

/// The pages in [notes], from their markers, or none if there are no markers
/// (a Word file, plain text, or notes made before pages were kept).
List<PageText> parsePages(String notes) {
  final ms = _marker.allMatches(notes).toList();
  final out = <PageText>[];
  for (var i = 0; i < ms.length; i++) {
    final end = i + 1 < ms.length ? ms[i + 1].start : notes.length;
    final text = notes.substring(ms[i].end, end).trim();
    if (text.isNotEmpty) out.add(PageText(int.parse(ms[i][1]!), text));
  }
  return out;
}

/// [notes] without the page markers, pages one empty line apart: what the
/// language steps and the model should read.
String stripPageMarkers(String notes) {
  if (!_marker.hasMatch(notes)) return notes;
  return notes
      .replaceAll(_marker, '')
      .replaceAll(RegExp(r'\n[ \t\r]*\n(?:[ \t\r]*\n)+'), '\n\n')
      .trim();
}

/// Letters and digits only, lower case, one space between words: so text from
/// the lesson and text from a page compare equal across line breaks, bullets and
/// the spaced-out numbers PDFs leave ("1, 000, 000").
String _squash(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// Finds the page that backs a piece of text. Word-for-word text is found by
/// quote; AI-written text by the page whose words and lines are most like it.
class SourceLocator {
  SourceLocator(this.pages, {this.minScore = 0.3, this.file = 0})
      : _idf = idfOf([for (final p in pages) p.text]) {
    for (final p in pages) {
      _squashed.add(_squash(p.text));
      _pageVec.add(vectorOf(p.text, _idf));
      final items = textItems(p.text).where((t) => t.length >= 12).toList();
      _items.add(items);
      _itemVec.add([for (final t in items) vectorOf(t, _idf)]);
    }
  }

  final List<PageText> pages;

  /// A match below this is flagged as unmatched.
  final double minScore;
  final int file;

  final Map<String, double> _idf;
  final _squashed = <String>[];
  final _pageVec = <Map<String, double>>[];
  final _items = <List<String>>[];
  final _itemVec = <List<Map<String, double>>>[];

  SourceRef locate(String claim) {
    final text = claim.trim();
    if (text.isEmpty || pages.isEmpty) return SourceRef(kind: SourceKind.unmatched, file: file);

    // Word for word: the first line, squashed, is somewhere on a page.
    final first = text.split('\n').firstWhere((l) => _squash(l).length >= 12, orElse: () => text.split('\n').first);
    final needle = _squash(first);
    if (needle.length >= 12) {
      final hits = [for (var i = 0; i < pages.length; i++) if (_squashed[i].contains(needle)) pages[i].number];
      if (hits.isNotEmpty) {
        return SourceRef(
            kind: SourceKind.copied,
            pages: hits.take(3).toList(),
            score: 1,
            quote: first.trim(),
            file: file);
      }
    }

    // Written by the AI: the page with the most alike words, or the most alike line.
    final v = vectorOf(text, _idf);
    final scores = <double>[];
    final bestLine = <int>[];
    for (var i = 0; i < pages.length; i++) {
      var line = -1;
      var lineScore = 0.0;
      for (var j = 0; j < _itemVec[i].length; j++) {
        final c = cosineOf(v, _itemVec[i][j]);
        if (c > lineScore) {
          lineScore = c;
          line = j;
        }
      }
      bestLine.add(line);
      scores.add([cosineOf(v, _pageVec[i]), lineScore * 0.9].reduce((a, b) => a > b ? a : b));
    }
    var best = 0;
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > scores[best]) best = i;
    }
    if (scores[best] <= 0) return SourceRef(kind: SourceKind.unmatched, file: file);

    final near = [
      best,
      for (var i = 0; i < scores.length; i++)
        if (i != best && scores[i] >= minScore && scores[i] >= scores[best] * 0.9) i,
    ].take(2);
    return SourceRef(
      kind: scores[best] >= minScore ? SourceKind.explained : SourceKind.unmatched,
      pages: [for (final i in near) pages[i].number],
      score: scores[best].clamp(0.0, 1.0),
      quote: bestLine[best] < 0 ? '' : _items[best][bestLine[best]],
      file: file,
    );
  }
}
