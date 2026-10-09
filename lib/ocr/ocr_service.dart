import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

abstract class OcrService {
  /// Returns the text found in the image, or '' if none.
  Future<String> recognize(String imagePath);
}

class OcrFailure implements Exception {
  OcrFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

typedef ProcessRunner = Future<ProcessResult> Function(String exe, List<String> args);

/// Runs the bundled tesseract.exe: `tesseract <image> stdout -l eng`.
class TesseractCliOcr implements OcrService {
  TesseractCliOcr({
    required this.exePath,
    required this.tessdataDir,
    ProcessRunner? run,
  }) : _run = run ?? ((exe, args) => Process.run(exe, args, stdoutEncoding: utf8));

  /// Locates tesseract next to the app executable (see third_party/ + CMake install).
  factory TesseractCliOcr.bundled() {
    final dir = File(Platform.resolvedExecutable).parent.path;
    return TesseractCliOcr(
      exePath: p.join(dir, 'tesseract', 'tesseract.exe'),
      tessdataDir: p.join(dir, 'tesseract', 'tessdata'),
    );
  }

  final String exePath;
  final String tessdataDir;
  final ProcessRunner _run;

  @override
  Future<String> recognize(String imagePath) async {
    final ProcessResult r;
    try {
      r = await _run(exePath,
          [imagePath, 'stdout', '-l', 'eng', '--tessdata-dir', tessdataDir]);
    } on ProcessException {
      throw OcrFailure('The text recognition engine was not found. Reinstall Kodigno.');
    }
    if (r.exitCode != 0) {
      throw OcrFailure('Text recognition failed (code ${r.exitCode}).');
    }
    return (r.stdout as String).trim();
  }
}
