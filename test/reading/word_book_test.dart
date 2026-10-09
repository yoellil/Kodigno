import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/reading/story_engine.dart';
import 'package:kodigno/reading/word_book.dart';

import 'story_engine_test.dart' show ScriptedRuntime;

/// The real dictionary files, read from disk.
WordBook realBook() => WordBook(load: (path) async => File(path).readAsBytes());

void main() {
  group('baseForms', () {
    test('undoes -s, -ed, -ing, -er, -est, -ly and the usual irregulars', () {
      expect(baseForms('stories'), contains('story'));
      expect(baseForms('boxes'), contains('box'));
      expect(baseForms('walked'), contains('walk'));
      expect(baseForms('liked'), contains('like'));
      expect(baseForms('stopped'), contains('stop'));
      expect(baseForms('running'), contains('run'));
      expect(baseForms('making'), contains('make'));
      expect(baseForms('happier'), contains('happy'));
      expect(baseForms('quickly'), contains('quick'));
      expect(baseForms('saw'), ['see']);
      expect(baseForms('children'), ['child']);
      expect(baseForms('Cats'), contains('cat')); // any case
      expect(baseForms('is'), ['be']);
    });
  });

  group('WordBook, with the real dictionary', () {
    final book = realBook();

    test('a plain word has real meanings, most common first', () async {
      final m = await book.lookup('beginning');
      expect(m, isNotEmpty);
      expect(m.first.text, contains('start'));
      expect((await book.lookup('brave')).first.text, contains('courage'));
    });

    test('an inflected word finds its base word, and an irregular one finds both', () async {
      expect((await book.lookup('walked')).map((m) => m.pos), contains('verb'));
      final saw = await book.lookup('saw');
      expect(saw.first.pos, 'verb'); // "saw" is mostly the past of "see"...
      expect(saw.first.text, contains('sight'));
      expect(saw.any((m) => m.text.contains('toothed')), isTrue, reason: '...but the tool is still offered');
      expect((await book.lookup('stories')).isNotEmpty, isTrue);
    });

    test('words and punctuation: quotes and commas around a word are ignored, unknown words are empty', () async {
      expect(await book.lookup('"brave,"'), isNotEmpty);
      expect(await book.lookup('barangay'), isEmpty); // Filipino words are not in WordNet: the AI is asked
      expect(await book.lookup('123'), isEmpty);
      expect(await book.lookup(''), isEmpty);
    });

    test('meanings about sex and slurs are not in the book', () async {
      for (final w in ['adultery', 'fornication', 'intercourse']) {
        expect((await book.lookup(w)).where((m) => RegExp(r'sex', caseSensitive: false).hasMatch(m.text)), isEmpty, reason: w);
      }
      expect((await book.lookup('affair')).any((m) => m.text.contains('sexual')), isFalse);
    });

    test('the default book reads the files bundled with the app', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect((await WordBook().lookup('brave')).first.text, contains('courage'));
    });

    test('a missing file means no meanings, not a crash', () async {
      final broken = WordBook(load: (_) async => throw const FileSystemException('gone'));
      expect(await broken.lookup('brave'), isEmpty);
    });

    test('every letter has a file, and the whole book is small', () {
      var total = 0;
      for (final c in 'abcdefghijklmnopqrstuvwxyz'.split('')) {
        final f = File('assets/kulay/dict/$c.json.gz');
        expect(f.existsSync(), isTrue, reason: c);
        total += f.lengthSync();
      }
      expect(total, lessThan(4 * 1024 * 1024));
    });
  });

  group('word help in the engine', () {
    test('the AI only picks which real meaning fits the sentence', () async {
      final rt = ScriptedRuntime((system, user) => jsonEncode({'choice': 2}));
      final engine = StoryEngine(() async => rt, book: realBook(), random: Random(1));
      final all = await realBook().lookup('beginning');
      final help = await engine.explainWord('beginning', 'The beginning of the story was quiet.', 3);
      expect(rt.calls.single, contains('1. (${all[0].pos}) ${all[0].text}'));
      expect(help.meaning, startsWith(all[1].text[0].toUpperCase() + all[1].text.substring(1)));
      expect(help.meaning.split('\n').first, endsWith('.')); // a closing period is added
    });

    test('with no AI the most common meaning is shown, from the book', () async {
      final rt = ScriptedRuntime((_, _) => throw ModelUnavailableException('down'));
      final help = await StoryEngine(() async => rt, book: realBook()).explainWord('brave', 'Mika was brave.', 2);
      expect(help.meaning, contains('courage'));
    });

    test('a nonsense answer from the AI falls back to the first meaning', () async {
      final rt = ScriptedRuntime((_, _) => jsonEncode({'choice': 99}));
      final first = (await realBook().lookup('brave')).first;
      final help = await StoryEngine(() async => rt, book: realBook()).explainWord('brave', 'Mika was brave.', 2);
      expect(help.meaning, startsWith(first.text.substring(0, 20)[0].toUpperCase() + first.text.substring(1, 20)));
    });

    test('a word with one meaning needs no AI call at all', () async {
      final rt = ScriptedRuntime((_, _) => throw StateError('should not be asked'));
      final one = await realBook().lookup('basketball'); // two meanings, so check a rare one instead
      final help = await StoryEngine(() async => rt, book: realBook()).explainWord('accost', 'He tried to accost her.', 3);
      expect(one, isNotEmpty);
      expect(help.meaning, startsWith('Speak to someone'));
      expect(rt.calls, isEmpty);
    });

    test('a word the book does not have is explained by the AI, and a bare synonym is not shown', () async {
      var asked = 0;
      final rt = ScriptedRuntime((_, user) {
        asked++;
        return jsonEncode({'meaning': 'A small local district', 'synonym': 'bulacan'});
      });
      final help = await StoryEngine(() async => rt, book: realBook()).explainWord('barangay', 'The barangay held a fiesta.', 3);
      expect(asked, 1);
      expect(help.meaning, 'A small local district');

      final junk = ScriptedRuntime((_, _) => jsonEncode({'meaning': 'a barangay is a barangay', 'synonym': 'bulacan'}));
      await expectLater(StoryEngine(() async => junk, book: realBook()).explainWord('barangay', 'The barangay held a fiesta.', 3), throwsA(isA<StoryFailed>()));
    });
  });
}
