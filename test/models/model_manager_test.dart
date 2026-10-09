import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/models/model_downloader.dart';
import 'package:kodigno/models/model_manager.dart';
import 'package:kodigno/models/tier.dart';

class _FakeDownloader extends ModelDownloader {
  _FakeDownloader({this.fail = false});
  final bool fail;
  @override
  Stream<DownloadProgress> download({
    required Uri url, required File target, required String sha256Hex,
  }) async* {
    await target.writeAsBytes([1, 2, 3]);
    if (fail) throw const SocketException('offline');
    yield DownloadProgress(3, 3);
  }
}

const _tier = Tier(
  id: 'low', label: 'l', model: 'tiny', url: 'http://x/y', sha256: 'aa',
  maxRamMb: null, sizeMb: 1, chunkChars: 1, questionsPerChunk: 1, cardsPerChunk: 1,
);

void main() {
  test('not installed until install completes (marker written last)', () async {
    final dir = await Directory.systemTemp.createTemp('mm');
    addTearDown(() => dir.delete(recursive: true));

    final failing = ModelManager(dir, _FakeDownloader(fail: true));
    await expectLater(failing.install(_tier).drain(), throwsA(isA<SocketException>()));
    expect(await failing.isInstalled(_tier), isFalse); // file exists, marker does not

    final ok = ModelManager(dir, _FakeDownloader());
    await ok.install(_tier).drain();
    expect(await ok.isInstalled(_tier), isTrue);
  });

  test('removeUnused deletes files of a tier that is gone, and keeps the current one', () async {
    final dir = await Directory.systemTemp.createTemp('mm');
    addTearDown(() => dir.delete(recursive: true));
    final m = ModelManager(dir, _FakeDownloader());
    await m.install(_tier).drain();
    for (final n in ['old.gguf', 'old.gguf.ok', 'old.gguf.part', 'notes.txt']) {
      File('${dir.path}/$n').writeAsStringSync('x');
    }
    await m.removeUnused([_tier]);
    final left = [for (final e in dir.listSync()) e.uri.pathSegments.last]..sort();
    expect(left, ['notes.txt', 'tiny.gguf', 'tiny.gguf.ok']);
    expect(await m.isInstalled(_tier), isTrue);
  });
}
