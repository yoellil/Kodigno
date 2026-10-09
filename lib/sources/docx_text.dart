import 'dart:convert';

import 'package:archive/archive.dart';

/// Extracts paragraph text from a .docx (a zip holding word/document.xml).
String docxText(List<int> bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const FormatException('Not a valid DOCX file.');
  }
  final file = archive.findFile('word/document.xml');
  if (file == null) throw const FormatException('Not a valid DOCX file.');

  final xml = utf8.decode(file.content as List<int>);
  final run = RegExp(r'<w:t(?:\s[^>]*)?>([^<]*)</w:t>');
  final paragraphs = <String>[];
  for (final p in xml.split('</w:p>')) {
    final text = run.allMatches(p).map((m) => m.group(1)!).join();
    if (text.trim().isNotEmpty) paragraphs.add(_unescape(text));
  }
  return paragraphs.join('\n');
}

String _unescape(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');
