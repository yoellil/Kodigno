import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

const _items = [
  ('Library', Icons.grid_view_rounded),
  ('Create', Icons.add_circle_outline),
  ('Settings', Icons.tune),
];

const _itemHeight = 46.0;
const _itemGap = 6.0;

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.pages, required this.tab});
  final List<Widget> pages; // Library, Create, Settings
  final ValueNotifier<int> tab;

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
            body: SafeArea(child: _content(index)),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => widget.tab.value = i,
              destinations: [
                for (final (label, icon) in _items)
                  NavigationDestination(icon: Icon(icon), label: label),
              ],
            ),
          );
        }
        return Scaffold(
          body: Row(children: [
            Container(
              width: 248,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: K.line)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const KSticker(icon: Icons.bolt, size: 34, tilt: -0.1),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text('Kodigno',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: display(26)),
                  ),
                ]),
                const SizedBox(height: 32),
                SizedBox(
                  height: _items.length * (_itemHeight + _itemGap),
                  child: Stack(children: [
                    AnimatedPositioned(
                      duration: reduceMotion(context) ? Duration.zero : Motion.medium,
                      curve: Motion.pop,
                      top: index * (_itemHeight + _itemGap),
                      left: 0,
                      right: 0,
                      height: _itemHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: K.yellow, borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    for (var i = 0; i < _items.length; i++)
                      Positioned(
                        top: i * (_itemHeight + _itemGap),
                        left: 0,
                        right: 0,
                        height: _itemHeight,
                        child: _SideItem(
                          label: _items[i].$1,
                          icon: _items[i].$2,
                          onTap: () => widget.tab.value = i,
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: _content(index),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.black.withValues(alpha: 0.05),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Text(label, style: body(16, weight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}
