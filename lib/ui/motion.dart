import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shared durations and curves so every screen moves the same way.
class Motion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 600);
  static const curve = Curves.easeOutCubic;
  static const pop = Curves.easeOutBack;
}

/// True when the OS "reduce motion / disable animations" setting is on.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

extension EnterX on Widget {
  /// Fade in and rise a little on first build, staggered by [index].
  /// Does nothing when the user asked for reduced motion.
  Widget enter(BuildContext context, {int index = 0, double dy = 0.06}) {
    if (reduceMotion(context)) return this;
    final delay = Duration(milliseconds: 45 * math.min(index, 12));
    return animate(delay: delay)
        .fadeIn(duration: 380.ms, curve: Motion.curve)
        .slideY(begin: dy, end: 0, duration: 380.ms, curve: Motion.curve);
  }
}
