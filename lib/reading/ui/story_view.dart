import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../ui/theme.dart';
import '../levels.dart';
import '../reading_repository.dart';

/// Kulay's frame colors, after JIM's Kulay screen.
const kIndigo = Color(0xFF3A2C82);
const kIndigoText = Color(0xFF2E2378);
const kSoft = Color(0xFF55507A);
const kPaper = Color(0xFFF6F4FB);
const kLine = Color(0xFFE3E0EF);
const kGood = Color(0xFF1E7A46);
const kBad = Color(0xFFB3261E);
const kMark = Color(0xFFFFE58A);

// ---------- read aloud: the computer's own voices, no internet ----------

/// Reads text aloud with the speech engine built into Windows (System.Speech),
/// through one PowerShell process that speaks a line at a time. No plugin and
/// no download. [available] is false off Windows, in tests, or with no English voice.
class Speaker {
  Speaker._();
  static final instance = Speaker._();

  final speaking = ValueNotifier<int?>(null); // sentence index being read
  bool available = false;
  Process? _ps;
  StreamIterator<String>? _lines;
  Future<bool>? _starting;
  int _run = 0;

  // Input: "rate|text" per line (rate -10..10, 0 = normal). Output: "ready", then "done" per line.
  static const _script = r'''
$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$v = @($s.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name -like 'en-*' })
if ($v.Count -eq 0) { [Console]::Out.WriteLine('none'); exit }
$pick = @($v | Where-Object { $_.VoiceInfo.Culture.Name -eq 'en-PH' }) + $v | Select-Object -First 1
$s.SelectVoice($pick.VoiceInfo.Name)
$s.SetOutputToDefaultAudioDevice()
[Console]::Out.WriteLine('ready'); [Console]::Out.Flush()
while ($null -ne ($line = [Console]::In.ReadLine())) {
  $parts = $line.Split([char]'|', 2)
  $s.Rate = [int]$parts[0]
  $s.Speak($parts[1])
  [Console]::Out.WriteLine('done'); [Console]::Out.Flush()
}
''';

  Future<bool> _start() => _starting ??= () async {
        if (!Platform.isWindows || Platform.environment.containsKey('FLUTTER_TEST')) return false;
        try {
          final ps = await Process.start('powershell', ['-NoProfile', '-NonInteractive', '-Command', _script]);
          unawaited(ps.stderr.drain<void>());
          final lines = StreamIterator(ps.stdout.transform(utf8.decoder).transform(const LineSplitter()));
          final ready = await lines.moveNext().timeout(const Duration(seconds: 20), onTimeout: () => false) &&
              lines.current.trim() == 'ready';
          if (!ready) {
            ps.kill();
            return false;
          }
          _ps = ps;
          _lines = lines;
          return true;
        } catch (_) {
          return false;
        }
      }();

  /// Checks once whether this computer can read aloud.
  Future<void> init() async => available = await _start();

  /// Speaks [text] and returns when it is done (or stopped).
  Future<void> say(String text, {int rate = -1}) async {
    if (!await _start()) return;
    final ps = _ps, lines = _lines;
    if (ps == null || lines == null) return;
    ps.stdin.add(utf8.encode('$rate|${text.replaceAll(RegExp(r'\s+'), ' ')}\n'));
    try {
      await ps.stdin.flush();
      await lines.moveNext(); // "done", or false once stop() ends the process
    } catch (_) {}
  }

  /// One word, cutting off anything being read.
  Future<void> sayWord(String word) async {
    stop();
    await say(word, rate: -2);
  }

  Future<void> readAll(List<String> sentences, {required bool young}) async {
    stop();
    final run = _run;
    for (var i = 0; i < sentences.length; i++) {
      if (run != _run) return;
      speaking.value = i;
      await say(sentences[i], rate: young ? -2 : -1);
    }
    if (run == _run) speaking.value = null;
  }

  /// Stops at once: the voice process is ended and restarted on the next [say].
  void stop() {
    _run++;
    speaking.value = null;
    _ps?.kill();
    _ps = null;
    _lines = null;
    _starting = null;
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
                padding: pad, shape: const StadiumBorder(), side: const BorderSide(color: kIndigoText, width: 1.5), foregroundColor: kIndigoText),
            child: Text(label, style: style))
        : FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
                padding: pad, shape: const StadiumBorder(), backgroundColor: kIndigoText, disabledBackgroundColor: kLine),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: kLine)),
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
                      onTap: () => speaking == null ? _speaker.readAll(sentences, young: p.level < 2) : _speaker.stop()),
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
                    style: readFont( body(size, weight: FontWeight.w500, color: const Color(0xFF1C1A2E)).copyWith(height: 1.6),
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
        ? const Color(0xFFD6E4FF)
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
          color: Colors.white,
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
                                TextSpan(text: ' Like "${snap.data!.synonym}".', style: const TextStyle(color: kSoft)),
                            ]), style: body(15, color: const Color(0xFF1C1A2E))),
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
            color: Colors.white,
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
                child: Text(sentences[q.evidence], style: body(14, color: const Color(0xFF1C1A2E))),
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
    final bg = key ? kGood.withValues(alpha: 0.12) : miss ? kBad.withValues(alpha: 0.10) : picked ? kPaper : Colors.white;
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
                decoration: BoxDecoration(shape: BoxShape.circle, color: picked ? kIndigoText : kPaper),
                child: Text('ABCD'[j], style: body(12, weight: FontWeight.w800, color: picked ? Colors.white : kIndigoText)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(c, style: readFont( body(15, color: const Color(0xFF1C1A2E)),
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
