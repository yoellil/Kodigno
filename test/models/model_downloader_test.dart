import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/models/model_downloader.dart';

void main() {
  final data = Uint8List.fromList(List.generate(300000, (i) => i % 251));
  final hash = sha256.convert(data).toString();
  late HttpServer server;
  late Directory dir;
  String? lastRange;
  var dropAfter = -1; // bytes to send before killing the connection; -1 = never

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('dl');
    lastRange = null;
    dropAfter = -1;
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      lastRange = req.headers.value(HttpHeaders.rangeHeader);
      var start = 0;
      if (lastRange != null) {
        start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(lastRange!)!.group(1)!);
        if (start >= data.length) {
          req.response.statusCode = 416; // range not satisfiable
          await req.response.close();
          return;
        }
        req.response.statusCode = 206;
      }
      final body = data.sublist(start);
      if (dropAfter >= 0) {
        // Promise the full body, send part of it, then kill the socket.
        final socket = await req.response.detachSocket(writeHeaders: false);
        const crlf = [13, 10];
        socket.add([
          ...ascii.encode('HTTP/1.1 ${req.response.statusCode} OK'), ...crlf,
          ...ascii.encode('content-length: ${body.length}'), ...crlf, ...crlf,
        ]);
        socket.add(body.sublist(0, dropAfter));
        await socket.flush();
        socket.destroy();
        return;
      }
      req.response.contentLength = body.length;
      req.response.add(body);
      await req.response.close();
    });
  });
  tearDown(() async {
    await server.close(force: true);
    await dir.delete(recursive: true);
  });

  Uri url() => Uri.parse('http://127.0.0.1:${server.port}/m.gguf');

  test('downloads and verifies checksum', () async {
    final target = File('${dir.path}/m.gguf');
    final events = await ModelDownloader()
        .download(url: url(), target: target, sha256Hex: hash)
        .toList();
    expect(events.last.received, data.length);
    expect(await target.readAsBytes(), data);
    expect(File('${target.path}.part').existsSync(), isFalse);
  });

  test('checksum mismatch throws and removes the partial file', () async {
    final target = File('${dir.path}/m.gguf');
    await expectLater(
        ModelDownloader().download(url: url(), target: target, sha256Hex: 'bad').drain(),
        throwsA(isA<ChecksumMismatch>()));
    expect(target.existsSync(), isFalse);
    expect(File('${target.path}.part').existsSync(), isFalse);
  });

  test('a .part file that already holds every byte is verified, not re-requested', () async {
    final target = File('${dir.path}/m.gguf');
    await File('${target.path}.part').writeAsBytes(data);
    await ModelDownloader().download(url: url(), target: target, sha256Hex: hash).drain();
    expect(await target.readAsBytes(), data);
  });

  test('resumes from an existing .part file using a Range header', () async {
    final target = File('${dir.path}/m.gguf');
    await File('${target.path}.part').writeAsBytes(data.sublist(0, 1000));
    await ModelDownloader()
        .download(url: url(), target: target, sha256Hex: hash)
        .drain();
    expect(lastRange, 'bytes=1000-');
    expect(await target.readAsBytes(), data);
  });

  test('connection dropped mid-download throws and keeps the .part file', () async {
    dropAfter = 5000;
    final target = File('${dir.path}/m.gguf');
    await expectLater(
        ModelDownloader().download(url: url(), target: target, sha256Hex: hash).drain(),
        throwsA(anything));
    expect(File('${target.path}.part').existsSync(), isTrue);
    expect(target.existsSync(), isFalse);
  });
}
