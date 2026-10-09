import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

/// Which way a horizontal drag/fling should move the deck:
/// -1 = swiped left, 1 = swiped right, 0 = not enough to count.
int swipeDirection({
  required double dx,
  required double velocity,
  double threshold = 110,
  double velocityThreshold = 700,
}) {
  if (dx.abs() >= threshold) return dx.sign.toInt();
  final sameWay = dx == 0 || dx.sign == velocity.sign;
  if (velocity.abs() >= velocityThreshold && sameWay) {
    return velocity.sign.toInt();
  }
  return 0;
}

/// Card that turns around its vertical axis between [front] and [back].
class FlipCard extends StatelessWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.showBack,
  });
  final Widget front;
  final Widget back;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 480);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: showBack ? 1.0 : 0.0),
      duration: duration,
      curve: Curves.easeInOutCubic,
      builder: (_, t, _) {
        final turned = t >= 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0005) // gentle perspective
            ..scaleByDouble(
              1 - 0.1 * math.sin(math.pi * t),
              1 - 0.1 * math.sin(math.pi * t),
              1,
              1,
            )
            ..rotateY(math.pi * t),
          child: turned
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(
                    math.pi,
                  ), // un-mirror the back face
                  child: back,
                )
              : front,
        );
      },
    );
  }
}

/// Swipeable, flippable stack of flashcards.
/// Tap or Space flips; swipe or arrow keys move; the next card rises from the stack.
class FlashDeck extends StatefulWidget {
  const FlashDeck({super.key, required this.cards});
  final List<Flashcard> cards;

  @override
  State<FlashDeck> createState() => _FlashDeckState();
}

class _FlashDeckState extends State<FlashDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(vsync: this);
  int _i = 0;
  bool _back = false;
  double _dx = 0;
  double _width = 600;
  bool _busy = false;

  int get _n => widget.cards.length;

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _flip() {
    if (_busy) return;
    setState(() => _back = !_back);
  }

  /// Moves the top card to [target] x-offset, then runs [then].
  Future<void> _animateTo(double target, {VoidCallback? then}) async {
    final from = _dx;
    if (reduceMotion(context)) {
      setState(() => _dx = target);
      then?.call();
      return;
    }
    _busy = true;
    final anim = Tween<double>(
      begin: from,
      end: target,
    ).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic));
    void tick() => setState(() => _dx = anim.value);
    _slide
      ..duration = const Duration(milliseconds: 260)
      ..reset()
      ..addListener(tick);
    await _slide.forward();
    _slide.removeListener(tick);
    _busy = false;
    if (mounted) then?.call();
  }

  /// [step] +1 = next card (flies off to the left), -1 = previous (flies right).
  void _go(int step) {
    final target = _i + step;
    if (_busy) return;
    if (target < 0 || target >= _n) {
      _animateTo(0); // nothing that way: spring back
      return;
    }
    _animateTo(
      -step * _width * 1.15,
      then: () {
        setState(() {
          _i = target;
          _dx = 0;
          _back = false;
        });
      },
    );
  }

  void _release(double velocity) {
    final dir = swipeDirection(dx: _dx, velocity: velocity);
    if (dir == 0) {
      _animateTo(0);
    } else {
      _go(-dir); // swipe left (-1) => next (+1)
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_i];
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.space ||
            e.logicalKey == LogicalKeyboardKey.enter) {
          _flip();
        } else if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          _go(1);
        } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _go(-1);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: KProgress(value: (_i + 1) / _n)),
              const SizedBox(width: 14),
              Text('${_i + 1} / $_n', style: body(15, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 36,
              ), // room for the stack peeking out
              child: LayoutBuilder(
                builder: (context, c) {
                  _width = c.maxWidth;
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Cards waiting underneath, peeking out below the top card.
                      for (var k = math.min(2, _n - 1 - _i); k >= 1; k--)
                        Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(0, 16.0 * k),
                            child: Transform.scale(
                              scale: 1 - 0.045 * k,
                              alignment: Alignment.bottomCenter,
                              child: Panel(
                                color: K.pastels[(_i + k) % K.pastels.length],
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _flip,
                          onHorizontalDragUpdate: (d) {
                            if (_busy) return;
                            setState(() => _dx += d.delta.dx);
                          },
                          onHorizontalDragEnd: (d) =>
                              _release(d.velocity.pixelsPerSecond.dx),
                          child: Transform.translate(
                            offset: Offset(_dx, 0),
                            child: Transform.rotate(
                              angle: _dx / 1100,
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey(
                                  _i,
                                ), // new card pops up from the stack
                                tween: Tween(
                                  begin: reduceMotion(context) ? 1 : 0.94,
                                  end: 1,
                                ),
                                duration: Motion.medium,
                                curve: Motion.pop,
                                builder: (_, s, child) =>
                                    Transform.scale(scale: s, child: child),
                                child: FlipCard(
                                  key: ValueKey('flip$_i'),
                                  showBack: _back,
                                  front: _Face(
                                    text: card.front,
                                    label: 'question',
                                    color: K.lavender,
                                  ),
                                  back: _Face(
                                    text: card.back,
                                    label: 'answer',
                                    color: K.yellow,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Previous (left arrow)',
                onPressed: _i > 0 ? () => _go(-1) : null,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 14),
              PillButton(label: 'Flip', icon: Icons.flip, onPressed: _flip),
              const SizedBox(width: 14),
              IconButton.filledTonal(
                tooltip: 'Next (right arrow)',
                onPressed: _i < _n - 1 ? () => _go(1) : null,
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Space flips · ← → or swipe to move',
            style: body(12, color: K.muted),
          ),
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.text, required this.label, required this.color});
  final String text;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Panel(
    color: color,
    padding: const EdgeInsets.all(36),
    child: SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: body(13, color: Colors.black54)),
          const SizedBox(height: 14),
          Text(text, textAlign: TextAlign.center, style: display(34)),
        ],
      ),
    ),
  );
}
