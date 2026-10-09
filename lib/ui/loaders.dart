import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'motion.dart';
import 'theme.dart';

/// Seconds since mount, for looping CustomPainters. Frozen when the OS asks
/// for reduced motion.
class LoopClock extends StatefulWidget {
  const LoopClock({super.key, required this.builder, this.stillAt = 0.4});
  final Widget Function(BuildContext context, ValueListenable<double> time) builder;
  final double stillAt;

  @override
  State<LoopClock> createState() => _LoopClockState();
}

class _LoopClockState extends State<LoopClock> with SingleTickerProviderStateMixin {
  late final _time = ValueNotifier<double>(0);
  Ticker? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _ticker?.stop();
      _time.value = widget.stillAt;
    } else {
      _ticker ??= createTicker((e) => _time.value = e.inMicroseconds / 1e6);
      if (!_ticker!.isActive) _ticker!.start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _time);
}

enum LoaderArt { folder, eye }

/// Loader with animated art, a label and a progress bar. Calls [onDone] once
/// the bar fills. [fullScreen] = its own always-white page (between home and
/// the app); otherwise it sits inside a page and follows the theme.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    required this.art,
    required this.label,
    required this.onDone,
    this.duration = const Duration(milliseconds: 2200),
    this.fullScreen = true,
  });
  final LoaderArt art;
  final String label;
  final VoidCallback onDone;
  final Duration duration;
  final bool fullScreen;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _progress.duration =
        reduceMotion(context) ? const Duration(milliseconds: 700) : widget.duration;
    _progress.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folder = widget.art == LoaderArt.folder;
    final full = widget.fullScreen;
    final view = Center(
        child: LoopClock(
          builder: (context, time) => Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 260,
              height: folder ? 212 : 180,
              child: CustomPaint(
                  painter: folder ? FolderBoxPainter(time) : ColorEyePainter(time, spin: 2.2)),
            ),
            const SizedBox(height: 28),
            ValueListenableBuilder<double>(
              valueListenable: time,
              builder: (context, t, _) => Text(
                '${widget.label}${'.' * ((t * 3).floor() % 4)}',
                style: display(28, color: full ? K.ink : K.text),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => _Bar(
                  value: Curves.easeInOutCubic.transform(_progress.value),
                  track: full ? const Color(0xFFEDEBF0) : K.line,
                  colors: folder
                      ? const [Color(0xFF2E8B7A), Color(0xFF2E8B7A)]
                      : ColorEyePainter.wedges,
                ),
              ),
            ),
          ]),
        ).animate().fadeIn(duration: 400.ms, curve: Motion.curve),
      );
    return full ? Scaffold(backgroundColor: Colors.white, body: view) : view;
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.colors, required this.track});
  final double value;
  final List<Color> colors;
  final Color track;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: 6,
          color: track,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: colors))),
          ),
        ),
      );
}

/// Kulay tab of the dashboard. Each time the tab is opened it plays the eye
/// loader first, then shows the page (a placeholder until the feature exists).
class KulayPage extends StatefulWidget {
  const KulayPage({super.key, required this.tab, required this.index});
  final ValueNotifier<int> tab;
  final int index; // this page's tab index

  @override
  State<KulayPage> createState() => _KulayPageState();
}

class _KulayPageState extends State<KulayPage> {
  var _run = 0;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.tab.addListener(_onTab);
  }

  @override
  void dispose() {
    widget.tab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (widget.tab.value != widget.index) return;
    setState(() {
      _run++;
      _loaded = false;
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _loaded
            ? const _KulayContent(key: ValueKey('kulay'))
            : LoadingScreen(
                key: ValueKey(_run),
                art: LoaderArt.eye,
                label: 'Opening Kulay',
                fullScreen: false,
                onDone: () => setState(() => _loaded = true),
              ),
      );
}

class _KulayContent extends StatelessWidget {
  const _KulayContent({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: LoopClock(
          builder: (context, time) => Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
                width: 240, height: 166, child: CustomPaint(painter: ColorEyePainter(time, spin: 0.5))),
            const SizedBox(height: 24),
            Text('Kulay', style: display(48)),
            const SizedBox(height: 10),
            Text('Coming soon.', style: body(16, color: K.muted)),
          ]),
        ),
      );
}

/// "← Home" pill. [onWhite] forces dark-on-white for the always-white screens.
class BackHomeButton extends StatefulWidget {
  const BackHomeButton({super.key, required this.onPressed, this.onWhite = false});
  final VoidCallback onPressed;
  final bool onWhite;

  @override
  State<BackHomeButton> createState() => _BackHomeButtonState();
}

class _BackHomeButtonState extends State<BackHomeButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.onWhite ? K.ink : K.text;
    final bg = widget.onWhite ? Colors.white : K.bg;
    return Tooltip(
      message: 'Back to home',
      child: Material(
        color: bg,
        shape: StadiumBorder(side: BorderSide(color: fg, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: widget.onPressed,
          onHover: (v) => setState(() => _hover = v),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 16, 9),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedSlide(
                offset: Offset(_hover && !reduceMotion(context) ? -0.18 : 0, 0),
                duration: Motion.fast,
                curve: Motion.curve,
                child: Icon(Icons.arrow_back_rounded, size: 18, color: fg),
              ),
              const SizedBox(width: 6),
              Text('Home', style: body(15, weight: FontWeight.w700, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Art. Both are drawn in a fixed design space and scaled to fit.

const _outline = Color(0xFF14202B);

/// Storage box of folders (after the reference): the folders take turns
/// popping up while the box bobs.
class FolderBoxPainter extends CustomPainter {
  FolderBoxPainter(this.time) : super(repaint: time);
  final ValueListenable<double> time;

  static const _teal = Color(0xFF2E8B7A);
  static const _interior = Color(0xFF1C5148);
  static const _khaki = Color(0xFFC9B36B);

  // Back to front: left, right, top, tab start, tab width, color.
  static const _folders = [
    (190.0, 250.0, 64.0, 204.0, 30.0, K.blue),
    (72.0, 196.0, 20.0, 150.0, 40.0, Colors.white),
    (58.0, 182.0, 64.0, 108.0, 42.0, _khaki),
    (40.0, 166.0, 80.0, 52.0, 40.0, K.pink),
  ];

  Path _poly(List<Offset> p) => Path()..addPolygon(p, true);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final s = math.min(size.width / 300, size.height / 245);
    canvas.translate((size.width - 300 * s) / 2, (size.height - 245 * s) / 2);
    canvas.scale(s);
    canvas.translate(-10, -14 + math.sin(t * 3) * 3);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..color = _outline;
    Paint fill(Color c) => Paint()..color = c;

    const a = Offset(32, 105), b = Offset(168, 120), c = Offset(168, 228), d = Offset(36, 208);
    const g = Offset(128, 72), e = Offset(264, 86), f = Offset(264, 184);

    // Drop shadow.
    canvas.drawPath(_poly(const [a, b, e, f, c, d]).shift(const Offset(10, 10)), fill(_outline));

    // Inside of the box.
    final inside = _poly(const [a, g, e, b]);
    canvas.drawPath(inside, fill(_interior));
    canvas.drawPath(inside, stroke);

    // Folders, sheared to sit in the box's perspective; one rises at a time.
    canvas.save();
    canvas.clipPath(_poly(const [Offset(0, 0), Offset(330, 0), e, b, a]));
    canvas.skew(0, 0.11);
    for (var i = 0; i < _folders.length; i++) {
      final (x0, x1, top0, tabX, tabW, color) = _folders[i];
      final local = (t / 0.55 - i) % _folders.length;
      final lift = local < 1 ? math.sin(math.pi * local) : 0.0;
      final top = top0 - lift * 26;
      const bottom = 200.0;
      final path = Path()
        ..moveTo(x0, bottom)
        ..lineTo(x0, top)
        ..lineTo(tabX, top)
        ..lineTo(tabX + 6, top - 12)
        ..lineTo(tabX + tabW - 6, top - 12)
        ..lineTo(tabX + tabW, top)
        ..lineTo(x1, top)
        ..lineTo(x1, bottom)
        ..close();
      canvas.drawPath(path, fill(color));
      canvas.drawPath(path, stroke);
    }
    canvas.restore();

    // Front and side.
    final front = _poly(const [a, b, c, d]);
    canvas.drawPath(front, fill(Colors.white));
    canvas.drawPath(front, stroke);
    final side = _poly(const [b, e, f, c]);
    canvas.drawPath(side, fill(_teal));
    canvas.drawPath(side, stroke);

    // Handle.
    canvas.save();
    canvas.skew(0, 0.11);
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(74, 136, 44, 15), const Radius.circular(8)),
        fill(_outline));
    canvas.restore();
  }

  @override
  bool shouldRepaint(FolderBoxPainter old) => old.time != time;
}

/// Eye with a color-wheel iris (after the reference). The wedges rotate and
/// the eye blinks every few seconds.
class ColorEyePainter extends CustomPainter {
  ColorEyePainter(this.time, {this.spin = 1.4}) : super(repaint: time);
  final ValueListenable<double> time;
  final double spin; // radians per second

  static const _navy = Color(0xFF0B2239);
  static const _cream = Color(0xFFF7F4EC);
  static const wedges = [
    Color(0xFFE8453C),
    Color(0xFFF2B21B),
    Color(0xFF6E7A2C),
    Color(0xFF1E4E8C),
    Color(0xFFF08BB5),
    Color(0xFF3E86B8),
    Color(0xFFEE7B2A),
    Color(0xFF8E3C6E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final s = math.min(size.width / 270, size.height / 186);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);

    // Blink: squash vertically for a moment every 2.6 s.
    final local = t % 2.6;
    final open = local > 2.3 ? 1 - 0.94 * math.sin(math.pi * (local - 2.3) / 0.3) : 1.0;
    canvas.scale(1, open);

    final almond = Path()
      ..moveTo(-128, 0)
      ..cubicTo(-80, -58, -44, -92, 0, -92)
      ..cubicTo(44, -92, 80, -58, 128, 0)
      ..cubicTo(80, 58, 44, 92, 0, 92)
      ..cubicTo(-44, 92, -80, 58, -128, 0)
      ..close();
    canvas.drawPath(almond, Paint()..color = _navy);
    canvas.drawCircle(Offset.zero, 74, Paint()..color = _cream);

    const r = 58.0;
    final sweep = 2 * math.pi / wedges.length;
    final rot = t * spin;
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    for (var k = 0; k < wedges.length; k++) {
      canvas.drawArc(rect, rot + k * sweep, sweep + 0.005, true, Paint()..color = wedges[k]);
    }
    canvas.drawCircle(Offset.zero, 22, Paint()..color = _navy);
  }

  @override
  bool shouldRepaint(ColorEyePainter old) => old.time != time || old.spin != spin;
}
