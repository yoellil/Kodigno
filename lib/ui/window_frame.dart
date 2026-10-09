import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The app's own window chrome, since the Windows window is borderless:
/// minimize and close at the top right and a strip along the top to drag the
/// window. The window has a fixed size, so there are no resize edges. The native side is in
/// windows/runner/flutter_window.cpp ("kodigno/window").
class WindowFrame extends StatelessWidget {
  const WindowFrame({super.key, required this.child});
  final Widget child;

  static const _channel = MethodChannel('kodigno/window');

  static Future<void> _call(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Not running in the Windows runner (tests, other platforms).
    }
  }

  static const _dragHeight = barHeight;

  /// Height of the band at the top kept clear for the window buttons. It is
  /// reported to the app as top padding, like a phone's status bar, so pages
  /// that use SafeArea (or read MediaQuery padding) start below it.
  static const barHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) return child;
    final mq = MediaQuery.of(context);
    final inset = EdgeInsets.only(top: barHeight);

    return Stack(children: [
      MediaQuery(
        data: mq.copyWith(padding: mq.padding + inset, viewPadding: mq.viewPadding + inset),
        child: child,
      ),
      // Drag the window from the top strip. Translucent, so taps still reach
      // anything under it; only a drag moves the window.
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: _dragHeight,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => _call('startDrag'),
        ),
      ),
      const Positioned(top: 8, right: 10, child: _Controls()),
    ]);
  }
}

/// Minimize and close, black on a small white pill so they show on any page.
class _Controls extends StatelessWidget {
  const _Controls();

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
            onTap: () => WindowFrame._call('minimize'),
          ),
          const SizedBox(width: 2),
          _WindowButton(
            tooltip: 'Close',
            glyph: _Glyph.close,
            danger: true,
            onTap: () => WindowFrame._call('close'),
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

enum _Glyph { minimize, close }

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
      ..strokeCap = StrokeCap.round;
    const r = 5.0;
    if (glyph == _Glyph.minimize) {
      canvas.drawLine(c + const Offset(-r, 0), c + const Offset(r, 0), pen);
    } else {
      canvas.drawLine(c + const Offset(-r, -r), c + const Offset(r, r), pen);
      canvas.drawLine(c + const Offset(-r, r), c + const Offset(r, -r), pen);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color;
}
