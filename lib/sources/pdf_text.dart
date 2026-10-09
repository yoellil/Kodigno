import 'package:pdfrx/pdfrx.dart';

import '../domain/source_ref.dart';
import 'well_formed.dart';

abstract class PdfTextExtractor {
  /// Text layer of the PDF, or '' if it has none (e.g. a scan).
  Future<String> extract(String path);
}

/// PDFs often yield U+FFFD for symbols the font can't map (©, bullets);
/// drop them and the double spaces they leave behind. Broken character pairs,
/// which formulas can leave, are put right too.
String cleanPdfText(String text) =>
    wellFormed(text.replaceAll('�', '').replaceAll(RegExp(r'[ 	]{2,}'), ' '));

class PdfrxTextExtractor implements PdfTextExtractor {
  @override
  Future<String> extract(String path) async {
    final doc = await PdfDocument.openFile(path);
    try {
      final buf = StringBuffer();
      for (final page in doc.pages) {
        final text = await page.loadText();
        // A marker line starts each page, so the true page number is kept (pages
        // with no text are skipped) and the empty line after it tells pages apart.
        final pageText = text?.fullText.trim() ?? '';
        if (pageText.isNotEmpty) buf.write('${pageMarker(page.pageNumber)}\n$pageText\n\n');
      }
      return cleanPdfText(buf.toString()).trim();
    } finally {
      await doc.dispose();
    }
  }
}
