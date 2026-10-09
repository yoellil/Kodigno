import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart' show StudySet;
import '../data/repository.dart';
import '../data/review_repository.dart';
import '../domain/source_ref.dart';
import '../study/confusions.dart';
import '../study/diagnosis.dart';
import '../study/practice_session.dart';
import '../study/scheduler.dart';
import 'anim.dart';
import 'diagnosis_line.dart';
import 'motion.dart';
import 'slide_tag.dart';
import 'theme.dart';
import 'widgets.dart';

/// A short practice session: a few flashcards and questions, the ones that are
/// due first. Every answer is recorded, and moves the item's schedule on.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.repo,
    required this.reviews,
    this.minutes = 5,
    this.setId,
  });
  final StudyRepository repo;
  final ReviewRepository reviews;

  /// How long the session should take: 2, 5 or 10 minutes.
  final int minutes;

  /// Practice only this set; null for all of them.
  final int? setId;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  PracticeSession? _session;
  Map<int, StudySet> _sets = const {};
  bool _loading = true;
  bool _revealed = false; // a card's answer is showing
  bool _doneToday = false; // nothing left because it has all been answered today
  String? _error;
  final _indexes = <int, PageIndex?>{}; // the pages of each set, to place a wrong choice
  int _earlier = 0; // times the choice just picked was picked, wrongly, before
  bool _choosing = false;
  List<Confusion> _patterns = const []; // pairs mixed up again in this session
  int _round = 0; // how many sessions have been run, to tell a fresh one from the last

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _revealed = false;
    });
    try {
      final start = await widget.reviews
          .startSession(size: sessionSizeFor(widget.minutes), setId: widget.setId);
      final sets = await widget.reviews.setsById({for (final i in start.items) i.setId});
      final done = start.items.isEmpty && (await widget.reviews.counts(setId: widget.setId)).doneToday > 0;
      if (!mounted) return;
      _session?.dispose();
      setState(() {
        _sets = sets;
        _patterns = const [];
        _indexes.clear();
        _doneToday = done;
        _session = PracticeSession(start.items, widget.reviews.recordPractice);
        _round++;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load your practice. Close this and try again.";
        _loading = false;
      });
    }
  }

  Future<void> _loadPatterns() async {
    try {
      final s = _session;
      final missed = {
        for (final m in s?.missed ?? const <PracticeItem>[])
          if (m.isQuestion) m.itemId,
      };
      // Only the pairs that were mixed up again in this session.
      final found = [
        for (final c in await widget.reviews.confusions(setId: widget.setId))
          if (missed.contains(c.questionId)) c,
      ];
      if (mounted) setState(() => _patterns = found.take(3).toList());
    } catch (_) {
      // patterns are a nicety too
    }
  }

  /// The pages of [setId], ready to place a choice on a slide; null for a file
  /// without pages.
  PageIndex? _indexFor(int setId) => _indexes.putIfAbsent(setId, () {
        final set = _sets[setId];
        if (set == null) return null;
        final pages = parsePages(set.sourceText);
        return pages.isEmpty ? null : PageIndex(pages);
      });

  /// A choice was tapped: how often it was picked before is read first, so it does
  /// not count the answer being given now.
  Future<void> _choose(int choice) async {
    final s = _session;
    if (s == null || s.isDone || s.answered || _choosing) return;
    _choosing = true;
    try {
      _earlier = await widget.reviews.timesPicked(s.current.itemId, choice);
    } catch (_) {
      _earlier = 0;
    }
    _choosing = false;
    if (!mounted) return;
    await s.choose(choice);
  }

  /// Where the wrong pick came from, with tags that open the slides.
  Widget _diagnosisFor(PracticeSession s) {
    final item = s.current;
    final chosen = s.lastChosen;
    if (!item.isQuestion || !s.answered || s.lastCorrect != false || chosen == null) {
      return const SizedBox.shrink();
    }
    final index = _indexFor(item.setId);
    final d = diagnose(
      choices: item.choices,
      answerIndex: item.answerIndex,
      chosen: chosen,
      pages: index ?? PageIndex(const []),
      questionSource: item.source,
      earlierPicks: _earlier,
    );
    final line = DiagnosisLine(d);
    final set = _sets[item.setId];
    return set == null ? line : SourceScope.forSet(set, child: line);
  }

  Future<void> _grade(bool correct) async {
    final s = _session;
    if (s == null) return;
    setState(() => _revealed = false);
    await s.answer(correct: correct);
    _advance();
  }

  void _advance() {
    final s = _session;
    if (s == null) return;
    s.next();
    setState(() => _revealed = false);
    if (s.isDone) _loadPatterns();
  }

  Future<void> _acknowledge() async {
    final s = _session;
    if (s == null) return;
    await s.acknowledge();
    _advance();
  }

  /// What Space or Enter does now, or null if nothing.
  VoidCallback? _primary() {
    final s = _session;
    if (s == null || s.isDone) return null;
    if (s.isInterlude) return s.answered ? null : _acknowledge;
    if (s.current.isQuestion) return s.answered ? _advance : null;
    return _revealed ? null : () => setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) => PanelPage(
        child: Focus(
          autofocus: true,
          onKeyEvent: (_, e) {
            if (e is! KeyDownEvent) return KeyEventResult.ignored;
            if (e.logicalKey != LogicalKeyboardKey.space && e.logicalKey != LogicalKeyboardKey.enter) {
              return KeyEventResult.ignored;
            }
            final go = _primary();
            if (go == null) return KeyEventResult.ignored;
            go();
            return KeyEventResult.handled;
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _body(),
            ),
          ),
        ),
      );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _Message(title: 'Something went wrong', text: _error!);
    final s = _session!;
    if (s.total == 0) {
      return _doneToday
          ? const _Message(
              title: 'All done for today', text: 'You have answered everything that is waiting. Come back tomorrow.')
          : const _Message(
              title: 'Nothing to practice yet',
              text: 'Make a study set and its cards and questions will show up here.');
    }
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => s.isDone
          ? _Finish(
              session: s,
              patterns: _patterns,
              tagFor: _tagFor,
              onMore: _load,
            )
          : _Running(
              key: ValueKey('$_round-${s.index}'),
              session: s,
              revealed: _revealed,
              tag: _tagFor(s.current),
              diagnosis: _diagnosisFor(s),
              onReveal: () => setState(() => _revealed = true),
              onGrade: _grade,
              onChoose: _choose,
              onNext: _advance,
              onContrast: _acknowledge,
              slideTag: _slideTag,
            ),
    );
  }

  /// The source tag of [item], tappable into its slide.
  Widget _tagFor(PracticeItem item) {
    final ref = item.source;
    return ref == null ? const SizedBox.shrink() : _slideTag(item.setId, ref);
  }

  /// A tag for [ref] in set [setId], tappable into its slide.
  Widget _slideTag(int setId, SourceRef ref) {
    final set = _sets[setId];
    final tag = SlideTag(ref);
    return set == null ? tag : SourceScope.forSet(set, child: tag);
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Align(alignment: Alignment.centerRight, child: CloseX()),
          const Spacer(),
          Text(title, style: display(30), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(text, style: body(15, color: K.muted), textAlign: TextAlign.center),
          const Spacer(),
        ]),
      );
}

class _Running extends StatelessWidget {
  const _Running({
    super.key,
    required this.session,
    required this.revealed,
    required this.tag,
    required this.diagnosis,
    required this.onReveal,
    required this.onGrade,
    required this.onChoose,
    required this.onNext,
    required this.onContrast,
    required this.slideTag,
  });
  final PracticeSession session;
  final bool revealed;
  final Widget tag;

  /// Where a wrong pick came from; nothing for a right one.
  final Widget diagnosis;
  final VoidCallback onReveal;
  final void Function(bool correct) onGrade;
  final void Function(int choice) onChoose;
  final VoidCallback onNext;
  final VoidCallback onContrast;
  final Widget Function(int setId, SourceRef ref) slideTag;

  @override
  Widget build(BuildContext context) {
    final item = session.current;
    return ListView(padding: const EdgeInsets.fromLTRB(28, 12, 28, 28), children: [
      Row(children: [
        Expanded(child: Text('Practice', style: display(24))),
        Text('${session.gradedIndex + 1} of ${session.gradedTotal}', style: body(13, color: K.muted)),
        const SizedBox(width: 6),
        const CloseX(),
      ]),
      const SizedBox(height: 6),
      KProgress(value: session.gradedIndex / session.gradedTotal),
      const SizedBox(height: 22),
      Text(
        '${item.isContrast ? 'EASY TO MIX UP' : item.isQuestion ? 'QUESTION' : 'FLASHCARD'}${item.setTitle.isEmpty ? '' : ' · ${item.setTitle}'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: body(11, weight: FontWeight.w800, color: K.muted),
      ),
      const SizedBox(height: 8),
      if (item.isContrast)
        ..._contrast(context, item)
      else if (item.isQuestion)
        ..._question(context, item)
      else
        ..._card(context, item),
      if (session.saveFailed) ...[
        const SizedBox(height: 14),
        Text("Couldn't save your progress for this one, so it may come back sooner than planned.",
            style: body(12, color: Colors.red.shade700)),
      ],
    ]);
  }

  List<Widget> _contrast(BuildContext context, PracticeItem item) {
    final c = item.contrast!;
    Widget side(ContrastSide s, Color color) => Panel(
          color: color,
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.term, style: display(22)),
              const SizedBox(height: 8),
              Text(s.text, style: body(14)),
              const SizedBox(height: 10),
              slideTag(item.setId, SourceRef(kind: SourceKind.copied, pages: [s.page], score: 1, quote: s.text)),
            ]),
          ),
        );
    return [
      Text('You have mixed up these ${c.times} times. Here is what your slides say about each.',
          style: body(15, weight: FontWeight.w700)),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, box) {
        final a = side(c.a, K.lavender), b = side(c.b, K.yellow);
        return box.maxWidth >= 560
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: a),
                const SizedBox(width: 14),
                Expanded(child: b),
              ])
            : Column(children: [a, const SizedBox(height: 12), b]);
      }).enter(context),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: PillButton(label: 'Ask me again', icon: Icons.arrow_forward, onPressed: onContrast),
      ),
    ];
  }

  List<Widget> _card(BuildContext context, PracticeItem item) => [
        Panel(
          color: K.lavender,
          padding: const EdgeInsets.all(30),
          child: SizedBox(
            width: double.infinity,
            child: Column(children: [
              Text('question', style: body(13, color: Colors.black54)),
              const SizedBox(height: 12),
              Text(item.prompt, textAlign: TextAlign.center, style: display(30)),
            ]),
          ),
        ).enter(context),
        const SizedBox(height: 14),
        if (!revealed)
          Align(
            alignment: Alignment.centerLeft,
            child: PillButton(label: 'Show answer', icon: Icons.visibility_outlined, onPressed: onReveal),
          )
        else ...[
          Panel(
            color: K.yellow,
            padding: const EdgeInsets.all(30),
            child: SizedBox(
              width: double.infinity,
              child: Column(children: [
                Text('answer', style: body(13, color: Colors.black54)),
                const SizedBox(height: 12),
                Text(item.answer, textAlign: TextAlign.center, style: display(28)),
              ]),
            ),
          ).enter(context),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: tag),
          const SizedBox(height: 16),
          Row(children: [
            PillButton(label: 'Missed it', icon: Icons.close, dark: true, onPressed: () => onGrade(false)),
            const SizedBox(width: 12),
            PillButton(label: 'Got it', icon: Icons.check, onPressed: () => onGrade(true)),
          ]),
        ],
      ];

  List<Widget> _question(BuildContext context, PracticeItem item) {
    final answered = session.answered;
    final last = session.isLastGraded;
    return [
      Panel(
        color: K.lavender,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('question', style: body(13, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(item.prompt, style: display(26)),
          ]),
        ),
      ).enter(context),
      const SizedBox(height: 14),
      for (var i = 0; i < item.choices.length; i++)
        _Choice(
          letter: String.fromCharCode(65 + i),
          text: item.choices[i],
          state: !answered
              ? _ChoiceState.open
              : i == item.answerIndex
                  ? _ChoiceState.right
                  : i == session.lastChosen
                      ? _ChoiceState.wrong
                      : _ChoiceState.rest,
          onTap: answered ? null : () => onChoose(i),
        ),
      if (answered) ...[
        const SizedBox(height: 6),
        Panel(
          color: session.lastCorrect == true ? K.mint : K.pink,
          radius: 18,
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                session.lastCorrect == true ? 'Correct' : 'Not quite. The answer is ${item.answer}.',
                style: body(15, weight: FontWeight.w800),
              ),
              if (item.explanation.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(item.explanation, style: body(13)),
              ],
              if (item.source != null) ...[const SizedBox(height: 10), tag],
            ]),
          ),
        ).enter(context),
        diagnosis,
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: PillButton(label: last ? 'Finish' : 'Next', icon: Icons.arrow_forward, onPressed: onNext),
        ),
      ],
    ];
  }
}

enum _ChoiceState { open, right, wrong, rest }

class _Choice extends StatelessWidget {
  const _Choice({required this.letter, required this.text, required this.state, required this.onTap});
  final String letter;
  final String text;
  final _ChoiceState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _ChoiceState.right => K.mint,
      _ChoiceState.wrong => K.pink,
      _ => K.tile,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: state == _ChoiceState.rest ? 0.55 : 1,
        child: Lift(
          color: color,
          radius: 18,
          padding: const EdgeInsets.all(14),
          onTap: onTap,
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: K.card, borderRadius: BorderRadius.circular(10)),
              child: Text(letter, style: body(14, weight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: body(16, weight: FontWeight.w600))),
            if (state == _ChoiceState.right) const Icon(Icons.check, size: 22),
            if (state == _ChoiceState.wrong) const Icon(Icons.close, size: 22),
          ]),
        ),
      ),
    );
  }
}

class _Finish extends StatelessWidget {
  const _Finish(
      {required this.session,
      required this.patterns,
      required this.tagFor,
      required this.onMore});
  final PracticeSession session;
  final List<Confusion> patterns;
  final Widget Function(PracticeItem) tagFor;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final missed = session.missed;
    final allRight = missed.isEmpty;
    return ListView(padding: const EdgeInsets.all(28), children: [
      const Align(alignment: Alignment.centerRight, child: CloseX()),
      Text('practice complete', style: body(14, color: K.muted)).enter(context),
      const SizedBox(height: 4),
      Text('${session.correctCount} of ${session.gradedTotal}', style: display(72)).enter(context, index: 1),
      Text(allRight ? 'All right. Nice.' : 'right', style: body(18, weight: FontWeight.w700))
          .enter(context, index: 2),
      const SizedBox(height: 18),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _Stat(
            icon: Icons.event_repeat,
            label: 'Back tomorrow',
            value: '${missed.length} ${missed.length == 1 ? 'item' : 'items'}'),
      ]).enter(context, index: 3),
      if (session.saveFailed) ...[
        const SizedBox(height: 12),
        Text("Some answers couldn't be saved, so their schedule did not change.",
            style: body(12, color: Colors.red.shade700)),
      ],
      if (patterns.isNotEmpty) ...[
        const SizedBox(height: 26),
        Text('patterns', style: body(14, color: K.muted)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: K.pink, borderRadius: BorderRadius.circular(18)),
          child: inkOnPastel(
            K.pink,
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final c in patterns) Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(c.message, style: body(14, weight: FontWeight.w700)),
              ),
              Text('A side-by-side comparison will come up in your next practice.',
                  style: body(12, color: Colors.black54)),
            ]),
          ),
        ),
      ],
      if (!allRight) ...[
        const SizedBox(height: 26),
        Text('review these', style: body(14, color: K.muted)),
        const SizedBox(height: 8),
        for (final m in missed)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: K.tile, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.prompt, style: body(16, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Answer: ${m.answer}', style: body(14)),
              if (m.source != null) ...[const SizedBox(height: 8), tagFor(m)],
            ]),
          ),
      ],
      const SizedBox(height: 20),
      Row(children: [
        PillButton(label: 'Practice more', icon: Icons.bolt, onPressed: onMore),
        const SizedBox(width: 12),
        PillButton(label: 'Done', dark: true, onPressed: () => Navigator.of(context).maybePop()),
      ]),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: K.tile, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: body(11, color: K.muted)),
            Text(value, style: body(15, weight: FontWeight.w800)),
          ]),
        ]),
      );
}
