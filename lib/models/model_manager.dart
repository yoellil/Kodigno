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

  Stream<DownloadProgress> install(Tier t) async* {
    final marker = _marker(t);
    if (await marker.exists()) await marker.delete();
    yield* downloader.download(
        url: Uri.parse(t.url), target: fileFor(t), sha256Hex: t.sha256);
    await marker.writeAsString('ok');
  }
}
