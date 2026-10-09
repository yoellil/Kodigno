import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../ui/motion.dart';
import '../../ui/theme.dart';

const _cream = Color(0xFFFFF7E6);
const _pageInk = Color(0xFF2E2378); // printed lines on cream pages, in either mode

/// Book cover colors, after the reference: deep, printed-cloth tones.
const bookColors = [
  Color(0xFF1F3B2D), // deep green
  Color(0xFFEDEAE4), // off-white
  Color(0xFF6E1A2B), // maroon
  Color(0xFFC9A43A), // mustard
  Color(0xFFB4532A), // rust
  Color(0xFF151515), // black
  Color(0xFF1B2440), // navy
  Color(0xFFE4DED1), // cream
  Color(0xFF2E3238), // charcoal
  Color(0xFF3E5C76), // slate blue
  Color(0xFF7A3E2E), // brown
  Color(0xFF5B6B3A), // olive
];

Color _inkOn(Color c) => c.computeLuminance() > 0.45 ? const Color(0xFF1C1A22) : Colors.white;
Color _shade(Color c, double t) => Color.lerp(c, Colors.black, t)!;
Color _tint(Color c, double t) => Color.lerp(c, Colors.white, t)!;

/// The color of the book that was opened last, so the writing page can keep it.
Color? lastOpenedBookColor;

/// Size and look of one book.
typedef BookSpec = ({double width, double height, Color color, int style});

/// A 3D book for the opening flight and the writing button: a spine facing
/// you, the cover and pages behind it. [turn] swings the book on its spine's
/// right edge (0 = spine on, pi/2 = cover on), [open] swings the cover open
/// (0 to about 2.8), and [flip] (0 to 1) turns one page from right to left.
class Book3D extends StatelessWidget {
  const Book3D({
    super.key,
    required this.title,
    required this.color,
    this.width = 44,
    this.height = 160,
    this.turn = 0,
    this.open = 0,
    this.flip,
    this.scale = 1,
    this.style = 0,
  });

  final String title;
  final Color color;
  final double width, height, turn, open, scale;
  final double? flip;
  final int style;

  double get coverWidth => height * 0.68;

  Matrix4 _hinge() => Matrix4.identity()
    ..translateByDouble(width, 0, 0, 1)
    ..rotateY(turn - math.pi / 2);

  Widget _at(Matrix4 m, Widget child) => Positioned(left: 0, top: 0, child: Transform(transform: m, child: child));

  @override
  Widget build(BuildContext context) {
    final cw = coverWidth;
    final spine = Matrix4.identity()
      ..translateByDouble(width, 0, 0, 1)
      ..rotateY(turn)
      ..translateByDouble(-width, 0, 0, 1);
    final pages = _at(_hinge()..translateByDouble(0, 3, 0, 1), _Pages(cw - 4, height - 6, back: true));
    final sheet = flip == null || flip! <= 0 || flip! >= 1
        ? null
        : _at(_hinge()..translateByDouble(0, 4, 0, 1)..rotateY(flip! * math.pi), _Pages(cw - 6, height - 8));
    final opened = open > math.pi / 2;
    final cover = _at(
        _hinge()..rotateY(open),
        opened
            ? _CoverInside(cw, height, color)
            : BookCoverFace(title: title, color: color, width: cw, height: height));
    return SizedBox(
      width: width,
      height: height,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..scaleByDouble(scale, scale, scale, 1),
        child: Stack(clipBehavior: Clip.none, children: [
          // Edge-on at rest, so only the spine shows until the book turns.
          if (turn > 0.02) ...[
            pages,
            if (opened) ...[cover, ?sheet] else ...[?sheet, cover],
          ],
          if (turn < math.pi / 2 - 0.02)
            _at(spine, BookSpineFace(title: title, color: color, width: width, height: height)),
        ]),
      ),
    );
  }
}

/// A printed cover: a small series line, the title large, a short byline.
class BookCoverFace extends StatelessWidget {
  const BookCoverFace({super.key, required this.title, required this.color, required this.width, required this.height});
  final String title;
  final Color color;
  final double width, height;

  /// Title size: as large as fits, but never so large a word breaks.
  double _titleSize() {
    // Room inside the padding and hinge, with a little to spare.
    final base = height * 0.13, room = width * 0.68;
    var longest = 0.0;
    for (final word in title.split(RegExp(r'\s+'))) {
      final tp = TextPainter(
        text: TextSpan(text: word, style: display(base)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      longest = math.max(longest, tp.width);
      tp.dispose();
    }
    return longest <= room ? base : base * room / longest;
  }

  @override
  Widget build(BuildContext context) {
    final ink = _inkOn(color);
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.fromLTRB(width * 0.1, height * 0.08, width * 0.1, height * 0.07),
      decoration: BoxDecoration(
        color: color,
        // The hinge, where the cover bends at the spine.
        border: Border(left: BorderSide(color: _shade(color, 0.18), width: width * 0.05)),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('KULAY · STORIES',
            textAlign: TextAlign.center,
            maxLines: 1,
            style: body(height * 0.042, weight: FontWeight.w700, color: ink.withValues(alpha: 0.7))
                .copyWith(letterSpacing: 0.8)),
        const Spacer(),
        Text(title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: display(_titleSize(), color: ink).copyWith(height: 1.05)),
        const Spacer(flex: 2),
        Container(height: 1, margin: EdgeInsets.symmetric(horizontal: width * 0.2), color: ink.withValues(alpha: 0.35)),
        SizedBox(height: height * 0.03),
        Text('A Kulay story',
            textAlign: TextAlign.center,
            maxLines: 1,
            style: body(height * 0.045, weight: FontWeight.w600, color: ink.withValues(alpha: 0.75))),
      ]),
    );
  }
}

/// The spine: the title running down it, as on a printed book.
class BookSpineFace extends StatelessWidget {
  const BookSpineFace({super.key, required this.title, required this.color, required this.width, required this.height});
  final String title;
  final Color color;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final ink = _inkOn(color);
    final base = _shade(color, 0.08);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_shade(base, 0.12), base, _shade(base, 0.12)]),
      ),
      child: Column(children: [
        SizedBox(height: height * 0.06),
        Container(height: 1.2, margin: EdgeInsets.symmetric(horizontal: width * 0.2), color: ink.withValues(alpha: 0.4)),
        Expanded(
          child: RotatedBox(
            quarterTurns: 1,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: height * 0.05),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(title.toUpperCase(),
                      maxLines: 1,
                      style: display(math.min(width * 0.5, 13), color: ink).copyWith(letterSpacing: 0.6)),
                ),
              ),
            ),
          ),
        ),
        Container(height: 1.2, margin: EdgeInsets.symmetric(horizontal: width * 0.2), color: ink.withValues(alpha: 0.4)),
        SizedBox(height: height * 0.06),
      ]),
    );
  }
}

/// The block of pages seen from the side: fine lines along the height.
class BookPagesFace extends StatelessWidget {
  const BookPagesFace({super.key, required this.width, required this.height});
  final double width, height;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _PageEdgePainter()),
      );
}

class _PageEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF3EBDA));
    final line = Paint()
      ..color = const Color(0xFFD9CDB4)
      ..strokeWidth = 0.6;
    for (var x = 1.5; x < size.width - 1; x += 2.2) {
      canvas.drawLine(Offset(x, 1), Offset(x, size.height - 1), line);
    }
  }

  @override
  bool shouldRepaint(_PageEdgePainter old) => false;
}

class _CoverInside extends StatelessWidget {
  const _CoverInside(this.w, this.h, this.color);
  final double w, h;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: _tint(color, 0.5),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(4), left: Radius.circular(2)),
          border: Border.all(color: color, width: 3),
        ),
      );
}

class _Pages extends StatelessWidget {
  const _Pages(this.w, this.h, {this.back = false});
  final double w, h;
  final bool back; // the block of pages, with a thicker edge

  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        padding: EdgeInsets.fromLTRB(10, h * 0.12, 10, 8),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
          border: back ? Border(right: BorderSide(color: _shade(_cream, 0.12), width: 3)) : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < (h / 14).floor() - 2; i++)
            Container(
              height: 1.6,
              width: i % 4 == 3 ? w * 0.4 : w,
              margin: const EdgeInsets.only(bottom: 10),
              color: _pageInk.withValues(alpha: 0.13),
            ),
        ]),
      );
}

// ---------------------------------------------------------------------------
// The flight: a book leaves its place, comes to the middle, turns its cover to
// you and opens, while the page behind it changes.

/// Flies a book from [from] to the middle of the window and opens it.
/// [onOpened] fires while the book is open and the page is covered.
void flyOpenBook(
  BuildContext context, {
  required Rect from,
  required String title,
  required BookSpec spec,
  required VoidCallback onOpened,
  VoidCallback? onDone,
  double startTurn = 0,
  bool fadeIn = false,
}) {
  lastOpenedBookColor = spec.color;
  if (reduceMotion(context)) {
    onOpened();
    onDone?.call();
    return;
  }
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Flight(
      from: from,
      title: title,
      spec: spec,
      startTurn: startTurn,
      fadeIn: fadeIn,
      onOpened: onOpened,
      onDone: () {
        entry.remove();
        onDone?.call();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
}

class _Flight extends StatefulWidget {
  const _Flight({
    required this.from,
    required this.title,
    required this.spec,
    required this.startTurn,
    required this.fadeIn,
    required this.onOpened,
    required this.onDone,
  });
  final Rect from;
  final String title;
  final BookSpec spec;
  final double startTurn;
  final bool fadeIn;
  final VoidCallback onOpened, onDone;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  var _fired = false;

  static double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (!_fired && _c.value >= 0.7) {
        _fired = true;
        widget.onOpened();
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
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final w = widget.spec.width, h = widget.spec.height, cw = h * 0.68;
    return AbsorbPointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final fly = Curves.easeInOutCubic.transform(_seg(t, 0, 0.45));
          final open = Curves.easeOutCubic.transform(_seg(t, 0.38, 0.78));
          final out = Curves.easeIn.transform(_seg(t, 0.8, 1));
          final s = 1 + (math.min(2.2, screen.height * 0.42 / h) - 1) * fly;
          // Keep the cover centred, then the open spread.
          final centre = (w + cw / 2) + (w - (w + cw / 2)) * open;
          final toLeft = screen.width / 2 - w / 2 - (centre - w / 2) * s;
          final toTop = screen.height / 2 - h / 2;
          final left = widget.from.left + (toLeft - widget.from.left) * fly;
          final top = widget.from.top + (toTop - widget.from.top) * fly;
          final fade = (widget.fadeIn ? _seg(t, 0, 0.12) : 1.0) * (1 - out);
          return Stack(children: [
            Positioned.fill(
              child: ColoredBox(color: Colors.white.withValues(alpha: 0.94 * _seg(t, 0, 0.3) * (1 - out))),
            ),
            Positioned(
              left: left,
              top: top,
              child: Opacity(
                opacity: fade,
                child: Book3D(
                  title: widget.title,
                  color: widget.spec.color,
                  style: widget.spec.style,
                  width: w,
                  height: h,
                  turn: widget.startTurn + (math.pi / 2 - widget.startTurn) * fly,
                  open: 2.75 * open,
                  scale: s,
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading: a closed book opens, then keeps turning pages. Each turned page
// takes the next Kulay color and lands on a growing, colorful pile.

class OpeningBookLoader extends StatefulWidget {
  const OpeningBookLoader({super.key, required this.title, required this.color, this.busy = true});
  final String title;
  final Color color; // the cover
  final bool busy; // false freezes the pages (an error showed)

  @override
  State<OpeningBookLoader> createState() => _OpeningBookLoaderState();
}

class _OpeningBookLoaderState extends State<OpeningBookLoader> with SingleTickerProviderStateMixin {
  late final _time = ValueNotifier<double>(0);
  Ticker? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _ticker?.stop();
      _time.value = _BookLoaderPainter.openTime + 0.5 * _BookLoaderPainter.pageTime;
    } else {
      _ticker ??= createTicker((e) => _time.value = e.inMicroseconds / 1e6);
      _sync();
    }
  }

  @override
  void didUpdateWidget(OpeningBookLoader old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// Runs while busy; on an error the book stops on its current page.
  void _sync() {
    final t = _ticker;
    if (t == null) return;
    if (widget.busy && !t.isActive) {
      t.start();
    } else if (!widget.busy && t.isActive) {
      t.stop();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          size: const Size(320, 220),
          painter: _BookLoaderPainter(_time, widget.color),
        ),
      );
}

class _BookLoaderPainter extends CustomPainter {
  _BookLoaderPainter(this.time, this.cover) : super(repaint: time);
  final ValueNotifier<double> time;
  final Color cover;

  static const openTime = 0.9; // seconds for the cover to swing open
  static const firstRest = 0.5; // a beat on the open book before the first page
  static const turnTime = 1.25; // one page turning
  static const restTime = 0.75; // the book at rest between pages
  static const pageTime = turnTime + restTime;
  static const settleTime = 0.5; // a landed page easing onto the pile
  static const maxPile = 10;
  static const _tintTop = 0.18, _tintEdge = 0.75; // how much color a top page and a pile edge show
  static const _pageColors = [
    Color(0xFFF25C8A),
    Color(0xFFF7934C),
    Color(0xFFFFD23F),
    Color(0xFF2FCB74),
    Color(0xFF49C6F5),
    Color(0xFF3D7BF5),
    Color(0xFF8E52EC),
  ];

  static Color _colorOf(int page) => _pageColors[page % _pageColors.length];
  static Color _tinted(int page, double amount) => Color.lerp(_cream, _colorOf(page), amount)!;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final cx = size.width / 2;
    const w = 122.0, h = 150.0;
    // A slow drift, so the book feels held rather than stamped in place.
    final top = (size.height - h) / 2 + 4 + 1.5 * math.sin(t * 1.1);

    // Timeline: the cover opens, a short rest, then each page turns and rests.
    final opening = t < openTime;
    final o = opening ? Curves.easeInOutSine.transform(((t - 0.3) / (openTime - 0.3)).clamp(0.0, 1.0)) : 1.0;
    final since = t - openTime - firstRest; // into the page cycles
    final cycle = since < 0 ? -1 : (since / pageTime).floor(); // page now turning or just turned
    final phase = since < 0 ? 0.0 : since - cycle * pageTime;
    final turning = cycle >= 0 && phase < turnTime;
    final p = turning ? Curves.easeInOutCubic.transform(phase / turnTime) : 0.0;
    // Pages lying on the left, and how far the newest one has eased in.
    final landed = cycle < 0 ? 0 : (turning ? cycle : cycle + 1);
    final settle = turning || landed == 0 ? 1.0 : Curves.easeOutCubic.transform(((phase - turnTime) / settleTime).clamp(0.0, 1.0));

    // Glow: crossfades to the turning page's color and breathes gently.
    if (!opening) {
      final from = landed > 0 ? _colorOf(landed - 1) : cover;
      final glowColor = turning ? Color.lerp(from, _colorOf(cycle), p)! : from;
      final rise = ((t - openTime) / 0.8).clamp(0.0, 1.0); // fades in after the cover opens
      final strength = (0.12 + 0.16 * math.sin(math.pi * p) + 0.03 * math.sin(t * 1.7)) * rise;
      final glow = Offset(cx, top + h / 2);
      canvas.drawCircle(
        glow,
        150,
        Paint()
          ..shader = ui.Gradient.radial(glow, 150, [
            glowColor.withValues(alpha: strength),
            glowColor.withValues(alpha: 0),
          ]),
      );
    }

    final coverPaint = Paint()..color = cover;
    // Cover board, right half always, left half once it has swung over.
    canvas.drawRRect(
        RRect.fromLTRBR(cx - 2, top - 6, cx + w + 8, top + h + 8, const Radius.circular(6)), coverPaint);
    if (!opening || o > 0.5) {
      canvas.drawRRect(
          RRect.fromLTRBR(cx - w - 8, top - 6, cx + 2, top + h + 8, const Radius.circular(6)), coverPaint);
    }

    // Right block: a steady stack, its top page already the color of the page
    // that turns next (so lifting it changes nothing underneath).
    for (var k = 5; k >= 1; k--) {
      _page(canvas, cx, top, w, h, side: 1, dx: k * 1.4, dy: k * 1.1, color: _shade(_cream, 0.04 * k));
    }
    // The next page to turn; while a page turns, the one after it waits below.
    final waiting = cycle < 0 ? 0 : cycle + 1;
    _page(canvas, cx, top, w, h, side: 1, color: _tinted(waiting, _tintTop), lines: true);

    // Left pile. Each page's place is measured from the top, in fractions, so
    // a newly landed page pushes the others out smoothly instead of all at once.
    if (!opening) {
      for (var j = 0; j < landed - 1; j++) {
        final k = (landed - 1 - j) - (1 - settle); // 0 = flush with the top page
        if (k > maxPile + 1) continue;
        final fade = (maxPile + 1 - k).clamp(0.0, 1.0); // the oldest fade off the bottom
        final c = Color.lerp(_cream, _colorOf(j), _tintTop + (_tintEdge - _tintTop) * k.clamp(0.0, 1.0))!;
        _page(canvas, cx, top, w, h,
            side: -1, dx: -k * 1.6, dy: k * 1.2, color: c.withValues(alpha: fade));
      }
      _page(canvas, cx, top, w, h,
          side: -1, color: landed == 0 ? _cream : _tinted(landed - 1, _tintTop), lines: true);
    }

    // The fold at the spine.
    canvas.drawRect(
      Rect.fromLTRB(cx - 10, top, cx + 10, top + h),
      Paint()
        ..shader = ui.Gradient.linear(Offset(cx - 10, 0), Offset(cx + 10, 0), [
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0.10),
          Colors.black.withValues(alpha: 0),
        ], const [0, 0.5, 1]),
    );

    // The moving sheet: the cover while opening, then the turning page. It
    // starts and ends at the same light tint as the pages it leaves and joins.
    // Its texture differs a little from a flat page, so it fades in as it
    // lifts and fades out as it settles, instead of swapping in one frame.
    if (opening) {
      _turning(canvas, cx, top, w, h, o, cover, isCover: true);
    } else if (cycle < 0 && since > -firstRest) {
      // The cover, flat on the left, giving way to the first page.
      final fade = 1 - ((since + firstRest) / (firstRest * 0.8)).clamp(0.0, 1.0);
      if (fade > 0) _faded(canvas, size, fade, () => _turning(canvas, cx, top, w, h, 1, cover, isCover: true));
    } else if (turning) {
      final fade = (phase / (turnTime * 0.12)).clamp(0.0, 1.0);
      _faded(canvas, size, fade,
          () => _turning(canvas, cx, top, w, h, p, _tinted(cycle, _tintTop + 0.3 * math.sin(math.pi * p)), isCover: false));
    } else if (landed > 0 && settle < 1) {
      _faded(canvas, size, 1 - settle,
          () => _turning(canvas, cx, top, w, h, 1, _tinted(landed - 1, _tintTop), isCover: false));
    }
  }

  /// Draws [draw] at [opacity] as one layer.
  void _faded(Canvas canvas, Size size, double opacity, void Function() draw) {
    if (opacity >= 0.999) return draw();
    canvas.saveLayer(Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: opacity));
    draw();
    canvas.restore();
  }

  /// One flat page on [side] (1 right, -1 left) with a gently curved top and bottom.
  void _page(Canvas canvas, double cx, double top, double w, double h,
      {required int side, double dx = 0, double dy = 0, required Color color, bool lines = false}) {
    final x0 = cx + dx, y0 = top + dy, xe = cx + side * w + dx;
    final path = Path()
      ..moveTo(x0, y0 + 4)
      ..quadraticBezierTo(cx + side * w * 0.5 + dx, y0 - 4, xe, y0)
      ..lineTo(xe, y0 + h)
      ..quadraticBezierTo(cx + side * w * 0.5 + dx, y0 + h - 6, x0, y0 + h + 4)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _shade(color, 0.12));
    if (!lines) return;
    final ink = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = _pageInk.withValues(alpha: 0.14);
    for (var i = 0; i < 8; i++) {
      final y = top + 26 + i * 14.0;
      final inner = cx + side * 16, outer = cx + side * (i % 4 == 3 ? w * 0.5 : w - 16);
      canvas.drawLine(Offset(inner, y), Offset(outer, y), ink);
    }
  }

  /// The sheet in mid-turn: [p] 0 lies flat on the right, 1 flat on the left.
  void _turning(Canvas canvas, double cx, double top, double w, double h, double p, Color color,
      {required bool isCover}) {
    // Drawn for the whole turn, flat ends included, so nothing underneath flashes.
    final edge = cx + w * math.cos(math.pi * p); // outer edge, right to left
    final lift = math.sin(math.pi * p); // highest mid-turn
    final span = edge - cx;
    final y0 = top - 10 * lift, y1 = top + h + 4 * lift;
    final path = Path()
      ..moveTo(cx, top + 4)
      ..quadraticBezierTo(cx + span * 0.55, y0 - 6 * lift - 4, edge, y0)
      ..lineTo(edge, y1)
      ..quadraticBezierTo(cx + span * 0.55, y1 - 6, cx, top + h + 4)
      ..close();
    // A soft shadow cast on the pages below.
    canvas.drawPath(
      path.shift(Offset(6 * lift, 6 * lift)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10 * lift)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Lit near the edge, shaded toward the spine; the far side is a little darker.
    final back = p > 0.5;
    final base = isCover ? (back ? _tint(color, 0.15) : color) : (back ? _shade(color, 0.05) : color);
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(Offset(cx, 0), Offset(edge == cx ? cx + 1 : edge, 0), [
          _shade(base, 0.14),
          base,
          _tint(base, 0.18),
        ], const [0, 0.55, 1]),
    );

    // Texture, mapped onto the curved sheet so it bends with the turn.
    // (u, v): u from spine (0) to outer edge (1), v from top (0) to bottom (1).
    Offset at(double u, double v) {
      final a = (1 - u) * (1 - u), b = 2 * (1 - u) * u, c = u * u;
      final x = a * cx + b * (cx + span * 0.55) + c * edge;
      final yt = a * (top + 4) + b * (y0 - 6 * lift - 4) + c * y0;
      final yb = a * (top + h + 4) + b * (y1 - 6) + c * y1;
      return Offset(x, yt + (yb - yt) * v);
    }

    canvas.save();
    canvas.clipPath(path);
    if (isCover) {
      // Woven linen: two sets of fine threads.
      final thread = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.white.withValues(alpha: 0.05);
      final warp = Path(), weft = Path();
      for (var i = 1; i < 40; i++) {
        final u = i / 40;
        final top = at(u, 0), bottom = at(u, 1);
        warp
          ..moveTo(top.dx, top.dy)
          ..lineTo(bottom.dx, bottom.dy);
      }
      for (var j = 1; j < 50; j++) {
        final v = j / 50;
        final a = at(0, v), m = at(0.5, v), b = at(1, v);
        weft
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(2 * m.dx - (a.dx + b.dx) / 2, 2 * m.dy - (a.dy + b.dy) / 2, b.dx, b.dy);
      }
      canvas.drawPath(warp, thread);
      canvas.drawPath(weft, thread..color = Colors.black.withValues(alpha: 0.035));
    } else {
      // Paper: speckles and short fibers.
      final dark = Path(), light = Path(), fibers = Path();
      for (final g in _grain) {
        final o = at(g.u, g.v);
        if (g.fiber) {
          final end = at((g.u + g.du).clamp(0.0, 1.0), (g.v + g.dv).clamp(0.0, 1.0));
          fibers
            ..moveTo(o.dx, o.dy)
            ..lineTo(end.dx, end.dy);
        } else {
          (g.dark ? dark : light).addOval(Rect.fromCircle(center: o, radius: g.r));
        }
      }
      canvas.drawPath(dark, Paint()..color = _shade(base, 0.35).withValues(alpha: 0.12));
      canvas.drawPath(light, Paint()..color = Colors.white.withValues(alpha: 0.2));
      canvas.drawPath(
          fibers,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6
            ..color = _shade(base, 0.3).withValues(alpha: 0.14));

      // Printed lines on the front; on the back they faintly show through.
      final ink = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = _pageInk.withValues(alpha: back ? 0.06 : 0.16);
      final lines = Path();
      for (var i = 0; i < 8; i++) {
        final v = 0.15 + i * 0.094;
        final end = i % 4 == 3 ? 0.5 : 0.86;
        final a = at(0.13, v), m = at((0.13 + end) / 2, v), b = at(end, v);
        lines
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(2 * m.dx - (a.dx + b.dx) / 2, 2 * m.dy - (a.dy + b.dy) / 2, b.dx, b.dy);
      }
      canvas.drawPath(lines, ink);
    }
    canvas.restore();

    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _shade(base, 0.18));
  }

  /// Fixed paper grain in sheet coordinates, the same on every frame.
  static final _grain = () {
    final r = math.Random(17);
    return [
      for (var i = 0; i < 320; i++)
        (
          u: r.nextDouble(),
          v: r.nextDouble(),
          r: 0.3 + r.nextDouble() * 0.5,
          dark: r.nextBool(),
          fiber: i % 6 == 0,
          du: (r.nextDouble() - 0.5) * 0.06,
          dv: (r.nextDouble() - 0.5) * 0.03,
        ),
    ];
  }();

  @override
  bool shouldRepaint(_BookLoaderPainter old) => old.cover != cover || old.time != time;
}
