import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../data/database.dart' show StudySet;
import '../data/repository.dart';
import '../domain/source_ref.dart';
import '../domain/summary.dart';
import 'motion.dart';
import 'slide_tag.dart';
import 'teach_back_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// The lesson of one study set. It is saved with the set the first time it is
/// written, and shown from then on without calling the model; Rewrite replaces it.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({
    super.key,
    required this.repo,
    required this.setId,
    required this.title,
    required this.notes,
  });
  final StudyRepository repo;
  final int setId;
  final String title;
  final String notes;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  LessonSummary? _lesson;
  StudySet? _set; // for the file behind the lesson, so a source tag can open its slide
  bool _loading = true; // reading the saved lesson
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.repo.getSet(widget.setId).then((d) {
      if (mounted) {
        setState(() {
          _lesson = d.summary;
          _set = d.set;
          _loading = false;
        });
      }
    });
  }

  Future<void> _run() async {
    if (_busy) return;
    final app = context.read<AppController>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final lesson = await app.summarize(widget.notes);
      await widget.repo.saveSummary(widget.setId, lesson);
      if (!mounted) return;
      setState(() => _lesson = lesson);
    } on SummaryFailed catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens "explain it back" for topic number [n] of the lesson.
  void _teach(int n) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TeachBackScreen(
          repo: widget.repo, setId: widget.setId, sectionIndex: n, model: teachModelOf(context))));

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _lesson!.toText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lesson copied')));
  }

  Widget _withSources(Widget child) =>
      _set == null ? child : SourceScope.forSet(_set!, child: child);

  @override
  Widget build(BuildContext context) => PanelPage(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 12, 0),
                child: Row(children: [
                  Expanded(
                      child: Text('Summary of ${widget.title}',
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: display(24))),
                  const CloseX(),
                ]),
              ),
              Expanded(child: _withSources(_loading
                  ? const Center(child: CircularProgressIndicator())
                  : _busy
                      ? const _Writing()
                      : _lesson != null
                          ? _Lesson(_lesson!, onCopy: _copy, onRedo: _run, onTeach: _teach)
                          : _Start(onStart: _run, error: _error))),
            ]),
          ),
        ),
      );
}

class _Start extends StatelessWidget {
  const _Start({required this.onStart, this.error});
  final VoidCallback onStart;
  final String? error;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const KSticker(icon: Icons.auto_stories_outlined, color: K.lavender, size: 64),
            const SizedBox(height: 20),
            Text('Make a lesson', style: display(28)),
            const SizedBox(height: 8),
            Text('Your notes become a short lesson that explains each topic\nand lists what to remember.',
                textAlign: TextAlign.center, style: body(15, color: K.muted)),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error!, textAlign: TextAlign.center, style: body(13, color: Colors.red.shade400)),
            ],
            const SizedBox(height: 24),
            PillButton(
                label: error == null ? 'Summarize' : 'Try again',
                icon: Icons.auto_awesome,
                onPressed: onStart),
          ]).enter(context),
        ),
      );
}

class _Writing extends StatelessWidget {
  const _Writing();

  @override
  Widget build(BuildContext context) {
    final fraction = context.watch<AppController>().summaryFraction;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const KSticker(icon: Icons.auto_stories_outlined, color: K.lavender, size: 64),
          const SizedBox(height: 20),
          Text('Writing your lesson…', style: display(24)),
          const SizedBox(height: 6),
          Text('This can take a minute on the first run.', style: body(14, color: K.muted)),
          const SizedBox(height: 20),
          SizedBox(width: 280, child: KProgress(value: fraction, color: K.lavender, height: 8)),
        ]),
      ),
    );
  }
}

class _Lesson extends StatelessWidget {
  const _Lesson(this.lesson, {required this.onCopy, required this.onRedo, required this.onTeach});
  final LessonSummary lesson;
  final VoidCallback onCopy;
  final VoidCallback onRedo;

  /// Opens the Teach-Back screen for topic number [n] of the lesson.
  final void Function(int n) onTeach;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (lesson.overview.isNotEmpty)
        _Card(K.yellow, 'The big idea', [lesson.overview], terms: lesson.keyTerms),
      for (var n = 0; n < lesson.sections.length; n++)
        _Card(K.pastels[(n + 1) % K.pastels.length], lesson.sections[n].heading,
            [if (lesson.sections[n].explanation.isNotEmpty) lesson.sections[n].explanation],
            bullets: lesson.sections[n].keyPoints,
            facts: lesson.sections[n].facts,
            terms: lesson.sections[n].terms,
            sourceOf: lesson.sourceOf,
            onTeachBack: () => onTeach(n)),
      if (lesson.takeaways.isNotEmpty)
        _Card(K.mint, 'Remember', const [], bullets: lesson.takeaways, sourceOf: lesson.sourceOf),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
      children: [
        for (var n = 0; n < cards.length; n++) cards[n].enter(context, index: n),
        const SizedBox(height: 4),
        Text(
            'Written by a small AI on this computer. The key facts are copied straight from your slides; check the rest against them.',
            style: body(12, color: K.muted)),
        const SizedBox(height: 14),
        Row(children: [
          PillButton(label: 'Copy lesson', icon: Icons.copy, onPressed: onCopy),
          const SizedBox(width: 12),
          PillButton(label: 'Rewrite', icon: Icons.refresh, dark: true, onPressed: onRedo),
        ]).enter(context, index: cards.length),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card(this.color, this.heading, this.paragraphs,
      {this.bullets = const [],
      this.facts = const [],
      this.terms = const [],
      this.sourceOf,
      this.onTeachBack});

  /// Opens "explain it back" for this topic; null for a card that is not a topic.
  final VoidCallback? onTeachBack;
  final Color color;
  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<String> facts; // verbatim dates and figures, shown apart from the points
  final List<String> terms; // the phrases the topic keeps coming back to

  /// The page behind a piece of text, if it was looked up; shown as a tag.
  final SourceRef? Function(String text)? sourceOf;

  Widget _tag(String text) {
    final ref = sourceOf?.call(text);
    return ref == null ? const SizedBox.shrink() : SlideTag(ref);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Panel(
          color: color,
          padding: const EdgeInsets.all(22),
          child: SizedBox(
            width: double.infinity,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(heading, style: display(22)),
              if (terms.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final t in terms)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: K.ink.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t, style: body(12, weight: FontWeight.w700)),
                    ),
                ]),
              ],
              for (final p in paragraphs) ...[
                const SizedBox(height: 10),
                SelectableText(p, style: body(15)),
                if (sourceOf?.call(p) != null) Padding(padding: const EdgeInsets.only(top: 6), child: _tag(p)),
              ],
              if (bullets.isNotEmpty) const SizedBox(height: 12),
              for (final b in bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: CircleAvatar(radius: 3, backgroundColor: K.ink),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: SelectableText(b, style: body(14, weight: FontWeight.w600))),
                    if (sourceOf?.call(b) != null) Padding(padding: const EdgeInsets.only(left: 8), child: _tag(b)),
                  ]),
                ),
              if (facts.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('KEY FACTS', style: body(11, weight: FontWeight.w800, color: K.ink.withValues(alpha: 0.6))),
                const SizedBox(height: 6),
                for (final f in facts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: K.ink.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: SelectableText(f, style: body(13, weight: FontWeight.w600))),
                        if (sourceOf?.call(f) != null) Padding(padding: const EdgeInsets.only(left: 8), child: _tag(f)),
                      ]),
                    ),
                  ),
              ],
              if (onTeachBack != null) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PillButton(label: 'Explain it back', icon: Icons.edit_outlined, dark: true, onPressed: onTeachBack),
                ),
              ],
            ]),
          ),
        ),
      );
}
