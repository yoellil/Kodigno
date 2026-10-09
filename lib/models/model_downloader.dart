import 'dart:io';

import 'package:crypto/crypto.dart';

class DownloadProgress {
  const DownloadProgress(this.received, this.total);
  final int received;
  final int total;
  double get fraction => total == 0 ? 0 : received / total;
}

class ChecksumMismatch implements Exception {
  @override
  String toString() => 'Downloaded model failed its integrity check.';
}

class ModelDownloader {
  /// Downloads [url] to [target] via `<target>.part`, resuming if a partial
  /// file exists, and verifies SHA-256 before the final rename.
  Stream<DownloadProgress> download({
    required Uri url,
    required File target,
    required String sha256Hex,
  }) async* {
    final part = File('${target.path}.part');
    final have = await part.exists() ? await part.length() : 0;
    final client = HttpClient();
    try {
      final req = await client.getUrl(url);
      if (have > 0) req.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
      final res = await req.close();
      if (res.statusCode != 200 && res.statusCode != 206) {
        throw HttpException('HTTP ${res.statusCode}', uri: url);
      }
      final resumed = res.statusCode == 206;
      final start = resumed ? have : 0;
      final total = start + res.contentLength;
      final sink = part.openWrite(mode: resumed ? FileMode.append : FileMode.write);
      var received = start;
      try {
        await for (final chunk in res) {
          sink.add(chunk);
          received += chunk.length;
          yield DownloadProgress(received, total);
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }
    final digest = await sha256.bind(part.openRead()).first;
    if (digest.toString() != sha256Hex) {
      await part.delete();
      throw ChecksumMismatch();
    }
    await part.rename(target.path);
  }
}
