import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/ai/llama_server_runtime.dart';

/// In-process stand-in for the llama-server child process.
class _FakeProcess implements Process {
  _FakeProcess._(this._server, {this.exitNow = false}) {
    if (exitNow) _exit.complete(1);
  }
  final HttpServer? _server;
  final bool exitNow;
  final _exit = Completer<int>();
  bool killed = false;

  static Future<_FakeProcess> serve(int port, {Duration loadingFor = Duration.zero}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final started = DateTime.now();
    server.listen((req) async {
      if (req.uri.path == '/health') {
        final ready = DateTime.now().difference(started) >= loadingFor;
        req.response.statusCode = ready ? 200 : 503;
      } else if (req.uri.path == '/v1/chat/completions') {
        final body = jsonDecode(await utf8.decoder.bind(req).join());
        final prompt = body['messages'][0]['content'];
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({
          'choices': [
            {'message': {'content': 'echo:$prompt'}}
          ]
        }));
      } else {
        req.response.statusCode = 404;
      }
      await req.response.close();
    });
    return _FakeProcess._(server);
  }

  static _FakeProcess exited() => _FakeProcess._(null, exitNow: true);

  @override
  Future<int> get exitCode => _exit.future;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    _server?.close(force: true);
    if (!_exit.isCompleted) _exit.complete(0);
    return true;
  }

  @override
  int get pid => 1;
  @override
  Stream<List<int>> get stdout => const Stream.empty();
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  IOSink get stdin => throw UnimplementedError();
}

void main() {
  late File model;
  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('lr');
    addTearDown(() => dir.delete(recursive: true));
    model = File('${dir.path}/m.gguf')..writeAsBytesSync([1]);
  });

  int portOf(List<String> args) => int.parse(args[args.indexOf('--port') + 1]);

  test('starts the server, waits for health, returns completion text', () async {
    late _FakeProcess proc;
    final rt = LlamaServerRuntime(
      serverExe: 'llama-server.exe',
      modelPath: model.path,
      pollInterval: const Duration(milliseconds: 10),
      spawn: (exe, args) async =>
          proc = await _FakeProcess.serve(portOf(args), loadingFor: const Duration(milliseconds: 80)),
    );
    expect(await rt.complete('hi'), 'echo:hi');
    expect(await rt.complete('again'), 'echo:again'); // reuses the same server
    await rt.dispose();
    expect(proc.killed, isTrue);
  });

  test('missing model file throws ModelUnavailableException without spawning', () {
    final rt = LlamaServerRuntime(
      serverExe: 'x',
      modelPath: 'C:/nope/missing.gguf',
      spawn: (_, _) => throw StateError('must not spawn'),
    );
    expect(rt.complete('hi'), throwsA(isA<ModelUnavailableException>()));
  });

  test('server that exits while loading throws ModelUnavailableException', () {
    final rt = LlamaServerRuntime(
      serverExe: 'x',
      modelPath: model.path,
      pollInterval: const Duration(milliseconds: 10),
      spawn: (_, _) async => _FakeProcess.exited(),
    );
    expect(rt.complete('hi'), throwsA(isA<ModelUnavailableException>()));
  });

  test('missing executable throws ModelUnavailableException', () {
    final rt = LlamaServerRuntime(
      serverExe: 'x',
      modelPath: model.path,
      spawn: (_, _) async => throw const ProcessException('x', []),
    );
    expect(rt.complete('hi'), throwsA(isA<ModelUnavailableException>()));
  });

  test('server dying later surfaces as ModelUnavailableException', () async {
    late _FakeProcess proc;
    final rt = LlamaServerRuntime(
      serverExe: 'x',
      modelPath: model.path,
      pollInterval: const Duration(milliseconds: 10),
      spawn: (_, args) async => proc = await _FakeProcess.serve(portOf(args)),
    );
    expect(await rt.complete('ok'), 'echo:ok');
    proc.kill(); // simulates a crash / out-of-memory kill
    await expectLater(rt.complete('again'), throwsA(isA<ModelUnavailableException>()));
  });

  test('bundled() points at llama/llama-server.exe next to the executable', () {
    final rt = LlamaServerRuntime.bundled('m.gguf');
    expect(rt.serverExe, endsWith(p.join('llama', 'llama-server.exe')));
  });
}
