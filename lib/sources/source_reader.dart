import 'dart:io';

import 'package:path/path.dart' as p;

import '../ocr/ocr_service.dart';
import 'docx_text.dart';
import 'pdf_text.dart';

class UnsupportedSourceException implements Exception {
  UnsupportedSourceException(this.ext);
  final String ext;
  @override
  String toString() =>
      'Unsupported file type${ext.isEmpty ? '' : ' ".$ext"'}. Use an image (PNG, JPG, BMP, TIFF), PDF, DOCX or TXT file.';
}

class SourceReader {
  SourceReader({required this.ocr, required this.pdf});
  final OcrService ocr;
  final PdfTextExtractor pdf;

  static const _images = {'png', 'jpg', 'jpeg', 'bmp', 'tif', 'tiff'};

  static String typeOf(String path) {
    final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
    if (_images.contains(ext)) return 'image';
    if (ext == 'pdf') return 'pdf';
    if (ext == 'docx') return 'docx';
    if (ext == 'txt' || ext == 'md') return 'text';
    throw UnsupportedSourceException(ext);
  }

  Future<String> read(String path) async {
    switch (typeOf(path)) {
      case 'image':
        return ocr.recognize(path);
      case 'pdf':
        return pdf.extract(path);
      case 'docx':
        return docxText(await File(path).readAsBytes());
      default:
        return (await File(path).readAsString()).trim();
    }
  }
}
