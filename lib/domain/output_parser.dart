import 'dart:convert';

import 'hygiene.dart';
import 'models.dart';

Map<dynamic, dynamic> _jsonObject(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const FormatException('no JSON object in model output');
  }
  final decoded = jsonDecode(raw.substring(start, end + 1));
  if (decoded is! Map) throw const FormatException('JSON is not an object');
  return decoded;
}

/// The model sometimes echoes the format's slots ("<fact 1> The sun..."): strip them.
final _placeholder = RegExp(r'<[^<>]{2,}>');

String _text(Object? v) => v is String ? v.replaceAll(_placeholder, '').trim() : '';

/// Question/answer pairs, one per fact. Throws [FormatException] if none are usable.
List<QaItem> parseQa(String raw) {
  final items = <QaItem>[];
  for (final i in (_jsonObject(raw)['items'] as List? ?? const [])) {
    if (i is! Map) continue;
    final q = _text(i['question']);
    final a = withoutQuestionEcho(cleanAnswer(_text(i['answer'])), q);
    if (q.isNotEmpty && !isPlaceholderAnswer(a)) items.add(QaItem(q, a));
  }
  if (items.isEmpty) throw const FormatException('no question/answer pairs');
  return items;
}

/// The fact check's own answer, or null for "none".
/// Throws [FormatException] if there is no answer.
String? parseCheck(String raw) {
  final a = _text(_jsonObject(raw)['answer']);
  if (a.isEmpty) throw const FormatException('no answer');
  return RegExp(r'^none\.?$', caseSensitive: false).hasMatch(a) ? null : a;
}

/// Wrong answers for quiz choices: one list per question, in order (empty
/// where the model gave none). Throws [FormatException] if there are no items.
List<List<String>> parseWrong(String raw) {
  final items = _jsonObject(raw)['items'] as List? ?? const [];
  if (items.isEmpty) throw const FormatException('no wrong answers');
  return [
    for (final i in items)
      [
        if (i is Map)
          for (final w in (i['wrong'] is List ? i['wrong'] as List : const []))
            if (!isPlaceholderAnswer(_text(w))) _text(w),
      ],
  ];
}
