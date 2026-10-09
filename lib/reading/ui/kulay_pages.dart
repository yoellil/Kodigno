import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../ui/theme.dart';
import '../levels.dart';
import '../nlp.dart' show skills;
import '../reading_controller.dart';
import '../reading_repository.dart';
import 'story_view.dart';

TextStyle _h(double size) => display(size, color: kIndigoText);
TextStyle _p(double size, {Color color = kSoft, FontWeight weight = FontWeight.w500}) => body(size, color: color, weight: weight);

// ---------- landing panels (shown beside JIM's shelves) ----------

/// First open: who uses Kulay here. Then, in personal mode, the reader's name.
class WelcomePanel extends StatefulWidget {
  const WelcomePanel({super.key});
  @override
  State<WelcomePanel> createState() => _WelcomePanelState();
}

class _WelcomePanelState extends State<WelcomePanel> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start(ReadingController c) async {
    final e = await c.addReader(_name.text);
    if (mounted) setState(() => _error = e);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    if (c.mode == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Who reads on this computer?', style: _p(16, color: kIndigoText, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          KButton('Just me', onTap: () => c.setMode(KulayMode.personal)),
          KButton('A class, taking turns', ghost: true, onTap: () => c.setMode(KulayMode.classroom)),
        ]),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text("What's your name?", style: _p(16, color: kIndigoText, weight: FontWeight.w700)),
      const SizedBox(height: 10),
      _NameField(controller: _name, onSubmit: () => _start(c), error: _error, button: 'Start reading check'),
    ]);
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.onSubmit, required this.error, required this.button});
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String? error;
  final String button;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: controller,
            maxLength: 40,
            onSubmitted: (_) => onSubmit(),
            style: _p(16, color: kIndigoText),
            decoration: InputDecoration(hintText: 'First name and last initial', counterText: '', fillColor: kPaper, errorText: error),
          ),
        ),
        const SizedBox(height: 10),
        KButton(button, onTap: onSubmit),
      ]);
}

/// Classroom: pick your name, or add a new reader.
class ReadersPanel extends StatefulWidget {
  const ReadersPanel({super.key});
  @override
  State<ReadersPanel> createState() => _ReadersPanelState();
}

class _ReadersPanelState extends State<ReadersPanel> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('Who is reading today?', style: _p(18, color: kIndigoText, weight: FontWeight.w800)),
      const SizedBox(height: 12),
      if (c.readers.isEmpty) Text('No readers yet. Add the first one below.', style: _p(14)),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final r in c.readers)
          Material(
            color: kPaper,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => c.pickReader(r),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: levels[r.level].bg, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(r.name, style: _p(15, color: kIndigoText, weight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text(r.placed ? levels[r.level].name : 'Needs reading check', style: _p(12)),
                ]),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 18),
      Text('New reader? Type your name.', style: _p(14, color: kIndigoText, weight: FontWeight.w700)),
      const SizedBox(height: 8),
      _NameField(
        controller: _name,
        error: _error,
        button: 'Start reading check',
        onSubmit: () async {
          final e = await c.addReader(_name.text);
          if (mounted) setState(() => _error = e);
        },
      ),
    ]);
  }
}

// ---------- the reader's page ----------

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _topic = TextEditingController();

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final r = c.reader!;
    final top = r.level == levels.length - 1;
    return ListView(padding: const EdgeInsets.fromLTRB(28, 8, 28, 28), children: [
      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 6, children: [
        Text('Hi, ${r.name}. You read at', style: _h(32)),
        LevelChip(r.level, big: true),
      ]),
      const SizedBox(height: 20),
      _Ladder(level: r.level),
      const SizedBox(height: 12),
      Text(
          top
              ? '${c.progress.up.clamp(0, 3)} of 3 strong scores. You are at the top color.'
              : '${c.progress.up} of 3 stories at 80% or more to move up to ${levels[r.level + 1].name}.',
          style: _p(15, color: kIndigoText)),
      if (c.progress.down > 0 && r.level > 0)
        Text('One more score under 60% moves you to ${levels[r.level - 1].name} for extra practice.', style: _p(14)),
      const SizedBox(height: 28),
      Text('What do you want to read about?', style: _h(24)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in topics)
          ActionChip(
            label: Text(t, style: _p(14, color: kIndigoText, weight: FontWeight.w600)),
            backgroundColor: kPaper,
            side: const BorderSide(color: kLine),
            shape: const StadiumBorder(),
            onPressed: () => c.readTopic(t),
          ),
      ]),
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: _topic,
            maxLength: 40,
            style: _p(15, color: kIndigoText),
            onSubmitted: (v) => c.readTopic(v),
            decoration: const InputDecoration(hintText: 'Type any topic, like "my pet cat"', counterText: '', fillColor: kPaper),
          ),
        ),
        KButton('Write my story', onTap: () => c.readTopic(_topic.text)),
      ]),
    ]);
  }
}

class _Ladder extends StatelessWidget {
  const _Ladder({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 6, runSpacing: 6, children: [
        for (final (i, l) in levels.indexed)
          Opacity(
            opacity: i > level ? 0.45 : 1,
            child: Container(
              width: 92,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: l.bg,
                borderRadius: BorderRadius.circular(12),
                border: i == level ? Border.all(color: kIndigoText, width: 3) : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.name, style: body(14, weight: FontWeight.w800, color: l.fg)),
                Text('Gr ${l.grades}', style: body(11, weight: FontWeight.w600, color: l.fg)),
              ]),
            ),
          ),
      ]);
}

// ---------- writing: the 8 steps ----------

class WritingPage extends StatelessWidget {
  const WritingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final l = levels[c.reader!.level];
    return ListView(padding: const EdgeInsets.fromLTRB(28, 8, 28, 28), children: [
      Text('Writing your story on this computer', style: _h(28)),
      const SizedBox(height: 6),
      Text('No internet needed. The AI checks its own work twice before you see it.', style: _p(15)),
      const SizedBox(height: 18),
      for (final (i, name) in stepNames.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i + 1 < c.step ? kIndigoText : i + 1 == c.step ? l.bg : kPaper,
              ),
              child: i + 1 < c.step
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                  : i + 1 == c.step && c.error == null
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.4, color: l.fg))
                      : Text('${i + 1}', style: body(13, weight: FontWeight.w800, color: kIndigoText)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: _p(15, color: i + 1 > c.step ? kSoft : kIndigoText, weight: FontWeight.w700)),
                if (c.stepDetail[i].isNotEmpty) Text(c.stepDetail[i], style: _p(13)),
              ]),
            ),
          ]),
        ),
      if (c.error != null) ...[
        const SizedBox(height: 8),
        Text(c.error!, style: _p(15, color: kBad, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: KButton('Pick another topic', ghost: true, onTap: c.goHome)),
      ],
    ]);
  }
}

// ---------- reading a story or a placement passage ----------

class ReadPage extends StatelessWidget {
  const ReadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final p = c.passage!;
    final isStory = p is Story;
    final proof = <int>{
      if (c.checked)
        for (final (i, q) in p.questions.indexed)
          if (c.answers[i] != q.answer) q.evidence,
    };
    final story = StoryCard(
      key: ValueKey(isStory ? 's${p.id}' : 'p${c.placementIndex}'),
      passage: p,
      label: isStory ? p.topic : 'Reading check ${c.placementIndex + 1}',
      proof: proof,
      onWord: c.explainWord,
    );
    final side = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!isStory && !c.checked) ...[
        Text(c.placementIndex == 0 ? 'Reading check' : 'Nice. Here is the next one.', style: _h(26)),
        const SizedBox(height: 4),
        Text('Part ${c.placementIndex + 1} of up to ${placement.length}. Read the story, then answer. This finds the color that fits you best.',
            style: _p(14)),
        const SizedBox(height: 14),
      ],
      if (isStory && c.result != null) _ResultBanner(story: p),
      if (!isStory && c.checked) _PlacementNext(),
      if (c.notice != null && isStory && c.result == null)
        Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(c.notice!, style: _p(14, color: kIndigoText))),
      Text('Questions', style: _h(22)),
      const SizedBox(height: 10),
      QuizPanel(passage: p, answers: c.answers, checked: c.checked, onChoose: c.choose),
      if (!c.checked)
        Align(
          alignment: Alignment.centerLeft,
          child: KButton(c.allAnswered ? 'Check my answers' : 'Answer every question',
              onTap: c.allAnswered ? (isStory ? c.submitStory : c.checkPlacement) : null),
        ),
    ]);
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth < 900) {
        return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
          story,
          if (isStory) ChecksNote(p),
          const SizedBox(height: 20),
          side,
        ]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 6,
          child: ListView(padding: const EdgeInsets.fromLTRB(28, 8, 12, 28), children: [story, if (isStory) ChecksNote(p)]),
        ),
        Expanded(flex: 5, child: ListView(padding: const EdgeInsets.fromLTRB(12, 8, 28, 28), children: [side])),
      ]);
    });
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.story});
  final Story story;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final res = c.result!;
    final l = levels[res.level];
    final up = res.level > res.from, down = res.level < res.from;
    final top = res.level == levels.length - 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: up ? l.bg : kPaper, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${res.correct} of ${res.total} correct (${res.pct}%)', style: display(26, color: up ? l.fg : kIndigoText)),
        const SizedBox(height: 6),
        Text(
          up
              ? 'You moved up to ${l.name}, Grades ${l.grades}. Stories get longer and questions get harder.'
              : down
                  ? 'Next stories will be ${l.name} for more practice. Three strong scores and you climb back up.'
                  : c.progress.down > 0 && res.level > 0
                      ? 'Tricky one. Read slowly next time: one more score under 60% moves you to ${levels[res.level - 1].name} for practice.'
                      : top
                          ? 'Keep going at the top color.'
                          : '${c.progress.up} of 3 strong scores toward ${levels[res.level + 1].name}.',
          style: _p(15, color: up ? l.fg : kIndigoText, weight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          KButton('Next ${story.topic} story', onTap: () => c.readTopic(story.topic)),
          KButton('Pick a new topic', ghost: true, onTap: c.goHome),
          if (c.mode == KulayMode.classroom) KButton('Done, next reader', ghost: true, onTap: c.switchReader),
        ]),
      ]),
    );
  }
}

class _PlacementNext extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final right = c.placementRight!.where((x) => x).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.placedLevel == null ? kPaper : levels[c.placedLevel!].bg, borderRadius: BorderRadius.circular(18)),
      child: c.placedLevel == null
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$right of ${c.placementRight!.length} right. On to the next one.', style: _p(16, color: kIndigoText, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              KButton('Next passage', onTap: c.nextPlacement),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your starting color is', style: _p(15, color: levels[c.placedLevel!].fg, weight: FontWeight.w600)),
              Text(levels[c.placedLevel!].name, style: display(44, color: levels[c.placedLevel!].fg)),
              Text('Grades ${levels[c.placedLevel!].grades}. Score 80% or more on 3 stories in a row to move up.',
                  style: _p(14, color: levels[c.placedLevel!].fg)),
              const SizedBox(height: 12),
              KButton('Pick a topic', onTap: c.nextPlacement),
            ]),
    );
  }
}

// ---------- teacher view ----------

const _skillHint = {
  'Details': 'who, what, where, when',
  'Cause and effect': 'why something happened',
  'Feelings': 'how a character felt',
  'Word meaning': 'what a word means',
};

/// Asks for the teacher PIN (sets it the first time). Returns the typed PIN.
Future<String?> askPin(BuildContext context, {required bool first}) {
  final pin = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(first ? 'Set a teacher PIN' : 'Teacher PIN', style: _h(22)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(first ? 'Pick 4 digits. Readers will need them to open the class view.' : 'Type the 4-digit PIN.', style: _p(14)),
        const SizedBox(height: 10),
        TextField(
          controller: pin,
          autofocus: true,
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          onSubmitted: (v) => Navigator.pop(ctx, v),
          decoration: const InputDecoration(counterText: ''),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, pin.text), child: const Text('Open')),
      ],
    ),
  ).whenComplete(pin.dispose);
}

class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key});
  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  late Future<ClassReport> _report = context.read<ReadingController>().classReport();

  void _refresh() => setState(() => _report = context.read<ReadingController>().classReport());

  @override
  Widget build(BuildContext context) {
    final c = context.read<ReadingController>();
    final classroom = c.mode == KulayMode.classroom;
    return FutureBuilder<ClassReport>(
      future: _report,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final rep = snap.data!;
        final placed = rep.readers.where((r) => r.reader.placed);
        return ListView(padding: const EdgeInsets.fromLTRB(28, 8, 28, 28), children: [
          Text(classroom ? 'Class progress' : 'My progress', style: _h(32)),
          Text('${rep.readers.length} ${rep.readers.length == 1 ? 'reader' : 'readers'}. Scores stay on this computer.', style: _p(15)),
          const SizedBox(height: 18),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (i, l) in levels.indexed)
              Container(
                width: 86,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: l.bg, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${placed.where((r) => r.reader.level == i).length}', style: display(24, color: l.fg)),
                  Text(l.name, style: body(12, weight: FontWeight.w700, color: l.fg)),
                ]),
              ),
          ]),
          const SizedBox(height: 24),
          _SkillsPanel(rep),
          const SizedBox(height: 24),
          if (rep.readers.isEmpty)
            Text('No readers yet.', style: _p(15))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: _p(13, color: kIndigoText, weight: FontWeight.w800),
                dataTextStyle: _p(14, color: kIndigoText),
                columns: [
                  for (final t in ['Reader', 'Color', 'Stories', 'Average', 'Recent scores', 'Needs work on', 'Status', if (classroom) ''])
                    DataColumn(label: Text(t)),
                ],
                rows: [
                  for (final r in rep.readers)
                    DataRow(cells: [
                      DataCell(Text(r.reader.name, style: _p(14, color: kIndigoText, weight: FontWeight.w700))),
                      DataCell(DropdownButton<int>(
                        value: r.reader.level,
                        underline: const SizedBox.shrink(),
                        items: [for (final i in levels.indexed.map((e) => e.$1)) DropdownMenuItem(value: i, child: LevelChip(i))],
                        onChanged: (v) async {
                          if (v == null) return;
                          await c.setReaderLevel(r.reader.id, v);
                          _refresh();
                        },
                      )),
                      DataCell(Text('${r.stories}')),
                      DataCell(Text(r.avg == null ? '' : '${r.avg}%')),
                      DataCell(_ScoreBars(r.recent)),
                      DataCell(Text(r.needs == null ? 'Nothing yet' : '${r.needs!.skill} (${r.needs!.right} of ${r.needs!.total})')),
                      DataCell(Text(_status(r))),
                      if (classroom)
                        DataCell(IconButton(
                          tooltip: 'Delete ${r.reader.name}',
                          icon: const Icon(Icons.delete_outline_rounded, color: kSoft),
                          onPressed: () => _delete(r.reader),
                        )),
                    ]),
                ],
              ),
            ),
        ]);
      },
    );
  }

  Future<void> _delete(Reader r) async {
    final c = context.read<ReadingController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${r.name}?', style: _h(22)),
        content: Text('Their scores are deleted too. This cannot be undone.', style: _p(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await c.deleteReader(r.id);
    _refresh();
  }

  String _status(ReaderReport r) {
    if (!r.reader.placed) return 'Reading check not done';
    if (r.down >= 1 && r.reader.level > 0) return 'Needs help: last score under 60%';
    if (r.up == 2 && r.reader.level < levels.length - 1) return 'One strong score from moving up';
    if (r.stories == 0) return 'Has not read yet';
    return 'On track';
  }
}

class _SkillsPanel extends StatelessWidget {
  const _SkillsPanel(this.rep);
  final ClassReport rep;

  @override
  Widget build(BuildContext context) {
    final focus = rep.focus;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Reading skills', style: _h(24)),
      const SizedBox(height: 4),
      Text(
          focus != null
              ? 'Teach next: ${focus.skill}. The class got ${focus.right} of ${focus.total} right.'
              : 'No weak skill yet. This fills in as readers answer questions.',
          style: _p(15, color: kIndigoText)),
      const SizedBox(height: 12),
      for (final k in skills)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
              width: 210,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(focus?.skill == k ? '$k  ·  Teach next' : k,
                    style: _p(14, color: focus?.skill == k ? kBad : kIndigoText, weight: FontWeight.w800)),
                Text(_skillHint[k]!, style: _p(12)),
              ]),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: rep.skills[k]!.$2 == 0 ? 0 : rep.skills[k]!.$1 / rep.skills[k]!.$2,
                  backgroundColor: kPaper,
                  color: focus?.skill == k ? kBad : kIndigoText,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: Text(
                rep.skills[k]!.$2 == 0
                    ? 'No answers yet'
                    : '${(rep.skills[k]!.$1 * 100 / rep.skills[k]!.$2).round()}% right (${rep.skills[k]!.$1} of ${rep.skills[k]!.$2})',
                style: _p(13, color: kIndigoText),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// Oldest to newest, left to right; the last score is printed.
class _ScoreBars extends StatelessWidget {
  const _ScoreBars(this.recent);
  final List<Score> recent;

  @override
  Widget build(BuildContext context) {
    if (recent.isEmpty) return Text('None yet', style: _p(13));
    final list = recent.reversed.toList();
    return Semantics(
      label: 'Recent scores: ${list.map((a) => '${a.pct}%').join(', ')}',
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final a in list)
          Tooltip(
            message: '${a.pct}% at ${levels[a.level].name}',
            child: Container(
              width: 8,
              height: 4 + 22 * a.pct / 100,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(color: a.pct < 60 ? kBad : kIndigoText, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        const SizedBox(width: 6),
        Text('${list.last.pct}%', style: _p(13, color: kIndigoText, weight: FontWeight.w700)),
      ]),
    );
  }
}
