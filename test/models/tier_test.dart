import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/models/tier.dart';

const _json = '''
{"tiers":[
 {"id":"low","label":"Basic quality","maxRamMb":3500,"model":"q05","url":"http://x/a","sha256":"aa","sizeMb":400,"chunkChars":800,"questionsPerChunk":3,"cardsPerChunk":3},
 {"id":"standard","label":"Standard","maxRamMb":7000,"model":"q15","url":"http://x/b","sha256":"bb","sizeMb":1000,"chunkChars":1500,"questionsPerChunk":5,"cardsPerChunk":5},
 {"id":"high","label":"High quality","maxRamMb":null,"model":"q3","url":"http://x/c","sha256":"cc","sizeMb":2000,"chunkChars":2500,"questionsPerChunk":8,"cardsPerChunk":8}
]}''';

void main() {
  final table = TierTable.fromJson(_json);

  test('pick by RAM', () {
    expect(table.pick(2048).id, 'low');
    expect(table.pick(3499).id, 'low');
    expect(table.pick(3500).id, 'standard');
    expect(table.pick(6999).id, 'standard');
    expect(table.pick(7000).id, 'high');
    expect(table.pick(16000).id, 'high');
  });

  test('lower tier for fallback', () {
    expect(table.lower(table.byId('high'))!.id, 'standard');
    expect(table.lower(table.byId('standard'))!.id, 'low');
    expect(table.lower(table.byId('low')), isNull);
  });

  test('storage check needs 25% headroom', () {
    final std = table.byId('standard');
    expect(table.fitsStorage(std, 1249), isFalse);
    expect(table.fitsStorage(std, 1250), isTrue);
  });

  test('bundled tier config has real checksums', () {
    final real = TierTable.fromJson(File('assets/model_tiers.json').readAsStringSync());
    expect(real.tiers.map((t) => t.id), ['standard']);
    expect(real.pick(2048).id, 'standard'); // Standard is the default whatever the RAM
    expect(real.pick(32000).id, 'standard');
    for (final t in real.tiers) {
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(t.sha256), isTrue, reason: t.id);
    }
  });
}
