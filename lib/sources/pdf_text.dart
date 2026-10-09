import 'package:pdfrx/pdfrx.dart';

abstract class PdfTextExtractor {
  /// Text layer of the PDF, or '' if it has none (e.g. a scan).
  Future<String> extract(String path);
}

class PdfrxTextExtractor implements PdfTextExtractor {
  @override
  Future<String> extract(String path) async {
    final doc = await PdfDocument.openFile(path);
    try {
      final buf = StringBuffer();
      for (final page in doc.pages) {
        final text = await page.loadText();
        if (text != null) buf.writeln(text.fullText);
      }
      return buf.toString().trim();
    } finally {
      await doc.dispose();
    }
  }
}
