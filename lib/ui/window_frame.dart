import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The app's own window chrome, since the Windows window is borderless:
/// minimize, full screen and close at the top right, and a strip along the
/// top to drag the window. The window has a fixed size, so there are no
/// resize edges; full screen (the button or F11) is the one way to make it
/// bigger. The native side is in windows/runner/flutter_window.cpp
/// ("kodigno/window").
class WindowFrame extends StatefulWidget {
  const WindowFrame({super.key, required this.child});
  final Widget child;

  /// Height of the band at the top kept clear for the window buttons. It is
  /// reported to the app as top padding, like a phone's status bar, so pages
  /// that use SafeArea (or read MediaQuery padding) start below it.
  static const barHeight = 48.0;

  static const _channel = MethodChannel('kodigno/window');

  static Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null; // Not running in the Windows runner (tests, other platforms).
    }
  }

  @override
  State<WindowFrame> createState() => _WindowFrameState();
}

class _WindowFrameState extends State<WindowFrame> {
  bool _fullscreen = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.f11) {
      _toggleFullscreen();
      return true;
    }
    return false;
  }

  Future<void> _toggleFullscreen() async {
    final on = await WindowFrame._call<bool>('toggleFullscreen');
    if (mounted && on != null) setState(() => _fullscreen = on);
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) return widget.child;
    final mq = MediaQuery.of(context);
    const inset = EdgeInsets.only(top: WindowFrame.barHeight);

    return Stack(children: [
      MediaQuery(
        data: mq.copyWith(padding: mq.padding + inset, viewPadding: mq.viewPadding + inset),
        child: widget.child,
      ),
      // Drag the window from the top strip. Translucent, so taps still reach
      // anything under it; only a drag moves the window (not in full screen).
      if (!_fullscreen)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: WindowFrame.barHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (_) => WindowFrame._call<void>('startDrag'),
          ),
        ),
      Positioned(
        top: 8,
        right: 10,
        child: _Controls(fullscreen: _fullscreen, onFullscreen: _toggleFullscreen),
      ),
    ]);
  }
}

/// Minimize, full screen and close, black on a small white pill so they show
/// on any page.
class _Controls extends StatelessWidget {
  const _Controls({required this.fullscreen, required this.onFullscreen});
  final bool fullscreen;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE6E6EE)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _WindowButton(
            tooltip: 'Minimize',
            glyph: _Glyph.minimize,
            onTap: () => WindowFrame._call<void>('minimize'),
          ),
          const SizedBox(width: 2),
          _WindowButton(
            tooltip: fullscreen ? 'Exit full screen' : 'Full screen',
            glyph: fullscreen ? _Glyph.exitFullscreen : _Glyph.fullscreen,
            onTap: onFullscreen,
          ),
          const SizedBox(width: 2),
          _WindowButton(
            tooltip: 'Close',
            glyph: _Glyph.close,
            danger: true,
            onTap: () => WindowFrame._call<void>('close'),
          ),
        ]),
      );
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({required this.tooltip, required this.glyph, required this.onTap, this.danger = false});
  final String tooltip;
  final _Glyph glyph;
  final VoidCallback onTap;
  final bool danger; // close: red on hover

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = !_hover
        ? Colors.transparent
        : widget.danger
            ? const Color(0xFFE81123)
            : const Color(0xFFEDEDF2);
    // No Tooltip: this sits above the app's Navigator, outside any Overlay.
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 34,
            height: 28,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
            child: CustomPaint(
              painter: _GlyphPainter(widget.glyph, _hover && widget.danger ? Colors.white : const Color(0xFF0F0F0F)),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Glyph { minimize, fullscreen, exitFullscreen, close }

/// The button marks, drawn as lines so they do not depend on an icon font.
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color);
  final _Glyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final pen = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    const r = 5.0, arm = 3.0;
    switch (glyph) {
      case _Glyph.minimize:
        canvas.drawLine(c + const Offset(-r, 0), c + const Offset(r, 0), pen);
      case _Glyph.close:
        canvas.drawLine(c + const Offset(-r, -r), c + const Offset(r, r), pen);
        canvas.drawLine(c + const Offset(-r, r), c + const Offset(r, -r), pen);
      case _Glyph.fullscreen:
      case _Glyph.exitFullscreen:
        // Four corners, pointing out to grow and in to shrink.
        final out = glyph == _Glyph.fullscreen;
        for (final (sx, sy) in const [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)]) {
          final corner = c + Offset(sx * r, sy * r);
          final inward = out ? 1.0 : -1.0;
          // Out: the bracket hugs the outer corner. In: it sits at the corner,
          // arms pointing back toward the middle edge-wise.
          final tip = out ? corner : c + Offset(sx * (r - arm), sy * (r - arm));
          canvas.drawPath(
            Path()
              ..moveTo(tip.dx - sx * arm * inward, tip.dy)
              ..lineTo(tip.dx, tip.dy)
              ..lineTo(tip.dx, tip.dy - sy * arm * inward),
            pen,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color;
}
