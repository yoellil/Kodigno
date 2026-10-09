import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ai_engine.dart';

typedef ProcessStarter = Future<Process> Function(
  String exe,
  List<String> args,
);
typedef PidKiller = Future<void> Function(int pid);

/// Kills [pid] only if it is still a llama-server (pids get reused).
Future<void> _killIfLlamaServer(int pid) async {
  if (!Platform.isWindows) return;
  final list = await Process.run('tasklist', [
    '/FI',
    'PID eq $pid',
    '/FO',
    'CSV',
    '/NH',
  ]);
  if ((list.stdout as String).toLowerCase().contains('llama-server')) {
    await Process.run('taskkill', ['/F', '/PID', '$pid']);
  }
}

/// Runs the bundled llama.cpp `llama-server` on 127.0.0.1 and talks to it
/// over HTTP. Loaded lazily on first use and kept alive between calls.
class LlamaServerRuntime implements LlmRuntime {
  LlamaServerRuntime({
    required this.serverExe,
    required this.modelPath,
    this.contextSize = 4096,
    this.startupTimeout = const Duration(minutes: 2),
    this.pollInterval = const Duration(milliseconds: 500),
    this.pidFile,
    ProcessStarter? spawn,
    PidKiller? killPid,
  }) : _spawn = spawn ?? ((exe, args) => Process.start(exe, args)),
       _killPid = killPid ?? _killIfLlamaServer;

  factory LlamaServerRuntime.bundled(String modelPath) {
    final dir = File(Platform.resolvedExecutable).parent.path;
    return LlamaServerRuntime(
      serverExe: p.join(dir, 'llama', 'llama-server.exe'),
      modelPath: modelPath,
      pidFile: p.join(Directory.systemTemp.path, 'kodigno-llama.pid'),
    );
  }

  final String serverExe;
  final String modelPath;
  final int contextSize;
  final Duration startupTimeout;
  final Duration pollInterval;

  /// Where the running server's pid is kept, so a server orphaned by a crash
  /// or a killed app can be stopped on the next start.
  final String? pidFile;
  final ProcessStarter _spawn;
  final PidKiller _killPid;

  Process? _proc;
  int? _port;
  Future<void>? _starting;

  @override
  Future<String> complete(String prompt, {int maxTokens = 1024}) async {
    await _ensureStarted();
    try {
      final (status, body) = await _request(
        _port!,
        'POST',
        '/v1/chat/completions',
        {
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': maxTokens,
          'temperature': 0.3,
        },
      );
      if (status != 200)
        throw ModelUnavailableException('server returned HTTP $status');
      return jsonDecode(body)['choices'][0]['message']['content'] as String;
    } on IOException catch (e) {
      _reset();
      throw ModelUnavailableException('model server stopped: $e');
    }
  }

  Future<void> _ensureStarted() async {
    if (_port != null) return;
    final pending = _starting ??= _launch();
    try {
      await pending;
    } catch (_) {
      _starting = null;
      rethrow;
    }
  }

  Future<void> _launch() async {
    if (!File(modelPath).existsSync()) {
      throw ModelUnavailableException('model file is missing');
    }
    await _killStale();
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();

    final Process proc;
    try {
      proc = await _spawn(serverExe, [
        '-m',
        modelPath,
        '--host',
        '127.0.0.1',
        '--port',
        '$port',
        '-c',
        '$contextSize',
      ]);
    } on ProcessException catch (e) {
      throw ModelUnavailableException(
        'cannot start model server: ${e.message}',
      );
    }
    if (pidFile != null) File(pidFile!).writeAsStringSync('${proc.pid}');
    var exited = false;
    unawaited(proc.exitCode.then((_) => exited = true));
    unawaited(proc.stdout.drain<void>()); // unread pipes can stall the child
    unawaited(proc.stderr.drain<void>());

    final deadline = DateTime.now().add(startupTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (exited) {
        throw ModelUnavailableException(
          'model server exited while loading the model',
        );
      }
      try {
        final (status, _) = await _request(port, 'GET', '/health');
        if (status == 200) {
          _proc = proc;
          _port = port;
          return;
        }
      } on IOException {
        // not listening yet
      }
      await Future<void>.delayed(pollInterval);
    }
    proc.kill();
    throw ModelUnavailableException('model load timed out');
  }

  Future<void> _killStale() async {
    final f = pidFile == null ? null : File(pidFile!);
    if (f == null || !f.existsSync()) return;
    final pid = int.tryParse(f.readAsStringSync().trim());
    if (pid != null) await _killPid(pid);
    f.deleteSync();
  }

  Future<(int, String)> _request(
    int port,
    String method,
    String path, [
    Object? json,
  ]) async {
    final client = HttpClient();
    try {
      final req = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:$port$path'),
      );
      if (json != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(json));
      }
      final res = await req.close();
      return (res.statusCode, await utf8.decoder.bind(res).join());
    } finally {
      client.close(force: true);
    }
  }

  void _reset() {
    _proc?.kill();
    _proc = null;
    if (pidFile != null) {
      try {
        File(pidFile!).deleteSync();
      } on FileSystemException {
        // already gone
      }
    }
    _port = null;
    _starting = null;
  }

  @override
  Future<void> dispose() async => _reset();
}
