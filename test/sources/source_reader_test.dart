import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ocr/ocr_service.dart';
import 'package:kodigno/sources/pdf_text.dart';
import 'package:kodigno/sources/source_reader.dart';

import 'docx_text_test.dart' show makeDocx;

class _Ocr implements OcrService {
  final calls = <String>[];
  @override
  Future<String> recognize(String imagePath) async {
    calls.add(imagePath);
    return 'ocr text';
  }
}

class _Pdf implements PdfTextExtractor {
  @override
  Future<String> extract(String path) async => 'pdf text';
}

void main() {
  late _Ocr ocr;
  late SourceReader reader;
  late Directory dir;
  setUp(() async {
    ocr = _Ocr();
    reader = SourceReader(ocr: ocr, pdf: _Pdf());
    dir = await Directory.systemTemp.createTemp('src');
  });
  tearDown(() => dir.delete(recursive: true));

  test('typeOf classifies, case-insensitively', () {
    expect(SourceReader.typeOf('C:/x/NOTE.PNG'), 'image');
    expect(SourceReader.typeOf('a.jpeg'), 'image');
    expect(SourceReader.typeOf('a.PDF'), 'pdf');
    expect(SourceReader.typeOf('a.docx'), 'docx');
    expect(SourceReader.typeOf('a.md'), 'text');
  });

  test('unsupported or missing extension throws', () {
    expect(() => SourceReader.typeOf('a.heic'), throwsA(isA<UnsupportedSourceException>()));
    expect(() => SourceReader.typeOf('noext'), throwsA(isA<UnsupportedSourceException>()));
  });

  test('image goes to OCR, pdf to extractor', () async {
    expect(await reader.read('C:/x/NOTE.PNG'), 'ocr text');
    expect(ocr.calls, ['C:/x/NOTE.PNG']);
    expect(await reader.read('a.pdf'), 'pdf text');
  });

  test('txt is read from disk', () async {
    final f = File('${dir.path}/n.txt')..writeAsStringSync('plain notes');
    expect(await reader.read(f.path), 'plain notes');
  });

  test('docx is read from disk', () async {
    final f = File('${dir.path}/n.docx')
      ..writeAsBytesSync(makeDocx('<w:p><w:r><w:t>From Word</w:t></w:r></w:p>'));
    expect(await reader.read(f.path), 'From Word');
  });
}
