import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/ai/llm_ai_engine.dart';
import 'package:kodigno/models/tier.dart';

import '../helpers/fake_llm_runtime.dart';

const _tier = Tier(
  id: 'low',
  label: 'Basic quality',
  model: 'm',
  url: 'u',
  sha256: 's',
  maxRamMb: 3500,
  sizeMb: 400,
  chunkChars: 800,
  questionsPerChunk: 3,
  cardsPerChunk: 3,
);

const _notes = 'Photosynthesis: plants make sugar from light, water and carbon dioxide. '
    'It happens in the chloroplasts, which contain the green pigment chlorophyll.';

String _section(String heading, String explanation, List<String> points) =>
    '{"heading":"$heading","explanation":"$explanation","keyPoints":[${points.map((p) => '"$p"').join(',')}]}';

const _overview = '{"overview":"This lesson explains how plants use photosynthesis to make sugar from light.",'
    '"takeaways":["Photosynthesis happens in the chloroplasts of plant cells.",'
    '"Plants turn light, water and carbon dioxide into sugar."]}';

final _goodSection = _section(
  'How plants make food',
  'Plants cannot eat, so they build their own sugar. Photosynthesis uses light, water and carbon dioxide, '
      'and it takes place in the chloroplasts where chlorophyll captures the light.',
  ['Photosynthesis happens in the chloroplasts', 'Chlorophyll is the green pigment'],
);

LlmAiEngine _engine(FakeLlmRuntime rt, {int maxChunks = 12}) =>
    LlmAiEngine(rt, _tier, maxChunks: maxChunks);

void main() {
  group('notes without pages', () {
    test('explains each section, then ties them into an overview and takeaways', () async {
      final rt = FakeLlmRuntime([_goodSection, _overview]);
      final progress = <double>[];
      final lesson = await _engine(rt).summarize(_notes, onProgress: progress.add);

      expect(lesson.sections, hasLength(1));
      expect(lesson.sections.first.heading, 'How plants make food');
      expect(lesson.sections.first.keyPoints, ['Photosynthesis happens in the chloroplasts', 'Chlorophyll is the green pigment']);
      expect(lesson.sections.first.terms, isNotEmpty);
      expect(lesson.keyTerms, isNotEmpty);
      expect(lesson.overview, contains('photosynthesis'));
      expect(lesson.takeaways, hasLength(2));
      expect(rt.prompts, hasLength(2));
      expect(rt.prompts.first, contains('Photosynthesis: plants make sugar')); // the core, here all of it
      expect(rt.prompts.first, contains('KEY TERMS:'));
      expect(rt.prompts.last, contains('How plants make food'));
      expect(rt.prompts.last, contains('THE LESSON KEEPS COMING BACK TO:'));
      expect(progress.last, 1);
    });

    test('an explanation copied from the notes is retried', () async {
      final copied = _section('Photosynthesis', '${_notes.split('. ').first.replaceAll('"', '')}.', ['Chloroplasts hold chlorophyll']);
      final rt = FakeLlmRuntime([copied, _goodSection, _overview]);
      final lesson = await _engine(rt).summarize(_notes);
      expect(lesson.sections.single.heading, 'How plants make food');
      expect(rt.prompts, hasLength(3));
    });

    test('an explanation that mostly reuses the slide wording is retried', () async {
      final reworded = _section('Photosynthesis', 'Photosynthesis: plants make sugar from light, water and carbon dioxide and it happens in the chloroplasts.', ['Chloroplasts hold chlorophyll']);
      final rt = FakeLlmRuntime([reworded, _goodSection, _overview]);
      final lesson = await _engine(rt).summarize(_notes);
      expect(lesson.sections.single.heading, 'How plants make food');
      expect(rt.prompts, hasLength(3));
    });

    test('an explanation not based on the notes is retried, then the lesson fails', () async {
      final invented = _section('Volcanoes', 'Volcanoes erupt when magma rises through cracks in the crust of the planet.', ['Magma is molten rock']);
      final rt = FakeLlmRuntime([invented, invented, invented]);
      await expectLater(_engine(rt).summarize(_notes), throwsA(isA<GenerationFailed>()));
    });

    test('a sentence with a year or figure that is not in the notes is dropped', () async {
      final made = _section('Photosynthesis', 'Plants make sugar in the chloroplasts. The process has been studied for over 300 years.', ['Chloroplasts hold chlorophyll']);
      final rt = FakeLlmRuntime([made, _goodSection, _overview]);
      final lesson = await _engine(rt).summarize(_notes);
      // the first answer is left with one short sentence, so it is asked again
      expect(lesson.sections.single.explanation, isNot(contains('300')));
      expect(rt.prompts, hasLength(3));
    });

    test('sentences about the slides themselves are dropped', () async {
      final talk = _section(
        'Photosynthesis',
        'This part introduces the idea of photosynthesis. Plants turn light, water and carbon dioxide into sugar inside the green chloroplasts.',
        ['Chlorophyll is the green pigment'],
      );
      final lesson = await _engine(FakeLlmRuntime([talk, _overview])).summarize(_notes);
      expect(lesson.sections.single.explanation,
          'Plants turn light, water and carbon dioxide into sugar inside the green chloroplasts.');
    });

    test('a sentence that says the opposite of the slide is dropped', () async {
      const flip = 'IT workers are not recognized as professionals because they are not licensed by the state or federal government.\n'
          'Every IT employee still has to respect a professional code of ethics and the policies of the company.';
      final model = _section(
        'Recognition',
        'IT workers are recognized as professionals because they are licensed by the state. Each IT employee must still follow the professional code of ethics at work.',
        ['Every employee follows the code of ethics'],
      );
      const overview = '{"overview":"IT employees follow a professional code of ethics even though IT workers are not licensed professionals.","takeaways":[]}';
      final lesson = await _engine(FakeLlmRuntime([model, overview])).summarize(flip);
      expect(lesson.sections.single.explanation, 'Each IT employee must still follow the professional code of ethics at work.');
    });

    test('key points that are labels, invented, or not in the notes are dropped, and the section is topped up from its own lines', () async {
      final s = _section(
        'How plants make food',
        'Plants build their own sugar using light, water and carbon dioxide in the chloroplasts.',
        [
          'Photosynthesis happens in the chloroplasts',
          'Dinosaurs disappeared sixty million years ago',
          'Photosynthesis And Light Reactions',
          'Plants lived for 400 years in the chloroplasts',
        ],
      );
      final lesson = await _engine(FakeLlmRuntime([s, _overview])).summarize(_notes);
      expect(lesson.sections.single.keyPoints, ['Photosynthesis happens in the chloroplasts', _notes]);
    });

    test('a key point that is a fragment or is cut off is not kept', () async {
      final s = _section(
        'How plants make food',
        'Plants build their own sugar using light, water and carbon dioxide in the chloroplasts.',
        ['one part of the plant holds the green pigment chlorophyll', 'A chloroplast is the organelle that...', 'Chlorophyll is the green pigment'],
      );
      final lesson = await _engine(FakeLlmRuntime([s, _overview])).summarize(_notes);
      expect(lesson.sections.single.keyPoints.first, 'Chlorophyll is the green pigment');
      expect(lesson.sections.single.keyPoints.where((p) => p.startsWith('one part') || p.endsWith('...')), isEmpty);
    });

    test('a rambling heading from the model is replaced by the topic\'s first key phrase', () async {
      final s = _section('A very long rambling heading that goes on and on forever and ever', _goodSection.contains('Plants') ? 'Plants cannot eat, so they build their own sugar. Photosynthesis uses light, water and carbon dioxide, and it takes place in the chloroplasts.' : '', ['Chlorophyll is the green pigment', 'Photosynthesis happens in the chloroplasts']);
      final lesson = await _engine(FakeLlmRuntime([s, _overview])).summarize(_notes);
      expect(lesson.sections.single.heading.split(' ').length, lessThanOrEqualTo(4));
      expect(lesson.sections.single.heading, isNot(contains('rambling')));
    });

    test('malformed output is retried', () async {
      final rt = FakeLlmRuntime(['not json at all', _goodSection, _overview]);
      final lesson = await _engine(rt).summarize(_notes);
      expect(lesson.sections, hasLength(1));
    });

    test('without an overview the lesson still has sections and takeaways from the key points', () async {
      final rt = FakeLlmRuntime([_goodSection, 'nope', 'nope', 'nope']);
      final lesson = await _engine(rt).summarize(_notes);
      expect(lesson.overview, isEmpty);
      expect(lesson.takeaways.first, 'Photosynthesis happens in the chloroplasts');
    });

    test('long notes are spread over the whole document, within maxChunks', () async {
      // Lines that differ only by a number would be dropped as repeated footers.
      final notes = [
        for (final w in ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 'Eta', 'Theta'])
          '$w plants use photosynthesis, with light, water and carbon dioxide, to make sugar in chloroplasts.',
      ].join('\n');
      final section = _section(
        'Making sugar',
        'Photosynthesis lets plants use light, water and carbon dioxide to make sugar inside the chloroplasts.',
        ['Plants make sugar from light'],
      );
      final rt = FakeLlmRuntime([section, section, _overview]);
      final lesson = await _engine(rt, maxChunks: 2).summarize(notes);
      expect(lesson.sections, hasLength(2));
      expect(rt.prompts, hasLength(3)); // two sections and the overview
    });

    test('a model that cannot run is not retried', () async {
      final rt = FakeLlmRuntime([ModelUnavailableException('oom')]);
      await expectLater(_engine(rt).summarize(_notes), throwsA(isA<ModelUnavailableException>()));
      expect(rt.prompts, hasLength(1));
    });
  });

  group('paged slides', () {
    const deck = 'Economic Development\n'
        'The growth of an export economy in 1830 brought increasing prosperity to the Filipino middle and upper classes of the islands.\n'
        'The Rizal family in the 1890s rented over 390 hectares from the hacienda.\n\n'
        'Economic Development\n'
        'Rents were raised often, and friction grew between tenants and landlords as lands grew in value.\n\n'
        'Political Development\n'
        'Filipinos were deprived of the few positions they had held in the bureaucracy while Spanish officials had no interest in the country they governed.\n'
        'Spanish officials hoarded economic resources.';

    final econ = _section(
      'Growth',
      'Exports grew from 1830 and brought prosperity to the Filipino middle and upper classes, though rents on the hacienda rose.',
      ['Exports brought prosperity to the middle and upper classes'],
    );
    final politics = _section(
      'Bureaucracy',
      'Spanish officials had no interest in governing, so Filipinos lost the few bureaucracy positions they had previously held.',
      ['Filipinos were deprived of positions in the bureaucracy'],
    );

    const deckOverview = '{"overview":"This lesson covers how export growth brought prosperity while Filipinos lost bureaucracy positions to Spanish officials.",'
        '"takeaways":["Exports brought prosperity to the Filipino middle and upper classes.",'
        '"Filipinos were deprived of positions in the bureaucracy."]}';

    test('one section per heading, named by the slides, with the dates and figures kept from them', () async {
      final rt = FakeLlmRuntime([econ, politics, deckOverview]);
      final lesson = await _engine(rt).summarize(deck);

      expect(lesson.sections.map((s) => s.heading), ['Economic Development', 'Political Development']);
      expect(lesson.sections.first.facts, [
        'The growth of an export economy in 1830 brought increasing prosperity to the Filipino middle and upper classes of the islands.',
        'The Rizal family in the 1890s rented over 390 hectares from the hacienda.',
      ]);
      expect(lesson.sections.last.facts, isEmpty);
      expect(rt.prompts.first, contains('slides titled "Economic Development"'));
      expect(rt.prompts.first, contains('KEY TERMS:'));
      expect(rt.prompts.first, isNot(contains('Political Development')));
      expect(lesson.toText(), contains('Key facts:'));
    });

    test('the model sees only the most central lines when a topic is longer than its budget', () async {
      const lines = [
        'The export economy of the islands grew quickly after 1830 as farmers sold sugar and tobacco abroad.',
        'Growing exports of sugar and tobacco brought prosperity to the Filipino middle class in the islands.',
        'The export economy needed more rice for the growing population of the islands and its farmers.',
        'Tenants rented farm land from the friar haciendas, and rents on the haciendas rose with land values.',
        'Rising land values and rents caused friction between the tenants and the friar haciendas for years.',
        'The lecturer arrived late and the room was cold that morning, which has nothing to do with it.',
        'Prosperity from the export economy let the middle class send its sons to schools in Manila and Europe.',
        'Farmers who grew sugar and tobacco for export became richer while the friar haciendas gained land.',
      ];
      final big = 'Economic Development\n${lines.join('\n')}\n\n'
          'Economic Development\n'
          'Sugar exports and tobacco exports rose each decade, and the middle class grew richer as exports grew.\n'
          'The friar haciendas raised the rents of the tenants whenever the value of the land went up in the islands.\n\n'
          'Political Development\n'
          'Filipinos were deprived of the few positions they had held in the bureaucracy while Spanish officials had no interest in the country they governed.';
      final rt = FakeLlmRuntime([econ, politics, deckOverview]);
      await _engine(rt).summarize(big);
      // the prompt holds the key terms and a core of at most the tier's budget (800 characters)
      expect(rt.prompts.first.length, lessThan(2800));
      expect(rt.prompts.first, isNot(contains('lecturer')));
      expect(rt.prompts.first, contains('export'));
    });

    test('an overview that repeats a section is asked again', () async {
      const copy = '{"overview":"Exports grew from 1830 and brought prosperity to the Filipino middle and upper classes, though rents on the hacienda rose.","takeaways":[]}';
      const own = '{"overview":"Export growth brought prosperity to many Filipinos, while Spanish officials took no interest in the bureaucracy positions that Filipinos had held.","takeaways":[]}';
      final rt = FakeLlmRuntime([econ, politics, copy, own]);
      final lesson = await _engine(rt).summarize(deck);
      expect(lesson.overview, startsWith('Export growth brought prosperity'));
      expect(rt.prompts, hasLength(4));
    });

    test('a topic the model cannot explain is still in the lesson: its key lines, terms, dates and figures', () async {
      final rt = FakeLlmRuntime(['nope', 'nope', 'nope', politics, deckOverview]);
      final lesson = await _engine(rt).summarize(deck);

      expect(lesson.sections.map((s) => s.heading), ['Economic Development', 'Political Development']);
      final first = lesson.sections.first;
      expect(first.explanation, isEmpty);
      expect(first.facts, hasLength(2));
      expect(first.keyPoints, contains('Rents were raised often, and friction grew between tenants and landlords as lands grew in value.'));
      expect(first.terms, isNotEmpty);
      expect(rt.prompts.last, isNot(contains('Economic Development'))); // the overview skips it
    });
  });
}
