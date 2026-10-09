import 'definitions.dart';

const _countWords = {
  'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
};

final _asksForSeveral = RegExp(
    r'\b(?:what|which)\s+(?:are|were)\b|^\s*(?:list|name|identify|state|give|outline|enumerate|mention)\b');
// "6-year" and "two-thirds" are not counts of things asked for.
final _countToken = RegExp(r'\b(two|three|four|five|six|seven|eight|nine|ten|[2-9]|10)\b(?![-\d])');

/// How many things [question] asks for ("What are the three key principles...?"
/// gives 3), or null if it asks for one thing.
int? expectedCount(String question) {
  final q = question.toLowerCase();
  if (!_asksForSeveral.hasMatch(q)) return null;
  final m = _countToken.firstMatch(q);
  if (m == null) return null;
  return _countWords[m[1]] ?? int.parse(m[1]!);
}

final _marker = RegExp(r'(?:^|(?<=[\s;,:(]))(\d{1,2})[.)]\s+(?=\S)');

String _tidy(String s) => s.trim().replaceAll(RegExp(r'[\s;,.]+$'), '').replaceAll(RegExp(r'\s+'), ' ');

/// The items of a run-in numbered list ("1. A 2. B 3. C"), or null if [text]
/// does not hold one that counts up from 1.
List<String>? numberedItems(String text) {
  final starts = <RegExpMatch>[];
  for (final m in _marker.allMatches(text)) {
    if (int.parse(m[1]!) == starts.length + 1) starts.add(m);
  }
  if (starts.length < 2) return null;
  return [
    for (var i = 0; i < starts.length; i++)
      _tidy(text.substring(starts[i].end, i + 1 < starts.length ? starts[i + 1].start : text.length)),
  ].where((s) => s.isNotEmpty).toList();
}

final _listLine = RegExp(r'^\s*(?:\d{1,2}(?:\.\d{1,2})*[.)]?|[•▪◦●■□➢►*]|[-–—])\s+(.+)$');

final _listNouns = RegExp(
    r'\b(?:principles|steps|stages|phases|types|kinds|categories|components|elements|parts|ways|reasons|'
    r'benefits|advantages|disadvantages|characteristics|features|examples|goals|objectives|causes|effects|'
    r'functions|roles|rules|responsibilities|requirements|methods|techniques|factors|areas|levels|laws|'
    r'values|duties|rights|skills|threats|attacks|sections|topics|pillars|properties|criteria|guidelines|'
    r'standards|stakeholders|tools|issues)\b');

/// True if [question] wants a list: it gives a count ("the three principles")
/// or asks "What are the main principles / steps / types...?".
bool asksForList(String question) {
  if (expectedCount(question) != null) return true;
  final q = question.toLowerCase();
  return _asksForSeveral.hasMatch(q) && _listNouns.hasMatch(q);
}

/// Words with a trailing "s" taken off, so "professionals" matches "professional".
Set<String> _words(String s) => {
      for (final m in RegExp(r'[a-z]{4,}').allMatches(s.toLowerCase()))
        m[0]!.endsWith('s') ? m[0]!.substring(0, m[0]!.length - 1) : m[0]!,
    };

typedef NotesList = ({String heading, List<String> items, bool ordered});

/// Runs of bulleted or numbered lines in [text], each with the (up to two)
/// ordinary lines just above it.
List<({List<String> items, List<String> above, bool ordered})> _runs(String text) {
  final runs = <({List<String> items, List<String> above, bool ordered})>[];
  List<String>? cur;
  var curAbove = <String>[];
  var curOrdered = false;
  final recent = <String>[];
  void close() {
    if (cur != null) runs.add((items: cur!, above: curAbove, ordered: curOrdered));
    cur = null;
  }

  for (final line in text.split('\n')) {
    final m = _listLine.firstMatch(line);
    if (m != null && RegExp(r'[A-Za-z]{3,}').hasMatch(m[1]!)) {
      if (cur == null) {
        cur = <String>[];
        curAbove = List.of(recent);
        curOrdered = RegExp(r'^\s*\d').hasMatch(line);
      }
      cur!.add(m[1]!);
    } else if (cur != null && RegExp(r'^\s*[a-z(]').hasMatch(line)) {
      cur![cur!.length - 1] = '${cur!.last} ${line.trim()}'; // wrapped line
    } else {
      close();
      if (line.trim().isNotEmpty) {
        recent.add(line.trim());
        if (recent.length > 2) recent.removeAt(0);
      }
    }
  }
  close();
  return runs;
}

/// Every list in [notes] with the title above it ('' if it has none): the
/// notes' own structure, usable for cards and quiz questions with no model.
List<NotesList> notesLists(String notes) => [
      for (final r in _runs(notes))
        (
          heading: r.above.reversed
              .map((l) => l.replaceAll(RegExp(r'\s*:$'), ''))
              .firstWhere(isGoodTitle, orElse: () => ''),
          items: [for (final x in r.items) _tidy(x)].where((x) => x.isNotEmpty).toList(),
          ordered: r.ordered,
        ),
    ];

/// A list in [chunk] that fits [hint] (the question and the model's answer):
/// bulleted or numbered lines ("1.", "1.1", "-", "•"), or a numbered list run
/// together in one line. It has exactly [n] items, or 2 to 10 if [n] is null,
/// and shares at least [minShared] words with the hint. Lines just above a
/// list ("General Ethical Principles") count too. Null if there is none.
List<String>? listFromNotes(String chunk, int? n, String hint, {int minShared = 0}) {
  final runs = [
    for (final r in _runs(chunk)) (items: r.items, context: r.above.join(' ')),
  ];
  final inline = numberedItems(chunk.replaceAll('\n', ' '));
  if (inline != null) runs.add((items: inline, context: ''));

  final want = _words(hint);
  List<String>? best;
  var bestScore = minShared - 1;
  for (final r in runs) {
    final items = [for (final x in r.items) _tidy(x)].where((s) => s.isNotEmpty).toList();
    if (n != null ? items.length != n : (items.length < 2 || items.length > 10)) continue;
    final score = _words('${r.context} ${items.join(' ')}').where(want.contains).length;
    if (score > bestScore) {
      best = items;
      bestScore = score;
    }
  }
  return best;
}
