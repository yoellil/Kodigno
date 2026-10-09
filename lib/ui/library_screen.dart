import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/database.dart';
import '../data/repository.dart';
import '../data/review_repository.dart';
import 'anim.dart';
import 'motion.dart';
import 'practice_card.dart';
import 'practice_screen.dart';
import 'set_detail_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Source types as stored, with the label used on filter chips.
const _types = [
  ('image', 'Photos'),
  ('pdf', 'PDFs'),
  ('docx', 'Docs'),
  ('text', 'Text'),
];

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' //
];

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.repo, required this.tab});
  final StudyRepository repo;
  final ValueNotifier<int> tab;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';
  String? _type; // null = all
  late final _reviews = ReviewRepository(widget.repo.db);

  void _practice(int minutes, int? setId) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PracticeScreen(repo: widget.repo, reviews: _reviews, minutes: minutes, setId: setId)));

  void _open(StudySet s) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SetDetailScreen(repo: widget.repo, setId: s.id)));

  void _create() => widget.tab.value = 1;

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
        final present = {for (final s in lib.sets) s.sourceType};
        final type = present.contains(_type) ? _type : null;
        final q = _query.toLowerCase();
        final sets = lib.sets
            .where((s) => (type == null || s.sourceType == type) && s.title.toLowerCase().contains(q))
            .toList();

        return LayoutBuilder(builder: (context, box) {
          final wide = box.maxWidth >= 860;
          final header = _Header(onSearch: (v) => setState(() => _query = v), onCreate: _create);
          final chips = Wrap(spacing: 8, runSpacing: 8, children: [
            _FilterChip('All', selected: type == null, onTap: () => setState(() => _type = null)),
            for (final (id, label) in _types)
              if (present.contains(id))
                _FilterChip(label,
                    selected: type == id, onTap: () => setState(() => _type = id)),
          ]);
          final grid = sets.isEmpty
              ? _Empty(hasAny: lib.sets.isNotEmpty, onCreate: _create)
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 200),
                  itemCount: sets.length,
                  itemBuilder: (_, i) => _SetCard(
                    set: sets[i],
                    percent: lib.lastPercent[sets[i].id],
                    onOpen: () => _open(sets[i]),
                    onDelete: () => _confirmDelete(sets[i]),
                  ).enter(context, index: i),
                );
          final upNext = _UpNext(sets: lib.sets, lastPercent: lib.lastPercent, onOpen: _open);
          final stats = _StatsCard(stats: lib.stats, onCreate: _create);

          return ListView(padding: const EdgeInsets.fromLTRB(32, 30, 32, 36), children: [
            header,
            const SizedBox(height: 22),
            if (lib.sets.isNotEmpty) ...[
              PracticeCard(reviews: _reviews, sets: lib.sets, snapshot: lib, onStart: _practice),
              const SizedBox(height: 22),
              chips,
              const SizedBox(height: 18),
            ],
            grid,
            const SizedBox(height: 24),
            if (wide)
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 3, child: upNext),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: stats),
                ]),
              )
            else ...[
              upNext,
              const SizedBox(height: 16),
              stats,
            ],
          ]);
        });
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch, required this.onCreate});
  final ValueChanged<String> onSearch;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: K.line),
    );
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Welcome back', style: body(14, color: K.muted)),
          const SizedBox(height: 4),
          Text('My library', style: display(36)),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 240,
            child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search sets',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: K.card,
                border: border,
                enabledBorder: border,
              ),
            ),
          ),
          const SizedBox(width: 12),
          PillButton(label: 'New set', icon: Icons.add, onPressed: onCreate),
        ]),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? K.text : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: selected ? K.text : K.line, width: 1.2)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: AnimatedPadding(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(label,
                style: body(13, weight: FontWeight.w700, color: selected ? K.bg : K.text)),
          ),
        ),
      );
}

/// Pastel card with a thin outline: source tag, title, last score, Open.
class _SetCard extends StatelessWidget {
  const _SetCard(
      {required this.set, required this.percent, required this.onOpen, required this.onDelete});
  final StudySet set;
  final int? percent;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = K.pastels[set.id % K.pastels.length];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: K.ink, width: 1.4),
      ),
      child: Lift(
        color: color,
        radius: 21,
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
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
                tooltip: 'More',
                icon: const Icon(Icons.more_horiz),
                onSelected: (_) => onDelete(),
                itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(set.title,
                  style: display(22), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(children: [
              Expanded(
                  child: Text('Last score',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: body(12))),
              Text(percent == null ? 'Not taken' : '$percent%',
                  style: body(12, weight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: KProgress(value: (percent ?? 0) / 100, color: K.ink),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: Text(_date(set.createdAt),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: body(12))),
            _SmallButton(label: 'Open', onTap: onOpen),
          ]),
        ]),
      ),
    );
  }
}

String _date(DateTime d) => '${_months[d.month - 1]} ${d.day}';

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: K.ink,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(label, style: body(13, weight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      );
}

/// Most recent sets as a simple list; the ones never quizzed come first.
class _UpNext extends StatelessWidget {
  const _UpNext({required this.sets, required this.lastPercent, required this.onOpen});
  final List<StudySet> sets;
  final Map<int, int> lastPercent;
  final void Function(StudySet) onOpen;

  @override
  Widget build(BuildContext context) {
    final list = [
      ...sets.where((s) => !lastPercent.containsKey(s.id)),
      ...sets.where((s) => lastPercent.containsKey(s.id)),
    ].take(5).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
      decoration: BoxDecoration(
        color: K.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: K.line, width: 1.2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pick up where you left off', style: display(20)),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Your sets will show up here.', style: body(14, color: K.muted)),
          )
        else ...[
          Row(children: [
            Expanded(child: Text('Set', style: body(12, color: K.muted))),
            SizedBox(
                width: 90,
                child: Text('Last score',
                    textAlign: TextAlign.right, style: body(12, color: K.muted))),
            const SizedBox(width: 32),
          ]),
          const SizedBox(height: 6),
          for (var i = 0; i < list.length; i++) ...[
            Divider(height: 1, color: K.line),
            _UpNextRow(set: list[i], percent: lastPercent[list[i].id], onTap: () => onOpen(list[i])),
          ],
        ],
      ]),
    );
  }
}

class _UpNextRow extends StatelessWidget {
  const _UpNextRow({required this.set, required this.percent, required this.onTap});
  final StudySet set;
  final int? percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: K.pastels[set.id % K.pastels.length],
                shape: BoxShape.circle,
                border: Border.all(color: K.ink, width: 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(set.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(14, weight: FontWeight.w700)),
                Text(
                    '${_types.firstWhere((t) => t.$1 == set.sourceType, orElse: () => (set.sourceType, set.sourceType)).$2} · added ${_date(set.createdAt)}',
                    style: body(12, color: K.muted)),
              ]),
            ),
            SizedBox(
              width: 90,
              child: Text(percent == null ? 'New' : '$percent%',
                  textAlign: TextAlign.right, style: body(14, weight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: K.muted),
          ]),
        ),
      );
}

/// Dark card: this week's count, sets, and a create button.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.onCreate});
  final LibraryStats stats;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    final muted = Colors.white.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: K.dark ? const Color(0xFF26262E) : K.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      // spaceBetween keeps the button at the bottom when the card is stretched
      // (wide layout) and just stacks when its height is open (narrow).
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Answered this week', style: body(14, color: muted)),
        const SizedBox(height: 6),
        CountUp(value: stats.answeredThisWeek, style: display(64, color: fg)),
        const SizedBox(height: 16),
        Row(children: [
          _Stat(
              icon: Icon(Icons.collections_bookmark_outlined, size: 18, color: muted),
              label: 'Sets',
              value: '${stats.sets}'),
        ]),
        const SizedBox(height: 22),
          ]),
          SizedBox(
            width: double.infinity,
            child: PillButton(label: 'Make a new set', icon: Icons.add, onPressed: onCreate),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          icon,
          const SizedBox(width: 6),
          Text('$label ', style: body(12, color: Colors.white.withValues(alpha: 0.6))),
          Text(value, style: body(13, weight: FontWeight.w800, color: Colors.white)),
        ]),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasAny, required this.onCreate});
  final bool hasAny;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: K.line, width: 1.2),
        ),
        child: Center(
          child: Column(children: [
            const KSticker(icon: Icons.folder_open, color: K.yellow, size: 64, tilt: -0.08),
            const SizedBox(height: 18),
            Text(hasAny ? 'No sets match' : 'Nothing here yet', style: display(24)),
            const SizedBox(height: 8),
            Text(
              hasAny
                  ? 'Try a different word or filter.'
                  : 'Add a photo, PDF or document and Kodigno turns it into a quiz.',
              textAlign: TextAlign.center,
              style: body(15, color: K.muted),
            ),
            if (!hasAny) ...[
              const SizedBox(height: 18),
              PillButton(label: 'Add source', icon: Icons.add, onPressed: onCreate),
            ],
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
        Expanded(child: box(190)),
        const SizedBox(width: 16),
        Expanded(child: box(190)),
        const SizedBox(width: 16),
        Expanded(child: box(190)),
      ]),
      const SizedBox(height: 24),
      box(220),
    ]);
    if (reduceMotion(context)) return list;
    return list
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1300.ms, color: K.card);
  }
}

