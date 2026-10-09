import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/domain/card_assist.dart';
import 'package:kodigno/ui/card_editor.dart';
import 'package:kodigno/ui/theme.dart';

Future<void> _pump(WidgetTester t, Widget form) async {
  t.view.devicePixelRatio = 1.0;
  t.view.physicalSize = const Size(900, 900);
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(theme: kTheme(), home: Scaffold(body: SingleChildScrollView(child: form))));
  await t.pumpAndSettle();
}

Finder get _term => find.byKey(const ValueKey('card-term'));
Finder get _def => find.byKey(const ValueKey('card-definition'));
Finder get _askForDefinition => find.byTooltip('Suggest the definition from this term');
Finder get _askForTerm => find.byTooltip('Suggest the term from this definition');
Finder get _save => find.widgetWithText(ElevatedButton, 'Save card').evaluate().isNotEmpty
    ? find.widgetWithText(ElevatedButton, 'Save card')
    : find.text('Save card');

String _text(WidgetTester t, Finder f) => (t.widget<TextField>(f)).controller!.text;

void main() {
  testWidgets('Save needs both sides, then hands over the trimmed text', (t) async {
    String? gotTerm, gotDef;
    await _pump(t, CardEditorForm(onSave: (a, b) async { gotTerm = a; gotDef = b; }, onCancel: () {}));
    await t.tap(_save);
    await t.pump();
    expect(gotTerm, isNull); // nothing typed: disabled

    await t.enterText(_term, '  Mitochondria ');
    await t.pump();
    await t.tap(_save);
    await t.pump();
    expect(gotTerm, isNull); // still one side missing

    await t.enterText(_def, '  Makes ATP.  ');
    await t.pump();
    await t.tap(_save);
    await t.pumpAndSettle();
    expect((gotTerm, gotDef), ('Mitochondria', 'Makes ATP.'));
  });

  testWidgets('Ask AI beside the Term writes the Definition from the term', (t) async {
    final calls = <(AssistField, String, String)>[];
    await _pump(t, CardEditorForm(
      onSave: (a, b) async {},
      onCancel: () {},
      suggest: (want, term, def) async { calls.add((want, term, def)); return const CardSuggestion("The cell's power plant."); },
    ));
    await t.enterText(_term, 'Mitochondria');
    await t.pump();
    expect(find.textContaining('Tap Ask AI above to write the definition'), findsOneWidget);
    await t.tap(_askForDefinition);
    await t.pumpAndSettle();
    expect(calls.single, (AssistField.definition, 'Mitochondria', ''));
    expect(_text(t, _def), "The cell's power plant.");
    expect(_text(t, _term), 'Mitochondria');
  });

  testWidgets('Ask AI beside the Definition writes the Term from the definition', (t) async {
    final calls = <(AssistField, String, String)>[];
    await _pump(t, CardEditorForm(
      onSave: (a, b) async {},
      onCancel: () {},
      suggest: (want, term, def) async { calls.add((want, term, def)); return const CardSuggestion('Mitochondria'); },
    ));
    await t.enterText(_def, 'The powerhouse of the cell.');
    await t.pump();
    await t.tap(_askForTerm);
    await t.pumpAndSettle();
    expect(calls.single, (AssistField.term, '', 'The powerhouse of the cell.'));
    expect(_text(t, _term), 'Mitochondria');
  });

  testWidgets('a suggestion that replaces typed text can be undone', (t) async {
    await _pump(t, CardEditorForm(
      initialTerm: 'Mitochondria',
      initialDefinition: 'my own draft',
      onSave: (a, b) async {},
      onCancel: () {},
      suggest: (want, term, def) async => const CardSuggestion('AI wrote this.'),
    ));
    await t.tap(_askForDefinition);
    await t.pumpAndSettle();
    expect(_text(t, _def), 'AI wrote this.');
    await t.tap(find.text('Undo'));
    await t.pump();
    expect(_text(t, _def), 'my own draft');
    expect(find.text('Undo'), findsNothing);
    expect(find.textContaining('AI suggestion'), findsNothing);
  });

  testWidgets('while the AI thinks both buttons are off; a failure shows its message and keeps the text', (t) async {
    final reply = Completer<String>();
    await _pump(t, CardEditorForm(
      initialTerm: 'Zorblax',
      onSave: (a, b) async {},
      onCancel: () {},
      suggest: (want, term, def) => reply.future.then(CardSuggestion.new),
    ));
    await t.tap(_askForDefinition);
    await t.pump();
    expect(find.text('Thinking…'), findsOneWidget);
    // both Ask AI buttons are disabled while one request is out
    for (final b in t.widgetList<TextButton>(find.byType(TextButton))) {
      if (b.child is Text && (b.child as Text).data == 'Cancel') continue;
      expect(b.onPressed, isNull);
    }
    expect(t.widget<TextField>(_def).readOnly, isTrue); // the AI is writing it

    reply.completeError(CardAssistFailed("The AI wasn't sure about that one."));
    await t.pumpAndSettle();
    expect(find.text("The AI wasn't sure about that one."), findsOneWidget);
    expect(find.text('Thinking…'), findsNothing);
    expect(_text(t, _term), 'Zorblax');
    expect(_text(t, _def), '');
    expect(t.widget<TextField>(_def).readOnly, isFalse);
  });

  testWidgets('an unexpected failure is a plain message, not a crash', (t) async {
    await _pump(t, CardEditorForm(
      initialTerm: 'x',
      onSave: (a, b) async {},
      onCancel: () {},
      suggest: (want, term, def) async => throw StateError('boom'),
    ));
    await t.tap(_askForDefinition);
    await t.pumpAndSettle();
    expect(find.text("Couldn't get a suggestion. Try again."), findsOneWidget);
  });

  testWidgets('a save that fails keeps the form open with a message', (t) async {
    await _pump(t, CardEditorForm(
      initialTerm: 'a',
      initialDefinition: 'b',
      onSave: (a, b) async => throw Exception('disk full'),
      onCancel: () {},
    ));
    await t.tap(_save);
    await t.pumpAndSettle();
    expect(find.text("Couldn't save the card. Try again."), findsOneWidget);
    expect(_text(t, _term), 'a');
  });

  testWidgets('no Ask AI buttons without a model, and Cancel calls back', (t) async {
    var cancelled = false;
    await _pump(t, CardEditorForm(onSave: (a, b) async {}, onCancel: () => cancelled = true));
    expect(find.text('Ask AI'), findsNothing);
    await t.tap(find.text('Cancel'));
    expect(cancelled, isTrue);
  });

  testWidgets('the Add card dialog closes when the card is saved', (t) async {
    String? saved;
    bool? result;
    await t.pumpWidget(MaterialApp(
      theme: kTheme(),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await showAddCardDialog(ctx, onSave: (a, b) async => saved = '$a|$b'),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Add a card'), findsOneWidget);
    await t.enterText(_term, 'Nucleus');
    await t.enterText(_def, 'Holds the DNA.');
    await t.pump();
    await t.tap(_save);
    await t.pumpAndSettle();
    expect(saved, 'Nucleus|Holds the DNA.');
    expect(result, isTrue);
    expect(find.text('Add a card'), findsNothing);
  });

  testWidgets('a suggestion says whether it came from the notes or from the AI\'s own knowledge', (t) async {
    var fromNotes = true;
    await _pump(t, CardEditorForm(
      initialTerm: 'Mercado',
      onSave: (a, b) async {},
      onCancel: () {},
      suggest: (want, term, def) async => CardSuggestion('Market.', fromNotes: fromNotes),
    ));
    await t.tap(_askForDefinition);
    await t.pumpAndSettle();
    expect(find.textContaining('based on your notes'), findsOneWidget);

    fromNotes = false;
    await t.enterText(_def, '');
    await t.tap(_askForDefinition);
    await t.pumpAndSettle();
    expect(find.textContaining('general knowledge, not your notes'), findsOneWidget);
    expect(find.textContaining('based on your notes'), findsNothing);
  });
}
