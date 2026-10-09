import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';

/// Flowing bands of the app's colors, rising from the bottom left to the top
/// right so the upper left stays calm for a title. They drift slowly.
/// [fadeLeft] calms the left side for left-aligned content; [strength] (0..1)
/// tones the colors down behind busy pages.
class WavyBackground extends StatefulWidget {
  const WavyBackground({super.key, this.fadeLeft = true, this.strength = 1});
  final bool fadeLeft;
  final double strength;

  @override
  State<WavyBackground> createState() => _WavyBackgroundState();
}

class _WavyBackgroundState extends State<WavyBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 30));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
            painter: _WavesPainter(_drift,
                dark: K.dark, background: K.bg, fadeLeft: widget.fadeLeft, strength: widget.strength)),
      );
}

class _WavesPainter extends CustomPainter {
  _WavesPainter(this.drift,
      {required this.dark, required this.background, required this.fadeLeft, required this.strength})
      : super(repaint: drift);
  final Animation<double> drift;
  final bool dark;
  final Color background;
  final bool fadeLeft;
  final double strength;

  // Back to front.
  static const _colors = [K.lavender, Color(0xFF7FB2FF), K.pink, K.yellow, K.mint];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = drift.value * 2 * math.pi;
    for (var i = 0; i < _colors.length; i++) {
      // Each band's top edge: high on the right, low on the left, rippling.
      final right = h * (0.06 + 0.13 * i), left = h * (0.80 + 0.06 * i);
      final amp = h * (0.035 + 0.008 * i);
      double y(double x) {
        final u = x / w;
        final rise = left + (right - left) * (u * u * (3 - 2 * u)); // smooth slope
        return rise + amp * math.sin(u * 2 * math.pi * 1.4 + t + i * 1.3) + amp * 0.5 * math.sin(u * 7 - t * 0.7 + i);
      }

      final crest = Path()..moveTo(0, y(0));
      for (var x = 0.0; x <= w; x += 8) {
        crest.lineTo(x, y(x));
      }
      crest.lineTo(w, y(w));
      final path = Path()
        ..addPath(crest, Offset.zero)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      final c = _colors[i];
      final fill = dark ? Color.lerp(c, background, 0.55)! : Color.lerp(c, Colors.white, 0.15)!;
      canvas.drawPath(path, Paint()..color = fill.withValues(alpha: (dark ? 0.75 : 0.85) * strength));
      // A light crest along each wave's top edge.
      canvas.drawPath(
        crest,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: (dark ? 0.06 : 0.35) * strength),
      );
    }
    if (!fadeLeft) return;
    // Calm the area behind the content: the page color fading out to the right.
    final fade = Rect.fromLTWH(0, 0, w * 0.68, h);
    canvas.drawRect(
      fade,
      Paint()
        ..shader = LinearGradient(colors: [
          background.withValues(alpha: 0.88),
          background.withValues(alpha: 0.55),
          background.withValues(alpha: 0),
        ], stops: const [0, 0.6, 1]).createShader(fade),
    );
  }

  @override
  bool shouldRepaint(_WavesPainter old) => old.dark != dark || old.background != background || old.fadeLeft != fadeLeft || old.strength != strength;
}
