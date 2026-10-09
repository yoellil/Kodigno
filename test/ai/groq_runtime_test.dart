import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kodigno/ai/ai_engine.dart';
import 'package:kodigno/ai/groq_runtime.dart';

class _Local implements LlmRuntime {
  int calls = 0;
  @override
  Future<String> complete(String prompt, {int maxTokens = 1024, Map<String, Object?>? schema}) async {
    calls++;
    return 'local';
  }

  @override
  Future<String> chat(List<Map<String, String>> messages,
      {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema}) async {
    calls++;
    return 'local';
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  late HttpServer server;
  late String baseUrl;
  var status = 200;
  var hits = 0;
  var reply = 'groq';
  Map<String, String> headers = {};
  Map<String, dynamic>? lastBody;
  String? lastAuth;

  setUp(() async {
    status = 200;
    hits = 0;
    reply = 'groq';
    headers = {};
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${server.port}/openai/v1';
    server.listen((req) async {
      hits++;
      lastAuth = req.headers.value(HttpHeaders.authorizationHeader);
      lastBody = jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
      req.response.statusCode = status;
      headers.forEach(req.response.headers.set);
      req.response.write(jsonEncode({
        'choices': [
          {'message': {'content': reply}},
        ],
      }));
      await req.response.close();
    });
  });
  tearDown(() => server.close(force: true));

  OnlineFirstRuntime make(_Local local, {String? key = 'gsk_x', Duration cooldown = const Duration(seconds: 45), DateTime Function()? clock}) =>
      OnlineFirstRuntime(
        local: local,
        apiKey: () => key,
        online: (k) => GroqRuntime(apiKey: k, baseUrl: baseUrl),
        cooldown: cooldown,
        clock: clock,
      );

  test('GroqRuntime sends the key and the messages, and returns the reply', () async {
    final out = await GroqRuntime(apiKey: 'gsk_x', baseUrl: baseUrl).complete('hi');
    expect(out, 'groq');
    expect(lastAuth, 'Bearer gsk_x');
    expect(lastBody!['messages'].last['content'], 'hi');
  });

  test('a schema is sent as json_schema, and a reply that fits it is returned', () async {
    reply = '{"a":"x"}';
    final schema = {'type': 'object', 'required': ['a']};
    expect(await GroqRuntime(apiKey: 'k', baseUrl: baseUrl).complete('hi', schema: schema), reply);
    expect(lastBody!['response_format']['type'], 'json_schema');
    expect(lastBody!['response_format']['json_schema']['schema'], schema);
  });

  test('a reply that is not JSON, or lacks a required field, goes to the local model without a cooldown', () async {
    final schema = {'type': 'object', 'required': ['a']};
    final local = _Local();
    final rt = make(local);
    reply = 'not json';
    expect(await rt.complete('1', schema: schema), 'local');
    reply = '{"b":1}';
    expect(await rt.complete('2', schema: schema), 'local');
    reply = '{"a":1}';
    expect(await rt.complete('3', schema: schema), '{"a":1}'); // Groq was not benched
    expect(hits, 3);
  });

  test('one HTTP 400 uses the local model for that call only', () async {
    final local = _Local();
    final rt = make(local);
    status = 400;
    expect(await rt.complete('a'), 'local');
    status = 200;
    expect(await rt.complete('b'), 'groq');
  });

  test('429 waits as long as Retry-After says', () async {
    var now = DateTime(2026, 10, 10, 12);
    final rt = make(_Local(), clock: () => now);
    status = 429;
    headers = {'retry-after': '120'};
    await rt.complete('a');
    status = 200;
    now = now.add(const Duration(seconds: 60));
    expect(await rt.complete('b'), 'local'); // longer than the usual 45s
    now = now.add(const Duration(seconds: 61));
    expect(await rt.complete('c'), 'groq');
  });

  test('lastModel names who answered', () async {
    final rt = OnlineFirstRuntime(
        local: _Local(), localName: 'tiny', apiKey: () => null, online: (k) => GroqRuntime(apiKey: k, baseUrl: baseUrl));
    await rt.complete('a');
    expect(rt.lastModel, 'tiny');
  });

  test('online: Groq answers and the local model is not touched', () async {
    final local = _Local();
    expect(await make(local).complete('hi'), 'groq');
    expect(local.calls, 0);
  });

  test('no key: the local model answers and Groq is not asked', () async {
    final local = _Local();
    expect(await make(local, key: '  ').complete('hi'), 'local');
    expect(hits, 0);
  });

  test('offline (nothing listening): the local model answers', () async {
    await server.close(force: true);
    final local = _Local();
    expect(await make(local).complete('hi'), 'local');
  });

  test('after a failure Groq is left alone until the cooldown ends, then tried again', () async {
    var now = DateTime(2026, 10, 10, 12);
    final local = _Local();
    final rt = make(local, clock: () => now);
    status = 429;
    expect(await rt.complete('a'), 'local');
    expect(hits, 1);
    status = 200;
    expect(await rt.complete('b'), 'local'); // still cooling down
    expect(hits, 1);
    now = now.add(const Duration(seconds: 46));
    expect(await rt.complete('c'), 'groq');
    expect(rt.lastWasOnline, isTrue);
  });

  test('a bad key (401) falls back to the local model', () async {
    status = 401;
    final local = _Local();
    expect(await make(local).chat([
      {'role': 'user', 'content': 'hi'},
    ]), 'local');
  });
}
