import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../ui/motion.dart';
import '../../ui/theme.dart';
import 'story_view.dart' show kIndigoText;

const _cream = Color(0xFFFFF7E6);

/// Flat, muted book colors, after the bookshelf reference.
const bookColors = [
  Color(0xFFD98C8C), // dusty pink
  Color(0xFF7B5EA7), // purple
  Color(0xFF3E8A86), // teal
  Color(0xFF4A2235), // plum
  Color(0xFFF5C6A5), // peach
  Color(0xFF34495E), // navy
  Color(0xFF8E2C48), // maroon
  Color(0xFFF1EBD3), // cream
  Color(0xFFE0457B), // raspberry
  Color(0xFF5E6B2F), // olive
  Color(0xFFF08A4B), // orange
  Color(0xFF8E9B4C), // sage
];

Color _inkOn(Color c) => c.computeLuminance() > 0.45 ? const Color(0xFF3B2A2A) : Colors.white;
Color _shade(Color c, double t) => Color.lerp(c, Colors.black, t)!;
Color _tint(Color c, double t) => Color.lerp(c, Colors.white, t)!;

/// The color of the book that was opened last, so the writing page can keep it.
Color? lastOpenedBookColor;

/// A 3D book: a spine facing you, the cover and pages behind it.
/// [turn] swings the book on its spine's right edge (0 = spine on, pi/2 =
/// cover on), [open] swings the cover open (0 to about 2.8), and [flip]
/// (0 to 1) turns one page from right to left.
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
  final int style; // spine decoration, see [BookSpine]

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
    final cover = _at(_hinge()..rotateY(open),
        opened ? _CoverInside(cw, height, color) : _Cover(cw, height, color, title));
    return SizedBox(
      width: width,
      height: height,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..scaleByDouble(scale, scale, scale, 1),
        child: Stack(clipBehavior: Clip.none, children: [
          // Edge-on at rest, so the shelf look stays flat until the book turns.
          if (turn > 0.02) ...[
            pages,
            if (opened) ...[cover, ?sheet] else ...[?sheet, cover],
          ],
          _at(spine, BookSpine(title: title, color: color, width: width, height: height, style: style)),
        ]),
      ),
    );
  }
}

/// A flat spine: one color, a label block with the title, a stripe or two.
/// [style] (any int) picks where the label and stripes go.
class BookSpine extends StatelessWidget {
  const BookSpine({
    super.key,
    required this.title,
    required this.color,
    required this.width,
    required this.height,
    this.style = 0,
  });
  final String title;
  final Color color;
  final double width, height;
  final int style;

  /// Title type on every spine: one size, so no title is shrunk to fit.
  static final titleStyle = body(14, weight: FontWeight.w800).copyWith(letterSpacing: 0.2);

  /// Length of [title] along the spine, in pixels.
  static double titleLength(String title) {
    final tp = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final w = tp.width;
    tp.dispose();
    return w;
  }

  /// The shortest spine that fits [title] with its stripes.
  static double minHeight(String title) => titleLength(title) + 22 + 66;

  @override
  Widget build(BuildContext context) {
    final dark = color.computeLuminance() < 0.45;
    // Cream label with dark ink on dark books, the reverse on light ones.
    final label = dark ? const Color(0xFFFFF8EC) : const Color(0xFF3B2A35);
    final ink = dark ? const Color(0xFF2B2230) : Colors.white;
    final stripe = dark ? _tint(color, 0.35) : _shade(color, 0.14);
    Widget band(double h) => Container(height: h, color: stripe);
    final s = style % 3;
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          // A darker right edge reads as the book's side.
          border: Border(right: BorderSide(color: _shade(color, 0.18), width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 2, 0),
          child: Column(children: [
            const SizedBox(height: 10),
            if (s != 2) ...[band(3), const SizedBox(height: 3), band(1.5)],
            Spacer(flex: s == 0 ? 1 : 2),
            Container(
              height: math.min(titleLength(title) + 22, math.max(0.0, height - 52)),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: label, borderRadius: BorderRadius.circular(3)),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle.copyWith(color: ink)),
              ),
            ),
            Spacer(flex: s == 0 ? 3 : 2),
            if (s != 0) ...[band(1.5), const SizedBox(height: 3), band(3)],
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover(this.w, this.h, this.color, this.title);
  final double w, h;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = color.computeLuminance() < 0.45;
    final label = dark ? _tint(color, 0.6) : _shade(color, 0.15);
    return Container(
      width: w,
      height: h,
      padding: EdgeInsets.fromLTRB(10, h * 0.16, 10, h * 0.16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4), left: Radius.circular(2)),
        border: Border(left: BorderSide(color: _shade(color, 0.2), width: 5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: label, borderRadius: BorderRadius.circular(3)),
          child: Text(title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: display(13, color: _inkOn(label)).copyWith(height: 1.15)),
        ),
        const Spacer(),
        Container(height: 3, color: label),
        const SizedBox(height: 4),
        Container(height: 1.5, color: label),
      ]),
    );
  }
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
              color: kIndigoText.withValues(alpha: 0.13),
            ),
        ]),
      );
}

// ---------------------------------------------------------------------------
// The shelf of topics.

typedef BookSpec = ({double width, double height, Color color, int style});

BookSpec _specFor(int i, String title) => (
      width: 40.0 + (i * 7) % 12,
      height: math.max(128.0 + (i * 23) % 40, BookSpine.minHeight(title)),
      color: bookColors[(i * 5) % bookColors.length],
      style: i,
    );

/// How far the first books of a row lean on their neighbour (radians).
const _leans = [0.18];

/// Topics as books on wooden shelves. A book lifts when hovered; a click flies
/// it open (see [flyOpenBook]) and then calls [onOpen].
class BookShelf extends StatefulWidget {
  const BookShelf({super.key, required this.topics, required this.onOpen});
  final List<String> topics;
  final void Function(String topic) onOpen;

  @override
  State<BookShelf> createState() => _BookShelfState();
}

class _BookShelfState extends State<BookShelf> {
  int? _hover;
  int? _opening;

  static const _gap = 3.0, _plank = 14.0, _lift = 16.0, _side = 28.0;

  /// Horizontal room a book takes, leaning ones need more.
  double _room(int i, int pos, {bool alone = false}) {
    final s = _specFor(i, widget.topics[i]);
    final lean = pos < _leans.length && !alone ? _leans[pos] : 0.0;
    return s.width + s.height * math.sin(lean) + 2 + _gap;
  }

  void _setHover(int? i) {
    if (_opening != null || i == _hover) return;
    setState(() => _hover = i);
  }

  void _open(BuildContext slot, int i) {
    if (_opening != null) return;
    final box = slot.findRenderObject() as RenderBox?;
    final t = widget.topics[i];
    if (box == null || !box.hasSize) return widget.onOpen(t);
    final spec = _specFor(i, widget.topics[i]);
    // The book's own rect, at the bottom of its slot, lifted if hovered.
    final at = box.localToGlobal(Offset(0, box.size.height - spec.height - (_hover == i ? _lift : 0)));
    setState(() {
      _opening = i;
      _hover = null;
    });
    flyOpenBook(
      context,
      from: at & Size(spec.width, spec.height),
      title: t,
      spec: spec,
      onOpened: () => widget.onOpen(t),
      onDone: () {
        if (mounted) setState(() => _opening = null);
      },
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        // How many rows the books need, then the same number on each row,
        // so no row is left with a lone book.
        List<List<int>> fill(int perRow) {
          final rows = <List<int>>[];
          var row = <int>[];
          var used = _side * 2;
          for (var i = 0; i < widget.topics.length; i++) {
            final w = _room(i, row.length);
            if (row.isNotEmpty && (used + w > box.maxWidth || row.length == perRow)) {
              rows.add(row);
              row = [];
              used = _side * 2;
            }
            used += _room(i, row.length);
            row.add(i);
          }
          if (row.isNotEmpty) rows.add(row);
          return rows;
        }

        final count = fill(widget.topics.length).length;
        final rows = fill((widget.topics.length / count).ceil());
        return MouseRegion(
          onExit: (_) => _setHover(null),
          child: Column(children: [
            for (final (r, ids) in rows.indexed) ...[
              if (r > 0) const SizedBox(height: 26),
              _row(ids, box.maxWidth),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 30,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a), child: child),
                ),
                child: _hover == null
                    ? Text('Point at a book to read its title. Click it to start.',
                        key: const ValueKey(-1), style: body(14, color: const Color(0xFF6B6680)))
                    : Text.rich(
                        key: ValueKey(_hover),
                        TextSpan(children: [
                          TextSpan(text: widget.topics[_hover!], style: display(22, color: kIndigoText)),
                          TextSpan(
                              text: '   Click to read',
                              style: body(14, weight: FontWeight.w600, color: const Color(0xFF6B6680))),
                        ]),
                      ),
              ),
            ),
          ]),
        );
      });

  Widget _row(List<int> ids, double maxWidth) {
    final tallest = ids.map((i) => _specFor(i, widget.topics[i]).height).reduce(math.max);
    final alone = ids.length == 1;
    final width = [for (final (p, i) in ids.indexed) _room(i, p, alone: alone)].fold(0.0, (a, b) => a + b) - _gap;
    var x = (maxWidth - width) / 2;
    final slots = <Widget>[];
    for (final (p, i) in ids.indexed) {
      final lean = p < _leans.length && ids.length > 1 ? _leans[p] : 0.0;
      final room = _room(i, p, alone: alone);
      // A leaning book stands at the right of its room, top resting on the next.
      slots.add(Positioned(
        key: ValueKey(i),
        left: x + room - _gap - _specFor(i, widget.topics[i]).width,
        bottom: _plank,
        child: _book(i, lean),
      ));
      x += room;
    }
    return SizedBox(
      height: tallest + _lift + _plank + 12,
      child: Stack(clipBehavior: Clip.none, children: [
        // Soft shadow on the wall under the plank.
        Positioned(
          left: 40,
          right: 40,
          bottom: -2,
          height: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [BoxShadow(color: const Color(0xFF6B4A2A).withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8))],
            ),
          ),
        ),
        ...slots,
        // The wooden plank: a lit top face over the front.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _plank,
          child: Column(children: [
            Container(height: 4, decoration: const BoxDecoration(color: Color(0xFFF6C35B), borderRadius: BorderRadius.vertical(top: Radius.circular(3)))),
            Expanded(
              child: Container(decoration: const BoxDecoration(color: Color(0xFFE9A23B), borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)))),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _book(int i, double lean) {
    final spec = _specFor(i, widget.topics[i]);
    final still = reduceMotion(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHover(i),
      onExit: (_) {
        if (_hover == i) _setHover(null);
      },
      child: Semantics(
        button: true,
        label: 'Read about ${widget.topics[i]}',
        child: Builder(
          builder: (slot) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _open(slot, i),
            // A fixed slot: the hit area does not move while the book lifts.
            child: SizedBox(
              width: spec.width,
              height: spec.height + _lift,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: _opening == i ? 0 : 1,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _hover == i && !still ? 1 : 0),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) => Transform.translate(
                      offset: Offset(0, -_lift * v),
                      child: Transform.rotate(
                        angle: lean * (1 - 0.6 * v),
                        alignment: Alignment.bottomRight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06 + 0.08 * v),
                              blurRadius: 3 + 9 * v,
                              offset: Offset(1, 1 + 3 * v),
                            ),
                          ]),
                          child: child,
                        ),
                      ),
                    ),
                    child: BookSpine(
                      title: widget.topics[i],
                      color: spec.color,
                      width: spec.width,
                      height: spec.height,
                      style: spec.style,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  static const pageTime = 1.4; // seconds per page
  static const maxPile = 10;
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

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final cx = size.width / 2;
    const w = 122.0, h = 150.0;
    final top = (size.height - h) / 2 + 4;

    // Where we are: opening, then page after page.
    final opening = t < openTime;
    // Closed for a moment, then the cover swings over.
    final o = opening ? Curves.easeInOutSine.transform(((t - 0.3) / (openTime - 0.3)).clamp(0.0, 1.0)) : 1.0;
    final pt = opening ? 0.0 : (t - openTime) / pageTime;
    final turned = pt.floor(); // pages already on the left pile
    final p = Curves.easeInOutSine.transform(pt - turned); // the page turning now
    final current = _colorOf(turned);

    // Soft glow that pulses with the color of the turning page.
    if (!opening) {
      final pulse = 0.5 + 0.5 * math.sin(math.pi * p);
      final glow = Offset(cx, top + h / 2);
      canvas.drawCircle(
        glow,
        150,
        Paint()
          ..shader = ui.Gradient.radial(glow, 150, [
            current.withValues(alpha: 0.10 + 0.22 * pulse),
            current.withValues(alpha: 0),
          ]),
      );
    }

    final coverPaint = Paint()..color = cover;
    // Cover board, right half always, left half once it has swung over.
    canvas.drawRRect(
        RRect.fromLTRBR(cx - 2, top - 6, cx + w + 8, top + h + 8, const Radius.circular(6)), coverPaint);
    if (!opening) {
      canvas.drawRRect(
          RRect.fromLTRBR(cx - w - 8, top - 6, cx + 2, top + h + 8, const Radius.circular(6)), coverPaint);
    }

    // Right block: what is left to read gets thinner as pages turn.
    final rightLayers = math.max(2, 6 - turned ~/ 2);
    for (var k = rightLayers; k >= 1; k--) {
      _page(canvas, cx, top, w, h, side: 1, dx: k * 1.4, dy: k * 1.1, color: _shade(_cream, 0.04 * k));
    }
    _page(canvas, cx, top, w, h, side: 1, color: _cream, lines: true);

    // Left pile: every turned page stays, its colored edge showing.
    if (!opening) {
      final pile = math.min(turned, maxPile);
      for (var k = pile; k >= 1; k--) {
        final c = _colorOf(turned - k);
        _page(canvas, cx, top, w, h, side: -1, dx: -k * 1.6, dy: k * 1.2, color: Color.lerp(_cream, c, 0.75)!);
      }
      final last = turned > 0 ? _colorOf(turned - 1) : null;
      _page(canvas, cx, top, w, h,
          side: -1, color: last == null ? _cream : Color.lerp(_cream, last, 0.18)!, lines: true);
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

    // The moving sheet: the cover while opening, then the current page.
    final sweep = opening ? o : p;
    final tint = opening ? cover : Color.lerp(_cream, current, 0.25 + 0.4 * math.sin(math.pi * p))!;
    _turning(canvas, cx, top, w, h, sweep, tint, isCover: opening);
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
      ..color = kIndigoText.withValues(alpha: 0.14);
    for (var i = 0; i < 8; i++) {
      final y = top + 26 + i * 14.0;
      final inner = cx + side * 16, outer = cx + side * (i % 4 == 3 ? w * 0.5 : w - 16);
      canvas.drawLine(Offset(inner, y), Offset(outer, y), ink);
    }
  }

  /// The sheet in mid-turn: [p] 0 lies flat on the right, 1 flat on the left.
  void _turning(Canvas canvas, double cx, double top, double w, double h, double p, Color color,
      {required bool isCover}) {
    if ((!isCover && p <= 0.001) || p >= 0.999) return;
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
        ..color = kIndigoText.withValues(alpha: back ? 0.06 : 0.16);
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
