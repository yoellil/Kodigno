import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ocr/ocr_service.dart';
import 'package:kodigno/sources/pdf_text.dart';
import 'package:kodigno/sources/source_reader.dart';
import 'package:kodigno/ui/add_source_screen.dart';
import 'package:kodigno/ui/theme.dart';
import 'package:kodigno/ui/widgets.dart';

class _Ocr implements OcrService {
  _Ocr(this.text);
  final String text;
  @override
  Future<String> recognize(String imagePath) async => text;
}

class _Pdf implements PdfTextExtractor {
  @override
  Future<String> extract(String path) async => '';
}

Widget _app(String ocrText, void Function(String, String, String) onGenerate,
        {String path = 'C:/n/photo.png'}) =>
    MaterialApp(
      theme: kTheme(),
      home: Scaffold(
        body: AddSourceBody(
          reader: SourceReader(ocr: _Ocr(ocrText), pdf: _Pdf()),
          generating: false,
          initialPath: path,
          enableDrop: false,
          onGenerate: onGenerate,
        ),
      ),
    );

PillButton _generateButton(WidgetTester t) =>
    t.widget<PillButton>(find.widgetWithText(PillButton, 'Generate study materials'));

void _tall(WidgetTester t) {
  // ListView builds lazily: a tall viewport keeps the Generate button built.
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1000, 2400);
  addTearDown(t.view.reset);
}

void main() {
  testWidgets('no text found: message shown and Generate disabled', (t) async {
    _tall(t);
    await t.pumpWidget(_app('', (_, _, _) {}));
    await t.pumpAndSettle();
    expect(find.textContaining('No text found'), findsOneWidget);
    expect(_generateButton(t).onPressed, isNull);
  });

  testWidgets('typing text enables Generate and passes text, type, path', (t) async {
    _tall(t);
    final sent = <String>[];
    await t.pumpWidget(_app('', (text, type, path) => sent.addAll([text, type, path])));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Cells divide by mitosis');
    await t.pump();
    expect(_generateButton(t).onPressed, isNotNull);
    await t.tap(find.widgetWithText(PillButton, 'Generate study materials'));
    expect(sent, ['Cells divide by mitosis', 'image', 'C:/n/photo.png']);
  });

  testWidgets('unsupported file shows a clear message', (t) async {
    _tall(t);
    await t.pumpWidget(_app('x', (_, _, _) {}, path: 'C:/n/photo.heic'));
    await t.pumpAndSettle();
    expect(find.textContaining('Unsupported file type'), findsOneWidget);
    expect(_generateButton(t).onPressed, isNull);
  });
}
