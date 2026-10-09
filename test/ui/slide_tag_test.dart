import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/models.dart';
import 'package:kodigno/domain/source_ref.dart';
import 'package:kodigno/ui/flash_deck.dart';
import 'package:kodigno/ui/quiz_screen.dart';
import 'package:kodigno/ui/slide_tag.dart';
import 'package:kodigno/ui/source_viewer_screen.dart';
import 'package:kodigno/ui/theme.dart';

const _quote = 'A patent permits its owner to exclude the public from making, using, or selling a protected invention.';
const _pages = [
  PageText(5, 'Patents\n- $_quote'),
  PageText(7, 'Trade Secrets\n- Business information that is generally unknown to the public and kept confidential.'),
];

Future<void> _pump(WidgetTester t, Widget child) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(1000, 1000);
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(theme: kTheme(), home: Scaffold(body: child)));
}

Widget _scoped(Widget child, {List<String> paths = const []}) =>
    SourceScope(title: 'Module 3', paths: paths, pages: _pages, child: child);

SourceRef _ref(SourceKind kind, {List<int> pages = const [5], double score = 0.6}) =>
    SourceRef(kind: kind, pages: pages, score: score, quote: _quote);

Future<void> _viewer(WidgetTester t, SourceRef ref, {List<String> paths = const []}) => _pump(
    t, SourceViewerScreen(source: ref, title: 'Module 3', paths: paths, pages: _pages));

void main() {
  group('SlideTag', () {
    testWidgets('says which slide, and how sure that is', (t) async {
      await _pump(t, Column(children: [
        SlideTag(_ref(SourceKind.copied, pages: [3])),
        SlideTag(_ref(SourceKind.explained, pages: [5, 6])),
        SlideTag(_ref(SourceKind.unmatched, pages: [9])),
      ]));
      expect(find.text('Slide 3'), findsOneWidget);
      expect(find.text('Slide 5, 6'), findsOneWidget);
      expect(find.text('No match'), findsOneWidget); // flagged, not hidden
    });

    testWidgets('a tag with no scope does nothing when tapped', (t) async {
      await _pump(t, SlideTag(_ref(SourceKind.copied)));
      await t.tap(find.byType(SlideTag));
      await t.pumpAndSettle();
      expect(find.byType(SourceViewerScreen), findsNothing);
    });

    testWidgets('tapped inside a scope, it opens the slide', (t) async {
      await _pump(t, _scoped(SlideTag(_ref(SourceKind.copied))));
      await t.tap(find.byType(SlideTag));
      await t.pumpAndSettle();
      expect(find.byType(SourceViewerScreen), findsOneWidget);
      expect(find.text('Slide 5 of Module 3'), findsOneWidget);
    });
  });

  group('SourceViewerScreen', () {
    testWidgets('copied text: green banner, the page text, the quote highlighted', (t) async {
      await _viewer(t, _ref(SourceKind.copied, score: 1));
      expect(find.text('Copied word for word from this slide.'), findsOneWidget);
      expect(find.text('Slide 5 of Module 3'), findsOneWidget);
      expect(find.textContaining('The original file is not available', findRichText: true), findsOneWidget);
      final text = t.widget<SelectableText>(find.byType(SelectableText));
      final spans = text.textSpan!.children!.cast<TextSpan>();
      expect(spans.any((s) => s.text == _quote.replaceAll(' invention.', ' invention') && s.style?.backgroundColor != null), isTrue);
    });

    testWidgets('AI-written text says how alike it is and that the line shown is the closest', (t) async {
      await _viewer(t, _ref(SourceKind.explained, score: 0.53));
      expect(find.textContaining('Written by the AI from this slide (53% alike)'), findsOneWidget);
    });

    testWidgets('text no slide supports well is flagged, and still shows the closest slide', (t) async {
      await _viewer(t, _ref(SourceKind.unmatched, score: 0.12));
      expect(find.textContaining('No slide supports this well'), findsOneWidget);
      expect(find.textContaining('Check it yourself'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('text with nothing like it says so plainly', (t) async {
      await _viewer(t, const SourceRef(kind: SourceKind.unmatched));
      expect(find.textContaining('No slide supports this. Check it against your own notes.'), findsOneWidget);
      expect(find.textContaining('Nothing in your file looks like this'), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing);
    });

    testWidgets('several slides can be stepped through', (t) async {
      await _viewer(t, _ref(SourceKind.explained, pages: [5, 7]));
      expect(find.text('Slide 5 of Module 3'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
      expect(t.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_back)).onPressed, isNull);
      await t.tap(find.byTooltip('Next slide'));
      await t.pumpAndSettle();
      expect(find.text('Slide 7 of Module 3'), findsOneWidget);
      expect(find.textContaining('Trade Secrets', findRichText: true), findsOneWidget);
      expect(t.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_forward)).onPressed, isNull);
    });

    testWidgets('a file that has moved falls back to the page text without failing', (t) async {
      await _viewer(t, _ref(SourceKind.copied), paths: ['C:/moved/away/Module 3.pdf']);
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.textContaining('The original file is not available', findRichText: true), findsOneWidget);
    });
  });

  group('where the tags appear', () {
    testWidgets('a missed quiz question can be traced to its slide', (t) async {
      await _pump(
          t,
          _scoped(QuizBody(
            title: 'Patents',
            questions: [
              QuizQuestion(
                prompt: 'Who may sell a patented invention?',
                choices: const ['only the owner', 'anyone'],
                answerIndex: 0,
                explanation: _quote,
                source: _ref(SourceKind.copied, score: 1),
              ),
            ],
            onFinished: (_, _, _, _) {},
          )));
      await t.tap(find.text('anyone')); // wrong on purpose
      await t.pump();
      await t.tap(find.text('Finish'));
      await t.pumpAndSettle();
      expect(find.text('review these'), findsOneWidget);
      // the question's own tag, and the answer's tag under "where your pick came from"
      expect(find.text('Slide 5'), findsNWidgets(2));
      expect(find.text('WHERE YOUR PICK CAME FROM'), findsOneWidget);
      expect(find.text('You picked "anyone", which is not in your slides, so it may have been a guess.'), findsOneWidget);
      await t.tap(find.text('Slide 5').first);
      await t.pumpAndSettle();
      expect(find.text('Slide 5 of Module 3'), findsOneWidget);
    });

    testWidgets('a quiz question with no source shows no tag', (t) async {
      await _pump(
          t,
          QuizBody(
            title: 'Patents',
            questions: const [QuizQuestion(prompt: 'Q?', choices: ['right', 'wrong'], answerIndex: 0, explanation: 'Because.')],
            onFinished: (_, _, _, _) {},
          ));
      await t.tap(find.text('wrong'));
      await t.pump();
      await t.tap(find.text('Finish'));
      await t.pumpAndSettle();
      expect(find.byType(SlideTag), findsNothing);
    });

    testWidgets('a flashcard shows where its answer comes from once it is turned over', (t) async {
      await _pump(
          t,
          _scoped(FlashDeck(cards: [
            Flashcard(front: 'What is a patent?', back: 'A right to exclude others', source: _ref(SourceKind.explained)),
          ])));
      expect(find.byType(SlideTag), findsNothing); // the answer is not showing yet
      await t.tap(find.text('Flip'));
      await t.pumpAndSettle();
      expect(find.text('Slide 5'), findsOneWidget);
    });

    testWidgets('a flashcard with no source shows no tag', (t) async {
      await _pump(t, const FlashDeck(cards: [Flashcard(front: 'Q', back: 'A')]));
      await t.tap(find.text('Flip'));
      await t.pumpAndSettle();
      expect(find.byType(SlideTag), findsNothing);
    });
  });
}
