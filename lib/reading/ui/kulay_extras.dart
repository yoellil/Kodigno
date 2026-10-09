// My Words (saved word help, with practice) and the teacher's "add your own story" form.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database.dart';
import '../../ui/theme.dart';
import '../levels.dart';
import '../reading_controller.dart';
import '../reading_repository.dart' show ReadingRepository;
import 'story_view.dart';

TextStyle _h(double size) => display(size, color: kIndigoText);
TextStyle _p(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w500,
}) => body(size, color: color ?? kSoft, weight: weight);

// ---------- streak, speed, reading look ----------

/// The story the reader asked for and set aside: still writing, ready, or failed.
class WaitingStory extends StatelessWidget {
  const WaitingStory({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReadingController>();
    final topic = c.waitingTopic;
    if (topic == null) return const SizedBox.shrink();
    final (text, button) = switch (c.waitingState) {
      Waiting.ready => ('Your "$topic" story is ready.', 'Read it'),
      Waiting.writing => ('Your "$topic" story is still being written.', 'Wait for it'),
      Waiting.failed => ('Your "$topic" story could not be written. Try again, or pick another topic.', 'Try again'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.waitingState == Waiting.ready ? kGood.withValues(alpha: 0.12) : kPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.waitingState == Waiting.ready ? kGood : kLine),
      ),
      child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(text, style: _p(15, color: kIndigoText, weight: FontWeight.w700)),
        KButton(button, small: true, onTap: c.readWaiting),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: kSoft),
          onPressed: c.dismissWaiting,
          child: const Text('Dismiss'),
        ),
      ]),
    );
  }
}

/// Days in a row with a finished story.
class StreakNote extends StatelessWidget {
  const StreakNote(this.streak, {super.key});
  final ({int days, bool today}) streak;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEE8A3A)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${streak.days} ${streak.days == 1 ? 'day' : 'days'} in a row.${streak.today ? '' : ' Read a story today to keep it going.'}',
            style: _p(15, color: kIndigoText, weight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

/// Words a minute over the last stories the reader timed, oldest to newest.
class SpeedChart extends StatelessWidget {
  const SpeedChart(this.wpm, {super.key});
  final List<int> wpm;

  @override
  Widget build(BuildContext context) {
    final top = wpm.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in wpm)
            Container(
              width: 14,
              height: 6 + 38 * v / top,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: kIndigoText.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(4)),
            ),
          const SizedBox(width: 8),
          Flexible(child: Text('Reading speed: ${wpm.last} words a minute${wpm.last > wpm.first ? ', up from ${wpm.first}' : ''}.', style: _p(14))),
        ],
      ),
    );
  }
}

/// Text size and the easy-read font, for the reading page.
Future<void> showReadingLook(BuildContext context) => showDialog<void>(
  context: context,
  builder: (ctx) => Consumer<ReadingController>(
    builder: (ctx, c, _) => AlertDialog(
      title: Text('Make reading easier', style: _h(22)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Text size', style: _p(14, color: kIndigoText, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Normal')),
              ButtonSegment(value: 1, label: Text('Large')),
              ButtonSegment(value: 2, label: Text('Extra large')),
            ],
            selected: {c.textSize},
            onSelectionChanged: (v) => c.setLook(size: v.first),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Easy-read letters', style: _p(15, color: kIndigoText, weight: FontWeight.w600)),
            subtitle: Text('Wider, plainer letters with more space between them.', style: readFont(_p(13), c.easyFont)),
            value: c.easyFont,
            onChanged: (v) => c.setLook(easy: v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Dark mode', style: _p(15, color: kIndigoText, weight: FontWeight.w600)),
            subtitle: Text('Light letters on a dark page. Easier on the eyes at night.', style: _p(13)),
            value: c.darkMode,
            onChanged: (v) => c.setLook(dark: v),
          ),
        ],
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
    ),
  ),
);

// ---------- my words ----------

class WordsPage extends StatefulWidget {
  const WordsPage({super.key});
  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  late Future<List<SavedWord>> _words = context
      .read<ReadingController>()
      .myWords();
  List<SavedWord>? _queue; // words being practiced
  var _at = 0;
  var _shown = false;

  static const _learned = 3; // right answers in a row
  static const _perRound = 8;

  Future<void> _answer(SavedWord w, bool right) async {
    final c = context.read<ReadingController>();
    await c.markWord(w.id, right: right);
    if (!mounted) return;
    setState(() {
      _shown = false;
      if (++_at >= _queue!.length) {
        _queue = null;
        _words = c.myWords();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SavedWord>>(
      future: _words,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final all = snap.data!;
        final learning = all.where((w) => w.known < _learned).toList();
        final q = _queue;
        if (q != null) return _practice(q[_at], _at, q.length);
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          children: [
            Text('My words', style: _h(32)),
            const SizedBox(height: 4),
            Text(
              all.isEmpty
                  ? 'Tap any word in a story to see what it means. It is saved here so you can practice it.'
                  : '${learning.length} to learn, ${all.length - learning.length} learned. A word is learned after 3 "I knew it" in a row.',
              style: _p(15),
            ),
            if (learning.isNotEmpty) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: KButton(
                  'Practice ${learning.length > _perRound ? _perRound : learning.length} words',
                  onTap: () => setState(() {
                    _queue = learning.take(_perRound).toList();
                    _at = 0;
                    _shown = false;
                  }),
                ),
              ),
            ],
            const SizedBox(height: 18),
            for (final w in all)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kPaper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          w.word,
                          style: _p(
                            18,
                            color: kIndigoText,
                            weight: FontWeight.w800,
                          ),
                        ),
                        if (w.known >= _learned) ...[
                          const SizedBox(width: 10),
                          Text(
                            'Learned',
                            style: _p(
                              13,
                              color: kGood,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(w.meaning, style: _p(15, color: kIndigoText)),
                    const SizedBox(height: 4),
                    Text(w.sentence, style: _p(13)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _practice(SavedWord w, int i, int n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      children: [
        Text('Word ${i + 1} of $n', style: _p(14)),
        const SizedBox(height: 14),
        Text(w.word, style: display(44, color: kIndigoText)),
        const SizedBox(height: 10),
        Text(w.sentence, style: _p(18, color: kIndigoText)),
        const SizedBox(height: 22),
        if (!_shown)
          Align(
            alignment: Alignment.centerLeft,
            child: KButton(
              'Show the meaning',
              onTap: () => setState(() => _shown = true),
            ),
          )
        else ...[
          Text(
            w.meaning,
            style: _p(20, color: kIndigoText, weight: FontWeight.w600),
          ),
          if (w.synonym != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Like "${w.synonym}".', style: _p(15)),
            ),
          const SizedBox(height: 20),
          Text('Did you know it?', style: _p(15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              KButton('I knew it', onTap: () => _answer(w, true)),
              KButton('Not yet', ghost: true, onTap: () => _answer(w, false)),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------- teacher: add your own story ----------

class TeacherStories extends StatefulWidget {
  const TeacherStories({super.key});
  @override
  State<TeacherStories> createState() => _TeacherStoriesState();
}

class _TeacherStoriesState extends State<TeacherStories> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  int? _level; // null = pick the color from the text
  int? _forReader; // null = everyone at that color
  String? _message;
  var _error = false;
  late Future<List<StoryRow>> _mine = context
      .read<ReadingController>()
      .repo
      .allTeacherStories();

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final c = context.read<ReadingController>();
    setState(() => _message = null);
    final err = await c.addTeacherStory(_title.text, _text.text, _level, forReader: _forReader);
    if (!mounted) return;
    setState(() {
      _error = err != null;
      _message = err ?? 'Saved. Readers at that color will see it on their page under "From your teacher".';
      if (err == null) {
        _title.clear();
        _text.clear();
      }
      _mine = c.repo.allTeacherStories();
    });
  }

  Future<void> _delete(StoryRow s) async {
    final c = context.read<ReadingController>();
    final gone = await c.repo.deleteTeacherStory(s.id);
    if (!mounted) return;
    setState(() {
      _error = !gone;
      _message = gone
          ? null
          : 'A reader already has a score on this story, so it stays.';
      _mine = c.repo.allTeacherStories();
    });
  }

  /// ", for Ana" when the story was made for one reader.
  static String _forName(StoryRow s, List<Reader> readers) {
    final id = ReadingRepository.assignedTo(s.checks);
    if (id == null) return '';
    final who = readers.where((r) => r.id == id).firstOrNull;
    return ', for ${who?.name ?? 'a reader who was removed'}';
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<ReadingController, bool>((c) => c.teacherBusy);
    final readers = context.select<ReadingController, List<Reader>>((c) => c.readers);
    final forReader = readers.any((r) => r.id == _forReader) ? _forReader : null;
    return Material(
      type: MaterialType.transparency, // ExpansionTile paints on the nearest Material, not the page's decoration
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text('Add your own story', style: _h(22)),
          subtitle: Text(
            'Paste a text. The AI writes and checks the questions. Your words stay as you wrote them.',
            style: _p(14),
          ),
          children: [
            const SizedBox(height: 10),
            SizedBox(
              width: 420,
              child: TextField(
                controller: _title,
                maxLength: 60,
                style: _p(15, color: kIndigoText),
                decoration: InputDecoration(
                  hintText: 'Title',
                  counterText: '',
                  fillColor: kPaper,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _text,
              minLines: 6,
              maxLines: 14,
              style: _p(15, color: kIndigoText),
              decoration: InputDecoration(
                hintText: 'Paste the story here (4 or more sentences, under 700 words)',
                fillColor: kPaper,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<int?>(
                  value: _level,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        'Pick the color for me',
                        style: _p(14, color: kIndigoText),
                      ),
                    ),
                    for (final (i, l) in levels.indexed)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${l.name}, Grades ${l.grades}',
                          style: _p(14, color: kIndigoText),
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _level = v),
                ),
                DropdownButton<int?>(
                  value: forReader,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: null, child: Text('For everyone at that color', style: _p(14, color: kIndigoText))),
                    for (final r in readers) DropdownMenuItem(value: r.id, child: Text('Only for ${r.name}', style: _p(14, color: kIndigoText))),
                  ],
                  onChanged: (v) => setState(() => _forReader = v),
                ),
                KButton(
                  busy ? 'Writing questions...' : 'Make the questions',
                  onTap: busy ? null : _add,
                ),
              ],
            ),
            if (busy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
              const SizedBox(height: 6),
              Text(
                'The AI is writing questions and checking each one. This can take a minute or two.',
                style: _p(13),
              ),
            ],
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _message!,
                  style: _p(
                    14,
                    color: _error ? kBad : kGood,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            FutureBuilder<List<StoryRow>>(
              future: _mine,
              builder: (context, snap) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in snap.data ?? const <StoryRow>[])
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: _p(
                                  15,
                                  color: kIndigoText,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${levels[s.level].name}, Grades ${levels[s.level].grades}${_forName(s, readers)}',
                                style: _p(13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete ${s.title}',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: kSoft,
                          ),
                          onPressed: () => _delete(s),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
