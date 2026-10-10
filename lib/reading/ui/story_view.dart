import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../ui/theme.dart';
import '../levels.dart';
import '../reading_repository.dart';

/// Kulay's own dark mode, a reading-look setting. Kulay's colors are read as
/// it builds: KulayScreen sets this from the saved setting and rebuilds the
/// whole of Kulay when it flips.
bool kulayDark = false;

/// Kulay's colors, after JIM's Kulay screen, with a dark version of each.
Color get kIndigo => kulayDark ? const Color(0xFF1C1736) : const Color(0xFF3A2C82); // the frame
Color get kIndigoText => kulayDark ? const Color(0xFFE2DCFF) : const Color(0xFF2E2378); // headings, icons
Color get kSoft => kulayDark ? const Color(0xFFADA6D2) : const Color(0xFF55507A); // quieter text
Color get kPaper => kulayDark ? const Color(0xFF29243F) : const Color(0xFFF6F4FB); // fields, chips
Color get kLine => kulayDark ? const Color(0xFF3D3757) : const Color(0xFFE3E0EF);
Color get kGood => kulayDark ? const Color(0xFF6BD69B) : const Color(0xFF1E7A46);
Color get kBad => kulayDark ? const Color(0xFFFF8F86) : const Color(0xFFB3261E);
Color get kMark => kulayDark ? const Color(0xFF6A5820) : const Color(0xFFFFE58A); // proof highlight
Color get kCard => kulayDark ? const Color(0xFF16132A) : Colors.white; // the page itself
Color get kInk => kulayDark ? const Color(0xFFECE8F8) : const Color(0xFF1C1A2E); // story and answer text
Color get kAccent => kulayDark ? const Color(0xFF6C5AE0) : const Color(0xFF2E2378); // filled buttons (white text)
Color get kSpeaking => kulayDark ? const Color(0xFF33406E) : const Color(0xFFD6E4FF); // sentence being read aloud

// ---------- read aloud: a neural voice (Piper) that runs on this computer, no internet ----------

/// Reads text aloud with the bundled Piper voice. Piper turns one line of text into a
/// WAV file; Windows' own `PlaySound` plays it. The next sentence is made while the
/// current one plays, so there is no gap. [available] is false off Windows,
/// in tests, or when `piper/` was not bundled next to the app.
class Speaker {
  Speaker._();
  static final instance = Speaker._();

  final speaking = ValueNotifier<int?>(null); // sentence index being read
  bool available = false;
  Process? _piper;
  StreamIterator<String>? _piperOut;
  Completer<void>? _playing;
  Future<bool> _boot = Future.value(false);
  Future<void> _synthLine = Future.value(); // piper answers one line at a time
  double _pace = 1.12; // piper length_scale: bigger is slower
  int _run = 0;

  // winmm PlaySoundW: plays a WAV file in the background; a null name stops it.
  static final _playSound = DynamicLibrary.open('winmm.dll')
      .lookupFunction<Int32 Function(Pointer<Utf16>, IntPtr, Uint32), int Function(Pointer<Utf16>, int, int)>('PlaySoundW');
  static const _sndFilenameAsync = 0x20000 | 0x1 | 0x2; // SND_FILENAME | SND_ASYNC | SND_NODEFAULT

  Future<bool> _ensure(double pace) => _boot = _boot.then((_) => _bring(pace));

  Future<bool> _bring(double pace) async {
    if (!Platform.isWindows || Platform.environment.containsKey('FLUTTER_TEST')) return false;
    if (_piper != null && pace != _pace) {
      _piper!.kill();
      _piper = _piperOut = null;
    }
    _pace = pace;
    try {
      if (_piper == null) {
        final dir = path.join(File(Platform.resolvedExecutable).parent.path, 'piper');
        final out = Directory(path.join(Directory.systemTemp.path, 'kodigno-voice'))..createSync(recursive: true);
        final ps = await Process.start(
            path.join(dir, 'piper.exe'),
            ['-m', path.join(dir, 'en_US-ljspeech-medium.onnx'), '--output_dir', out.path, '--length_scale', '$pace'],
            workingDirectory: dir);
        unawaited(ps.stderr.drain<void>());
        unawaited(ps.exitCode.then((_) {
          if (identical(_piper, ps)) _piper = _piperOut = null;
        }));
        _piperOut = StreamIterator(ps.stdout.transform(utf8.decoder).transform(const LineSplitter()));
        _piper = ps;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks once whether this computer can read aloud (and warms the voice up).
  Future<void> init() async => available = await _ensure(_pace);

  /// Makes a WAV file for [text]; null if the voice failed.
  Future<String?> _synth(String text) {
    final f = _synthLine.then((_) async {
      final ps = _piper, out = _piperOut;
      if (ps == null || out == null) return null;
      final line = text.replaceAll(RegExp(r'[“”]'), '"').replaceAll(RegExp(r'[‘’]'), "'").replaceAll(RegExp(r'\s+'), ' ');
      try {
        ps.stdin.add(utf8.encode('$line\n'));
        await ps.stdin.flush();
        return await out.moveNext() ? out.current.trim() : null;
      } catch (_) {
        return null;
      }
    });
    _synthLine = f.then<void>((_) {});
    return f;
  }

  /// Plays a WAV file, then deletes it. Returns when it ends or [stop] cuts it off.
  Future<void> _play(String file) async {
    try {
      final wav = await File(file).readAsBytes();
      // 44-byte header; byte rate sits at offset 28. The clip is as long as its data at that rate.
      final secs = (wav.length - 44) / ByteData.sublistView(wav).getUint32(28, Endian.little);
      final done = _playing = Completer<void>();
      final name = file.toNativeUtf16();
      _playSound(name, 0, _sndFilenameAsync);
      calloc.free(name);
      Timer(Duration(milliseconds: (secs * 1000).round() + 60), () {
        if (!done.isCompleted) done.complete();
      });
      await done.future;
    } catch (_) {
    } finally {
      _drop(file);
    }
  }

  void _drop(String? file) {
    if (file != null) File(file).delete().ignore();
  }

  /// Speaks [text] and returns when it is done (or stopped).
  Future<void> say(String text) async {
    if (!await _ensure(_pace)) return;
    final file = await _synth(text);
    if (file != null) await _play(file);
  }

  /// One word, cutting off anything being read.
  Future<void> sayWord(String word) async {
    stop();
    await say(word);
  }

  /// Reads the story one sentence at a time. [paragraphStarts] are sentence indexes that
  /// open a new paragraph; the reader takes a longer breath before them.
  Future<void> readAll(List<String> sentences, {required bool young, Set<int> paragraphStarts = const {}}) async {
    stop();
    final run = _run;
    if (sentences.isEmpty || !await _ensure(young ? 1.3 : 1.12) || run != _run) return;
    Future<String?>? ahead = _synth(sentences[0]);
    for (var i = 0; i < sentences.length; i++) {
      final file = await ahead;
      ahead = i + 1 < sentences.length ? _synth(sentences[i + 1]) : null;
      if (run != _run) {
        _drop(file);
        break;
      }
      if (file == null) continue;
      speaking.value = i;
      await _play(file);
      if (run == _run && i + 1 < sentences.length) {
        await Future<void>.delayed(Duration(milliseconds: paragraphStarts.contains(i + 1) ? 600 : 220));
      }
    }
    if (ahead != null) unawaited(ahead.then(_drop));
    if (run == _run) speaking.value = null;
  }

  /// Stops at once. The voice stays loaded.
  void stop() {
    _run++;
    speaking.value = null;
    final playing = _playing;
    if (playing == null) return;
    _playing = null;
    _playSound(nullptr, 0, 0);
    if (!playing.isCompleted) playing.complete();
  }
}

// ---------- pieces ----------

/// The easy-read look: Verdana, with a little more room between letters and words.
TextStyle readFont(TextStyle s, bool easy) => easy
    ? s.copyWith(fontFamily: 'Verdana', letterSpacing: 0.4, wordSpacing: 2)
    : s;

class LevelChip extends StatelessWidget {
  const LevelChip(this.level, {super.key, this.big = false});
  final int level;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final l = levels[level];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 14 : 10, vertical: big ? 6 : 3),
      decoration: BoxDecoration(color: l.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(l.name, style: body(big ? 18 : 13, weight: FontWeight.w800, color: l.fg)),
    );
  }
}

class KButton extends StatelessWidget {
  const KButton(this.label, {super.key, required this.onTap, this.ghost = false, this.small = false});
  final String label;
  final VoidCallback? onTap;
  final bool ghost, small;

  @override
  Widget build(BuildContext context) {
    final pad = small ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9) : const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final style = body(small ? 13 : 15, weight: FontWeight.w700, color: ghost ? kIndigoText : Colors.white);
    return ghost
        ? OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
                padding: pad, shape: StadiumBorder(), side: BorderSide(color: kIndigoText, width: 1.5), foregroundColor: kIndigoText),
            child: Text(label, style: style))
        : FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
                padding: pad, shape: const StadiumBorder(), backgroundColor: kAccent, disabledBackgroundColor: kLine),
            child: Text(label, style: style));
  }
}

// ---------- the story card ----------

/// Title band, read-aloud, and the story with tappable words. Sentences in
/// [proof] are highlighted (the ones that hold a missed answer).
class StoryCard extends StatefulWidget {
  const StoryCard({super.key, required this.passage, required this.label, required this.onWord, this.proof = const {},
    this.easy = false});
  final bool easy;
  final Passage passage;
  final String label;
  final Set<int> proof;
  final Future<({String meaning, String? synonym})> Function(String word, String sentence) onWord;

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  final _speaker = Speaker.instance;
  var _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _speaker.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _speaker.stop();
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _wordTapped(String word, String sentence, Offset at) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      // showGeneralDialog does not carry this page's theme, so pass it on.
      pageBuilder: (ctx, _, _) =>
          Theme(data: Theme.of(context), child: _WordPop(word: word, at: at, meaning: widget.onWord(word, sentence), speaker: _speaker)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.passage;
    final l = levels[p.level];
    final size = p.level < 2 ? 22.0 : p.level < 4 ? 20.0 : 18.0;
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers = [];
    final sentences = p.sentences;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kLine)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: l.bg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(children: [
            Text('${l.name}  ·  Grades ${l.grades}', style: body(13, weight: FontWeight.w800, color: l.fg)),
            const Spacer(),
            Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis, style: body(13, weight: FontWeight.w600, color: l.fg))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: ValueListenableBuilder<int?>(
            valueListenable: _speaker.speaking,
            builder: (context, speaking, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, style: display(30, color: kIndigoText)),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (_speaker.available)
                  KButton(speaking == null ? 'Listen to the story' : 'Stop reading',
                      small: true,
                      ghost: true,
                      onTap: () => speaking == null
                          ? _speaker.readAll(sentences,
                              young: p.level < 2, paragraphStarts: {for (var i = 1; i < p.paras.length; i++) _index(i, 0)})
                          : _speaker.stop()),
                Text('Tap a word to see what it means.', style: body(13, color: kSoft)),
              ]),
              const SizedBox(height: 16),
              for (final (pi, para) in p.paras.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text.rich(
                    TextSpan(children: [
                      for (final (si, s) in para.indexed) ...[
                        if (si > 0) const TextSpan(text: ' '),
                        _sentence(s, _index(pi, si), speaking),
                      ],
                    ]),
                    style: readFont( body(size, weight: FontWeight.w500, color: kInk).copyWith(height: 1.6),
                          widget.easy),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  int _index(int para, int sentence) {
    var n = 0;
    for (var i = 0; i < para; i++) {
      n += widget.passage.paras[i].length;
    }
    return n + sentence;
  }

  TextSpan _sentence(String s, int i, int? speaking) {
    final bg = speaking == i
        ? kSpeaking
        : widget.proof.contains(i)
            ? kMark
            : null;
    // Lowercase words of 3+ letters can be tapped (capitalized ones are mostly names and places).
    final parts = <InlineSpan>[];
    var last = 0;
    for (final m in RegExp(r"[A-Za-z][A-Za-z'’-]*").allMatches(s)) {
      if (m.start > last) parts.add(TextSpan(text: s.substring(last, m.start)));
      final w = m[0]!;
      if (canExplain(w)) {
        Offset at = Offset.zero;
        final r = TapGestureRecognizer()
          ..onTapDown = ((d) => at = d.globalPosition)
          ..onTap = () => _wordTapped(w, s, at);
        _recognizers.add(r);
        parts.add(TextSpan(text: w, recognizer: r, mouseCursor: SystemMouseCursors.help));
      } else {
        parts.add(TextSpan(text: w));
      }
      last = m.end;
    }
    if (last < s.length) parts.add(TextSpan(text: s.substring(last)));
    return TextSpan(children: parts, style: bg == null ? null : TextStyle(backgroundColor: bg));
  }
}

/// Small helper words are not tappable: the AI explains them badly ("about" came back as
/// "concern") and a reader learns nothing from them.
const _helperWords = {
  'about', 'above', 'across', 'after', 'again', 'all', 'also', 'always', 'among', 'and', 'any', 'are', 'around', 'been', 'before',
  'being', 'below', 'between', 'both', 'but', 'can', 'could', 'did', 'does', 'done', 'down', 'during', 'each', 'else', 'enough', 'even',
  'ever', 'every', 'for', 'from', 'had', 'has', 'have', 'her', 'here', 'hers', 'him', 'his', 'how', 'however', 'into', 'its', 'just',
  'many', 'may', 'might', 'more', 'most', 'much', 'must', 'never', 'not', 'now', 'off', 'often', 'once', 'only', 'onto', 'other', 'our',
  'out', 'over', 'own', 'same', 'shall', 'she', 'should', 'since', 'some', 'such', 'than', 'that', 'the', 'their', 'them', 'then',
  'there', 'these', 'they', 'this', 'those', 'through', 'too', 'under', 'until', 'upon', 'very', 'was', 'were', 'what', 'when', 'where',
  'which', 'while', 'who', 'whom', 'whose', 'why', 'will', 'with', 'within', 'without', 'would', 'yet', 'you', 'your',
};

/// Words a reader can tap for help: lowercase, 3+ letters, and not a small helper word.
/// (Capitalized words are mostly names and places.)
bool canExplain(String w) => w.length >= 3 && RegExp('^[a-z]').hasMatch(w) && !_helperWords.contains(w.toLowerCase());

final _popButton = TextButton.styleFrom(foregroundColor: kIndigoText, textStyle: body(14, weight: FontWeight.w700));

class _WordPop extends StatelessWidget {
  const _WordPop({required this.word, required this.at, required this.meaning, required this.speaker});
  final String word;
  final Offset at;
  final Future<({String meaning, String? synonym})> meaning;
  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    const w = 300.0;
    final left = (at.dx - 24).clamp(12.0, screen.width - w - 12);
    final below = at.dy + 16;
    final top = below + 160 > screen.height ? at.dy - 176 : below;
    return Stack(children: [
      Positioned(
        left: left,
        top: top,
        width: w,
        child: Material(
          color: kCard,
          elevation: 6,
          shadowColor: kIndigo.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(word, style: body(18, weight: FontWeight.w800, color: kIndigoText))),
                if (speaker.available)
                  TextButton(style: _popButton, onPressed: () => speaker.sayWord(word), child: const Text('Hear it')),
                TextButton(style: _popButton, onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              ]),
              FutureBuilder(
                future: meaning,
                builder: (context, snap) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: snap.hasError
                      ? Text('The AI could not explain that word right now. Try again, or ask your teacher.', style: body(14, color: kSoft))
                      : !snap.hasData
                          ? Text('Looking it up...', style: body(14, color: kSoft))
                          : Text.rich(TextSpan(children: [
                              TextSpan(text: snap.data!.meaning),
                              if (snap.data!.synonym != null)
                                TextSpan(text: ' Like "${snap.data!.synonym}".', style: TextStyle(color: kSoft)),
                            ]), style: body(15, color: kInk)),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ---------- questions ----------

/// The questions for [passage]. Before checking, choices are picked with
/// [onChoose]; after, right and wrong are marked and a missed answer shows
/// its proof sentence.
class QuizPanel extends StatelessWidget {
  const QuizPanel({super.key, required this.passage, required this.answers, required this.checked, required this.onChoose,
    this.easy = false});
  final bool easy;
  final Passage passage;
  final List<int?> answers;
  final bool checked;
  final void Function(int question, int choice) onChoose;

  @override
  Widget build(BuildContext context) {
    final sentences = passage.sentences;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (i, q) in passage.questions.indexed)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: !checked ? kLine : answers[i] == q.answer ? kGood : kBad, width: checked ? 2 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${i + 1}. ${q.question}', style: readFont( body(16, weight: FontWeight.w700, color: kIndigoText),
                    easy)),
            const SizedBox(height: 10),
            for (final (j, c) in q.choices.indexed) _choice(i, j, c, q),
            if (checked && answers[i] == q.answer)
              Text('Correct', style: body(14, weight: FontWeight.w800, color: kGood)),
            if (checked && answers[i] != q.answer) ...[
              Text('Not quite. The answer is "${q.choices[q.answer]}". This sentence shows it:',
                  style: body(14, weight: FontWeight.w700, color: kBad)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kMark.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
                child: Text(sentences[q.evidence], style: body(14, color: kInk)),
              ),
            ],
          ]),
        ),
    ]);
  }

  Widget _choice(int i, int j, String c, Question q) {
    final picked = answers[i] == j;
    final key = checked && j == q.answer;
    final miss = checked && picked && j != q.answer;
    final bg = key ? kGood.withValues(alpha: 0.12) : miss ? kBad.withValues(alpha: 0.10) : picked ? kPaper : kCard;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: checked ? null : () => onChoose(i, j),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: picked || key ? kIndigoText : kLine, width: picked || key ? 1.6 : 1),
            ),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: picked ? kAccent : kPaper),
                child: Text('ABCD'[j], style: body(12, weight: FontWeight.w800, color: picked ? Colors.white : kIndigoText)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(c, style: readFont( body(15, color: kInk),
                      easy))),
            ]),
          ),
        ),
      ),
    );
  }
}

/// "How the AI checked this story", for stories the AI wrote.
class ChecksNote extends StatelessWidget {
  const ChecksNote(this.story, {super.key});
  final Story story;

  @override
  Widget build(BuildContext context) {
    final c = story.checks;
    final hand = c['handwritten'] == true;
    if (c['grade'] == null && !hand) return const SizedBox.shrink();
    final target = (c['target'] as List?) ?? const [0, 0];
    final teacher = story.byTeacher;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          hand ? 'How this story was checked' : teacher ? 'How the AI checked these questions' : 'How the AI checked this story',
          style: body(14, weight: FontWeight.w700, color: kSoft),
        ),
        children: [
          for (final t in hand
              ? ['A starter story: written and checked by hand before it shipped with Kodigno. Every answer is stated in the story, or is a main-idea or thinking question checked by a person.']
              : [
            if (teacher)
              'Written by your teacher. Kulay measured it at reading grade ${c['grade']}, ${c['words']} words.',
            if (!teacher)
            'Check 1: every sentence is complete, ${c['name'] ?? 'the main character'} is named from the first sentence, and it stays on topic. '
                'Reading difficulty measured at grade ${c['grade']} (target ${target[0]} to ${target[1]}), ${c['words']} words. Draft ${c['drafts']} of up to ${c['maxDrafts'] ?? 4}.',
            'Check 2: each answer is stated in the sentence it points to (a main-idea or thinking question is judged by the AI instead), each wrong choice was checked against the story, and the AI answered all '
                '${c['verified']} questions correctly from the story alone. ${c['rewritten']} rewritten, ${c['dropped']} thrown out.',
            '${teacher ? 'Questions written' : 'Written'} by ${c['model']} on this computer in ${c['seconds']} seconds. No internet used.',
            if (c['reviewed'] == true) 'A starter story: read and checked by hand before it shipped with Kodigno.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(t, style: body(13, color: kSoft)),
            ),
        ],
      ),
    );
  }
}
