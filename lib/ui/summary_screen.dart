import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../data/repository.dart';
import '../domain/summary.dart';
import 'motion.dart';
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

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _lesson!.toText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lesson copied')));
  }

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
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _busy
                    ? const _Writing()
                    : _lesson != null
                        ? _Lesson(_lesson!, onCopy: _copy, onRedo: _run)
                        : _Start(onStart: _run, error: _error),
              ),
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
            const _PenScribble(),
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
          const _PenScribble(),
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

/// A pen writing a curvy line, over and over: it fades in, draws, holds,
/// then line and pen fade out together, so each loop starts from nothing.
class _PenScribble extends StatefulWidget {
  const _PenScribble();
  @override
  State<_PenScribble> createState() => _PenScribbleState();
}

class _PenScribbleState extends State<_PenScribble> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c
        ..stop()
        ..value = 0.8; // the finished line, pen at rest
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Writing',
        child: SizedBox(
          width: 170,
          height: 96,
          child: CustomPaint(painter: _ScribblePainter(_c, ink: K.lavender, outline: K.ink)),
        ),
      );
}

class _ScribblePainter extends CustomPainter {
  _ScribblePainter(this.t, {required this.ink, required this.outline}) : super(repaint: t);
  final Animation<double> t;
  final Color ink, outline;

  static double _seg(double v, double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);

  /// A loose handwriting stroke: a rise, a small loop, and a wave out.
  static Path _stroke(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(w * 0.069, h * 0.70)
      ..cubicTo(w * 0.151, h * 0.30, w * 0.233, h * 0.28, w * 0.282, h * 0.52)
      ..cubicTo(w * 0.332, h * 0.80, w * 0.414, h * 0.86, w * 0.430, h * 0.56)
      ..cubicTo(w * 0.446, h * 0.30, w * 0.348, h * 0.30, w * 0.381, h * 0.50)
      ..cubicTo(w * 0.414, h * 0.72, w * 0.528, h * 0.78, w * 0.594, h * 0.50)
      ..cubicTo(w * 0.643, h * 0.30, w * 0.725, h * 0.32, w * 0.791, h * 0.58);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    // Timeline: fade in, draw, hold, fade everything out.
    final appear = Curves.easeOut.transform(_seg(v, 0.0, 0.10));
    final drawn = Curves.easeInOutCubic.transform(_seg(v, 0.06, 0.72));
    final vanish = 1 - Curves.easeIn.transform(_seg(v, 0.84, 1.0));
    final alpha = appear * vanish;
    if (alpha <= 0.001) return;

    final metric = _stroke(size).computeMetrics().first;
    final len = metric.length * drawn;
    if (len > 0.5) {
      canvas.drawPath(
        metric.extractPath(0, len),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ink.withValues(alpha: alpha),
      );
    }

    // The pen, its tip on the end of the line, tilting with the stroke a little.
    final at = metric.getTangentForOffset(math.max(len, 0.001))!;
    final tilt = 0.62 + 0.15 * math.sin(at.angle); // body up and to the right, like a right hand
    canvas.save();
    canvas.translate(at.position.dx, at.position.dy);
    canvas.rotate(tilt);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..color = outline.withValues(alpha: alpha);
    // Nib, from the tip up to the body.
    final nib = Path()
      ..moveTo(0, 0)
      ..lineTo(-5, -12)
      ..lineTo(5, -12)
      ..close();
    canvas.drawPath(nib, Paint()..color = Colors.white.withValues(alpha: alpha));
    canvas.drawPath(nib, edge);
    canvas.drawCircle(const Offset(0, -2.5), 1.6, Paint()..color = outline.withValues(alpha: alpha));
    // Body and cap.
    final body = RRect.fromLTRBR(-6, -50, 6, -12, const Radius.circular(3));
    canvas.drawRRect(body.shift(const Offset(3, 2)), Paint()..color = outline.withValues(alpha: 0.9 * alpha));
    canvas.drawRRect(body, Paint()..color = ink.withValues(alpha: alpha));
    canvas.drawRRect(body, edge);
    canvas.drawLine(const Offset(-6, -40), const Offset(6, -40), edge);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScribblePainter old) => old.ink != ink || old.outline != outline;
}

class _Lesson extends StatelessWidget {
  const _Lesson(this.lesson, {required this.onCopy, required this.onRedo});
  final LessonSummary lesson;
  final VoidCallback onCopy;
  final VoidCallback onRedo;

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
            terms: lesson.sections[n].terms),
      if (lesson.takeaways.isNotEmpty)
        _Card(K.mint, 'Remember', const [], bullets: lesson.takeaways),
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
      {this.bullets = const [], this.facts = const [], this.terms = const []});
  final Color color;
  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<String> facts; // verbatim dates and figures, shown apart from the points
  final List<String> terms; // the phrases the topic keeps coming back to

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
                      child: SelectableText(f, style: body(13, weight: FontWeight.w600)),
                    ),
                  ),
              ],
            ]),
          ),
        ),
      );
}
