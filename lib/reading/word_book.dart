// Offline word meanings for Kulay's word help, from Open English WordNet 2025
// (CC BY 4.0, https://en-word.net). The data is built by tool/build_dictionary.py into one
// gzipped file per first letter, so a lookup reads one small file. No internet.
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/services.dart' show rootBundle;

/// One meaning of a word.
class Meaning {
  const Meaning(this.pos, this.text, this.example, this.synonym);
  final String pos, text, example, synonym;

  factory Meaning.fromJson(List<dynamic> j) => Meaning('${j[0]}', '${j[1]}', '${j[2]}', '${j[3]}');
}

/// Irregular forms that a "-s / -ed / -ing" rule cannot undo.
const _irregular = {
  'am': 'be', 'is': 'be', 'are': 'be', 'was': 'be', 'were': 'be', 'been': 'be', 'being': 'be',
  'has': 'have', 'had': 'have', 'does': 'do', 'did': 'do', 'done': 'do', 'goes': 'go', 'went': 'go', 'gone': 'go',
  'saw': 'see', 'seen': 'see', 'took': 'take', 'taken': 'take', 'gave': 'give', 'given': 'give', 'made': 'make',
  'came': 'come', 'got': 'get', 'gotten': 'get', 'said': 'say', 'knew': 'know', 'known': 'know', 'thought': 'think',
  'told': 'tell', 'found': 'find', 'bought': 'buy', 'brought': 'bring', 'caught': 'catch', 'taught': 'teach',
  'ran': 'run', 'sat': 'sit', 'stood': 'stand', 'ate': 'eat', 'eaten': 'eat', 'drank': 'drink', 'drunk': 'drink',
  'began': 'begin', 'begun': 'begin', 'wrote': 'write', 'written': 'write', 'spoke': 'speak', 'spoken': 'speak',
  'broke': 'break', 'broken': 'break', 'chose': 'choose', 'chosen': 'choose', 'fell': 'fall', 'fallen': 'fall',
  'flew': 'fly', 'flown': 'fly', 'grew': 'grow', 'grown': 'grow', 'drew': 'draw', 'drawn': 'draw', 'threw': 'throw',
  'thrown': 'throw', 'wore': 'wear', 'worn': 'wear', 'won': 'win', 'swam': 'swim', 'swum': 'swim', 'sang': 'sing',
  'sung': 'sing', 'rang': 'ring', 'rung': 'ring', 'kept': 'keep', 'left': 'leave', 'felt': 'feel', 'met': 'meet',
  'lost': 'lose', 'built': 'build', 'sent': 'send', 'spent': 'spend', 'slept': 'sleep', 'held': 'hold', 'heard': 'hear',
  'paid': 'pay', 'laid': 'lay', 'led': 'lead', 'sold': 'sell', 'understood': 'understand', 'forgot': 'forget',
  'forgotten': 'forget', 'hid': 'hide', 'hidden': 'hide', 'rose': 'rise', 'risen': 'rise', 'shook': 'shake',
  'shaken': 'shake', 'woke': 'wake', 'woken': 'wake', 'dug': 'dig', 'hung': 'hang', 'fed': 'feed', 'fought': 'fight',
  'swept': 'sweep', 'wept': 'weep', 'bent': 'bend', 'lit': 'light', 'stuck': 'stick', 'struck': 'strike', 'stole': 'steal',
  'stolen': 'steal', 'rode': 'ride', 'ridden': 'ride', 'drove': 'drive', 'driven': 'drive', 'blew': 'blow', 'blown': 'blow',
  'children': 'child', 'men': 'man', 'women': 'woman', 'feet': 'foot', 'teeth': 'tooth', 'mice': 'mouse', 'geese': 'goose',
  'people': 'person', 'leaves': 'leaf', 'lives': 'life', 'wives': 'wife', 'knives': 'knife', 'wolves': 'wolf',
  'shelves': 'shelf', 'loaves': 'loaf', 'halves': 'half', 'better': 'good', 'best': 'good', 'worse': 'bad', 'worst': 'bad',
};

/// The dictionary forms a word might come from, most likely first: "walked" -> walk, "stories" -> story.
List<String> baseForms(String word) {
  final w = word.toLowerCase();
  final out = <String>[];
  void add(String f) {
    if (f.length >= 3 && f != w && !out.contains(f)) out.add(f);
  }

  final irregular = _irregular[w];
  if (irregular != null) out.add(irregular); // "is" -> "be" is short but right
  String undouble(String s) => s.length > 3 && s[s.length - 1] == s[s.length - 2] && !'aeiouls'.contains(s[s.length - 1]) ? s.substring(0, s.length - 1) : s;
  if (w.endsWith('ies')) add('${w.substring(0, w.length - 3)}y');
  if (w.endsWith('ied')) add('${w.substring(0, w.length - 3)}y');
  if (w.endsWith('ier')) add('${w.substring(0, w.length - 3)}y');
  if (w.endsWith('iest')) add('${w.substring(0, w.length - 4)}y');
  if (w.endsWith('ily')) add('${w.substring(0, w.length - 3)}y');
  if (w.endsWith('ing')) {
    final stem = w.substring(0, w.length - 3);
    add(undouble(stem));
    add('${undouble(stem)}e');
  }
  if (w.endsWith('ed')) {
    final stem = w.substring(0, w.length - 2);
    add(undouble(stem));
    add('${stem}e');
  }
  if (w.endsWith('es')) add(w.substring(0, w.length - 2));
  if (w.endsWith('s') && !w.endsWith('ss')) add(w.substring(0, w.length - 1));
  if (w.endsWith('est')) {
    final stem = w.substring(0, w.length - 3);
    add(undouble(stem));
    add('${stem}e');
  }
  if (w.endsWith('er')) {
    final stem = w.substring(0, w.length - 2);
    add(undouble(stem));
    add('${stem}e');
  }
  if (w.endsWith('ly')) add(w.substring(0, w.length - 2));
  return out;
}

/// Reads the dictionary files from the app's assets. [load] is replaced in tests.
class WordBook {
  WordBook({Future<List<int>> Function(String path)? load}) : _load = load ?? _fromAssets;

  final Future<List<int>> Function(String path) _load;
  final _shards = <String, Future<Map<String, List<Meaning>>>>{};

  static Future<List<int>> _fromAssets(String path) async => (await rootBundle.load(path)).buffer.asUint8List();

  Future<Map<String, List<Meaning>>> _shard(String letter) => _shards.putIfAbsent(letter, () async {
        try {
          final raw = jsonDecode(utf8.decode(gzip.decode(await _load('assets/kulay/dict/$letter.json.gz')))) as Map<String, dynamic>;
          return {
            for (final e in raw.entries) e.key: [for (final m in e.value as List) Meaning.fromJson(m as List)],
          };
        } catch (_) {
          return const {}; // a missing file only means no meaning from the book: the AI is asked instead
        }
      });

  Future<List<Meaning>> _entry(String word) async {
    if (!RegExp(r'^[a-z]').hasMatch(word)) return const [];
    return (await _shard(word[0]))[word] ?? const [];
  }

  /// Up to [max] meanings of [word]: its own entry first, then the entry of the form it comes from
  /// ("saw" gives the tool and "see").
  Future<List<Meaning>> lookup(String word, {int max = 5}) async {
    final w = word.toLowerCase().replaceAll(RegExp(r"^[^a-z]+|[^a-z]+$"), '');
    if (w.isEmpty) return const [];
    final out = <Meaning>[];
    final seen = <String>{};
    void take(List<Meaning> list, int n) {
      for (final m in list.take(n)) {
        if (seen.add(m.text) && out.length < max) out.add(m);
      }
    }

    final own = await _entry(w);
    // "saw", "left", "felt": mostly the verb, so the form it comes from goes first.
    final irregular = _irregular.containsKey(w);
    if (!irregular) take(own, 3);
    var bases = 0;
    for (final b in baseForms(w)) {
      final e = await _entry(b);
      if (e.isEmpty) continue;
      take(e, irregular ? 3 : own.isEmpty ? 4 : 2);
      if (++bases == 2) break;
    }
    if (irregular) take(own, 2);
    return out;
  }
}
