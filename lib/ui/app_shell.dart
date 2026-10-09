import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kulay.dart';
import 'loaders.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

const _items = [
  ('Library', Icons.grid_view_rounded),
  ('Create', Icons.add_circle_outline),
  ('Settings', Icons.tune),
];

const _railWidth = 84.0;
const _itemSize = 60.0;
const _itemGap = 10.0;

/// The dark frame around the canvas; a touch deeper than the canvas in dark mode.
Color get _frame => K.dark ? const Color(0xFF070708) : K.ink;

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.pages, required this.tab, this.onHome, this.onKulay});
  final List<Widget> pages; // Library, Create, Settings
  final ValueNotifier<int> tab;

  /// Back to the landing screen.
  final VoidCallback? onHome;

  /// Opens the full-screen Kulay dashboard; called mid color burst.
  final VoidCallback? onKulay;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  late final AnimationController _enter =
      AnimationController(vsync: this, duration: Motion.medium)..value = 1;

  @override
  void initState() {
    super.initState();
    widget.tab.addListener(_onTab);
  }

  void _onTab() {
    if (!reduceMotion(context)) _enter.forward(from: 0);
  }

  @override
  void dispose() {
    widget.tab.removeListener(_onTab);
    _enter.dispose();
    super.dispose();
  }

  final _kulayKey = GlobalKey();

  void _openKulay() {
    final box = _kulayKey.currentContext?.findRenderObject() as RenderBox?;
    final size = MediaQuery.sizeOf(context);
    final origin = box != null && box.hasSize
        ? box.localToGlobal(box.size.center(Offset.zero))
        : Offset(size.width * 0.62, size.height - 40);
    playColorBurst(context, origin: origin, onCovered: widget.onKulay!);
  }

  Widget _content(int index) {
    final curved = CurvedAnimation(parent: _enter, curve: Motion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
        child: IndexedStack(index: index, children: widget.pages),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return ValueListenableBuilder<int>(
      valueListenable: widget.tab,
      builder: (context, index, _) {
        if (!wide) {
          return Scaffold(
            body: SafeArea(
              child: Column(children: [
                if (widget.onHome != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: BackHomeButton(onPressed: widget.onHome!)),
                  ),
                Expanded(child: _content(index)),
              ]),
            ),
            bottomNavigationBar: NavigationBar(
              // Kulay sits third in the bar but is not a page.
              selectedIndex: index < 2 ? index : index + 1,
              onDestinationSelected: (i) {
                if (i == 2) {
                  if (widget.onKulay != null) _openKulay();
                } else {
                  widget.tab.value = i < 2 ? i : i - 1;
                }
              },
              destinations: [
                for (final (label, icon) in _items.take(2))
                  NavigationDestination(icon: Icon(icon), label: label),
                NavigationDestination(key: _kulayKey, icon: const KulayIcon(), label: 'Kulay'),
                for (final (label, icon) in _items.skip(2))
                  NavigationDestination(icon: Icon(icon), label: label),
              ],
            ),
          );
        }
        // Wide: slim dark rail, pages on a rounded canvas inside the frame.
        return Scaffold(
          backgroundColor: _frame,
          body: Row(children: [
            SizedBox(
              width: _railWidth,
              child: Column(children: [
                const SizedBox(height: 22),
                const KSticker(icon: Icons.bolt, size: 40, tilt: -0.1),
                const SizedBox(height: 34),
                SizedBox(
                  height: _items.length * (_itemSize + _itemGap),
                  width: _itemSize,
                  child: Stack(children: [
                    AnimatedPositioned(
                      duration: reduceMotion(context) ? Duration.zero : Motion.medium,
                      curve: Motion.pop,
                      top: index * (_itemSize + _itemGap),
                      left: 0,
                      right: 0,
                      height: _itemSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: K.yellow, borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                    for (var i = 0; i < _items.length; i++)
                      Positioned(
                        top: i * (_itemSize + _itemGap),
                        left: 0,
                        right: 0,
                        height: _itemSize,
                        child: _RailItem(
                          label: _items[i].$1,
                          icon: _iconOf(_items[i].$2),
                          selected: i == index,
                          onTap: () => widget.tab.value = i,
                        ),
                      ),
                  ]),
                ),
                if (widget.onKulay != null) ...[
                  Container(
                    width: 28,
                    height: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  _RailItem(
                    key: _kulayKey,
                    label: 'Kulay',
                    icon: (_, hover) => KulayIcon(active: hover),
                    selected: false,
                    onTap: _openKulay,
                  ),
                ],
                const Spacer(),
                if (widget.onHome != null)
                  _RailItem(
                    label: 'Home',
                    icon: (fg, _) => Transform.flip(
                        flipX: true, child: Icon(Icons.logout_rounded, size: 22, color: fg)),
                    selected: false,
                    onTap: widget.onHome!,
                  ),
                const SizedBox(height: 18),
              ]),
            ),
            Expanded(
              child: Container(
                // Below the window buttons' band when there is one.
                margin: EdgeInsets.fromLTRB(0, math.max(12, MediaQuery.paddingOf(context).top), 12, 12),
                clipBehavior: Clip.antiAlias,
                decoration:
                    BoxDecoration(color: K.bg, borderRadius: BorderRadius.circular(28)),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: _content(index),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// Plain rail icon in the item's foreground color.
Widget Function(Color, bool) _iconOf(IconData icon) =>
    (fg, _) => Icon(icon, size: 22, color: fg);

/// Icon over a small label, on the dark rail. Selected sits on the yellow tile.
class _RailItem extends StatefulWidget {
  const _RailItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Widget Function(Color fg, bool hover) icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.selected
        ? K.ink
        : Colors.white.withValues(alpha: _hover ? 1 : 0.62);
    return Semantics(
      button: true,
      selected: widget.selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hover = v),
          child: SizedBox(
            width: _itemSize,
            height: _itemSize,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              widget.icon(fg, _hover),
              const SizedBox(height: 4),
              Text(widget.label, style: body(11, weight: FontWeight.w700, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}
