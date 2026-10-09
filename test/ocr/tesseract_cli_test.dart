import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:kodigno/ocr/ocr_service.dart';

void main() {
  test('passes image, language and tessdata dir; trims stdout', () async {
    late List<String> seen;
    final ocr = TesseractCliOcr(
      exePath: 't.exe',
      tessdataDir: 'C:/td',
      run: (exe, args) async {
        seen = [exe, ...args];
        return ProcessResult(1, 0, '  Hello notes \n', '');
      },
    );
    expect(await ocr.recognize('a.png'), 'Hello notes');
    expect(seen, ['t.exe', 'a.png', 'stdout', '-l', 'eng', '--tessdata-dir', 'C:/td']);
  });

  test('non-zero exit throws OcrFailure', () {
    final ocr = TesseractCliOcr(
        exePath: 't', tessdataDir: 'd', run: (_, _) async => ProcessResult(1, 1, '', 'boom'));
    expect(ocr.recognize('a.png'), throwsA(isA<OcrFailure>()));
  });

  test('missing executable throws OcrFailure', () {
    final ocr = TesseractCliOcr(
        exePath: 't', tessdataDir: 'd',
        run: (_, _) async => throw const ProcessException('t', []));
    expect(ocr.recognize('a.png'), throwsA(isA<OcrFailure>()));
  });

  test('bundled() points at tesseract/ next to the executable, with no control characters', () {
    final ocr = TesseractCliOcr.bundled();
    expect(ocr.exePath, endsWith(p.join('tesseract', 'tesseract.exe')));
    expect(ocr.tessdataDir, endsWith(p.join('tesseract', 'tessdata')));
    expect(ocr.exePath.contains(String.fromCharCode(9)), isFalse);
  });
}
