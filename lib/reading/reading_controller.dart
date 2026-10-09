import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/ai_engine.dart';
import '../data/database.dart';
import 'levels.dart';
import 'reading_repository.dart';
import 'report_pdf.dart';
import 'story_engine.dart';

enum KulayMode { personal, classroom }

/// A story set aside while the reader does something else.
enum Waiting { writing, ready, failed }

/// Which Kulay screen shows. Kept here, not in a Navigator, so leaving Kulay
/// and coming back lands on the same screen with answers intact.
enum KulayScreenId { welcome, readers, home, placement, writing, story, teacher,
  words }

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
  ReadingController({required this.repo, required this.engine, required this.prefs, this.modelName});

  final ReadingRepository repo;
  final StoryEngine engine;
  final SharedPreferences prefs;

  /// The current model's name.
  final String Function()? modelName;

  KulayMode? get mode => KulayMode.values.asNameMap()[prefs.getString('kulay.mode')];
  bool get hasPin => prefs.getString('kulay.pin') != null;

  /// Reading page text size: 0 normal, 1 large, 2 extra large.
  int get textSize => (prefs.getInt('kulay.size') ?? 0).clamp(0, 2);
  double get textScale => const [1.0, 1.2, 1.45][textSize];

  /// Wider, plainer letters (Verdana) for readers who find the normal font hard.
  bool get easyFont => prefs.getBool('kulay.easy') ?? false;

  Future<void> setLook({int? size, bool? easy}) async {
    if (size != null) await prefs.setInt('kulay.size', size);
    if (easy != null) await prefs.setBool('kulay.easy', easy);
    notifyListeners();
  }

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
  int? wpm; // words a minute, if the reader timed this story

  // Trying the missed questions again after a story is scored. Not scored again.
  List<int>? retryOf; // indexes of the questions that were missed
  List<int?> retryAnswers = [];
  bool retryChecked = false;

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

  /// The story the reader asked for, when they left the writing screen before it was done.
  String? waitingTopic;
  var waitingState = Waiting.writing;
  String? _asking; // the topic being written for the screen the reader is looking at

  void _go(KulayScreenId s) {
    if (screen == KulayScreenId.writing && s != KulayScreenId.writing && _asking != null) {
      waitingTopic = _asking;
      waitingState = Waiting.writing;
    }
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
    if (reader?.id != r.id) waitingTopic = null;
    reader = await repo.reader(r.id) ?? r;
    if (!reader!.placed) return startPlacement();
    progress = await repo.progress(reader!);
    _go(KulayScreenId.home);
  }

  void switchReader() {
    reader = null;
    waitingTopic = null;
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
    wpm = null;
    retryOf = null;
    retryChecked = false;
  }

  /// Starts a second try at the questions the reader missed.
  void startRetry() {
    if (result == null) return;
    final s = passage! as Story;
    retryOf = [
      for (final (i, q) in s.questions.indexed)
        if (answers[i] != q.answer) i,
    ];
    retryAnswers = List.filled(retryOf!.length, null);
    retryChecked = false;
    notifyListeners();
  }

  void endRetry() {
    retryOf = null;
    retryChecked = false;
    notifyListeners();
  }

  void chooseRetry(int question, int choice) {
    if (retryChecked) return;
    retryAnswers[question] = choice;
    notifyListeners();
  }

  void checkRetry() {
    retryChecked = true;
    notifyListeners();
  }

  /// Only the missed questions, over the same story.
  Passage get retryPassage {
    final s = passage!;
    return Passage(s.level, s.title, s.paras, [
      for (final i in retryOf!) s.questions[i],
    ]);
  }

  /// A timed reading. Kept only if it is believable (5 to 400 words a minute).
  void setWpm(int? v) {
    wpm = v != null && v >= 5 && v <= 400 ? v : null;
    notifyListeners();
  }

  void choose(int question, int choice) {
    if (checked) return;
    answers[question] = choice;
    notifyListeners();
  }

  bool get allAnswered => answers.every((a) => a != null);

  /// Checks a placement passage: shows what was right, then [nextPlacement] moves on.
  void checkPlacement() {
    if (checked || !allAnswered) return;
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
    final model = modelName?.call();
    if (model != null) engine.modelName = model;
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
    final asked = topic!;
    if (waitingTopic == asked) waitingTopic = null; // reading it now
    notice = null;
    step = 1;
    stepDetail.fillRange(0, 8, '');
    stepDetail[0] = '${levels[r.level].name}, $topic';
    var id = await repo.unread(r.id, r.level, topic);
    final waited = id == null;
    if (id == null) {
      _go(KulayScreenId.writing);
      _asking = asked;
      try {
        id = await _generate(r.level, topic!, Job(Priority.reader), (n, detail) {
          if (screen != KulayScreenId.writing) return;
          step = n;
          stepDetail[n - 1] = detail;
          notifyListeners();
        });
      } on JobCancelled {
        if (_asking == asked) _asking = null;
        return;
      } catch (e) {
        if (_asking == asked) _asking = null;
        if (reader?.id == r.id && screen != KulayScreenId.writing) {
          // The reader is reading something else: tell them when they look up.
          if (waitingTopic == asked) {
            waitingState = Waiting.failed;
            notifyListeners();
          }
          return;
        }
        // AI down or stuck: any saved story at this color.
        id = await repo.unread(r.id, r.level, null) ?? await repo.anyStory(r.level);
        if (id == null) {
          error = e is ModelUnavailableException
              ? 'The AI could not start on this computer, and there are no saved stories for this color yet.'
              : "Couldn't write a story. Try another topic.";
          notifyListeners();
          return;
        }
        notice = e is ModelUnavailableException
            ? 'The AI could not start, so here is a saved story.'
            : 'Here is a ready story while the AI rests.';
      }
    }
    if (_asking == asked) _asking = null;
    // Left the writing screen while waiting: the story is saved, and the reader is told it is ready.
    if (waited && reader?.id == r.id && screen != KulayScreenId.writing) {
      if (waitingTopic == asked) {
        waitingState = Waiting.ready;
        notifyListeners();
      }
      return;
    }
    if (reader?.id != r.id) return;
    final s = (await repo.story(id))!;
    _showPassage(s);
    _go(KulayScreenId.story);
  }

  /// Gives up waiting for the AI: reads a saved story at this color now. The AI
  /// keeps writing in the background, so the story asked for is ready next time.
  Future<void> readSavedInstead() async {
    final r = reader;
    if (r == null || screen != KulayScreenId.writing) return;
    final id = await repo.unread(r.id, r.level, null) ?? await repo.anyStory(r.level);
    if (reader?.id != r.id || screen != KulayScreenId.writing) return; // the reader moved on while we looked
    if (id == null) {
      error = 'There are no saved stories for this color yet. Keep waiting, or pick another topic.';
      notifyListeners();
      return;
    }
    final s = (await repo.story(id))!;
    topic = s.topic; // the story asked for stays in waitingTopic: _go sets it as the screen changes
    notice = 'Here is a saved story. The story you asked for keeps writing. A note will tell you when it is ready.';
    _showPassage(s);
    _go(KulayScreenId.story);
  }

  /// Opens the story that was set aside: at once if it is ready, otherwise the writing screen.
  Future<void> readWaiting() async {
    final t = waitingTopic;
    if (t == null) return;
    waitingTopic = null;
    await readTopic(t);
  }

  void dismissWaiting() {
    waitingTopic = null;
    notifyListeners();
  }

  /// Checks the reader's answers, moves their color, and starts the next story.
  var _submitting = false;

  Future<void> submitStory() async {
    if (result != null || _submitting || !allAnswered) return; // a second tap must not save a second score
    _submitting = true;
    final s = passage! as Story;
    final r = reader!;
    try {
      result = await repo.answer(r, s, [for (final a in answers) a!], wpm: wpm);
    } finally {
      _submitting = false;
    }
    reader = await repo.reader(r.id);
    progress = (up: result!.up, down: result!.down);
    notifyListeners();
    // A teacher's story has no topic to write more of.
    if (!s.byTeacher) _prefetch(r.id, result!.level, s.topic);
  }

  /// Writes the next story before the reader asks for it.
  Future<void> _prefetch(int readerId, int level, String t) async {
    if (await repo.unread(readerId, level, t) != null) return;
    unawaited(_generate(level, t, Job(Priority.background), null).then((_) {}, onError: (_) {}));
  }

  // ---------- word help ----------

  /// Explains a word, and adds it to the reader's My Words.

  Future<({String meaning, String? synonym})> explainWord(String word, String sentence) async {
    final out = await
      engine.explainWord(word, sentence, passage?.level ?? reader?.level ?? 0);
    final r = reader;
    if (r != null) {
      unawaited(
        repo
            .saveWord(r.id, word, out.meaning, out.synonym, sentence)
            .then((_) {}, onError: (_) {}),
      );
    }
    return out;
  }

  // ---------- my words ----------

  void openWords() => _go(KulayScreenId.words);

  Future<List<SavedWord>> myWords() => repo.words(reader!.id);

  Future<void> markWord(int id, {required bool right}) =>
      repo.markWord(id, right: right);

  /// Opens a story the teacher added.
  Future<void> readStoryById(int id) async {
    final s = await repo.story(id);
    if (s == null) return;
    topic = s.topic;
    notice = null;
    _showPassage(s);
    _go(KulayScreenId.story);
  }

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

  /// Saves the class report as a PDF in Documents\Kodigno and opens it in the
  /// computer's PDF viewer. Returns the file path. Throws if the file cannot be written.
  Future<String> saveReport() async {
    final bytes = await buildReportPdf(
      await repo.classReport(),
      classroom: mode == KulayMode.classroom,
      font: await loadReportFont(),
    );
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'Kodigno'),
    );
    await dir.create(recursive: true);
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final file = File(
      p.join(
        dir.path,
        'Kulay report ${d.year}-${two(d.month)}-${two(d.day)}.pdf',
      ),
    );
    await file.writeAsBytes(bytes);
    if (Platform.isWindows && !Platform.environment.containsKey('FLUTTER_TEST')) {
      await Process.start('explorer', [file.path]);
    }
    return file.path;
  }

  Future<void> setReaderLevel(int readerId, int level) async {
    await repo.setLevel(readerId, level);
    readers = await repo.readers();
    if (reader?.id == readerId) reader = await repo.reader(readerId);
    notifyListeners();
  }

  /// The teacher asks for the reading check again. Takes effect when the reader next opens Kulay.
  Future<void> retestReader(int readerId) async {
    await repo.resetPlacement(readerId);
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

  // ---------- teacher's own stories ----------

  /// True while the AI writes questions for a teacher's text.
  bool teacherBusy = false;

  /// The AI writes and checks questions for the teacher's [text], and the story
  /// is saved for readers at its color. Returns an error to show, or null.
  /// [forReader] limits it to one reader, whatever their color; null = everyone at its color.
  Future<String?> addTeacherStory(
    String title,
    String text,
    int? level, {
    int? forReader,
  }) async {
    final t = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return 'Give the story a title.';
    teacherBusy = true;
    notifyListeners();
    try {
      final model = modelName?.call();
      if (model != null) engine.modelName = model;
      final s = await engine.makeTeacherStory(
        t.length > 60 ? t.substring(0, 60) : t,
        text,
        level: level,
        job: Job(Priority.reader),
      );
      if (forReader != null) s.checks['for'] = forReader;
      await repo.saveStory(s, source: 'teacher');
      return null;
    } on StoryFailed catch (e) {
      return e.message;
    } on JobCancelled {
      return 'Stopped.';
    } catch (e) {
      return e is ModelUnavailableException
          ? 'The AI could not start on this computer, so it cannot write questions now.'
          : "Couldn't write questions. Try again.";
    } finally {
      teacherBusy = false;
      notifyListeners();
    }
  }

  /// Stops background writing (app closing or tier change).
  void cancelAll() {
    for (final (job, _) in _pending.values) {
      job.cancelled = true;
    }
  }
}
