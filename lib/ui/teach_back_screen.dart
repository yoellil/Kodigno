import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../data/database.dart' show StudySet, TeachBackAttempt;
import '../data/repository.dart';
import '../data/teach_back_repository.dart';
import '../domain/source_ref.dart';
import '../domain/summary.dart';
import '../study/teach_back.dart';
import '../study/teach_judge.dart';
import 'motion.dart';
import 'slide_tag.dart';
import 'summary_screen.dart';
import 'theme.dart';
import 'widgets.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _when(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// The app's AI model, for the screens that check an explanation; null if there is
/// none above [context] (then the check compares words only).
TeachBackModel? teachModelOf(BuildContext context) {
  try {
    return context.read<AppController>();
  } catch (_) {
    return null;
  }
}

/// Everything a screen needs to check one topic of a set's lesson.
class _Topic {
  _Topic(this.set, this.lesson, this.index, this.pages)
      : section = lesson.sections[index],
        ideas = ideasOf(lesson.sections[index], lesson, pages),
        source = sourceTextOf(lesson.sections[index], lesson, pages),
        topicPages = [
          for (final p in pages)
            if (pagesOfTopic(lesson.sections[index], lesson, pages).contains(p.number)) p,
        ];
  final StudySet set;

  /// The pages under this topic's heading, to place the model's key ideas on a slide.
  final List<PageText> topicPages;
  final LessonSummary lesson;
  final int index;
  final List<PageText> pages;
  final SummarySection section;
  final List<Idea> ideas;
  final String source;
}

/// Loads the lesson of [setId] and its pages, or null if the set has no lesson
/// yet or [index] is not one of its topics.
Future<_Topic?> _loadTopic(StudyRepository repo, int setId, int index) async {
  final d = await repo.getSet(setId);
  final lesson = d.summary;
  if (lesson == null || index < 0 || index >= lesson.sections.length) return null;
  return _Topic(d.set, lesson, index, parsePages(d.set.sourceText));
}

/// A small label that says this is not finished: the check compares words, so it
/// can miss an idea that was explained differently.
class _Beta extends StatelessWidget {
  const _Beta();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: K.yellow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: K.ink, width: 1.2),
        ),
        child: Text('BETA', style: body(10, weight: FontWeight.w800, color: K.ink)),
      );
}

/// The student explains one topic of the lesson in their own words, and the slides
/// say what was covered. The slides' own words stay hidden until the check.
class TeachBackScreen extends StatefulWidget {
  const TeachBackScreen(
      {super.key, required this.repo, required this.setId, required this.sectionIndex, this.model});
  final StudyRepository repo;
  final int setId;

  /// The AI model that writes the key ideas and, if it is big enough, judges the
  /// explanation. Without it the check compares words only.
  final TeachBackModel? model;

  /// Which topic of the lesson, counting from 0.
  final int sectionIndex;

  @override
  State<TeachBackScreen> createState() => _TeachBackScreenState();
}

class _TeachBackScreenState extends State<TeachBackScreen> {
  final _text = TextEditingController();
  late final _store = TeachBackRepository(widget.repo.db);
  _Topic? _topic;
  bool _loading = true;
  TeachBackResult? _result;
  int? _attemptId;
  final _overruled = <int>{};
  List<TeachBackAttempt> _history = const [];
  String? _error;
  bool _checking = false;

  /// Who did the checking, in words, for the foot of the result.
  String _note = '';

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final t = await _loadTopic(widget.repo, widget.setId, widget.sectionIndex);
      final history = t == null ? const <TeachBackAttempt>[] : await _store.attemptsFor(widget.setId, t.section.heading);
      if (!mounted) return;
      setState(() {
        _topic = t;
        _history = history;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't open this topic. Close this and try again.";
        _loading = false;
      });
    }
  }

  bool get _longEnough => wordCount(_text.text) >= minExplanationWords;

  /// The key ideas the model wrote for this topic (kept, so they are the same on
  /// every try), or null if there are none: no model, or it could not write them.
  Future<List<String>?> _concepts(_Topic t) async {
    final m = widget.model;
    if (m == null || !m.available) return null;
    final kept = await _store.conceptsFor(widget.setId, t.section.heading);
    if (kept != null) return kept;
    final made = await m.concepts(t.source, topic: t.section.heading);
    if (made.length < 2) return null;
    try {
      await _store.saveConcepts(widget.setId, t.section.heading, made);
    } catch (_) {
      // not kept: they are written again next time
    }
    return made;
  }

  Future<TeachBackResult> _run(_Topic t, String answer) async {
    final m = widget.model;
    final concepts = await _concepts(t);
    if (concepts == null) {
      _note = m == null || !m.available
          ? 'Checked by comparing words only. The AI model is not installed.'
          : 'Checked by comparing words only. The AI model could not write the key ideas this time.';
      return checkTeachBack(answer: answer, ideas: t.ideas, sourceText: t.source, terms: t.section.terms);
    }
    final locator = t.topicPages.isEmpty ? null : SourceLocator(t.topicPages);
    final ideas = [
      for (final c in concepts)
        Idea(c, source: () {
          final ref = locator?.locate(c);
          return ref == null || ref.kind == SourceKind.unmatched ? null : ref;
        }()),
    ];
    final words = checkTeachBack(answer: answer, ideas: ideas, sourceText: t.source, terms: t.section.terms);
    if (m == null || !m.canJudge) {
      _note = 'The AI model wrote the key ideas, but it is too small to judge your explanation, so they were '
          'checked by comparing words. A Standard or High model checks the meaning too.';
      return words;
    }
    final judged = await m.judge(concepts: concepts, answer: answer, slideText: t.source);
    if (judged == null) {
      _note = 'Checked by comparing words only. The AI model could not judge your explanation this time.';
      return words;
    }
    _note = 'Checked by the AI model, which read your slides and your explanation, and by comparing words.';
    return combineWithModel(words, judged);
  }

  Future<void> _check() async {
    final t = _topic;
    if (t == null || !_longEnough || _checking) return;
    final answer = _text.text.trim();
    setState(() => _checking = true);
    TeachBackResult result;
    try {
      result = await _run(t, answer);
    } catch (_) {
      _note = 'Checked by comparing words only.';
      result = checkTeachBack(answer: answer, ideas: t.ideas, sourceText: t.source, terms: t.section.terms);
    }
    int? id;
    try {
      id = await _store.save(
          setId: widget.setId,
          section: t.section.heading,
          sectionIndex: t.index,
          answer: answer,
          result: result);
    } catch (_) {
      id = null; // the check still shows; it just is not kept
    }
    final history = await _store.attemptsFor(widget.setId, t.section.heading);
    if (!mounted) return;
    setState(() {
      _result = result;
      _attemptId = id;
      _overruled.clear();
      _history = history;
      _checking = false;
    });
  }

  Future<void> _overrule(int i) async {
    setState(() => _overruled.add(i));
    final id = _attemptId;
    if (id == null) return;
    await _store.overrule(id, i);
    final t = _topic;
    if (t == null) return;
    final history = await _store.attemptsFor(widget.setId, t.section.heading);
    if (mounted) setState(() => _history = history);
  }

  @override
  Widget build(BuildContext context) => PanelPage(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _body(),
          ),
        ),
      );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final t = _topic;
    if (_error != null || t == null) {
      return _Notice(
        title: _error == null ? 'No lesson yet' : 'Something went wrong',
        text: _error ?? 'Make the summary for this set first, then you can explain its topics here.',
      );
    }
    if (t.ideas.isEmpty) {
      return const _Notice(
        title: 'Nothing to compare with',
        text: 'This topic has no slide text to check an explanation against.',
      );
    }
    return SourceScope.forSet(
      t.set,
      child: ListView(padding: const EdgeInsets.fromLTRB(28, 12, 28, 28), children: [
        Row(children: [
          Text('Teach it back', style: display(24)),
          const SizedBox(width: 10),
          const _Beta(),
          const Spacer(),
          const CloseX(),
        ]),
        const SizedBox(height: 8),
        Text(t.section.heading, style: display(20)),
        const SizedBox(height: 16),
        if (_checking)
          ..._thinking()
        else if (_result == null)
          ..._writing(t)
        else
          ..._feedback(t, _result!),
        if (_history.isNotEmpty) ..._earlier(),
      ]),
    );
  }

  List<Widget> _thinking() => [
        const SizedBox(height: 40),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 18),
        Text('Reading your explanation...', textAlign: TextAlign.center, style: display(20)),
        const SizedBox(height: 6),
        Text('The AI model is comparing it with your slides. This can take a few seconds.',
            textAlign: TextAlign.center, style: body(13, color: K.muted)),
      ];

  List<Widget> _writing(_Topic t) {
    final words = wordCount(_text.text);
    return [
      Text('Explain this topic in your own words, as if to a classmate who missed class. Two to four sentences is plenty.',
          style: body(15)),
      const SizedBox(height: 6),
      Text("Your slides stay hidden until you check, so try it from memory.", style: body(12, color: K.muted)),
      const SizedBox(height: 14),
      TextField(
        controller: _text,
        minLines: 6,
        maxLines: 12,
        style: body(15),
        decoration: InputDecoration(
          hintText: 'Type your explanation here...',
          filled: true,
          fillColor: K.tile,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        words < minExplanationWords
            ? '$words ${words == 1 ? 'word' : 'words'}. Write a little more first (at least $minExplanationWords).'
            : '$words words',
        style: body(12, color: K.muted),
      ),
      const SizedBox(height: 14),
      Align(
        alignment: Alignment.centerLeft,
        child: PillButton(label: 'Check my explanation', icon: Icons.fact_check_outlined, onPressed: _longEnough ? _check : null),
      ),
    ];
  }

  List<Widget> _feedback(_Topic t, TeachBackResult r) {
    final counted = (r.covered + _overruled.length).clamp(0, r.total);
    return [
      Panel(
        color: r.copied ? K.pink : K.yellow,
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.headline, style: display(22)),
            if (_overruled.isNotEmpty && !r.copied) ...[
              const SizedBox(height: 6),
              Text('With the ${_overruled.length} you said you covered: $counted of ${r.total}.', style: body(13, weight: FontWeight.w700)),
            ],
          ]),
        ),
      ).enter(context),
      const SizedBox(height: 16),
      Text('THE IDEAS IN YOUR SLIDES', style: body(11, weight: FontWeight.w800, color: K.muted)),
      const SizedBox(height: 8),
      for (var i = 0; i < r.ideas.length; i++)
        _IdeaTile(
          result: r.ideas[i],
          overruled: _overruled.contains(i),
          onOverrule: () => _overrule(i),
        ),
      if (r.flags.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text('WORTH A SECOND LOOK', style: body(11, weight: FontWeight.w800, color: K.muted)),
        const SizedBox(height: 8),
        for (final f in r.flags)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: K.pink, borderRadius: BorderRadius.circular(16)),
            child: inkOnPastel(
              K.pink,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('"${f.sentence}"', style: body(12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(f.message, style: body(13, weight: FontWeight.w700)),
              ]),
            ),
          ),
      ],
      if (r.missingTerms.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text('Words from your slides you did not use: ${r.missingTerms.join(', ')}.', style: body(13, color: K.muted)),
      ],
      const SizedBox(height: 14),
      if (_note.isNotEmpty) Text(_note, style: body(12, weight: FontWeight.w700, color: K.muted)),
      const SizedBox(height: 6),
      Text(
        r.checkedBy == CheckedBy.model
            ? 'The AI model can be wrong too. If it missed something you explained, tap "I covered this".'
            : 'This check compares words, so it can miss an idea you explained differently. If it did, tap "I covered this".',
        style: body(12, color: K.muted),
      ),
      const SizedBox(height: 14),
      Row(children: [
        PillButton(label: 'Try again', icon: Icons.refresh, onPressed: () => setState(() => _result = null)),
        const SizedBox(width: 12),
        PillButton(label: 'Done', dark: true, onPressed: () => Navigator.of(context).maybePop()),
      ]),
    ];
  }

  List<Widget> _earlier() => [
        const SizedBox(height: 26),
        Text('EARLIER TRIES AT THIS TOPIC', style: body(11, weight: FontWeight.w800, color: K.muted)),
        const SizedBox(height: 8),
        for (final a in _history.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Text(_when(a.takenAt), style: body(13, color: K.muted)),
              const SizedBox(width: 12),
              Text(
                a.copied ? 'Copied from the slides' : 'Covered ${a.coveredCounted} of ${a.total}'
                    '${a.partly > 0 ? ', ${a.partly} partly' : ''}',
                style: body(13, weight: FontWeight.w700),
              ),
            ]),
          ),
      ];
}

class _IdeaTile extends StatelessWidget {
  const _IdeaTile({required this.result, required this.overruled, required this.onOverrule});
  final IdeaResult result;
  final bool overruled;
  final VoidCallback onOverrule;

  @override
  Widget build(BuildContext context) {
    final c = overruled ? Coverage.covered : result.coverage;
    final (icon, label, color) = switch (c) {
      Coverage.covered => (Icons.check_circle, overruled ? 'You said you covered this' : 'Covered', K.mint),
      Coverage.partly => (Icons.timelapse, 'Partly there', K.yellow),
      Coverage.missing => (Icons.radio_button_unchecked, 'Not found', K.tile),
    };
    final source = result.idea.source;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: inkOnPastel(
        color,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label.toUpperCase(), style: body(10, weight: FontWeight.w800, color: K.ink.withValues(alpha: 0.6))),
          ]),
          const SizedBox(height: 6),
          Text(result.idea.text, style: body(14)),
          if (c != Coverage.missing && result.matched != null) ...[
            const SizedBox(height: 6),
            Text('You wrote: "${result.matched}"', style: body(12, color: Colors.black54)),
          ],
          if (c != Coverage.covered || source != null) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              if (source != null) SlideTag(source),
              if (c != Coverage.covered)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onOverrule,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('I covered this', style: body(12, weight: FontWeight.w800).copyWith(decoration: TextDecoration.underline)),
                  ),
                ),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Align(alignment: Alignment.centerRight, child: CloseX()),
          const Spacer(),
          Text(title, style: display(28), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(text, style: body(15, color: K.muted), textAlign: TextAlign.center),
          const Spacer(),
        ]),
      );
}

/// The topics of a set's lesson, each with how the last try went; pick one to
/// explain it back.
class TeachBackTopicsScreen extends StatefulWidget {
  const TeachBackTopicsScreen({super.key, required this.repo, required this.setId, this.model});
  final StudyRepository repo;
  final int setId;

  /// Passed on to each topic's screen.
  final TeachBackModel? model;

  @override
  State<TeachBackTopicsScreen> createState() => _TeachBackTopicsScreenState();
}

class _TeachBackTopicsScreenState extends State<TeachBackTopicsScreen> {
  late final _store = TeachBackRepository(widget.repo.db);
  StudySetDetail? _detail;
  Map<String, TeachBackAttempt> _latest = const {};
  Map<String, int> _tries = const {};
  List<int> _hasIdeas = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await widget.repo.getSet(widget.setId);
    final latest = await _store.latestBySection(widget.setId);
    final all = await widget.repo.db.select(widget.repo.db.teachBackAttempts).get();
    final tries = <String, int>{};
    for (final a in all) {
      if (a.studySetId == widget.setId) tries[a.section] = (tries[a.section] ?? 0) + 1;
    }
    final lesson = d.summary;
    final pages = parsePages(d.set.sourceText);
    if (!mounted) return;
    setState(() {
      _detail = d;
      _latest = latest;
      _tries = tries;
      _hasIdeas = [
        if (lesson != null)
          for (var i = 0; i < lesson.sections.length; i++)
            if (ideasOf(lesson.sections[i], lesson, pages).isNotEmpty) i,
      ];
    });
  }

  Future<void> _open(int i) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TeachBackScreen(repo: widget.repo, setId: widget.setId, sectionIndex: i, model: widget.model)));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return PanelPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: d == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.fromLTRB(28, 12, 28, 28), children: [
                  Row(children: [
                    Text('Teach it back', style: display(24)),
                    const SizedBox(width: 10),
                    const _Beta(),
                    const Spacer(),
                    const CloseX(),
                  ]),
                  const SizedBox(height: 6),
                  Text(d.set.title, style: body(14, color: K.muted)),
                  const SizedBox(height: 14),
                  Text('Pick a topic and explain it in your own words. Your slides check how much you covered.',
                      style: body(15)),
                  const SizedBox(height: 18),
                  if (d.summary == null) ...[
                    Text('This set has no lesson yet. Make the summary first, then come back.',
                        style: body(14, color: K.muted)),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PillButton(
                        label: 'Open summary',
                        icon: Icons.auto_stories_outlined,
                        onPressed: d.set.sourceText.trim().isEmpty
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => SummaryScreen(
                                    repo: widget.repo, setId: widget.setId, title: d.set.title, notes: d.set.sourceText))),
                      ),
                    ),
                  ] else
                    for (var i = 0; i < d.summary!.sections.length; i++) _topic(d.summary!.sections[i].heading, i),
                ]),
        ),
      ),
    );
  }

  Widget _topic(String heading, int i) {
    final last = _latest[heading];
    final usable = _hasIdeas.contains(i);
    final subtitle = !usable
        ? 'Nothing to compare with'
        : last == null
            ? 'Not tried yet'
            : 'Last try: ${last.copied ? 'copied from the slides' : 'covered ${last.coveredCounted} of ${last.total}'}'
                ' · ${_tries[heading]} ${_tries[heading] == 1 ? 'try' : 'tries'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: usable ? 1 : 0.5,
        child: Material(
          color: K.tile,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: usable ? () => _open(i) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(heading, style: body(15, weight: FontWeight.w800)),
            subtitle: Text(subtitle, style: body(12, color: K.muted)),
            trailing: usable ? const Icon(Icons.chevron_right) : null,
          ),
        ),
      ),
    );
  }
}
