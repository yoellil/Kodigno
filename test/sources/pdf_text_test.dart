import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/sources/pdf_text.dart';

void main() {
  test('cleanPdfText drops replacement characters and tidies spaces', () {
    expect(cleanPdfText('Copyright � 2020  Acme�\nPage 1'), 'Copyright 2020 Acme\nPage 1');
  });
}
