// Renders key screens to PNGs for visual review (not part of the test suite).
// Run: flutter test tool/shots_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/ocr/ocr_service.dart';
import 'package:kodigno/sources/pdf_text.dart';
import 'package:kodigno/sources/source_reader.dart';
import 'package:kodigno/ui/add_source_screen.dart';
import 'package:kodigno/ui/app_shell.dart';
import 'package:kodigno/ui/flash_deck.dart';
import 'package:kodigno/ui/quiz_screen.dart';
import 'package:kodigno/ui/theme.dart';

class _Ocr implements OcrService {
  @override
  Future<String> recognize(String imagePath) async =>
      'Photosynthesis turns light into chemical energy in the chloroplasts.';
}

class _Pdf implements PdfTextExtractor {
  @override
  Future<String> extract(String path) async => '';
}

const _qs = [
  QuizQuestion(
      prompt: 'What is the derivative of sin(x)?',
      choices: ['cos(x)', '-cos(x)', 'tan(x)', '-sin(x)'],
      answerIndex: 0,
      explanation: 'The derivative of sin is cos.'),
  QuizQuestion(prompt: 'Q2?', choices: ['a', 'b'], answerIndex: 1),
  QuizQuestion(prompt: 'Which organelle makes ATP?', choices: ['Nucleus', 'Mitochondria'], answerIndex: 1, explanation: 'Respiration happens there.'),
];

Future<void> _size(WidgetTester t, double w, double h) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = Size(w, h);
  addTearDown(t.view.reset);
}

Widget _app(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kTheme(),
      home: Scaffold(body: home),
    );

Future<void> _loadFonts() async {
  final brico = FontLoader('Bricolage')
    ..addFont(rootBundle.load('assets/fonts/BricolageGrotesque.ttf'));
  await brico.load();
  final icons = File('C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  testWidgets('flashcards front', (t) async {
    await _size(t, 1000, 760);
    await t.pumpWidget(_app(const Padding(
      padding: EdgeInsets.all(28),
      child: FlashDeck(cards: [
        Flashcard(front: 'Chlorophyll', back: 'The green pigment that captures light'),
        Flashcard(front: 'Mitochondria', back: 'Makes ATP'),
        Flashcard(front: 'ATP', back: 'Energy currency of the cell'),
      ]),
    )));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/flash_front.png'));

    await t.tap(find.text('Chlorophyll'));
    await t.pump(); // animation starts
    await t.pump(const Duration(milliseconds: 170)); // mid-flip
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/flash_midflip.png'));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/flash_back.png'));
  });

  testWidgets('quiz question and results', (t) async {
    await _size(t, 1000, 900);
    await t.pumpWidget(_app(QuizBody(title: 'Intro to Calculus', questions: _qs, onFinished: (_, _, _, _) {})));
    await t.pumpAndSettle();
    await t.tap(find.text('cos(x)'));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/quiz_selected.png'));

    await t.pumpWidget(_app(ResultsView(
      questions: _qs,
      results: const [
        {'q': 0, 'chosen': 0, 'correct': true},
        {'q': 1, 'chosen': 1, 'correct': true},
        {'q': 2, 'chosen': 1, 'correct': true},
      ],
      score: 3,
      onRetry: () {},
    )));
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    await t.pump(const Duration(milliseconds: 520)); // confetti mid-air, number rolling
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/results_mid.png'));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/results_end.png'));
  });

  testWidgets('add source with a file loaded', (t) async {
    await _size(t, 1000, 1100);
    await t.pumpWidget(_app(AddSourceBody(
      reader: SourceReader(ocr: _Ocr(), pdf: _Pdf()),
      generating: false,
      initialPath: 'C:/notes/photosynthesis.png',
      enableDrop: false,
      onGenerate: (_, _, _) {},
    )));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/add_source.png'));
  });

  testWidgets('shell wide and narrow', (t) async {
    await _size(t, 1280, 760);
    final tab = ValueNotifier(0);
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: kTheme(),
      home: AppShell(tab: tab, pages: const [
        Center(child: Text('Library page')),
        Center(child: Text('Create page')),
        Center(child: Text('Settings page')),
      ]),
    ));
    await t.pumpAndSettle();
    tab.value = 1;
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/shell_wide.png'));
    await _size(t, 430, 820);
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/shell_narrow.png'));
  });
}
