import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../ui/motion.dart';
import '../../ui/theme.dart';
import 'book3d.dart';
import 'story_view.dart' show kCard, kIndigoText, kLine, kSoft;

/// Topics as real 3D books standing in a ring that revolves. The book at the
/// front faces you with its cover; the rest turn their spines and fade toward
/// the back. Idle, the ring turns slowly all the way round. Pointing at it
/// settles the nearest book at the front, dragging spins it, the arrows step
/// it. Clicking a side book brings it to the front; clicking the front book
/// flies it open (see [flyOpenBook]) and then calls [onOpen].
class BookCarousel extends StatefulWidget {
  const BookCarousel({super.key, required this.topics, required this.onOpen});
  final List<String> topics;
  final void Function(String topic) onOpen;

  @override
  State<BookCarousel> createState() => _BookCarouselState();
}

/// Size of book [i]: covers share a size, spines vary in thickness.
BookSpec _specFor(int i) => (
      width: 18.0 + (i * 7) % 10, // spine thickness
      height: 124.0,
      color: bookColors[(i * 5) % bookColors.length],
      style: i,
    );

class _BookCarouselState extends State<BookCarousel> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  double _spin = 0; // ring rotation, radians
  double _vel = 0; // after a drag, radians per second
  double? _target; // easing to this rotation
  bool _inside = false, _dragging = false;
  int? _hover; // book under the pointer
  final _lift = <int, double>{}; // 0..1 per book, eased
  int? _opening;
  late List<GlobalKey> _coverKeys = _keys();

  static const _autoSpeed = 0.16; // radians per second when idle
  static const _tilt = 0.16; // camera looks slightly down, so tops show
  static const _k = 0.0011; // perspective
  static const _height = 300.0;

  int get _n => widget.topics.length;
  double get _step => 2 * math.pi / _n;
  List<GlobalKey> _keys() => List.generate(widget.topics.length, (_) => GlobalKey());

  /// Book nearest the front for a ring rotation.
  int _frontFor(double spin) => ((-(spin / _step).round()) % _n + _n) % _n;
  int get _front => _frontFor(_spin);

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void didUpdateWidget(BookCarousel old) {
    super.didUpdateWidget(old);
    if (old.topics.length != widget.topics.length) _coverKeys = _keys();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    final still = reduceMotion(context);
    final before = _spin;
    var moved = false;
    if (!_dragging) {
      if (_target != null) {
        final d = _target! - _spin;
        _spin += still ? d : d * math.min(1, dt * 7);
        if ((_target! - _spin).abs() < 0.0008) {
          _spin = _target!;
          _target = null;
        }
      } else if (_vel.abs() > 0.02) {
        _spin += _vel * dt;
        _vel *= math.pow(0.05, dt).toDouble(); // friction
        if (_vel.abs() < 0.3) _settle();
      } else if (_inside || _opening != null || still) {
        _settle();
      } else {
        _spin += _autoSpeed * dt;
      }
    }
    for (var i = 0; i < _n; i++) {
      final want = i == _hover && i == _front && !_dragging ? 1.0 : 0.0;
      final v = _lift[i] ?? 0;
      if ((v - want).abs() > 0.001) {
        _lift[i] = v + (want - v) * math.min(1, dt * 10);
        moved = true;
      }
    }
    // Settled and nothing lifting: no need to rebuild.
    if (moved || _spin != before || _dragging) setState(() {});
  }

  /// Ease to the nearest whole book.
  void _settle() {
    final snap = (_spin / _step).round() * _step;
    if ((snap - _spin).abs() > 0.0008) _target = snap;
  }

  /// Revolve book [i] to the front by the short way round.
  void _bringToFront(int i) {
    final want = -i * _step;
    var d = (want - _spin) % (2 * math.pi);
    if (d > math.pi) d -= 2 * math.pi;
    _vel = 0;
    _target = _spin + d;
  }

  void _tap(int i) {
    if (_opening != null) return;
    if (i != _front || _target != null) return _bringToFront(i);
    final box = _coverKeys[i].currentContext?.findRenderObject() as RenderBox?;
    final t = widget.topics[i];
    if (box == null || !box.hasSize) return widget.onOpen(t);
    final rect = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
    final spec = _specFor(i);
    setState(() => _opening = i);
    flyOpenBook(
      context,
      // The flight's book stands on its spine, left of the cover.
      from: Rect.fromLTWH(rect.left - spec.width, rect.top, spec.width, rect.height),
      title: t,
      spec: spec,
      startTurn: math.pi / 2,
      onOpened: () => widget.onOpen(t),
      onDone: () {
        if (mounted) setState(() => _opening = null);
      },
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final r = math.min(300.0, w * 0.34); // ring radius
        final cx = w / 2, cy = _height * 0.47;
        final front = _front;

        // Far books first, near books last.
        final order = List.generate(_n, (i) => i)
          ..sort((a, b) => math.cos(a * _step + _spin).compareTo(math.cos(b * _step + _spin)));

        return Column(children: [
          SizedBox(
            height: _height,
            child: MouseRegion(
              onEnter: (_) => _inside = true,
              onExit: (_) {
                _inside = false;
                _hover = null;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) {
                  _dragging = true;
                  _target = null;
                  _vel = 0;
                },
                onHorizontalDragUpdate: (d) => _spin += d.delta.dx / (r * 0.9),
                onHorizontalDragEnd: (d) {
                  _dragging = false;
                  _vel = (d.velocity.pixelsPerSecond.dx / (r * 0.9)).clamp(-6.0, 6.0);
                  if (_vel.abs() < 0.3) _settle();
                },
                child: Stack(clipBehavior: Clip.none, children: [
                  // Soft shadow where the ring stands.
                  Positioned(
                    left: cx - r - 60,
                    width: 2 * r + 120,
                    top: cy + 52,
                    height: 70,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                  ),
                  for (final i in order) ..._book(i, cx, cy, r, i == front),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _caption(front),
        ]);
      });

  /// The visible faces of book [i], placed in 3D. Faces turned away are
  /// skipped (the book is a box, so that alone draws it correctly).
  List<Widget> _book(int i, double cx, double cy, double r, bool isFront) {
    final spec = _specFor(i);
    final h = spec.height, d = spec.width, cw = h * 0.68;
    final a = i * _step + _spin;
    final s = math.sin(a), c = math.cos(a);
    // Fade toward the back of the ring.
    final fade = ((c + 0.25) / 1.0).clamp(0.0, 1.0);
    if (fade <= 0.02 || _opening == i) return const [];
    final lift = (_lift[i] ?? 0) * 12;

    // Book centre and face normals (y down, +z away from you), before the tilt.
    final pos = (-r * s, -lift, -r * c);
    final faces = <(String, (double, double, double), double)>[
      ('front', (-s, 0, -c), d / 2),
      ('back', (s, 0, c), d / 2),
      ('spine', (-c, 0, s), cw / 2),
      ('pages', (c, 0, -s), cw / 2),
      ('top', (0, -1, 0), h / 2),
    ];
    final ct = math.cos(_tilt), st = math.sin(_tilt);
    (double, double, double) tilt((double, double, double) v) => (v.$1, v.$2 * ct - v.$3 * st, v.$2 * st + v.$3 * ct);
    final p = tilt(pos);
    const camZ = -1 / _k;

    final base = Matrix4.identity()
      ..setEntry(3, 2, _k)
      ..rotateX(_tilt)
      ..rotateY(a)
      ..translateByDouble(0, -lift, -r, 1);

    final out = <Widget>[];
    for (final (name, n0, e) in faces) {
      final n = tilt(n0);
      final centre = (p.$1 + n.$1 * e, p.$2 + n.$2 * e, p.$3 + n.$3 * e);
      // Visible when it faces the camera.
      final facing = n.$1 * centre.$1 + n.$2 * centre.$2 + n.$3 * (centre.$3 - camZ);
      if (facing >= 0) continue;
      final (Matrix4 f, Widget face) = switch (name) {
        'front' => (
            Matrix4.translationValues(-cw / 2, -h / 2, -d / 2),
            KeyedSubtree(
              key: _coverKeys[i],
              child: BookCoverFace(title: widget.topics[i], color: spec.color, width: cw, height: h),
            ),
          ),
        'back' => (
            Matrix4.translationValues(cw / 2, -h / 2, d / 2)..rotateY(math.pi),
            Container(width: cw, height: h, color: Color.lerp(spec.color, Colors.black, 0.12)),
          ),
        'spine' => (
            Matrix4.translationValues(-cw / 2, -h / 2, d / 2)..rotateY(math.pi / 2),
            BookSpineFace(title: widget.topics[i], color: spec.color, width: d, height: h),
          ),
        'pages' => (
            Matrix4.translationValues(cw / 2, -h / 2, -d / 2)..rotateY(-math.pi / 2),
            BookPagesFace(width: d, height: h),
          ),
        _ => (
            Matrix4.translationValues(-cw / 2, -h / 2, d / 2)..rotateX(-math.pi / 2),
            Container(
              width: cw,
              height: d,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBDA),
                border: Border.all(color: spec.color, width: 1.5),
              ),
            ),
          ),
      };
      Widget child = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _hover = i,
        onExit: (_) {
          if (_hover == i) _hover = null;
        },
        child: GestureDetector(onTap: () => _tap(i), child: face),
      );
      if (fade < 1) child = Opacity(opacity: fade, child: child);
      out.add(Positioned(
        left: cx,
        top: cy,
        child: Transform(transform: base.clone()..multiply(f), child: child),
      ));
    }
    return out;
  }

  Widget _caption(int front) {
    Widget arrow(IconData icon, String label, int delta) => Semantics(
          button: true,
          label: label,
          child: Material(
            color: kCard,
            shape: CircleBorder(side: BorderSide(color: kLine, width: 1.5)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _bringToFront((front + delta) % _n),
              child: SizedBox(width: 40, height: 40, child: Icon(icon, color: kIndigoText)),
            ),
          ),
        );
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      arrow(Icons.chevron_left_rounded, 'Previous book', -1),
      const SizedBox(width: 18),
      SizedBox(
        width: 340,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(key: ValueKey(front), mainAxisSize: MainAxisSize.min, children: [
            Text(widget.topics[front],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: display(24, color: kIndigoText)),
            const SizedBox(height: 4),
            Text('Click the front book to read it',
                style: body(13, weight: FontWeight.w600, color: kSoft)),
          ]),
        ),
      ),
      const SizedBox(width: 18),
      arrow(Icons.chevron_right_rounded, 'Next book', 1),
    ]);
  }
}
