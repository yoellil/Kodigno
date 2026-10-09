import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/ai_engine.dart';
import '../data/database.dart';
import 'levels.dart';
import 'reading_repository.dart';
import 'story_engine.dart';

enum KulayMode { personal, classroom }

/// Which Kulay screen shows. Kept here, not in a Navigator, so leaving Kulay
/// and coming back lands on the same screen with answers intact.
enum KulayScreenId { welcome, readers, home, placement, writing, story, teacher }

const stepNames = [
  'Choose color and topic',
  'AI writes the story',
  'Check 1: does the story make sense, at the right level?',
  'Number every sentence, find the people and places',
  'AI writes questions',
  'Check 2: is every answer in the story?',
  'Mix up the choices and save',
  'Your turn to read',
];

/// All Kulay state: mode, readers, the screen, the story being read, and the
/// next story being written in the background.
class ReadingController extends ChangeNotifier {
  ReadingController({required this.repo, required this.engine, required this.prefs, this.tierInfo});

  final ReadingRepository repo;
  final StoryEngine engine;
  final SharedPreferences prefs;

  /// The current model tier. Basic (0.5B) writes fewer drafts, then falls back to a saved story.
  final ({bool basic, String model}) Function()? tierInfo;

  KulayMode? get mode => KulayMode.values.asNameMap()[prefs.getString('kulay.mode')];
  bool get hasPin => prefs.getString('kulay.pin') != null;

  var screen = KulayScreenId.welcome;
  List<Reader> readers = [];
  Reader? reader;
  ({int up, int down}) progress = (up: 0, down: 0);
  String? error;

  // Placement
  int placementIndex = 0;
  int? placedLevel;

  // Writing
  String? topic;
  int step = 0;
  final stepDetail = List<String>.filled(8, '');
  String? notice;

  // Reading
  Passage? passage; // a Story, or a placement passage
  List<int?> answers = [];
  AnswerResult? result; // set once a story is checked
  List<bool>? placementRight; // set once a placement passage is checked
  bool get checked => result != null || placementRight != null;

  final _pending = <String, (Job, Future<int>)>{};
  var _opened = false;

  /// First open: copies starter stories in and picks the first screen.
  Future<void> open({String? starters}) async {
    if (_opened) return;
    _opened = true;
    if (starters != null) await repo.loadStarters(starters);
    readers = await repo.readers();
    if (mode == null) {
      screen = KulayScreenId.welcome;
    } else if (mode == KulayMode.personal && readers.isNotEmpty) {
      await pickReader(readers.first);
      return;
    } else {
      screen = mode == KulayMode.personal ? KulayScreenId.welcome : KulayScreenId.readers;
    }
    notifyListeners();
  }

  void _go(KulayScreenId s) {
    screen = s;
    error = null;
    notifyListeners();
  }

  Future<void> setMode(KulayMode m) async {
    await prefs.setString('kulay.mode', m.name);
    readers = await repo.readers();
    if (m == KulayMode.personal && readers.isNotEmpty) return pickReader(reader ?? readers.first);
    _go(m == KulayMode.personal ? KulayScreenId.welcome : KulayScreenId.readers);
  }

  // ---------- readers ----------

  /// Adds a reader and starts their reading check. Returns an error to show, or null.
  Future<String?> addReader(String name) async {
    try {
      final r = await repo.addReader(name);
      readers = await repo.readers();
      await pickReader(r);
      return null;
    } on DuplicateReader catch (e) {
      return e.toString();
    } on ArgumentError catch (e) {
      return '${e.message}';
    }
  }

  Future<void> pickReader(Reader r) async {
    reader = await repo.reader(r.id) ?? r;
    if (!reader!.placed) return startPlacement();
    progress = await repo.progress(reader!);
    _go(KulayScreenId.home);
  }

  void switchReader() {
    reader = null;
    _go(mode == KulayMode.classroom ? KulayScreenId.readers : KulayScreenId.welcome);
  }

  Future<void> goHome() async {
    if (reader == null) return switchReader();
    await pickReader(reader!);
  }

  // ---------- placement ----------

  void startPlacement() {
    placementIndex = 0;
    placedLevel = null;
    _showPassage(placement[0]);
    _go(KulayScreenId.placement);
  }

  void _showPassage(Passage p) {
    passage = p;
    answers = List.filled(p.questions.length, null);
    result = null;
    placementRight = null;
  }

  void choose(int question, int choice) {
    if (checked) return;
    answers[question] = choice;
    notifyListeners();
  }

  bool get allAnswered => answers.every((a) => a != null);

  /// Checks a placement passage: shows what was right, then [nextPlacement] moves on.
  void checkPlacement() {
    final p = passage!;
    placementRight = [for (final (i, q) in p.questions.indexed) answers[i] == q.answer];
    final passed = placementRight!.where((x) => x).length >= 2;
    placedLevel = placementStep(placementIndex, passed).level;
    notifyListeners();
  }

  Future<void> nextPlacement() async {
    if (placedLevel != null) {
      await repo.setLevel(reader!.id, placedLevel!);
      reader = await repo.reader(reader!.id);
      readers = await repo.readers();
      progress = (up: 0, down: 0);
      passage = null;
      _go(KulayScreenId.home);
      return;
    }
    placementIndex++;
    _showPassage(placement[placementIndex]);
    _go(KulayScreenId.placement);
  }

  // ---------- stories ----------

  String _key(int level, String topic) => '$level|${topic.toLowerCase()}';

  /// Writes a story in the background unless one is already being written.
  /// [job] priority can be raised later.
  Future<int> _generate(int level, String topic, Job job, OnStep? onStep) {
    final key = _key(level, topic);
    final running = _pending[key];
    if (running != null) {
      if (job.priority < running.$1.priority) running.$1.priority = job.priority;
      onStep?.call(2, 'This story is already being written. Almost ready.');
      return running.$2;
    }
    final tier = tierInfo?.call();
    engine.maxDrafts = tier?.basic ?? false ? 3 : 4;
    if (tier != null) engine.modelName = tier.model;
    final future = engine
        .makeStory(level, topic, job: job, onStep: onStep)
        .then((s) => repo.saveStory(s))
        .whenComplete(() => _pending.remove(key));
    _pending[key] = (job, future);
    return future;
  }

  /// Opens a story on [t]: a ready one at once, otherwise the AI writes it while the 8 steps show.
  Future<void> readTopic(String t) async {
    final r = reader!;
    topic = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (topic!.isEmpty) return;
    if (topic!.length > 40) topic = topic!.substring(0, 40);
    notice = null;
    step = 1;
    stepDetail.fillRange(0, 8, '');
    stepDetail[0] = '${levels[r.level].name}, $topic';
    var id = await repo.unread(r.id, r.level, topic);
    final waited = id == null;
    if (id == null) {
      _go(KulayScreenId.writing);
      try {
        id = await _generate(r.level, topic!, Job(Priority.reader), (n, detail) {
          if (screen != KulayScreenId.writing) return;
          step = n;
          stepDetail[n - 1] = detail;
          notifyListeners();
        });
      } on JobCancelled {
        return;
      } catch (e) {
        // AI down or stuck: any saved story at this color.
        id = await repo.unread(r.id, r.level, null) ?? await repo.anyStory(r.level);
        if (id == null) {
          error = e is ModelUnavailableException
              ? 'The AI could not start on this computer, and there are no saved stories for this color yet. Try Basic quality in Settings.'
              : "Couldn't write a story. Try another topic.";
          notifyListeners();
          return;
        }
        notice = e is ModelUnavailableException
            ? 'The AI could not start, so here is a saved story. If this keeps happening, choose Basic quality in Settings.'
            : 'Here is a ready story while the AI rests.';
      }
    }
    // Left the writing screen while waiting: the story stays saved for later.
    if (reader?.id != r.id || (waited && screen != KulayScreenId.writing)) return;
    final s = (await repo.story(id))!;
    _showPassage(s);
    _go(KulayScreenId.story);
  }

  /// Checks the reader's answers, moves their color, and starts the next story.
  Future<void> submitStory() async {
    final s = passage! as Story;
    final r = reader!;
    result = await repo.answer(r, s, [for (final a in answers) a!]);
    reader = await repo.reader(r.id);
    progress = (up: result!.up, down: result!.down);
    notifyListeners();
    _prefetch(r.id, result!.level, s.topic);
  }

  /// Writes the next story before the reader asks for it.
  Future<void> _prefetch(int readerId, int level, String t) async {
    if (await repo.unread(readerId, level, t) != null) return;
    unawaited(_generate(level, t, Job(Priority.background), null).then((_) {}, onError: (_) {}));
  }

  // ---------- word help ----------

  Future<({String meaning, String? synonym})> explainWord(String word, String sentence) =>
      engine.explainWord(word, sentence, passage?.level ?? reader?.level ?? 0);

  // ---------- teacher ----------

  static String _hash(String pin) => sha256.convert(utf8.encode('kulay:$pin')).toString();

  /// Sets the PIN the first time, then checks it. True opens the teacher view.
  Future<bool> unlockTeacher(String pin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return false;
    final saved = prefs.getString('kulay.pin');
    if (saved == null) await prefs.setString('kulay.pin', _hash(pin));
    if (saved != null && saved != _hash(pin)) return false;
    _go(KulayScreenId.teacher);
    return true;
  }

  /// Personal mode: the progress view needs no PIN.
  void openTeacher() => _go(KulayScreenId.teacher);

  Future<ClassReport> classReport() => repo.classReport();

  Future<void> setReaderLevel(int readerId, int level) async {
    await repo.setLevel(readerId, level);
    readers = await repo.readers();
    if (reader?.id == readerId) reader = await repo.reader(readerId);
    notifyListeners();
  }

  Future<void> deleteReader(int readerId) async {
    await repo.deleteReader(readerId);
    readers = await repo.readers();
    if (reader?.id == readerId) reader = null;
    notifyListeners();
  }

  /// Stops background writing (app closing or tier change).
  void cancelAll() {
    for (final (job, _) in _pending.values) {
      job.cancelled = true;
    }
  }
}
