import 'dart:io';

import 'model_downloader.dart';
import 'tier.dart';

class ModelManager {
  ModelManager(this.dir, this.downloader);
  final Directory dir;
  final ModelDownloader downloader;

  File fileFor(Tier t) => File('${dir.path}/${t.model}.gguf');
  File _marker(Tier t) => File('${fileFor(t).path}.ok');

  /// Installed only if the checksum-verified marker exists, so a half-written
  /// or deleted model is never treated as ready.
  Future<bool> isInstalled(Tier t) async =>
      await fileFor(t).exists() && await _marker(t).exists();

  /// Deletes model files (and their markers and partial downloads) that belong
  /// to none of [keep], such as a tier that was dropped from the table.
  Future<void> removeUnused(Iterable<Tier> keep) async {
    final names = {for (final t in keep) ...[fileFor(t), _marker(t), File('${fileFor(t).path}.part')].map((f) => f.uri.pathSegments.last)};
    await for (final e in dir.list()) {
      final name = e.uri.pathSegments.last;
      final isModelFile = name.endsWith('.gguf') || name.endsWith('.gguf.ok') || name.endsWith('.gguf.part');
      if (e is File && isModelFile && !names.contains(name)) await e.delete();
    }
  }

  Stream<DownloadProgress> install(Tier t) async* {
    final marker = _marker(t);
    if (await marker.exists()) await marker.delete();
    yield* downloader.download(
        url: Uri.parse(t.url), target: fileFor(t), sha256Hex: t.sha256);
    await marker.writeAsString('ok');
  }
}
