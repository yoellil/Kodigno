import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../ui/motion.dart';
import '../../ui/theme.dart';
import '../levels.dart';
import '../nlp.dart' show skillOf, skills;
import '../reading_controller.dart';
import '../reading_repository.dart';
import 'book3d.dart';
import 'kulay_extras.dart';
import 'story_view.dart';

TextStyle _h(double size) => display(size, color: kIndigoText);
TextStyle _p(double size, {Color color = kSoft, FontWeight weight = FontWeight.w500}) => body(size, color: color, weight: weight);

// ---------- landing panels (shown beside JIM's shelves) ----------

/// First open: who uses Kulay here. Then, in personal mode, the reader's name.
class WelcomePanel extends StatefulWidget {
  const WelcomePanel({super.key});
  @override
  State<WelcomePanel> createState() => _WelcomePanelState();
}

class _WelcomePanelState extends State<WelcomePanel> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start(ReadingController c) async {
    final e = await c.addReader(_name.text);
    if (mounted) setState(() => _error = e);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    if (c.mode == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Who reads on this computer?', style: _p(16, color: kIndigoText, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          KButton('Just me', onTap: () => c.setMode(KulayMode.personal)),
          KButton('A class, taking turns', ghost: true, onTap: () => c.setMode(KulayMode.classroom)),
        ]),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text("What's your name?", style: _p(16, color: kIndigoText, weight: FontWeight.w700)),
      const SizedBox(height: 10),
      _NameField(controller: _name, onSubmit: () => _start(c), error: _error, button: 'Start reading check'),
    ]);
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.onSubmit, required this.error, required this.button});
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String? error;
  final String button;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: controller,
            maxLength: 40,
            onSubmitted: (_) => onSubmit(),
            style: _p(16, color: kIndigoText),
            decoration: InputDecoration(hintText: 'First name and last initial', counterText: '', fillColor: kPaper, errorText: error),
          ),
        ),
        const SizedBox(height: 10),
        KButton(button, onTap: onSubmit),
      ]);
}

/// Classroom: pick your name, or add a new reader.
class ReadersPanel extends StatefulWidget {
  const ReadersPanel({super.key});
  @override
  State<ReadersPanel> createState() => _ReadersPanelState();
}

class _ReadersPanelState extends State<ReadersPanel> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('Who is reading today?', style: _p(18, color: kIndigoText, weight: FontWeight.w800)),
      const SizedBox(height: 12),
      if (c.readers.isEmpty) Text('No readers yet. Add the first one below.', style: _p(14)),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final r in c.readers)
          Material(
            color: kPaper,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => c.pickReader(r),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: levels[r.level].bg, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(r.name, style: _p(15, color: kIndigoText, weight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text(r.placed ? levels[r.level].name : 'Needs reading check', style: _p(12)),
                ]),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 18),
      Text('New reader? Type your name.', style: _p(14, color: kIndigoText, weight: FontWeight.w700)),
      const SizedBox(height: 8),
      _NameField(
        controller: _name,
        error: _error,
        button: 'Start reading check',
        onSubmit: () async {
          final e = await c.addReader(_name.text);
          if (mounted) setState(() => _error = e);
        },
      ),
    ]);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _topic = TextEditingController();
  late final Future<List<({int id, String title})>> _fromTeacher;
  late final Future<List<SavedWord>> _words;
  late final Future<int> _best;
  late final Future<({int days, bool today})> _streak;
  late final Future<List<int>> _speeds;

  @override
  void initState() {
    super.initState();
    final c = context.read<ReadingController>();
    final r = c.reader!;
    _best = c.repo.bestLevel(r);
    _streak = c.repo.dayStreak(r.id);
    _speeds = c.repo.speeds(r.id);
    _fromTeacher = c.repo.teacherStories(r.id, r.level);
    _words = c.myWords();
  }

  /// A closed book comes out of the button, flies to the middle and opens.
  void _write(BuildContext button, ReadingController c) {
    final t = _topic.text.trim();
    final box = button.findRenderObject() as RenderBox?;
    if (t.isEmpty || box == null || !box.hasSize) {
      c.readTopic(t);
      return;
    }
    final at = box.localToGlobal(box.size.center(Offset.zero));
    flyOpenBook(
      context,
      from: Rect.fromCenter(center: at, width: 44, height: math.max(150, BookSpine.minHeight(t))),
      title: t,
      spec: (width: 44, height: math.max(150, BookSpine.minHeight(t)), color: bookColors[t.toLowerCase().hashCode % bookColors.length], style: t.length),
      fadeIn: true,
      onOpened: () => c.readTopic(t),
    );
  }

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final r = c.reader;
    if (r == null) return const SizedBox.shrink(); // fading out after a reader switch
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(padding: const EdgeInsets.fromLTRB(28, 12, 28, 32), children: [
          Text('Hi, ${r.name}.', style: _h(38)).enter(context),
          const SizedBox(height: 18),
          _ColorProgress(level: r.level, up: c.progress.up, down: c.progress.down).enter(context, index: 1),
          const SizedBox(height: 12),
          FutureBuilder<int>(
            future: _best,
            builder: (context, snap) => _Ladder(level: r.level, best: snap.data ?? r.level),
          ),
          FutureBuilder<({int days, bool today})>(
            future: _streak,
            builder: (context, snap) =>
                snap.data == null || snap.data!.days == 0 ? const SizedBox.shrink() : StreakNote(snap.data!),
          ),
          FutureBuilder<List<int>>(
            future: _speeds,
            builder: (context, snap) =>
                (snap.data?.length ?? 0) < 2 ? const SizedBox.shrink() : SpeedChart(snap.data!),
          ),
          FutureBuilder<List<SavedWord>>(
            future: _words,
            builder: (context, snap) => (snap.data ?? const []).isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: KButton('My words (${snap.data!.length})', ghost: true, small: true, onTap: c.openWords),
                    ),
                  ),
          ),
          FutureBuilder<List<({int id, String title})>>(
            future: _fromTeacher,
            builder: (context, snap) => (snap.data ?? const []).isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('From your teacher', style: _h(24)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final t in snap.data!) KButton(t.title, onTap: () => c.readStoryById(t.id)),
                      ]),
                    ]),
                  ),
          ),
          const SizedBox(height: 24),
          const WaitingStory(),
          Text('What do you want to read about?', style: _h(24)).enter(context, index: 2),
          const SizedBox(height: 14),
          BookShelf(topics: topics, onOpen: c.readTopic).enter(context, index: 3, dy: 0.1),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _topic,
                maxLength: 40,
                style: _p(15, color: kIndigoText),
                onSubmitted: (v) => c.readTopic(v),
                decoration: InputDecoration(
                  hintText: 'Or type your own, like "my pet cat"',
                  counterText: '',
                  fillColor: kPaper,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Builder(builder: (button) => KButton('Write my story', onTap: () => _write(button, c))),
          ]).enter(context, index: 4),
        ]),
      ),
    );
  }
}

/// The reader's color, where it sits among all 8, and the progress to the next one.
class _ColorProgress extends StatelessWidget {
  const _ColorProgress({required this.level, required this.up, required this.down});
  final int level, up, down;

  @override
  Widget build(BuildContext context) {
    final l = levels[level];
    final top = level == levels.length - 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kPaper, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('You read at', style: _p(15, color: kIndigoText, weight: FontWeight.w600)),
          const SizedBox(width: 10),
          LevelChip(level, big: true),
          const SizedBox(width: 10),
          Text('Grades ${l.grades}', style: _p(13)),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final (i, x) in levels.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Tooltip(
                message: '${x.name} · Grades ${x.grades}',
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: i == level ? 18 : 8),
                  duration: Duration(milliseconds: 400 + i * 60),
                  curve: Curves.easeOutBack,
                  builder: (_, h, _) => Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: i > level ? x.bg.withValues(alpha: 0.35) : x.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: i == level ? Border.all(color: kIndigoText, width: 2) : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 16),
        Row(children: [
          for (var i = 0; i < 3; i++)
            AnimatedContainer(
              duration: Duration(milliseconds: 300 + i * 120),
              margin: const EdgeInsets.only(right: 6),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < up ? l.bg : Colors.white,
                border: Border.all(color: i < up ? l.fg.withValues(alpha: 0.4) : kLine, width: 1.5),
              ),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              top
                  ? '${up.clamp(0, 3)} of 3 strong scores. You are at the top color.'
                  : '$up of 3 strong scores to reach ${levels[level + 1].name}.',
              style: _p(14, color: kIndigoText, weight: FontWeight.w600),
            ),
          ),
        ]),
        if (down > 0 && level > 0) ...[
          const SizedBox(height: 6),
          Text('Careful: one more score under 60% moves you to ${levels[level - 1].name} for practice.', style: _p(13)),
        ],
      ]),
    );
  }
}

/// The 8 colors. A color the reader has reached keeps its badge (a check) even after a move down.
class _Ladder extends StatelessWidget {
  const _Ladder({required this.level, required this.best});
  final int level, best;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 6, runSpacing: 6, children: [
        for (final (i, l) in levels.indexed)
          Opacity(
            opacity: i > best ? 0.45 : 1,
            child: Container(
              width: 92,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: l.bg,
                borderRadius: BorderRadius.circular(12),
                border: i == level ? Border.all(color: kIndigoText, width: 3) : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Expanded(
                      child:
                Text(l.name, style: body(14, weight: FontWeight.w800, color: l.fg),
                      ),
                    ),
                    if (i <= best)
                      Icon(Icons.verified_rounded, size: 16, color: l.fg)
                    else
                      Icon(Icons.lock_outline_rounded, size: 14, color: l.fg),
                  ]),
                Text('Gr ${l.grades}', style: body(11, weight: FontWeight.w600, color: l.fg)),
              ]),
            ),
          ),
      ]);
}

// ---------- writing: the 8 steps ----------

class WritingPage extends StatelessWidget {
  const WritingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    if (c.reader == null) return const SizedBox.shrink();
    final l = levels[c.reader!.level];
    final step = c.step.clamp(1, stepNames.length);
    final detail = c.stepDetail[step - 1];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            OpeningBookLoader(
              title: c.topic ?? 'Your story',
              color: lastOpenedBookColor ?? bookColors[(c.topic ?? '').toLowerCase().hashCode % bookColors.length],
              busy: c.error == null,
            ),
            const SizedBox(height: 18),
            Text(c.topic == null ? 'Writing your story' : 'Writing your ${c.topic} story',
                textAlign: TextAlign.center, style: _h(30)),
            const SizedBox(height: 6),
            Text('On this computer, no internet. The AI checks its own work twice.',
                textAlign: TextAlign.center, style: _p(14)),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a), child: child),
              ),
              child: Column(key: ValueKey(step), children: [
                Text('Step $step of ${stepNames.length}', style: _p(12, weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(stepNames[step - 1],
                    textAlign: TextAlign.center, style: _p(17, color: kIndigoText, weight: FontWeight.w700)),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(detail, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: _p(13)),
                ],
              ]),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: step / stepNames.length),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 8, backgroundColor: kPaper, color: l.bg),
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= stepNames.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == step ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < step ? kIndigoText : i == step ? l.bg : kLine,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ]),
            if (c.error != null) ...[
              const SizedBox(height: 24),
              Text(c.error!, textAlign: TextAlign.center, style: _p(15, color: kBad, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              KButton('Pick another topic', ghost: true, onTap: c.goHome),
            ],
          ]),
        ),
      ),
    );
  }
}

// ---------- reading a story or a placement passage ----------

/// Read first, then answer from memory. Once the reader moves on to the
/// questions the story stays hidden until the answers are checked; after
/// that it comes back with the proof sentences marked.
class ReadPage extends StatefulWidget {
  const ReadPage({super.key});
  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  /// Passages whose questions are open. Kept for the whole session so leaving
  /// Kulay, or opening the same story again, cannot bring the story back.
  static final _answering = <String>{};

  int _q = 0;
  String? _key;

  String _keyOf(ReadingController c, Passage p) =>
      p is Story ? 's${p.id}' : 'p${c.reader?.id}-${c.placementIndex}';

  Future<void> _toQuestions(String key) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ready for the questions?', style: _h(22)),
        content: Text('The story will be hidden while you answer, so answer from memory. You can see it again after you check your answers.',
            style: _p(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep reading')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kIndigoText),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Go to questions'),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      Speaker.instance.stop();
      setState(() => _answering.add(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final p = c.passage;
    if (p == null) return const SizedBox.shrink(); // fading out after the passage closed
    final key = _keyOf(c, p);
    if (key != _key) {
      _key = key;
      _q = 0;
    }
    if (c.checked) _answering.remove(key); // done: a later retake starts at the story
    final answering = _answering.contains(key) || c.answers.any((a) => a != null);
    final phase = c.checked ? 2 : answering ? 1 : 0;
    final page = switch (phase) {
      0 => _Reading(passage: p, onDone: () => _toQuestions(key)),
      1 => _Answering(
          passage: p,
          index: _q.clamp(0, p.questions.length - 1),
          onIndex: (i) {
            if (mounted) setState(() => _q = i);
          },
        ),
      _ => const _Review(),
    };
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(c.textScale)),
      child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a), child: child),
      ),
      child: KeyedSubtree(key: ValueKey('$key/$phase'), child: page),
    ));
  }
}

/// Step 1 of 2 and step 2 of 2 labels above the page.
class _StepLabel extends StatelessWidget {
  const _StepLabel(this.step, this.text);
  final int step;
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 1; i <= 2; i++)
          Container(
            margin: const EdgeInsets.only(right: 6),
            width: i == step ? 26 : 10,
            height: 10,
            decoration: BoxDecoration(color: i <= step ? kIndigoText : kLine, borderRadius: BorderRadius.circular(99)),
          ),
        const SizedBox(width: 6),
        Text('Step $step of 2 · $text', style: _p(13, color: kIndigoText, weight: FontWeight.w800)),
      ]);
}

class _Reading extends StatelessWidget {
  const _Reading({required this.passage, required this.onDone});
  final Passage passage;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final p = passage;
    final isStory = p is Story;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), children: [
          const _StepLabel(1, 'Read the story'),
          const SizedBox(height: 8),
          Text(
            isStory
                ? 'Read it all the way through. The questions come next, without the story.'
                : 'Reading check, part ${c.placementIndex + 1} of up to ${placement.length}. This finds the color that fits you best.',
            style: _p(14),
          ),
          if (c.notice != null && isStory) ...[
            const SizedBox(height: 8),
            Text(c.notice!, style: _p(14, color: kIndigoText)),
          ],
          const SizedBox(height: 16),
          if (isStory)
            _ReadTimer(key: ValueKey(p.id), words: p.sentences.join(' ').split(RegExp(r'\s+')).length),
          StoryCard(
            passage: p,
            label: isStory ? p.topic : 'Reading check ${c.placementIndex + 1}',
            onWord: c.explainWord,
            easy: c.easyFont,
          ),
          const SizedBox(height: 22),
          Center(
            child: FilledButton.icon(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: kIndigoText,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                shape: const StadiumBorder(),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              label: Text("I'm done reading", style: body(15, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('${p.questions.length} questions are waiting.', style: _p(13))),
        ]),
      ),
    );
  }
}

/// One question at a time, from memory.
class _Answering extends StatelessWidget {
  const _Answering({required this.passage, required this.index, required this.onIndex});
  final Passage passage;
  final int index;
  final ValueChanged<int> onIndex;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final p = passage;
    if (!identical(c.passage, p) || index >= c.answers.length) return const SizedBox.shrink();
    final q = p.questions[index];
    final last = index == p.questions.length - 1;
    final picked = c.answers[index];
    final l = levels[p.level];
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), children: [
          const _StepLabel(2, 'Answer from memory'),
          const SizedBox(height: 18),
          Row(children: [
            for (var i = 0; i < p.questions.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onIndex(i),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 8,
                      decoration: BoxDecoration(
                        color: c.answers[i] != null ? kIndigoText : i == index ? l.bg : kLine,
                        borderRadius: BorderRadius.circular(99),
                        border: i == index ? Border.all(color: kIndigoText, width: 1.5) : null,
                      ),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a), child: child),
            ),
            child: Column(key: ValueKey(index), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Question ${index + 1} of ${p.questions.length}', style: _p(13, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(q.question, style: readFont(_h(26), c.easyFont)),
              const SizedBox(height: 18),
              for (final (j, choice) in q.choices.indexed)
                _ChoiceTile(
                  letter: 'ABCD'[j],
                  text: choice,
                  easy: c.easyFont,
                  selected: picked == j,
                  color: l.bg,
                  onTap: () {
                    c.choose(index, j);
                    // A first answer moves on by itself; changing one stays put.
                    if (picked == null && !last) {
                      Future.delayed(const Duration(milliseconds: 280), () => onIndex(index + 1));
                    }
                  },
                ),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            if (index > 0) KButton('Previous', ghost: true, onTap: () => onIndex(index - 1)),
            const Spacer(),
            if (!last)
              KButton('Next', onTap: picked == null ? null : () => onIndex(index + 1))
            else
              KButton(
                c.allAnswered ? 'Check my answers' : 'Answer every question',
                onTap: c.allAnswered ? (p is Story ? c.submitStory : c.checkPlacement) : null,
              ),
          ]),
        ]),
      ),
    );
  }
}

class _ChoiceTile extends StatefulWidget {
  const _ChoiceTile(
      {required this.letter, required this.text, required this.selected, required this.color, required this.onTap, this.easy = false});
  final String letter, text;
  final bool selected, easy;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<_ChoiceTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: sel ? 1.015 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: sel ? widget.color.withValues(alpha: 0.45) : _hover ? kPaper : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? kIndigoText : kLine, width: sel ? 2 : 1.2),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? kIndigoText : kPaper),
                  child: Text(widget.letter,
                      style: body(13, weight: FontWeight.w800, color: sel ? Colors.white : kIndigoText)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.text, style: readFont(body(16, color: const Color(0xFF1C1A2E)), widget.easy))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// After checking: the result, the marked answers, and the story again with
/// the proof sentences highlighted.
class _Review extends StatelessWidget {
  const _Review();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final p = c.passage;
    if (p == null || !c.checked) return const SizedBox.shrink();
    final isStory = p is Story;
    final retrying = c.retryOf != null;
    // Retrying: the highlights stay hidden until the second try is checked.
    final proof = <int>{
      if (retrying) ...[
        if (c.retryChecked)
          for (final (k, i) in c.retryOf!.indexed)
            if (c.retryAnswers[k] != p.questions[i].answer) p.questions[i].evidence,
      ] else ...[
        for (final (i, q) in p.questions.indexed)
          if (c.answers[i] != q.answer) q.evidence,
      ],
    };
    final story = StoryCard(
      passage: p,
      label: isStory ? p.topic : 'Reading check ${c.placementIndex + 1}',
      proof: proof,
      onWord: c.explainWord,
      easy: c.easyFont,
    );
    final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (isStory) ...[const WaitingStory(), _ResultBanner(story: p)] else _PlacementNext(),
      if (retrying) ...[
        Text('Try the missed ones again', style: _h(22)),
        const SizedBox(height: 4),
        Text('Look back at the story. This does not change your score.', style: _p(14)),
        const SizedBox(height: 10),
        QuizPanel(
          passage: c.retryPassage,
          answers: c.retryAnswers,
          checked: c.retryChecked,
          onChoose: c.chooseRetry,
          easy: c.easyFont,
        ),
        Wrap(spacing: 10, runSpacing: 10, children: [
          if (!c.retryChecked)
            KButton(
              c.retryAnswers.every((a) => a != null) ? 'Check my answers' : 'Answer every question',
              onTap: c.retryAnswers.every((a) => a != null) ? c.checkRetry : null,
            ),
          KButton('Back to my answers', ghost: true, onTap: c.endRetry),
        ]),
      ] else ...[
        Text('Your answers', style: _h(22)),
        const SizedBox(height: 10),
        QuizPanel(passage: p, answers: c.answers, checked: true, onChoose: c.choose, easy: c.easyFont),
      ],
    ]);
    final storyCol = [
      Text(proof.isEmpty ? 'The story' : 'The story · proof sentences are marked', style: _p(13, weight: FontWeight.w800)),
      const SizedBox(height: 8),
      story,
      if (isStory) ChecksNote(p),
    ];
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth < 900) {
        return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
          side,
          const SizedBox(height: 20),
          ...storyCol,
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 5, child: ListView(padding: const EdgeInsets.fromLTRB(28, 8, 12, 28), children: [side])),
        Expanded(flex: 6, child: ListView(padding: const EdgeInsets.fromLTRB(12, 8, 28, 28), children: storyCol)),
      ]);
    });
  }
}


/// Times the reader's reading and shows words a minute. Optional: the questions can be answered without it.
class _ReadTimer extends StatefulWidget {
  const _ReadTimer({super.key, required this.words});
  final int words;
  @override
  State<_ReadTimer> createState() => _ReadTimerState();
}

class _ReadTimerState extends State<_ReadTimer> {
  final _watch = Stopwatch();
  Timer? _tick;
  var _tooOdd = false;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _start(ReadingController c) {
    _tooOdd = false;
    c.setWpm(null);
    _watch
      ..reset()
      ..start();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    setState(() {});
  }

  void _stop(ReadingController c) {
    _watch.stop();
    _tick?.cancel();
    c.setWpm(
      (widget.words *
              60 /
              (_watch.elapsedMilliseconds / 1000).clamp(0.5, double.infinity))
          .round(),
    );
    _tooOdd =
        c.wpm ==
        null; // under 5 or over 400 words a minute is not a real reading
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final secs = _watch.elapsed.inSeconds;
    final Widget row;
    if (_watch.isRunning) {
      row = Row(
        children: [
          Text(
            '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}',
            style: _h(26),
          ),
          const SizedBox(width: 14),
          KButton('I finished reading', small: true, onTap: () => _stop(c)),
        ],
      );
    } else if (c.wpm != null) {
      row = Row(
        children: [
          Flexible(
            child: Text(
              'You read ${c.wpm} words a minute.',
              style: _p(16, color: kIndigoText, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          KButton(
            'Time it again',
            ghost: true,
            small: true,
            onTap: () => _start(c),
          ),
        ],
      );
    } else {
      row = Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          KButton(
            'Time my reading',
            ghost: true,
            small: true,
            onTap: () => _start(c),
          ),
          Text(
            _tooOdd
                ? 'That time looks off. Read the whole story, then try again.'
                : 'Optional. Read the story, then tap finished.',
            style: _p(13),
          ),
        ],
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 18), child: row);
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.story});
  final Story story;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final res = c.result;
    if (res == null) return const SizedBox.shrink();
    final l = levels[res.level];
    final up = res.level > res.from, down = res.level < res.from;
    final top = res.level == levels.length - 1;
    final teacher = story.byTeacher;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: up ? l.bg : kPaper, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${res.correct} of ${res.total} correct (${res.pct}%)', style: display(26, color: up ? l.fg : kIndigoText)),
        const SizedBox(height: 6),
        Text(
          up
              ? 'You moved up to ${l.name}, Grades ${l.grades}. Stories get longer and questions get harder.'
              : down
                  ? 'Next stories will be ${l.name} for more practice. Three strong scores and you climb back up.'
                  : c.progress.down > 0 && res.level > 0
                      ? 'Tricky one. Read slowly next time: one more score under 60% moves you to ${levels[res.level - 1].name} for practice.'
                      : top
                          ? 'Keep going at the top color.'
                          : '${c.progress.up} of 3 strong scores toward ${levels[res.level + 1].name}.',
          style: _p(15, color: up ? l.fg : kIndigoText, weight: FontWeight.w600),
        ),
        if (c.wpm != null) ...[
          const SizedBox(height: 6),
          Text('You read ${c.wpm} words a minute.', style: _p(15, color: up ? l.fg : kIndigoText, weight: FontWeight.w600)),
        ],
        const SizedBox(height: 12),
        _SkillSummary(story: story, answers: c.answers, dark: up ? l.fg : kIndigoText),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          // A teacher's story has no topic to write more of: the next story comes from the reader's page.
          if (!teacher) KButton('Next ${story.topic} story', onTap: () => c.readTopic(story.topic)),
          if (res.correct < res.total && c.retryOf == null) KButton('Try the missed ones again', ghost: true, onTap: c.startRetry),
          KButton(teacher ? 'Back to my page' : 'Pick a new topic', ghost: true, onTap: c.goHome),
          if (c.mode == KulayMode.classroom) KButton('Done, next reader', ghost: true, onTap: c.switchReader),
        ]),
      ]),
    );
  }
}

/// What this story showed, skill by skill, and what to look for next time.
class _SkillSummary extends StatelessWidget {
  const _SkillSummary({required this.story, required this.answers, required this.dark});
  final Story story;
  final List<int?> answers;
  final Color dark;

  @override
  Widget build(BuildContext context) {
    final totals = <String, (int, int)>{};
    for (final (i, q) in story.questions.indexed) {
      final (right, all) = totals[skillOf(q.question)] ?? (0, 0);
      totals[skillOf(q.question)] = (right + (answers[i] == q.answer ? 1 : 0), all + 1);
    }
    final missed = totals.entries.where((e) => e.value.$1 < e.value.$2).map((e) => e.key).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 6, children: [
        for (final e in totals.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(999)),
            child: Text('${e.key}  ${e.value.$1} of ${e.value.$2}',
                style: _p(13, color: e.value.$1 == e.value.$2 ? kGood : kBad, weight: FontWeight.w700)),
          ),
      ]),
      if (missed.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('Next time, practice: ${missed.first.toLowerCase()} (${_skillHint[missed.first]}).', style: _p(14, color: dark, weight: FontWeight.w600)),
      ],
    ]);
  }
}

class _PlacementNext extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    if (c.placementRight == null) return const SizedBox.shrink();
    final right = c.placementRight!.where((x) => x).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.placedLevel == null ? kPaper : levels[c.placedLevel!].bg, borderRadius: BorderRadius.circular(18)),
      child: c.placedLevel == null
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$right of ${c.placementRight!.length} right. On to the next one.', style: _p(16, color: kIndigoText, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              KButton('Next passage', onTap: c.nextPlacement),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your starting color is', style: _p(15, color: levels[c.placedLevel!].fg, weight: FontWeight.w600)),
              Text(levels[c.placedLevel!].name, style: display(44, color: levels[c.placedLevel!].fg)),
              Text('Grades ${levels[c.placedLevel!].grades}. Score 80% or more on 3 stories in a row to move up.',
                  style: _p(14, color: levels[c.placedLevel!].fg)),
              const SizedBox(height: 12),
              KButton('Pick a topic', onTap: c.nextPlacement),
            ]),
    );
  }
}

// ---------- teacher view ----------

const _skillHint = {
  'Details': 'who, what, where, when',
  'Sequence': 'what happened first, next, last',
  'Cause and effect': 'why something happened',
  'Feelings': 'how a character felt',
  'Word meaning': 'what a word means',
  'Main idea': 'what the story is mostly about',
  'Inference': 'figuring out what is not said',
};

/// Asks for the teacher PIN (sets it the first time). Returns the typed PIN.
Future<String?> askPin(BuildContext context, {required bool first}) {
  final pin = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(first ? 'Set a teacher PIN' : 'Teacher PIN', style: _h(22)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(first ? 'Pick 4 digits. Readers will need them to open the class view.' : 'Type the 4-digit PIN.', style: _p(14)),
        const SizedBox(height: 10),
        TextField(
          controller: pin,
          autofocus: true,
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          onSubmitted: (v) => Navigator.pop(ctx, v),
          decoration: const InputDecoration(counterText: ''),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, pin.text), child: const Text('Open')),
      ],
    ),
  ).whenComplete(pin.dispose);
}

class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key});
  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  late Future<ClassReport> _report = context.read<ReadingController>().classReport();

  void _refresh() => setState(() => _report = context.read<ReadingController>().classReport());

  @override
  Widget build(BuildContext context) {
    final c = context.read<ReadingController>();
    final classroom = c.mode == KulayMode.classroom;
    return FutureBuilder<ClassReport>(
      future: _report,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final rep = snap.data!;
        final placed = rep.readers.where((r) => r.reader.placed);
        return ListView(padding: const EdgeInsets.fromLTRB(28, 8, 28, 28), children: [
          Text(classroom ? 'Class progress' : 'My progress', style: _h(32)),
          Text('${rep.readers.length} ${rep.readers.length == 1 ? 'reader' : 'readers'}. Scores stay on this computer.', style: _p(15)),
          Text('Word meanings: Open English WordNet 2025, CC BY 4.0 (en-word.net).', style: _p(12)),
          const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: KButton(
                'Save report as PDF',
                ghost: true,
                small: true,
                onTap: rep.readers.isEmpty ? null : _print,
              ),
            ),
            const SizedBox(height: 18),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (i, l) in levels.indexed)
              Container(
                width: 86,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: l.bg, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${placed.where((r) => r.reader.level == i).length}', style: display(24, color: l.fg)),
                  Text(l.name, style: body(12, weight: FontWeight.w700, color: l.fg)),
                ]),
              ),
          ]),
          const SizedBox(height: 24),
          _SkillsPanel(rep),
          const SizedBox(height: 24),
            const TeacherStories(),
            const SizedBox(height: 24),
          if (rep.readers.isEmpty)
            Text('No readers yet.', style: _p(15))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: _p(13, color: kIndigoText, weight: FontWeight.w800),
                dataTextStyle: _p(14, color: kIndigoText),
                columns: [
                  for (final t in ['Reader', 'Color', 'Stories', 'Average',
                      'Speed', 'Recent scores', 'Needs work on', 'Status', if (classroom) ''])
                    DataColumn(label: Text(t)),
                ],
                rows: [
                  for (final r in rep.readers)
                    DataRow(cells: [
                      DataCell(Text(r.reader.name, style: _p(14, color: kIndigoText, weight: FontWeight.w700))),
                      DataCell(DropdownButton<int>(
                        value: r.reader.level,
                        underline: const SizedBox.shrink(),
                        items: [for (final i in levels.indexed.map((e) => e.$1)) DropdownMenuItem(value: i, child: LevelChip(i))],
                        onChanged: (v) async {
                          if (v == null) return;
                          await c.setReaderLevel(r.reader.id, v);
                          _refresh();
                        },
                      )),
                      DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [Text('${r.stories}'),
                                IconButton(
                                  tooltip:
                                      'Give ${r.reader.name} the reading check again',
                                  icon: const Icon(
                                    Icons.replay_rounded,
                                    size: 18,
                                    color: kSoft,
                                  ),
                                  onPressed: r.reader.placed
                                      ? () => _retest(r.reader)
                                      : null,
                                ),
                              ])),
                      DataCell(Text(r.avg == null ? '' : '${r.avg}%')),
                          DataCell(Text(r.wpm == null ? '' : '${r.wpm} wpm')),
                      DataCell(_ScoreBars(r.recent)),
                      DataCell(Text(r.needs == null ? 'Nothing yet' : '${r.needs!.skill} (${r.needs!.right} of ${r.needs!.total})')),
                      DataCell(Text(readerStatus(r))),
                      if (classroom)
                        DataCell(IconButton(
                          tooltip: 'Delete ${r.reader.name}',
                          icon: const Icon(Icons.delete_outline_rounded, color: kSoft),
                          onPressed: () => _delete(r.reader),
                        )),
                    ]),
                ],
              ),
            ),
        ]);
      },
    );
  }

  Future<void> _retest(Reader r) async {
    final c = context.read<ReadingController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Give ${r.name} the reading check again?', style: _h(22)),
        content: Text(
          '${r.name} keeps their color until they finish the check, then it is set from the new result. Scores are kept.',
          style: _p(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start again'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await c.retestReader(r.id);
    _refresh();
  }

  Future<void> _print() async {
    final c = context.read<ReadingController>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await c.saveReport();
      messenger.showSnackBar(SnackBar(content: Text('Report saved: $path')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't save the report. If it is open in a PDF viewer, close it and try again.",
          ),
        ),
      );
    }
  }

  Future<void> _delete(Reader r) async {
    final c = context.read<ReadingController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${r.name}?', style: _h(22)),
        content: Text('Their scores are deleted too. This cannot be undone.', style: _p(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await c.deleteReader(r.id);
    _refresh();
  }
}

class _SkillsPanel extends StatelessWidget {
  const _SkillsPanel(this.rep);
  final ClassReport rep;

  @override
  Widget build(BuildContext context) {
    final focus = rep.focus;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Reading skills', style: _h(24)),
      const SizedBox(height: 4),
      Text(
          focus != null
              ? 'Teach next: ${focus.skill}. The class got ${focus.right} of ${focus.total} right.'
              : 'No weak skill yet. This fills in as readers answer questions.',
          style: _p(15, color: kIndigoText)),
      const SizedBox(height: 12),
      for (final k in skills)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
              width: 210,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(focus?.skill == k ? '$k  ·  Teach next' : k,
                    style: _p(14, color: focus?.skill == k ? kBad : kIndigoText, weight: FontWeight.w800)),
                Text(_skillHint[k]!, style: _p(12)),
              ]),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: rep.skills[k]!.$2 == 0 ? 0 : rep.skills[k]!.$1 / rep.skills[k]!.$2,
                  backgroundColor: kPaper,
                  color: focus?.skill == k ? kBad : kIndigoText,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: Text(
                rep.skills[k]!.$2 == 0
                    ? 'No answers yet'
                    : '${(rep.skills[k]!.$1 * 100 / rep.skills[k]!.$2).round()}% right (${rep.skills[k]!.$1} of ${rep.skills[k]!.$2})',
                style: _p(13, color: kIndigoText),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// Oldest to newest, left to right; the last score is printed.
class _ScoreBars extends StatelessWidget {
  const _ScoreBars(this.recent);
  final List<Score> recent;

  @override
  Widget build(BuildContext context) {
    if (recent.isEmpty) return Text('None yet', style: _p(13));
    final list = recent.reversed.toList();
    return Semantics(
      label: 'Recent scores: ${list.map((a) => '${a.pct}%').join(', ')}',
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final a in list)
          Tooltip(
            message: '${a.pct}% at ${levels[a.level].name}',
            child: Container(
              width: 8,
              height: 4 + 22 * a.pct / 100,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(color: a.pct < 60 ? kBad : kIndigoText, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        const SizedBox(width: 6),
        Text('${list.last.pct}%', style: _p(13, color: kIndigoText, weight: FontWeight.w700)),
      ]),
    );
  }
}
