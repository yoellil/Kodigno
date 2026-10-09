import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/database.dart';
import '../data/repository.dart';
import 'anim.dart';
import 'motion.dart';
import 'set_detail_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.repo, required this.tab});
  final StudyRepository repo;
  final ValueNotifier<int> tab;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';

  Future<void> _confirmDelete(StudySet s) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${s.title}"?'),
        content: const Text('The set, its quiz, flashcards and scores will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) await widget.repo.deleteSet(s.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LibraryData>(
      stream: widget.repo.watchLibrary(),
      builder: (context, snap) {
        final lib = snap.data;
        if (lib == null) return const _Skeleton();
        final sets = lib.sets
            .where((s) => s.title.toLowerCase().contains(_query.toLowerCase()))
            .toList();
        return ListView(padding: const EdgeInsets.fromLTRB(32, 32, 32, 40), children: [
          Row(children: [
            Expanded(child: Text('My library', style: display(38))),
            SizedBox(
              width: 280,
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: K.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: K.line),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 28),
          if (sets.isEmpty)
            _Empty(hasAny: lib.sets.isNotEmpty)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(6), // room for tilt and shadow
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 290,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.12),
              itemCount: sets.length,
              itemBuilder: (_, i) {
                final s = sets[i];
                return _SetCard(
                  set: s,
                  percent: lib.lastPercent[s.id],
                  onOpen: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SetDetailScreen(repo: widget.repo, setId: s.id))),
                  onDelete: () => _confirmDelete(s),
                ).enter(context, index: i);
              },
            ),
          const SizedBox(height: 32),
          Center(
            child: PillButton(
              label: 'Add source',
              icon: Icons.add,
              onPressed: () => widget.tab.value = 1,
            ),
          ),
          const SizedBox(height: 40),
          Text('Answered this week', style: body(14, color: K.muted)),
          const SizedBox(height: 4),
          CountUp(value: lib.stats.answeredThisWeek, style: display(92)),
          const SizedBox(height: 14),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _Chip(const Icon(Icons.collections_bookmark_outlined, size: 18), 'Sets',
                '${lib.stats.sets}'),
            _Chip(
              _Flame(active: lib.stats.streakDays > 0),
              'Streak',
              '${lib.stats.streakDays} ${lib.stats.streakDays == 1 ? 'day' : 'days'}',
            ),
          ]),
        ]);
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasAny});
  final bool hasAny;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(children: [
            const KSticker(icon: Icons.folder_open, color: K.yellow, size: 76, tilt: -0.08),
            const SizedBox(height: 22),
            Text(hasAny ? 'No sets match your search' : 'Nothing here yet',
                style: display(26)),
            const SizedBox(height: 8),
            Text(
              hasAny
                  ? 'Try a different word.'
                  : 'Add a photo, PDF or document and Kodigno turns it into a quiz.',
              style: body(15, color: K.muted),
            ),
          ]).enter(context),
        ),
      );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(
          height: h,
          decoration: BoxDecoration(color: K.tile, borderRadius: BorderRadius.circular(24)),
        );
    final list = ListView(padding: const EdgeInsets.all(32), children: [
      box(44),
      const SizedBox(height: 28),
      Row(children: [
        Expanded(child: box(150)),
        const SizedBox(width: 20),
        Expanded(child: box(150)),
        const SizedBox(width: 20),
        Expanded(child: box(150)),
      ]),
    ]);
    if (reduceMotion(context)) return list;
    return list
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1300.ms, color: Colors.white);
  }
}

class _Flame extends StatelessWidget {
  const _Flame({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.local_fire_department,
        size: 20, color: active ? const Color(0xFFFF6A2B) : K.muted);
    if (!active || reduceMotion(context)) return icon;
    return icon.animate().scale(
        begin: const Offset(0.4, 0.4), duration: 700.ms, curve: Curves.elasticOut);
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard(
      {required this.set, required this.percent, required this.onOpen, required this.onDelete});
  final StudySet set;
  final int? percent;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Lift(
        color: K.pastels[set.id % K.pastels.length],
        radius: 26,
        tilt: ((set.id * 37) % 5 - 2) * 0.012, // a gentle, stable tilt per card
        padding: const EdgeInsets.all(18),
        onTap: onOpen,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SourceTag(set.sourceType),
            const Spacer(),
            SizedBox(
              width: 32,
              height: 32,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz),
                onSelected: (_) => onDelete(),
                itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Expanded(
            child: Text(set.title,
                style: display(26), maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
          Row(children: [
            Expanded(child: KProgress(value: (percent ?? 0) / 100)),
            const SizedBox(width: 10),
            Text(percent == null ? '-' : '$percent%', style: body(13, weight: FontWeight.w800)),
          ]),
        ]),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label, this.value);
  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(color: K.tile, borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          icon,
          const SizedBox(width: 8),
          Text('$label ', style: body(13, color: K.muted)),
          Text(value, style: body(14, weight: FontWeight.w800)),
        ]),
      );
}
