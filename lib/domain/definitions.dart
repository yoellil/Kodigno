/// A term and its definition, taken word for word from the notes.
typedef Definition = ({String term, String definition});

/// A timeline line such as "1912 - First Code adopted": its own paragraph, not a continuation.
final _yearLine = RegExp(r'^(?:1[5-9]|20)\d\d\s*[-–—:]\s');

final _bullet = RegExp(r'^(?:[•▪◦●■□➢►*]|[-–—](?=\s))\s*');
final _capital = RegExp(r'^[A-Z]');
/// A line ending in "Dr.", "No." or an initial ("Marcelo H.") is mid-sentence.
final _abbrevEnd = RegExp(r'(?:\b[A-Z]|\b(?:Dr|Mr|Mrs|Ms|Prof|Sr|Jr|St|Mt|No|Ma|Gen|Col|Capt|Hon|Rev))\.$');
final _sentenceEnd = RegExp(r'[.!?:]$');

/// The notes' lines joined back into paragraphs. A bullet starts a new one, and
/// so does a capital letter after a line that ended a sentence or was short
/// (a slide title), unless the PDF reader left a space at the end of the line
/// above, which it does when a line wraps ("Travels in the Philippines by " /
/// "Dr. Feodor Jagor"). Other lines are a sentence wrapped onto the next line.
/// [bullet] says whether the paragraph began with a bullet, [newPage] whether
/// an empty line (a new page) came before it.
List<({String text, bool bullet, bool newPage})> _paragraphs(String text) {
  final out = <({String text, bool bullet, bool newPage})>[];
  var cur = '';
  var curBullet = false, curNewPage = false, newPage = false, wraps = false;
  var last = '';
  for (final raw in text.split('\n')) {
    final l = raw.trim();
    final isBullet = _bullet.hasMatch(l);
    final starts = l.isEmpty ||
        isBullet ||
        _yearLine.hasMatch(l) ||
        (!wraps &&
            _capital.hasMatch(l) &&
            ((_sentenceEnd.hasMatch(last) && !_abbrevEnd.hasMatch(last)) || last.split(' ').length <= 6));
    if (starts && cur.isNotEmpty) {
      out.add((text: cur, bullet: curBullet, newPage: curNewPage));
      cur = '';
    }
    if (l.isEmpty) newPage = true;
    final body = l.replaceFirst(_bullet, '');
    if (body.isNotEmpty) {
      if (cur.isEmpty) {
        curBullet = isBullet;
        curNewPage = newPage;
        newPage = false;
      }
      cur = cur.isEmpty ? body : '$cur $body';
    }
    wraps = raw.endsWith(' ');
    last = l;
  }
  if (cur.isNotEmpty) out.add((text: cur, bullet: curBullet, newPage: curNewPage));
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
  'there', 'this', 'these', 'those', 'it', 'they', 'his', 'her', 'each', 'many', 'more', 'most',
  'some', 'such', 'other', 'another', 'we', 'you', 'he', 'she', 'our', 'their', 'its',
  'chapter', 'section', 'module', 'lesson', 'part', 'figure', 'table', 'slide', 'page',
  'click', 'note',
};

/// "Term - definition", "Term: definition" and "A term is a ..." lines in
/// [notes], for flashcards that need no model and cannot be made up.
List<Definition> extractDefinitions(String notes, {bool headingCards = true}) {
  final out = <Definition>[];
  final seen = <String>{};
  final paras = _paragraphs(notes.replaceAll('\r', ''));

  Definition? fromPatterns(String p) {
    for (final pattern in _patterns) {
      final m = pattern.firstMatch(p);
      if (m == null) continue;
      final term = m[1]!.trim().replaceFirst(RegExp(r'^(?:A|An|The)\s+'), '');
      final definition = m[2]!.trim().split(_sentenceSplit).first;
      final words = definition.split(RegExp(r'\s+'));
      final titleCase = words.where(_capital.hasMatch).length * 2 >= words.length;
      if (_capital.hasMatch(m[1]!) &&
          term.split(' ').length <= 6 &&
          term.length >= 3 &&
          !term.contains(RegExp(r'[,:]')) &&
          isGoodTitle(m[1]!.trim()) &&
          !_dateLike(term) &&
          _readsAsDefinition(definition) &&
          !term.toLowerCase().split(' ').any(_notTerms.contains) &&
          words.length >= 4 &&
          !titleCase) {
        return (
          term: term[0].toUpperCase() + term.substring(1),
          definition: definition[0].toUpperCase() + definition.substring(1),
        );
      }
      return null; // only the first pattern that fits is tried
    }
    return null;
  }

  for (var i = 0; i < paras.length; i++) {
    final p = paras[i];
    var d = fromPatterns(p.text);
    // A slide heading followed by bullets that explain it: the heading is the
    // term and the most fitting sentence from its bullets the definition.
    // Bullets that define something themselves are left to their own card.
    if (d == null && headingCards && !p.bullet && _isHeading(p.text)) {
      final bullets = <String>[];
      // Only the bullets on the heading's own page.
      for (var j = i + 1; j < paras.length && paras[j].bullet && !paras[j].newPage; j++) {
        if (fromPatterns(paras[j].text) != null) break; // a section title, not a term
        bullets.add(paras[j].text);
      }
      final isList = isGoodList(bullets);
      final def = isList ? formatList(bullets) : _explain(p.text.trim(), bullets);
      if (def != null) d = (term: p.text.trim(), definition: def);
    }
    if (d != null && seen.add(d.term.toLowerCase())) out.add(d);
  }
  return out;
}

/// A sentence end: ". " before a capital, but not after "Dr.", "No.", "Mrs." and the like.
final _sentenceSplit = RegExp(
    r'(?<!\b(?:Dr|Mr|Mrs|Ms|Prof|Sr|Jr|St|Mt|vs|etc|No|Nos|Fig|Inc|Ltd|Gen|Col|Capt|Hon|Rev|Ma|e\.g|i\.e)\.|\b[A-Z]\.)(?<=[.!?])\s+(?=[A-Z0-9])');

Set<String> _termWords(String s) => {
      for (final m in RegExp(r'[a-z]{4,}|\d{3,}').allMatches(s.toLowerCase())) m[0]!,
    };

/// The sentence under a heading that best explains it, without restating it:
/// from the bullet that shares the most words with [heading], the first
/// sentence that does not mostly repeat the heading, with the heading's own
/// words taken off its front. Null if nothing usable.
String? _explain(String heading, List<String> bullets) {
  if (bullets.isEmpty) return null;
  final mine = _termWords(heading);
  var best = bullets.first;
  var bestScore = -1;
  for (final b in bullets) {
    final score = _termWords(b).where(mine.contains).length;
    if (score > bestScore) {
      best = b;
      bestScore = score;
    }
  }
  final sentences = best.split(_sentenceSplit).map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
  String? first;
  for (final sentence in sentences) {
    final rest = withoutTerm(sentence, heading);
    if (rest.split(RegExp(r'\s+')).length < 6 || !_readsAsSentence(rest)) continue;
    first ??= rest;
    final repeated = mine.isEmpty ? 0 : _termWords(rest).where(mine.contains).length / mine.length;
    if (repeated < 0.6) return rest;
  }
  return first;
}

/// A short title line: capitalised, a few words, no sentence punctuation.
bool _isHeading(String s) {
  final t = s.trim();
  return t.length <= 110 &&
      isGoodTitle(t) &&
      !t.toLowerCase().split(' ').any(_notTerms.contains);
}

/// A title that is a title: not a sentence fragment, a label ("Q: what"), a
/// caption or a wrapped line that stops mid-thought.
bool isGoodTitle(String s) {
  final t = s.trim();
  final words = t.split(RegExp(r'\s+'));
  if (!RegExp(r'^[A-Z"\u201C(\d]').hasMatch(t) || words.length > 12) return false;
  if (RegExp(r'[.!?:,;&\u2026-]$|[,:;]|\u2026').hasMatch(t)) return false;
  // a full stop inside is a sentence break, unless it ends "No.", "Dr." or an initial
  if (RegExp(r'(?<!\b(?:No|Nos|Dr|Mr|Mrs|Ms|St|Jr|Sr|Mt|Ma|Prof|Gen|Fig)|\b[A-Z])\.\s').hasMatch(t)) return false;
  if (RegExp(r'^[^"\u201C]*\u201D').hasMatch(t)) return false; // a closing quote with no opening one
  if (RegExp(r'\b(?:and|or|of|the|in|at|to|by|with|for|a|an|who|whom|where|which|that|from)$', caseSensitive: false)
      .hasMatch(t)) {
    return false;
  }
  return !RegExp(
          r'^(?:to|it|its|he|she|they|but|so|then|however|unfortunately|because|when|if|while|although|also|from|this|these)\b',
          caseSensitive: false)
      .hasMatch(t);
}

/// A sentence that stands alone: starts with a capital or digit, ends properly.
bool _readsAsSentence(String s) =>
    RegExp('^[A-Z\u201C"(\\d]').hasMatch(s) &&
    RegExp('[.!?\u201D")]\$').hasMatch(s) &&
    !RegExp(r'\b(?:of|and|or|to|for|the|a|an|in|on|by|with|that|which)[.]?$', caseSensitive: false).hasMatch(s);

/// A definition worth a card: at least two real words, not a question, a
/// fill-in blank or a cut-off line.
bool _readsAsDefinition(String s) =>
    RegExp(r'[A-Za-z]{4,}').allMatches(s).length >= 2 &&
    !s.contains('___') &&
    !RegExp(r'\b1\.\s.*\b2\.\s').hasMatch(s) && // a run-in list belongs on a list card
    !RegExp(r'[?:]$').hasMatch(s) &&
    !RegExp(r'\b(?:of|and|or|to|for|the|a|an|in|on|by|with|that|which)$', caseSensitive: false).hasMatch(s);

final _months = 'January|February|March|April|May|June|July|August|September|October|November|December';

/// "November 20, 1884", "1912", "May 8": a date is not a term.
bool _dateLike(String s) =>
    RegExp(r'\b(?:1[5-9]|20)\d\d\b').hasMatch(s) || RegExp('^(?:$_months)\\b', caseSensitive: false).hasMatch(s);

/// True if [items] make a list worth a card: 2 to 10 short points, each a clean
/// phrase that still reads well when trimmed to fit a card line.
bool isGoodList(List<String> items) {
  if (items.length < 2 || items.length > 10) return false;
  final lens = [for (final x in items) x.trim().split(RegExp(r'\s+')).length];
  if (lens.any((n) => n > 14) || lens.reduce((a, b) => a + b) / lens.length > 9) return false;
  if (items.any((x) => RegExp(r'[:\u2026]$|\.\.\.$').hasMatch(x.trim()))) return false;
  final shown = formatList(items);
  return !shown.contains('\u2026') &&
      !shown.split('\n').any((l) => RegExp(r'\b(?:of|and|or|to|for|the|a|an|in|on|by|with)$', caseSensitive: false).hasMatch(l));
}

const _joiners = {'the', 'a', 'an', 'of', 'for', 'and', 'in', 'on', 'to', 'or'};

/// [text] without the term restated at its front. Leading words that belong to
/// [term] (and any brackets right after them) are dropped, along with a following
/// "is/are": "The PRO-IP Act of 2008 (Public Law 110-403) created the post..."
/// becomes "Created the post...". [text] is returned unchanged if that would
/// leave too little.
String withoutTerm(String text, String term) {
  final vocab = {
    for (final m in RegExp(r"[A-Za-z0-9]+(?:[-'][A-Za-z0-9]+)*").allMatches(term)) m[0]!.toLowerCase(),
  };
  final tokens = text.trim().split(RegExp(r'\s+'));
  var i = 0;
  var contentSeen = false;
  while (i < tokens.length) {
    final t = tokens[i];
    if (t.startsWith('(')) {
      // a bracket after term words: consume through its closing ")"
      if (!contentSeen) break;
      var j = i;
      while (j < tokens.length && !tokens[j].contains(')')) {
        j++;
      }
      if (j >= tokens.length) break;
      i = j + 1;
      continue;
    }
    final w = t.toLowerCase().replaceAll(RegExp(r"^[^a-z0-9]+|[^a-z0-9]+$"), '');
    if (w.isEmpty) break;
    if (vocab.contains(w)) {
      if (!_joiners.contains(w)) contentSeen = true;
      i++;
    } else if (_joiners.contains(w) && contentSeen == false && i == 0) {
      i++; // a leading "The" before the term
    } else {
      break;
    }
  }
  if (!contentSeen) return text;
  // Do not end on a dangling joiner such as "of" that belonged to the rest.
  var rest = tokens.sublist(i);
  while (rest.isNotEmpty && RegExp(r'^(?:is|are|was|were)$', caseSensitive: false).hasMatch(rest.first) && rest.length > 1) {
    rest = rest.sublist(1);
    break;
  }
  final out = rest.join(' ');
  if (rest.length < 4) return text;
  return out[0].toUpperCase() + out.substring(1);
}

/// [s] cut down to something memorable on a card: whole if it fits in
/// [max] characters, else without its brackets, else up to the last clause
/// break that fits (a semicolon, dash, "which/that/because", or a comma that
/// is not part of a list), else at a word with an ellipsis. Never inside brackets.
String shortenDefinition(String s, {int max = 130, bool early = false}) {
  var t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.length <= max) return t;
  // "In relationships between X and Y, each party agrees..." -> keep the point, not the setting.
  final intro = RegExp(
      r'^(?:In|On|At|When|If|During|For|As|While|Although|After|Before|Because|Since|Under|With)\b[^,]{5,60},\s+(.{30,})$')
      .firstMatch(t);
  if (intro != null) {
    t = intro[1]![0].toUpperCase() + intro[1]!.substring(1);
    if (t.length <= max) return t;
  }
  final plain = t.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
  if (plain.length <= max && plain.split(' ').length >= 4) return plain;
  t = plain.length < t.length && plain.split(' ').length >= 4 ? plain : t;

  var firstStrong = -1, lastStrong = -1, lastWeak = -1;
  var depth = 0;
  for (var k = 0; k < t.length && k <= max; k++) {
    final c = t[k];
    if (c == '(') depth++;
    if (c == ')' && depth > 0) depth--;
    if (depth > 0 || k < 25) continue;
    final tail = t.substring(k);
    final inList = RegExp(r'\b(?:including|such as|for example|e\.g\.|like)\b', caseSensitive: false)
        .hasMatch(t.substring(0, k));
    if (RegExp(r'^[;:]\s|^\s[-–—]\s|^,\s(?:which|that|because|so that|while|but)\s').hasMatch(tail) ||
        (!inList && RegExp(r'^,\s').hasMatch(tail))) {
      if (firstStrong < 0) firstStrong = k;
      lastStrong = k;
    } else if (RegExp(r'^\s(?:which|that|because|so that|while|but)\s').hasMatch(tail)) {
      lastWeak = k;
    }
  }
  // A "first" break keeps a list item to its main phrase; otherwise the longest
  // piece that fits, and a bare "that/which" only when there is no better break.
  final cut = lastStrong >= 0 ? (early ? firstStrong : lastStrong) : lastWeak;
  if (cut > 0) {
    final head = t.substring(0, cut).replaceAll(RegExp(r'[\s,;:–—-]+$'), '');
    // "Articulate, encourage acceptance of" is not a thought: cut at a word instead.
    final dangling = RegExp(r'\b(?:of|and|or|to|for|the|a|an|in|on|by|with|that|which)$', caseSensitive: false);
    if (!dangling.hasMatch(head)) return head.endsWith('.') ? head : '$head.';
  }
  var space = t.lastIndexOf(' ', max);
  var head = t.substring(0, space > 0 ? space : max);
  final open = head.lastIndexOf('(');
  if (open > head.lastIndexOf(')') && open > 20) head = head.substring(0, open);
  // Do not stop on "...during all" or "...products of".
  final loose = RegExp(r'[\s,;:–—-]+$|\s(?:of|and|or|to|for|the|a|an|in|on|by|with|that|which|all|both|during|as|is|are)$',
      caseSensitive: false);
  while (loose.hasMatch(head) && head.split(' ').length > 3) {
    head = head.replaceFirst(loose, '');
  }
  return '$head…';
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

/// [items] as a numbered list, one per line, each kept brief:
/// "1. Contribute to society\n2. Avoid harm\n3. Be honest".
String formatList(List<String> items, {int maxItem = 70}) => [
      for (var i = 0; i < items.length; i++)
        '${i + 1}. ${shortenDefinition(items[i], max: maxItem, early: true).replaceAll(RegExp(r'[.;,]+$'), '')}',
    ].join('\n');
