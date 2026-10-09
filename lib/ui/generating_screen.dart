import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

class GeneratingScreen extends StatelessWidget {
  const GeneratingScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final f = context.watch<AppController>().generationFraction;
    final writingDone = f >= 1;
    final calm = reduceMotion(context);

    Widget bar = KProgress(value: f, height: 10);
    Widget sticker = const KSticker(icon: Icons.auto_awesome, color: K.lavender, size: 64);
    if (!calm) {
      if (!writingDone) {
        bar = bar.animate(onPlay: (c) => c.repeat()).shimmer(duration: 1400.ms, color: Colors.white70);
      }
      sticker = sticker
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 900.ms)
          .rotate(begin: -0.02, end: 0.02, duration: 900.ms);
    }

    return PopScope(
      canPop: false, // generation cannot be cancelled in v1
      child: PanelPage(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sticker,
                  const SizedBox(height: 22),
                  Chip(
                    label: Text(title),
                    avatar: const Icon(Icons.insert_drive_file_outlined, size: 16),
                  ),
                  const SizedBox(height: 20),
                  Text('generating', style: body(14, color: K.muted)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: f),
                    duration: calm ? Duration.zero : Motion.slow,
                    curve: Motion.curve,
                    builder: (_, v, _) => Text('${(v * 100).floor()}%', style: display(110)),
                  ),
                  const SizedBox(height: 12),
                  bar,
                  const SizedBox(height: 28),
                  const _Step('Reading your notes', done: true),
                  _Step('Writing questions & flashcards', done: writingDone, active: !writingDone),
                  _Step('Saving your set', done: false, active: writingDone),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.label, {required this.done, this.active = false});
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Widget icon = done
        ? const Icon(Icons.check_circle, size: 22, key: ValueKey('done'))
        : active
            ? const CircularProgressIndicator(strokeWidth: 2.5, key: ValueKey('active'))
            : Icon(Icons.circle_outlined, size: 22, color: K.muted, key: const ValueKey('todo'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        SizedBox(
          width: 22,
          height: 22,
          child: AnimatedSwitcher(
            duration: reduceMotion(context) ? Duration.zero : Motion.medium,
            transitionBuilder: (child, a) => ScaleTransition(
                scale: CurvedAnimation(parent: a, curve: Motion.pop), child: child),
            child: icon,
          ),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: body(16, weight: done || active ? FontWeight.w700 : FontWeight.w500,
                color: done || active ? K.text : K.muted)),
      ]),
    );
  }
}
