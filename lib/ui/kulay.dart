import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'motion.dart';
import 'theme.dart';

/// Kulay's palette, after the bookshelf reference.
const kulayColors = [
  Color(0xFFF25C8A), // pink
  Color(0xFFF7934C), // orange
  Color(0xFFFFD23F), // yellow
  Color(0xFF2FCB74), // green
  Color(0xFF3D7BF5), // blue
  Color(0xFF49C6F5), // sky
  Color(0xFF8E52EC), // purple
  Color(0xFFFF6B6B), // coral
];
const _indigo = Color(0xFF3A2C82);
const _indigoText = Color(0xFF2E2378);

// ---------------------------------------------------------------------------
// Icon: colored book spines on a little shelf. They wiggle while [active].

class KulayIcon extends StatefulWidget {
  const KulayIcon({super.key, this.size = 24, this.active = false});
  final double size;
  final bool active;

  @override
  State<KulayIcon> createState() => _KulayIconState();
}

class _KulayIconState extends State<KulayIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didUpdateWidget(KulayIcon old) {
    super.didUpdateWidget(old);
    if (widget.active && !reduceMotion(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(widget.size),
        painter: _KulayIconPainter(_c),
      );
}

class _KulayIconPainter extends CustomPainter {
  _KulayIconPainter(this.wiggle) : super(repaint: wiggle);
  final Animation<double> wiggle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final w = math.sin(wiggle.value * 2 * math.pi);
    // (left, top, width, color, lean) standing on y = 20.
    const books = [
      (3.0, 6.0, 3.6, Color(0xFFF25C8A), 0.0),
      (7.0, 3.5, 3.6, Color(0xFFFFD23F), 0.0),
      (11.0, 7.0, 3.4, Color(0xFF3D7BF5), 0.0),
      (15.4, 8.5, 3.4, Color(0xFF2FCB74), -0.32),
    ];
    for (var i = 0; i < books.length; i++) {
      final (x, top, bw, color, lean) = books[i];
      canvas.save();
      canvas.translate(x, 20);
      canvas.rotate(lean + w * 0.12 * (i.isEven ? 1 : -1));
      final r = RRect.fromLTRBR(0, top - 20, bw, 0, const Radius.circular(0.8));
      canvas.drawRRect(r, Paint()..color = color);
      canvas.drawLine(Offset(0.8, top - 20 + 3), Offset(bw - 0.8, top - 20 + 3),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..strokeWidth = 0.9);
      canvas.restore();
    }
    canvas.drawRRect(RRect.fromLTRBR(1.5, 19.6, 22.5, 21.6, const Radius.circular(1)),
        Paint()..color = const Color(0xFFFF8FB1));
  }

  @override
  bool shouldRepaint(_KulayIconPainter old) => old.wiggle != wiggle;
}

// ---------------------------------------------------------------------------
// Full-window color burst: the screen crystallizes into colored triangles
// from [origin], calls [onCovered] while fully covered, then shatters away.

void playColorBurst(BuildContext context,
    {required Offset origin, required VoidCallback onCovered}) {
  if (reduceMotion(context)) {
    onCovered();
    return;
  }
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Burst(origin: origin, onCovered: onCovered, onDone: () => entry.remove()),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
}

class _Burst extends StatefulWidget {
  const _Burst({required this.origin, required this.onCovered, required this.onDone});
  final Offset origin;
  final VoidCallback onCovered;
  final VoidCallback onDone;

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (!_covered && _c.value >= _BurstPainter.coverEnd) {
        _covered = true;
        widget.onCovered();
      }
    });
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox.expand(
          child: CustomPaint(painter: _BurstPainter(_c, widget.origin)),
        ),
      );
}

class _Crystal {
  _Crystal(this.a, this.b, this.c, this.color, this.spin)
      : center = (a + b + c) / 3;
  final Offset a, b, c, center;
  final int color;
  final double spin;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.origin) : super(repaint: t);
  final Animation<double> t;
  final Offset origin;

  static const coverEnd = 0.45; // fully covered from here...
  static const clearStart = 0.58; // ...until here

  static Size? _cachedSize;
  static List<_Crystal> _cached = const [];

  /// Jittered grid split into triangles; cached per window size.
  static List<_Crystal> _crystals(Size s) {
    if (s == _cachedSize) return _cached;
    final rnd = math.Random(5);
    const cell = 72.0;
    final cols = (s.width / cell).ceil() + 2, rows = (s.height / cell).ceil() + 2;
    final pts = [
      for (var r = 0; r < rows; r++)
        [
          for (var c = 0; c < cols; c++)
            Offset(
              (c - 0.5) * cell + (c == 0 || c == cols - 1 ? 0 : (rnd.nextDouble() - 0.5) * cell * 0.7),
              (r - 0.5) * cell + (r == 0 || r == rows - 1 ? 0 : (rnd.nextDouble() - 0.5) * cell * 0.7),
            )
        ]
    ];
    final out = <_Crystal>[];
    for (var r = 0; r < rows - 1; r++) {
      for (var c = 0; c < cols - 1; c++) {
        final p00 = pts[r][c], p01 = pts[r][c + 1], p10 = pts[r + 1][c], p11 = pts[r + 1][c + 1];
        final flip = (r + c).isEven;
        final tris = flip
            ? [(p00, p01, p11), (p00, p11, p10)]
            : [(p00, p01, p10), (p01, p11, p10)];
        for (final (a, b, cc) in tris) {
          out.add(_Crystal(a, b, cc, rnd.nextInt(kulayColors.length), (rnd.nextDouble() - 0.5) * 2));
        }
      }
    }
    _cachedSize = s;
    _cached = out;
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final crystals = _crystals(size);
    final far = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height)
    ].map((p) => (p - origin).distance).reduce(math.max) + 80;
    const band = 220.0; // how far behind the wave front a crystal finishes growing

    final cover = Curves.easeInCubic.transform((v / coverEnd).clamp(0.0, 1.0)) * (far + band);
    final clear = Curves.easeInOutCubic
            .transform(((v - clearStart) / (1 - clearStart)).clamp(0.0, 1.0)) *
        (far + band);

    final paths = List.generate(kulayColors.length, (_) => Path());
    for (final cr in crystals) {
      final d = (cr.center - origin).distance;
      var k = ((cover - d) / band).clamp(0.0, 1.0); // grow in
      if (v >= clearStart) k = 1 - ((clear - d) / band).clamp(0.0, 1.0); // shatter out
      if (k <= 0) continue;
      final grow = v < clearStart ? Curves.easeOutBack.transform(k) : k;
      final ang = (1 - k) * cr.spin;
      final ca = math.cos(ang), sa = math.sin(ang);
      Offset tf(Offset p) {
        final q = (p - cr.center) * grow;
        return cr.center + Offset(q.dx * ca - q.dy * sa, q.dx * sa + q.dy * ca);
      }

      final a = tf(cr.a), b = tf(cr.b), c = tf(cr.c);
      paths[cr.color]
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close();
    }
    for (var i = 0; i < paths.length; i++) {
      final paint = Paint()..color = kulayColors[i];
      canvas.drawPath(paths[i], paint);
      // A hairline of the same color hides seams between neighbours.
      canvas.drawPath(
          paths[i],
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.origin != origin;
}

// ---------------------------------------------------------------------------
// Full-screen Kulay dashboard.

class KulayScreen extends StatelessWidget {
  const KulayScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    Widget enter(Widget w, int i) => still
        ? w
        : w
            .animate(delay: (250 + i * 90).ms)
            .fadeIn(duration: 500.ms, curve: Motion.curve)
            .slideX(begin: -0.08, end: 0, duration: 500.ms, curve: Motion.curve);

    return Scaffold(
      backgroundColor: _indigo,
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(14),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: LayoutBuilder(builder: (context, box) {
            final narrow = box.maxWidth < 760;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                enter(Row(mainAxisSize: MainAxisSize.min, children: [
                  const KulayIcon(size: 34),
                  const SizedBox(width: 10),
                  Text('Kodigno', style: body(14, weight: FontWeight.w700, color: _indigoText)),
                ]), 0),
                const SizedBox(height: 22),
                enter(Text('Kulay', style: display(narrow ? 52 : 72, color: _indigoText)), 1),
                const SizedBox(height: 14),
                enter(
                    SizedBox(
                      width: 360,
                      child: Text(
                        'A colorful shelf for your studies. Coming soon.',
                        style: body(17, color: const Color(0xFF55507A)),
                      ),
                    ),
                    2),
                const SizedBox(height: 26),
                enter(_BackPill(onTap: onBack), 3),
                const SizedBox(height: 26),
                enter(
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          width: i == 1 ? 8 : 6,
                          height: i == 1 ? 8 : 6,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: i == 1 ? _indigoText : const Color(0xFFC9C5DD),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ]),
                    4),
              ],
            );
            return Stack(children: [
              Positioned.fill(child: _Shelves(narrow: narrow)),
              Positioned(
                left: narrow ? 20 : 64,
                right: narrow ? 20 : null,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: narrow ? Alignment.topLeft : Alignment.centerLeft,
                  child: narrow
                      ? Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: content,
                        )
                      : content,
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  const _BackPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: _indigoText,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 22, 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text('Back to Kodigno',
                  style: body(14, weight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
      );
}

/// Sweeping bookshelf on the right, books popping in shelf by shelf.
class _Shelves extends StatefulWidget {
  const _Shelves({required this.narrow});
  final bool narrow;

  @override
  State<_Shelves> createState() => _ShelvesState();
}

class _ShelvesState extends State<_Shelves> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(child: CustomPaint(painter: _ShelfPainter(_c, widget.narrow)));
}

class _ShelfPainter extends CustomPainter {
  _ShelfPainter(this.t, this.narrow) : super(repaint: t);
  final Animation<double> t;
  final bool narrow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = t.value;

    // Shelf area: everything right of a sweeping curve.
    final left = narrow ? 0.0 : 0.42;
    final area = Path()
      ..moveTo(w * (left + 0.16), 0)
      ..cubicTo(w * (left + 0.02), h * 0.2, w * (left + 0.1), h * 0.42, w * (left - 0.04), h * 0.62)
      ..cubicTo(w * (left - 0.14), h * 0.78, w * (left - 0.24), h * 0.86, w * (left - 0.3), h)
      ..lineTo(w, h)
      ..lineTo(w, 0)
      ..close();
    canvas.save();
    canvas.clipPath(area);
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF111018));

    const shelves = 6;
    final gap = h * 0.21;
    double scaleAt(double x) => 0.5 + 0.65 * (x / w);
    double baseY(int i, double x) {
      final u = 1 - x / w;
      return gap * (i - 0.25) + h * 0.5 * u * u;
    }

    for (var i = 0; i < shelves; i++) {
      final rnd = math.Random(31 + i);
      // Books, left to right; each pops up once the reveal passes it.
      var x = 0.0;
      while (x < w) {
        final s = scaleAt(x);
        final bw = h * 0.017 * s * (0.75 + rnd.nextDouble() * 0.9);
        final bh = gap * s * (0.55 + rnd.nextDouble() * 0.3);
        final color = kulayColors[rnd.nextInt(kulayColors.length)];
        final reveal = p * 1.6 - i * 0.08 - (x / w) * 0.6;
        final k = Curves.easeOutBack.transform(reveal.clamp(0.0, 1.0));
        if (k > 0) {
          final y0 = baseY(i, x), y1 = baseY(i, x + bw);
          final top = bh * k;
          canvas.drawPath(
              Path()
                ..moveTo(x, y0)
                ..lineTo(x, y0 - top)
                ..lineTo(x + bw, y1 - top)
                ..lineTo(x + bw, y1)
                ..close(),
              Paint()..color = color);
        }
        x += bw + 0.6;
      }
      // Shelf board.
      final board = Path();
      const steps = 36;
      for (var k = 0; k <= steps; k++) {
        final bx = w * k / steps;
        final y = baseY(i, bx);
        k == 0 ? board.moveTo(bx, y) : board.lineTo(bx, y);
      }
      for (var k = steps; k >= 0; k--) {
        final bx = w * k / steps;
        board.lineTo(bx, baseY(i, bx) + h * 0.014 * scaleAt(bx) + 2);
      }
      board.close();
      canvas.drawPath(
          board,
          Paint()
            ..shader = const LinearGradient(colors: [Color(0xFFF7A1C4), Color(0xFFFF6B7D)])
                .createShader(Offset.zero & size));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShelfPainter old) => old.t != t || old.narrow != narrow;
}
