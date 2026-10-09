import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'ai_engine.dart';

/// Groq could not answer. [cooldown] says whether Groq as a whole looks down (no
/// network, bad key, rate limit, server error) or only this one reply was bad.
class GroqUnavailable implements Exception {
  GroqUnavailable(this.reason, {this.cooldown = true, this.retryAfter});
  final String reason;
  final bool cooldown;
  final Duration? retryAfter;
  @override
  String toString() => 'Groq unavailable: $reason';
}

/// Groq's cloud API (OpenAI-compatible chat completions).
class GroqRuntime implements LlmRuntime {
  static const defaultModel = 'openai/gpt-oss-120b';

  GroqRuntime({
    required this.apiKey,
    this.model = defaultModel,
    this.baseUrl = 'https://api.groq.com/openai/v1',
    this.connectTimeout = const Duration(seconds: 4),
    this.requestTimeout = const Duration(seconds: 60),
  });

  final String apiKey, model, baseUrl;
  final Duration connectTimeout, requestTimeout;

  @override
  Future<String> complete(String prompt, {int maxTokens = 1024, Map<String, Object?>? schema}) =>
      chat([
        {'role': 'user', 'content': prompt},
      ], maxTokens: maxTokens, temperature: 0.3, schema: schema);

  @override
  Future<String> chat(
    List<Map<String, String>> messages, {
    int maxTokens = 512,
    double temperature = 0.5,
    Map<String, Object?>? schema,
  }) async {
    final client = HttpClient()..connectionTimeout = connectTimeout;
    try {
      return await _post(client, messages, maxTokens, temperature, schema).timeout(requestTimeout);
    } on IOException catch (e) {
      throw GroqUnavailable('$e');
    } on TimeoutException {
      throw GroqUnavailable('timed out');
    } on FormatException catch (e) {
      throw GroqUnavailable('bad reply: $e', cooldown: false);
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _post(HttpClient client, List<Map<String, String>> messages, int maxTokens,
      double temperature, Map<String, Object?>? schema) async {
    final req = await client.postUrl(Uri.parse('$baseUrl/chat/completions'));
    req.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    req.write(jsonEncode({
      'model': model,
      'messages': messages,
      'reasoning_effort': 'low', // gpt-oss thinks first; its thinking counts toward the limit
      'max_tokens': maxTokens + 512,
      'temperature': temperature,
      // strict: false is best effort, so the reply is checked again below.
      if (schema != null)
        'response_format': {
          'type': 'json_schema',
          'json_schema': {'name': 'reply', 'strict': false, 'schema': schema},
        },
    }));
    final res = await req.close();
    final body = await utf8.decoder.bind(res).join();
    if (res.statusCode != 200) {
      // A 400 is this one request (such as JSON that failed to validate), not Groq being down.
      final wait = int.tryParse(res.headers.value(HttpHeaders.retryAfterHeader) ?? '');
      throw GroqUnavailable('HTTP ${res.statusCode}',
          cooldown: res.statusCode != 400, retryAfter: wait == null ? null : Duration(seconds: wait));
    }
    final text = jsonDecode(body)['choices'][0]['message']['content'];
    if (text is! String) throw GroqUnavailable('empty reply', cooldown: false);
    if (schema != null) _checkShape(text, schema);
    return text;
  }

  /// The reply must be JSON with the schema's required fields, else the local
  /// model gets this call instead of the engine retrying a drifting reply here.
  void _checkShape(String text, Map<String, Object?> schema) {
    final out = jsonDecode(text);
    final required = schema['required'];
    if (out is! Map || (required is List && required.any((k) => !out.containsKey(k)))) {
      throw GroqUnavailable('reply does not match the schema', cooldown: false);
    }
  }

  @override
  Future<void> dispose() async {}
}

/// Asks Groq while there is a key and a connection, and the local model when
/// there is not. After Groq fails it is left alone for [cooldown], so being
/// offline costs one short wait, not one per question.
class OnlineFirstRuntime implements LlmRuntime {
  OnlineFirstRuntime({
    required this.local,
    required this.apiKey,
    LlmRuntime Function(String key)? online,
    this.localName = 'the local AI',
    this.cooldown = const Duration(seconds: 45),
    DateTime Function()? clock,
  })  : _online = online ?? ((key) => GroqRuntime(apiKey: key)),
        _clock = clock ?? DateTime.now;

  final LlmRuntime local;
  final String localName;
  final String? Function() apiKey;
  final LlmRuntime Function(String key) _online;
  final Duration cooldown;
  final DateTime Function() _clock;
  DateTime? _retryAt;

  bool lastWasOnline = false;

  /// The model behind the last answer, for logs and reports.
  String get lastModel => lastWasOnline ? GroqRuntime.defaultModel : localName;

  Future<T> _run<T>(Future<T> Function(LlmRuntime r) call) async {
    final key = apiKey()?.trim() ?? '';
    final skip = _retryAt != null && _clock().isBefore(_retryAt!);
    if (key.isNotEmpty && !skip) {
      try {
        final out = await call(_online(key));
        lastWasOnline = true;
        return out;
      } on GroqUnavailable catch (e) {
        debugPrint('$e; using the local model');
        if (e.cooldown) _retryAt = _clock().add(e.retryAfter ?? cooldown);
      }
    }
    lastWasOnline = false;
    return call(local);
  }

  @override
  Future<String> complete(String prompt, {int maxTokens = 1024, Map<String, Object?>? schema}) =>
      _run((r) => r.complete(prompt, maxTokens: maxTokens, schema: schema));

  @override
  Future<String> chat(List<Map<String, String>> messages,
          {int maxTokens = 512, double temperature = 0.5, Map<String, Object?>? schema}) =>
      _run((r) => r.chat(messages, maxTokens: maxTokens, temperature: temperature, schema: schema));

  @override
  Future<void> dispose() => local.dispose();
}
