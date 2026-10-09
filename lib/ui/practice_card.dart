import 'package:flutter/material.dart';

import '../data/database.dart' show StudySet;
import '../data/review_repository.dart';
import '../study/scheduler.dart';
import '../study/session_plan.dart';
import 'theme.dart';
import 'widgets.dart';

/// The lengths a student can pick, in minutes.
const practiceLengths = [2, 5, 10];

/// What a session would hold, in words: a headline and a line of detail.
({String headline, String detail}) practiceSummary(PracticeCounts counts, int minutes) {
  final w = counts.within(sessionSizeFor(minutes));
  final items = w.total;
  if (items == 0) {
    if (counts.doneToday > 0) {
      return (headline: 'All done for today', detail: 'Your next items come up on another day.');
    }
    return (headline: 'Nothing to practice yet', detail: 'Make a study set and it will show up here.');
  }
  final time = 'about ${estimateMinutes(items)} min';
  final noun = items == 1 ? 'item' : 'items';
  if (w.due == 0 && w.fresh == 0) {
    return (headline: 'Nothing due today', detail: 'Practice ahead: $items $noun · $time');
  }
  final parts = [
    if (w.due > 0) '${w.due} due',
    if (w.fresh > 0) '${w.fresh} new',
    if (w.ahead > 0) '${w.ahead} to revisit early',
  ];
  return (headline: '$items $noun · $time', detail: parts.join(' · '));
}

/// "Today's practice": how many items are waiting, how long to practice, which
/// set, and a Start button. Picking a length or a set updates the counts.
class PracticeCard extends StatefulWidget {
  const PracticeCard({
    super.key,
    required this.reviews,
    required this.sets,
    required this.snapshot,
    required this.onStart,
  });
  final ReviewRepository reviews;
  final List<StudySet> sets;

  /// Whatever the library last loaded; a new object means the counts may have
  /// changed and are read again.
  final Object snapshot;
  final void Function(int minutes, int? setId) onStart;

  @override
  State<PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<PracticeCard> {
  int _minutes = 5;
  int? _setId;
  late Future<PracticeCounts> _counts;

  /// The chosen set, or null if it has gone.
  int? get _validSet => widget.sets.any((s) => s.id == _setId) ? _setId : null;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(PracticeCard old) {
    super.didUpdateWidget(old);
    if (!identical(old.snapshot, widget.snapshot)) _reload();
  }

  void _reload() => _counts = widget.reviews.counts(setId: _validSet);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: K.yellow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: inkOnPastel(
        K.yellow,
        FutureBuilder<PracticeCounts>(
          future: _counts,
          builder: (context, snap) {
            final counts = snap.data;
            final summary = counts == null ? null : practiceSummary(counts, _minutes);
            final canStart = counts != null && counts.within(sessionSizeFor(_minutes)).total > 0;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.bolt, size: 22),
                const SizedBox(width: 8),
                Text("Today's practice", style: display(22)),
              ]),
              const SizedBox(height: 10),
              Text(summary?.headline ?? ' ', style: body(17, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(summary?.detail ?? ' ', style: body(13, color: Colors.black54)),
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                for (final m in practiceLengths)
                  _Length(
                    label: '$m min',
                    selected: _minutes == m,
                    onTap: () => setState(() => _minutes = m),
                  ),
                if (widget.sets.length > 1) _SetPicker(
                  sets: widget.sets,
                  value: _validSet,
                  onChanged: (id) => setState(() {
                    _setId = id;
                    _reload();
                  }),
                ),
              ]),
              const SizedBox(height: 16),
              PillButton(
                label: 'Start',
                icon: Icons.play_arrow,
                dark: true,
                onPressed: canStart ? () => widget.onStart(_minutes, _validSet) : null,
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _Length extends StatelessWidget {
  const _Length({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? K.ink : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: K.ink, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(label,
                style: body(14, weight: FontWeight.w800, color: selected ? Colors.white : K.ink)),
          ),
        ),
      );
}

class _SetPicker extends StatelessWidget {
  const _SetPicker({required this.sets, required this.value, required this.onChanged});
  final List<StudySet> sets;
  final int? value;
  final void Function(int? id) onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: ShapeDecoration(shape: StadiumBorder(side: BorderSide(color: K.ink, width: 1.5))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: value,
            isDense: true,
            isExpanded: true,
            dropdownColor: K.card,
            style: body(14, weight: FontWeight.w700, color: K.text),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text('All sets', style: body(14, weight: FontWeight.w700, color: K.text))),
              for (final s in sets)
                DropdownMenuItem<int?>(
                  value: s.id,
                  child: Text(s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(14, weight: FontWeight.w700, color: K.text)),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      );
}
