/// A term and its definition, taken word for word from the notes.
typedef Definition = ({String term, String definition});

final _bullet = RegExp(r'^[•▪◦●■□➢►*]\s*');
final _capital = RegExp(r'^[A-Z]');
final _sentenceEnd = RegExp(r'[.!?:]$');

/// The notes' lines joined back into paragraphs. A bullet starts a new one, and
/// so does a capital letter after a line that ended a sentence or was short
/// (a slide title). Other lines are a sentence wrapped onto the next line.
List<String> _paragraphs(String text) {
  final out = <String>[];
  var cur = '';
  var last = '';
  for (final raw in text.split('\n')) {
    final l = raw.trim();
    final starts = l.isEmpty ||
        _bullet.hasMatch(l) ||
        (_capital.hasMatch(l) && (_sentenceEnd.hasMatch(last) || last.split(' ').length <= 6));
    if (starts && cur.isNotEmpty) {
      out.add(cur);
      cur = '';
    }
    final body = l.replaceFirst(_bullet, '');
    if (body.isNotEmpty) cur = cur.isEmpty ? body : '$cur $body';
    last = l;
  }
  if (cur.isNotEmpty) out.add(cur);
  return out;
}

final _patterns = [
  RegExp(r'^(.{2,60}?)\s+[-–—]\s+(.+)$'), // Term - definition
  RegExp(r'^([^:]{2,60}):\s+(.+)$'), // Term: definition
  RegExp(r'^(.{2,60}?)\s+(?:is|are)\s+((?:a|an|the)\s.+)$'), // A term is a ...
  RegExp(r'^(.{2,60}?)\s+(?:refers to|means|is defined as)\s+(.+)$'),
];

/// Words of statements and headings, never part of a term.
const _notTerms = {
  'there', 'this', 'these', 'those', 'it', 'they', 'each', 'many', 'more', 'most',
  'some', 'such', 'other', 'another', 'we', 'you', 'he', 'she', 'our', 'their', 'its',
  'chapter', 'section', 'module', 'lesson', 'part', 'figure', 'table', 'slide', 'page',
  'click', 'note',
};

/// "Term - definition", "Term: definition" and "A term is a ..." lines in
/// [notes], for flashcards that need no model and cannot be made up.
List<Definition> extractDefinitions(String notes) {
  final out = <Definition>[];
  final seen = <String>{};
  for (final p in _paragraphs(notes.replaceAll('\r', ''))) {
    for (final pattern in _patterns) {
      final m = pattern.firstMatch(p);
      if (m == null) continue;
      final term = m[1]!.trim().replaceFirst(RegExp(r'^(?:A|An|The)\s+'), '');
      final definition = m[2]!.trim().split(RegExp(r'(?<=[.!?])\s+(?=[A-Z0-9])')).first;
      final words = definition.split(RegExp(r'\s+'));
      final titleCase = words.where(_capital.hasMatch).length * 2 >= words.length;
      if (_capital.hasMatch(m[1]!) &&
          term.split(' ').length <= 6 &&
          !term.contains(',') &&
          !term.toLowerCase().split(' ').any(_notTerms.contains) &&
          words.length >= 4 &&
          !titleCase &&
          seen.add(term.toLowerCase())) {
        out.add((
          term: term[0].toUpperCase() + term.substring(1),
          definition: definition[0].toUpperCase() + definition.substring(1),
        ));
      }
      break; // only the first pattern that fits is tried
    }
  }
  return out;
}

/// [text] with [term], its long form and its short form in brackets
/// ("EC-Council Certified Ethical Hacker (CEH)" -> "CEH") blanked out.
String maskTerm(String text, String term) {
  final short = RegExp(r'\(([^)]+)\)').firstMatch(term)?[1];
  final forms = {
    term,
    term.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim(),
    ?short,
  }.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final f in forms) {
    if (f.isEmpty) continue;
    text = text.replaceAll(
        RegExp(r'(?<!\w)' '${RegExp.escape(f)}' r'(?!\w)', caseSensitive: false), '____');
  }
  return text;
}

const _common = {
  'that', 'with', 'from', 'they', 'have', 'this', 'their', 'which', 'these', 'those',
  'other', 'more', 'into', 'such', 'about', 'also', 'used', 'some', 'many', 'what',
  'when', 'where', 'there', 'your', 'will', 'been', 'were', 'them', 'than', 'then',
  'each', 'only', 'over', 'example',
};

Set<String> _content(String s) => {
      for (final m in RegExp(r'[a-z]{4,}').allMatches(s.toLowerCase()))
        if (!_common.contains(m[0])) m[0]!,
    };

/// The other terms in [all] whose definitions share words with [d]'s, most
/// shared first: wrong quiz choices on the same subject, so they are not
/// easy to rule out.
List<String> relatedTerms(Definition d, List<Definition> all) {
  final mine = _content(d.definition);
  final scored = [
    for (final o in all)
      if (o.term != d.term) (o.term, _content(o.definition).where(mine.contains).length),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final (term, shared) in scored) if (shared > 0) term];
}
