import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/sources/docx_text.dart';

List<int> makeDocx(String bodyXml, {String name = 'word/document.xml'}) {
  final bytes = utf8.encode(
      '<?xml version="1.0"?><w:document xmlns:w="x"><w:body>$bodyXml</w:body></w:document>');
  final a = Archive()..addFile(ArchiveFile(name, bytes.length, bytes));
  return ZipEncoder().encode(a);
}

void main() {
  test('joins runs, splits paragraphs, unescapes entities, skips empties', () {
    final docx = makeDocx(
        '<w:p><w:r><w:t>Hello </w:t></w:r><w:r><w:t xml:space="preserve">world</w:t></w:r></w:p>'
        '<w:p></w:p>'
        '<w:p><w:r><w:t>A &amp; B &lt;3</w:t></w:r></w:p>');
    expect(docxText(docx), 'Hello world\nA & B <3');
  });

  test('zip without word/document.xml is not a DOCX', () {
    expect(() => docxText(makeDocx('', name: 'other.xml')), throwsFormatException);
  });

  test('random bytes are not a DOCX', () {
    expect(() => docxText([1, 2, 3, 4, 5]), throwsFormatException);
  });
}
