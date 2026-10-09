import 'package:pdfrx/pdfrx.dart';

abstract class PdfTextExtractor {
  /// Text layer of the PDF, or '' if it has none (e.g. a scan).
  Future<String> extract(String path);
}

/// PDFs often yield U+FFFD for symbols the font can't map (©, bullets);
/// drop them and the double spaces they leave behind.
String cleanPdfText(String text) =>
    text.replaceAll('�', '').replaceAll(RegExp(r'[ 	]{2,}'), ' ');

class PdfrxTextExtractor implements PdfTextExtractor {
  @override
  Future<String> extract(String path) async {
    final doc = await PdfDocument.openFile(path);
    try {
      final buf = StringBuffer();
      for (final page in doc.pages) {
        final text = await page.loadText();
        // An empty line marks the end of a page (slide), so topics can be told apart.
        final pageText = text?.fullText.trim() ?? '';
        if (pageText.isNotEmpty) buf.write('$pageText\n\n');
      }
      return cleanPdfText(buf.toString()).trim();
    } finally {
      await doc.dispose();
    }
  }
}
