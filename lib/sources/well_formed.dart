/// [text] with its broken character pairs put right. Characters outside the
/// basic range (math letters such as the italic x in a formula, emoji) take two
/// UTF-16 units, and some PDFs return them with the two halves swapped or with
/// one half missing. Flutter cannot draw such a string, and a text box that holds
/// one fails on every redraw. A swapped pair is put back in order; a half that
/// has lost its partner is dropped.
String wellFormed(String text) {
  bool high(int u) => u >= 0xD800 && u <= 0xDBFF;
  bool low(int u) => u >= 0xDC00 && u <= 0xDFFF;

  final u = text.codeUnits;
  if (!u.any((c) => high(c) || low(c))) return text; // the usual case
  final out = <int>[];
  for (var i = 0; i < u.length; i++) {
    final c = u[i];
    if (high(c) && i + 1 < u.length && low(u[i + 1])) {
      out..add(c)..add(u[i + 1]); // a good pair
      i++;
    } else if (low(c) && i + 1 < u.length && high(u[i + 1])) {
      out..add(u[i + 1])..add(c); // swapped: low then high
      i++;
    } else if (high(c) || low(c)) {
      continue; // its partner is missing
    } else {
      out.add(c);
    }
  }
  return String.fromCharCodes(out);
}
