library;

/// Keeps reference lists out of the notes and placeholder or odd-looking
/// answers out of the cards and quiz.

final _refHeading = RegExp(
  r'^\s*(?:\d+[.)]?\s*)?(?:references?|bibliography|works\s+cited|sources?|citations?|'
  r'further\s+reading|reading\s+list|image\s+(?:credits|sources)|acknowledge?ments?)\s*:?\s*$',
  caseSensitive: false,
);

final _url = RegExp(r'https?://|www\.|\bdoi\b|doi\.org|\bisbn\b|\barxiv\b|\bretrieved\b|\baccessed\b',
    caseSensitive: false);
final _numbered = RegExp(r'^\s*\[\d+\]');
final _yearParen = RegExp(r'\(\s*(?:19|20)\d{2}[a-z]?\s*\)|,\s*(?:19|20)\d{2}[a-z]?\s*[.,]');
final _citeDetail = RegExp(
  r'\b[A-Z]\.[,\s]|\bpp?\.\s*\d|\bvol(?:ume)?\.?\s*\d|\d+\s*\(\d+\)|\d{1,5}\s*[-–]\s*\d{1,5}\s*\.?\s*$|'
  r'\bjournal of\b|\bproceedings of\b|\bpress\b|\bpublish(?:ers?|ed by)\b|\bet al\.',
  caseSensitive: false,
);

/// True for a bibliography entry, a link or a citation, which are not
/// something a student should be quizzed on. Plain prose that merely names a
/// study ("Smith et al. found...") is not flagged.
bool looksLikeCitation(String s) =>
    _url.hasMatch(s) || _numbered.hasMatch(s) || (_yearParen.hasMatch(s) && _citeDetail.hasMatch(s));

final _marker = RegExp(r'\s*\[\d+(?:\s*[,–-]\s*\d+)*\]');

/// [text] without its reference list and citation lines. A "References" /
/// "Bibliography" / "Sources" heading in the later part of the notes drops
/// everything after it; an earlier one (a slide's own "Sources" line) drops
/// just the entries under it. Inline markers like "[3]" are removed too.
String stripReferences(String text) {
  final lines = text.split('\n');
  final cutFrom = lines.indexWhere(_refHeading.hasMatch);
  var kept = lines;
  if (cutFrom >= 0 && cutFrom >= lines.length * 0.4) {
    kept = lines.sublist(0, cutFrom);
  } else if (cutFrom >= 0) {
    var end = cutFrom + 1;
    while (end < lines.length && (lines[end].trim().isEmpty || looksLikeCitation(lines[end]))) {
      end++;
    }
    kept = [...lines.sublist(0, cutFrom), ...lines.sublist(end)];
  }
  return kept
      .where((l) => !looksLikeCitation(l))
      .map((l) => l.replaceAll(_marker, ''))
      .join('\n');
}

final _answerPrefix = RegExp(r'^\s*(?:the\s+)?(?:correct\s+)?answer\s*(?:is|=|:|-|–)\s*', caseSensitive: false);

const _placeholders = {
  'answer', 'the answer', 'correct answer', 'the correct answer', 'n/a', 'na', 'none',
  'unknown', 'not stated', 'not specified', 'not mentioned', 'see above', 'see notes',
  'none of the above', 'all of the above', 'both of the above', 'both a and b',
};

/// [a] without a leading "The answer is" or wrapping quotes.
String cleanAnswer(String a) {
  var s = a.replaceFirst(_answerPrefix, '').trim();
  if (s.length > 1 && RegExp('^["“\']').hasMatch(s) && RegExp('["”\']\$').hasMatch(s)) {
    s = s.substring(1, s.length - 1).trim();
  }
  return s;
}

/// True for an "answer" that says nothing: the word "answer" itself, "N/A",
/// "None of the above" and the like.
bool isPlaceholderAnswer(String a) {
  final s = cleanAnswer(a).toLowerCase().replaceAll(RegExp(r'[.!?\s]+$'), '');
  return s.isEmpty || _placeholders.contains(s);
}

/// A quiz choice in one house style, so the right answer is not the one that
/// looks different: no wrapping quotes, no closing full stop, first letter
/// capital. Applied to every choice, the correct one included.
String normalizeChoice(String choice) {
  var s = cleanAnswer(choice).replaceAll(RegExp(r'\s+'), ' ');
  // A closing full stop goes, but not the one in an abbreviation like "U.S."
  s = s.replaceFirst(RegExp(r'[;,]+$'), '');
  if (s.endsWith('.') && !s.split(' ').last.substring(0, s.split(' ').last.length - 1).contains('.')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

/// PDF headings sometimes lose their spaces ("forIntellectualPropertyActof2008").
/// In a line made of such run-together words, puts a space back at every
/// lower-to-upper step and between letters and digits. Lines with normal spacing
/// are left alone, so names like "JavaScript" in prose survive.
String fixSquashedText(String text) => text.split('\n').map(_fixSquashedLine).join('\n');

String _fixSquashedLine(String line) {
  // A run-together token: long, with at least two lower-to-upper steps.
  final squashed = RegExp(r'\S{12,}').allMatches(line).any(
      (m) => RegExp(r'[a-z)][A-Z]').allMatches(m[0]!).length >= 2);
  if (!squashed) return line;
  return line
      .replaceAllMapped(RegExp(r'([a-z)])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(RegExp(r'([a-z])(\d)'), (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(RegExp(r'(\d)([A-Za-z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(RegExp(r'\.(?=\d)'), (m) => '. ')
      .replaceAll(RegExp(r' {2,}'), ' ');
}

/// [answer] without a lead-in that only echoes the question: for "What does
/// the Code express?", "It expresses the conscience of the profession" becomes
/// "The conscience of the profession", and for "What is the CVE database?",
/// "The CVE database is an example of a national database" becomes "An example
/// of a national database". In a quiz that echo would mark the right choice.
String withoutQuestionEcho(String answer, String question) {
  final subject = _withoutEchoedSubject(answer, question);
  if (subject != null) return subject;
  final m = RegExp(r'^(?:it|they|this|that|these|those)\s+([a-z]+)\s+(.+)$', caseSensitive: false)
      .firstMatch(answer.trim());
  if (m == null) return answer;
  final stem = m[1]!.toLowerCase().replaceFirst(RegExp(r'(?:es|s|ed|ing)$'), '');
  final rest = m[2]!;
  if (stem.length < 4 ||
      !RegExp(r'\b' '${RegExp.escape(stem)}').hasMatch(question.toLowerCase()) ||
      rest.split(RegExp(r'\s+')).length < 2) {
    return answer;
  }
  return rest[0].toUpperCase() + rest.substring(1);
}

/// [answer] without its first words when they only name the question's subject
/// (two or more words of the question that are not "the", "and"..., then at
/// most its verb), or null.
String? _withoutEchoedSubject(String answer, String question) {
  final words = answer.trim().split(RegExp(r'\s+'));
  final q = question.toLowerCase();
  bool asked(String w) {
    final t = w.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    return t.isNotEmpty && RegExp(r'\b' '${RegExp.escape(t)}' r'\b').hasMatch(q);
  }

  var n = 0;
  while (n < words.length && asked(words[n])) {
    n++;
  }
  const small = {'the', 'and', 'are', 'was', 'were', 'for', 'with', 'from', 'that'};
  if (words.take(n).where((w) => w.length >= 3 && !small.contains(w.toLowerCase())).length < 2) return null;
  // Then the verb: "is", or the question's own ("enables" for "What does it enable?").
  final verb = n < words.length ? words[n].toLowerCase().replaceFirst(RegExp(r'(?:es|s)$'), '') : '';
  if (RegExp(r'^(?:i|are|was|were|ha|have)$').hasMatch(verb) || (verb.length >= 4 && q.contains(verb))) n++;
  if (words.length - n < 3) return null;
  final rest = words.skip(n).join(' ');
  return rest[0].toUpperCase() + rest.substring(1);
}
