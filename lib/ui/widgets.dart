import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = EdgeInsets.zero,
    this.radius = 28,
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
        clipBehavior: Clip.antiAlias,
        padding: padding,
        child: child,
      );
}

/// Primary = yellow with dark text; dark = ink with white text.
/// Grows slightly on hover and squishes on press.
class PillButton extends StatefulWidget {
  const PillButton(
      {super.key, required this.label, required this.onPressed, this.dark = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool dark;
  final IconData? icon;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fg = widget.dark ? Colors.white : K.ink;
    final scale = !enabled || reduceMotion(context) ? 1.0 : (_down ? 0.96 : (_hover ? 1.04 : 1.0));
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: AnimatedScale(
          scale: scale,
          duration: Motion.fast,
          curve: Motion.curve,
          child: Material(
            color: widget.dark ? K.ink : K.yellow,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: widget.onPressed,
              onHighlightChanged: (v) => setState(() => _down = v),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label, style: body(16, weight: FontWeight.w700, color: fg)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress bar that eases to its new value.
class KProgress extends StatelessWidget {
  const KProgress({super.key, required this.value, this.color = K.ink, this.height = 6});
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0, 1).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: target),
        duration: reduceMotion(context) ? Duration.zero : Motion.slow,
        curve: Motion.curve,
        builder: (_, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: Colors.black12,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

class SourceTag extends StatelessWidget {
  const SourceTag(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: K.ink, borderRadius: BorderRadius.circular(8)),
        child: Text(label.toUpperCase(),
            style: body(10, weight: FontWeight.w800, color: Colors.white)),
      );
}

/// A little inked, tilted "sticker" with an icon: the app's illustration style.
class KSticker extends StatelessWidget {
  const KSticker({
    super.key,
    required this.icon,
    this.color = K.yellow,
    this.size = 56,
    this.tilt = -0.07,
  });
  final IconData icon;
  final Color color;
  final double size;
  final double tilt;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: tilt,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * 0.3),
            border: Border.all(color: K.ink, width: 2),
            boxShadow: [BoxShadow(color: K.ink, offset: Offset(size * 0.06, size * 0.06))],
          ),
          child: Icon(icon, size: size * 0.5, color: K.ink),
        ),
      );
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.phase);
  final Color color;
  final double phase; // 0..1 shifts the dashes (marching ants)

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final shift = phase * 14;
    for (final m in path.computeMetrics()) {
      for (var d = -14 + shift; d < m.length; d += 14) {
        canvas.drawPath(m.extractPath(d.clamp(0, m.length), (d + 8).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.color != color || old.phase != phase;
}

/// Dashed rounded box. Dashes march while [highlighted] (e.g. a file is over it).
class DashedBox extends StatefulWidget {
  const DashedBox({super.key, required this.child, this.highlighted = false});
  final Widget child;
  final bool highlighted;

  @override
  State<DashedBox> createState() => _DashedBoxState();
}

class _DashedBoxState extends State<DashedBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didUpdateWidget(DashedBox old) {
    super.didUpdateWidget(old);
    if (widget.highlighted && !reduceMotion(context)) {
      _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => CustomPaint(
          painter: _DashedPainter(
              widget.highlighted ? K.ink : const Color(0xFF9A9AAE), _c.value),
          child: child,
        ),
        child: widget.child,
      );
}

/// Full-screen pushed page on the white canvas.
class PanelPage extends StatelessWidget {
  const PanelPage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SafeArea(child: child));
}

class CloseX extends StatelessWidget {
  const CloseX({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Close',
        onPressed: () => Navigator.of(context).maybePop(),
      );
}
