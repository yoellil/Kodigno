import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import 'card_editor.dart';
import 'motion.dart';
import 'slide_tag.dart';
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
        : const Duration(milliseconds: 560);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: showBack ? 1.0 : 0.0),
      duration: duration,
      curve: Curves.easeInOutCubic,
      builder: (_, t, _) {
        final turned = t >= 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0008) // gentle perspective
            ..scaleByDouble(
              1 + 0.04 * math.sin(math.pi * t), // lifts toward you mid-turn
              1 + 0.04 * math.sin(math.pi * t),
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
///
/// With [onSave] a card that has an id gets an Edit button: the card turns into a
/// form (term and definition, with Ask AI beside each when [suggest] is given) and
/// Save hands the corrected text to [onSave], whoever wrote the card.
class FlashDeck extends StatefulWidget {
  const FlashDeck({
    super.key,
    required this.cards,
    this.onSave,
    this.suggest,
    this.startAt = 0,
  });
  final List<Flashcard> cards;
  final Future<void> Function(Flashcard card, String front, String back)?
  onSave;
  final CardSuggester? suggest;

  /// The card to start on.
  final int startAt;

  @override
  State<FlashDeck> createState() => _FlashDeckState();
}

class _FlashDeckState extends State<FlashDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(vsync: this);
  late int _i = widget.startAt.clamp(0, widget.cards.length - 1);
  bool _back = false;
  bool _editing = false;
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
  Future<void> _animateTo(
    double target, {
    VoidCallback? then,
    Curve curve = Curves.easeOutCubic,
  }) async {
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
    ).animate(CurvedAnimation(parent: _slide, curve: curve));
    void tick() => setState(() => _dx = anim.value);
    _slide
      ..duration = Duration(milliseconds: target == 0 ? 360 : 260)
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
      _animateTo(0, curve: Motion.pop); // nothing that way: spring back
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
      _animateTo(0, curve: Motion.pop);
    } else {
      _go(-dir); // swipe left (-1) => next (+1)
    }
  }

  /// A card waiting [k] slots below the top. [rise] (0..1) moves every waiting
  /// card one slot up, so at 1 the first one sits exactly where the next top
  /// card will be: the swap at the end of a swipe is invisible.
  Widget _underCard(int k, double rise) {
    final d = k - rise;
    final panel = Panel(
      key: ValueKey('under$k'),
      color: Color.lerp(K.lavender, K.card, 0.3 * d)!,
      child: const SizedBox.expand(),
    );
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(0, 16.0 * d),
        child: Transform.scale(
          scale: 1 - 0.045 * d,
          alignment: Alignment.bottomCenter,
          child: k == 3 ? Opacity(opacity: rise, child: panel) : panel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_i];
    final rise = Curves.easeOut.transform(
      (_dx.abs() / (_width * 0.5)).clamp(0.0, 1.0),
    );
    // Going back from the last card still needs one card to rise.
    final under = math.min(3, math.max(_n - 1 - _i, _dx > 0 && _i > 0 ? 1 : 0));
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (_editing || e is! KeyDownEvent) {
          return KeyEventResult.ignored; // typing is not a shortcut
        }
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
          if (_editing)
            Expanded(
              child: SingleChildScrollView(
                child: Panel(
                  color: K.card,
                  padding: const EdgeInsets.all(24),
                  child: CardEditorForm(
                    key: ValueKey('edit-${card.id}'),
                    initialTerm: card.front,
                    initialDefinition: card.back,
                    termLabel: 'Term or question',
                    definitionLabel: 'Definition or answer',
                    saveLabel: 'Save changes',
                    suggest: widget.suggest,
                    onSave: (t, d) async {
                      await widget.onSave!(card, t, d);
                      if (mounted) {
                        setState(() {
                          _editing = false;
                          _back = false;
                        });
                      }
                    },
                    onCancel: () => setState(() => _editing = false),
                  ),
                ),
              ),
            )
          else ...[
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
                        // Cards waiting underneath; they rise a slot as the top card leaves.
                        for (var k = under; k >= 1; k--) _underCard(k, rise),
                        Positioned.fill(
                          key: const ValueKey(
                            'top',
                          ), // stack size changes mid-drag
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
                if (widget.onSave != null && card.id != null) ...[
                  const SizedBox(width: 14),
                  IconButton.filledTonal(
                    tooltip: 'Edit card',
                    onPressed: _busy
                        ? null
                        : () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Space flips · ← → or swipe to move',
              style: body(12, color: K.muted),
            ),
            // Where the answer comes from, once it is showing.
            if (_back && widget.cards[_i].source != null) ...[
              const SizedBox(height: 8),
              SlideTag(widget.cards[_i].source!),
            ],
          ],
        ],
      ),
    );
  }
}

/// Big for a word or two, smaller as the card text gets longer.
double faceFontSize(String text) {
  final n =
      text.length +
      20 * '\n'.allMatches(text).length; // lists need room per line
  if (n <= 40) return 34;
  if (n <= 80) return 28;
  if (n <= 140) return 23;
  return 19;
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
          // Long text steps down in size; scrolling is only a last resort.
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                text,
                // A numbered list reads best left-aligned, with air between lines.
                textAlign: text.contains('\n')
                    ? TextAlign.left
                    : TextAlign.center,
                style: display(faceFontSize(text))
                    .copyWith(height: text.contains('\n') ? 1.4 : null),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
