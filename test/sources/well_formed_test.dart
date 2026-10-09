import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/sources/pdf_text.dart';
import 'package:kodigno/sources/well_formed.dart';

bool _ok(String s) {
  final u = s.codeUnits;
  for (var i = 0; i < u.length; i++) {
    final hi = u[i] >= 0xD800 && u[i] <= 0xDBFF;
    final lo = u[i] >= 0xDC00 && u[i] <= 0xDFFF;
    if (hi && i + 1 < u.length && u[i + 1] >= 0xDC00 && u[i + 1] <= 0xDFFF) {
      i++;
    } else if (hi || lo) {
      return false;
    }
  }
  return true;
}

void main() {
  const x = '\u{1D465}'; // math italic x, two UTF-16 units: D835 DC65

  test('ordinary text and good pairs are left exactly as they are', () {
    expect(wellFormed('Plain text, with accents: caf\u00e9.'), 'Plain text, with accents: caf\u00e9.');
    expect(wellFormed('P(X \u2264 $x) and a smile \u{1F600}'), 'P(X \u2264 $x) and a smile \u{1F600}');
    expect(wellFormed(''), '');
  });

  test('a pair with its halves swapped is put back in order', () {
    final swapped = String.fromCharCodes([0x61, 0xDC65, 0xD835, 0x62]); // a, low, high, b
    expect(_ok(swapped), isFalse);
    expect(wellFormed(swapped), 'a${x}b');
  });

  test('a half with no partner is dropped', () {
    expect(wellFormed(String.fromCharCodes([0x61, 0xD835, 0x62])), 'ab'); // lone high
    expect(wellFormed(String.fromCharCodes([0x61, 0xDC65, 0x62])), 'ab'); // lone low
    expect(wellFormed(String.fromCharCodes([0x61, 0xD835])), 'a'); // high at the very end
    expect(wellFormed(String.fromCharCodes([0xDC65])), '');
  });

  test('the result can always be drawn', () {
    final messy = String.fromCharCodes([0xDC65, 0xD835, 0xD835, 0x61, 0xDC65, 0xDC65, 0xD835, 0xDC65, 0xD835]);
    expect(_ok(messy), isFalse);
    expect(_ok(wellFormed(messy)), isTrue);
  });

  test('cleanPdfText also repairs a formula\'s broken pair', () {
    final text = 'P(x1< X  x2 1${String.fromCharCodes([0xDC65, 0xD835])} = 2';
    final clean = cleanPdfText(text);
    expect(_ok(clean), isTrue);
    expect(clean, contains(x));
  });
}
