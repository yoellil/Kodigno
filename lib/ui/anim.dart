import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';

/// A number that rolls up to [value] (and re-rolls when [value] changes).
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
  });
  final int value;
  final TextStyle style;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return Text('$value$suffix', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Motion.curve,
      builder: (_, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Hover lift + press squish + ink ripple for any tappable card or tile.
/// With a null [onTap] it renders flat and does not react.
class Lift extends StatefulWidget {
  const Lift({
    super.key,
    required this.child,
    required this.onTap,
    this.color = K.tile,
    this.radius = 20,
    this.tilt = 0,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final double tilt; // radians; straightens on hover
  final EdgeInsets padding;

  @override
  State<Lift> createState() => _LiftState();
}

class _LiftState extends State<Lift> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !reduceMotion(context);
    final lifted = enabled && _hover;
    final scale = (enabled && _down) ? 0.97 : (lifted ? 1.02 : 1.0);
    final radius = BorderRadius.circular(widget.radius);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.curve,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(0, lifted ? -4 : 0, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1)
          ..rotateZ(lifted ? 0 : widget.tilt),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: lifted ? 0.16 : 0.06),
              blurRadius: lifted ? 22 : 8,
              offset: Offset(0, lifted ? 12 : 3),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _down = v),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// One-shot confetti burst. Finishes by itself; never loops.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.duration = const Duration(milliseconds: 2400)});
  final Duration duration;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Piece {
  _Piece(math.Random r)
      : angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.1,
        speed = 0.35 + r.nextDouble() * 0.65,
        spin = (r.nextDouble() - 0.5) * 14,
        size = 6 + r.nextDouble() * 8,
        color = [K.yellow, K.lavender, K.pink, K.mint, K.blue][r.nextInt(5)];
  final double angle, speed, spin, size;
  final Color color;
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final List<_Piece> _pieces;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final r = math.Random(7); // seeded: same burst every time
    _pieces = List.generate(70, (_) => _Piece(r));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !reduceMotion(context)) {
      _started = true;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _c.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.5, size.height * 0.28);
    final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
    for (final p in pieces) {
      final dx = math.cos(p.angle) * p.speed * t * size.width * 0.9;
      final dy = math.sin(p.angle) * p.speed * t * size.height * 0.6 +
          1.4 * t * t * size.height * 0.5;
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
        Paint()..color = p.color.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
