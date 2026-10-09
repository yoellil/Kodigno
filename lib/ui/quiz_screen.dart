import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/repository.dart';
import '../domain/models.dart';
import '../quiz/quiz_session.dart';
import 'anim.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

typedef QuizFinished = void Function(
    int score, int total, int seconds, List<Map<String, Object>> results);

class QuizBody extends StatefulWidget {
  const QuizBody(
      {super.key, required this.title, required this.questions, required this.onFinished});
  final String title;
  final List<QuizQuestion> questions;
  final QuizFinished onFinished;

  @override
  State<QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends State<QuizBody> {
  late QuizSession _session = QuizSession(widget.questions);
  Stopwatch _watch = Stopwatch()..start();
  int? _selected;

  void _next() {
    final choice = _selected;
    if (choice == null) return;
    setState(() {
      _session.answer(choice);
      _selected = null;
    });
    if (_session.isDone) {
      _watch.stop();
      widget.onFinished(_session.score, widget.questions.length, _watch.elapsed.inSeconds,
          _session.results);
    }
  }

  void _restart() => setState(() {
        _session = QuizSession(widget.questions);
        _watch = Stopwatch()..start();
        _selected = null;
      });

  @override
  Widget build(BuildContext context) {
    if (_session.isDone) {
      return ResultsView(
        questions: widget.questions,
        results: _session.results,
        score: _session.score,
        onRetry: _restart,
      );
    }
    final total = widget.questions.length;
    final q = _session.current;
    final last = _session.index == total - 1;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(padding: const EdgeInsets.all(28), children: [
          Row(children: [
            const CloseX(),
            const SizedBox(width: 8),
            Expanded(child: KProgress(value: _session.index / total)),
            const SizedBox(width: 12),
            Text('${_session.index + 1} / $total', style: body(15, weight: FontWeight.w700)),
          ]),
          const SizedBox(height: 18),
          Center(
            child: Text('${widget.title} · quiz'.toUpperCase(),
                style: body(11, weight: FontWeight.w700, color: K.muted)),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: reduceMotion(context) ? Duration.zero : Motion.medium,
            switchInCurve: Motion.curve,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(_session.index),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuestionCard(prompt: q.prompt),
                const SizedBox(height: 14),
                for (var i = 0; i < q.choices.length; i++)
                  _OptionTile(
                    letter: String.fromCharCode(65 + i),
                    text: q.choices[i],
                    selected: _selected == i,
                    onTap: () => setState(() => _selected = i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: PillButton(
              label: last ? 'Finish' : 'Next',
              dark: true,
              onPressed: _selected == null ? null : _next,
            ),
          ),
        ]),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.prompt});
  final String prompt;

  @override
  Widget build(BuildContext context) {
    Widget bubble = const KSticker(icon: Icons.question_mark, color: Colors.white, size: 48, tilt: 0.12);
    if (!reduceMotion(context)) {
      bubble = bubble.animate().shake(hz: 3, rotation: 0.18, duration: 700.ms, curve: Curves.easeOut);
    }
    return Panel(
      color: K.lavender,
      padding: const EdgeInsets.all(24),
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.only(right: 60),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('question', style: body(13, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(prompt, style: display(30)),
          ]),
        ),
        Positioned(right: 0, bottom: 0, child: bubble),
      ]),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile(
      {required this.letter, required this.text, required this.selected, required this.onTap});
  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = reduceMotion(context) ? Duration.zero : Motion.fast;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Lift(
        color: selected ? K.yellow : K.tile,
        radius: 18,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(children: [
          AnimatedContainer(
            duration: d,
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: selected ? K.ink : Colors.white,
                borderRadius: BorderRadius.circular(10)),
            child: Text(letter,
                style: body(14, weight: FontWeight.w800, color: selected ? Colors.white : K.ink)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: body(16, weight: FontWeight.w600))),
          AnimatedScale(
            scale: selected ? 1 : 0,
            duration: d,
            curve: Motion.pop,
            child: const Icon(Icons.check, size: 22),
          ),
        ]),
      ),
    );
  }
}

class ResultsView extends StatelessWidget {
  const ResultsView(
      {super.key,
      required this.questions,
      required this.results,
      required this.score,
      required this.onRetry});
  final List<QuizQuestion> questions;
  final List<Map<String, Object>> results;
  final int score;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final total = questions.length;
    final pct = total == 0 ? 0 : (score * 100 / total).round();
    final missed = [
      for (var i = 0; i < total; i++)
        if (results[i]['correct'] == false) questions[i]
    ];
    return Stack(children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(padding: const EdgeInsets.all(28), children: [
            const Align(alignment: Alignment.centerRight, child: CloseX()),
            Text('quiz complete', style: body(14, color: K.muted)).enter(context),
            CountUp(value: pct, suffix: '%', style: display(120)),
            const SizedBox(height: 6),
            Text('$score of $total correct', style: body(18, weight: FontWeight.w700))
                .enter(context, index: 2),
            const SizedBox(height: 20),
            Row(children: [
              _Stat(score, 'nailed it', K.lavender, K.ink).enter(context, index: 3),
              const SizedBox(width: 16),
              _Stat(missed.length, 'to review', K.blue, Colors.white).enter(context, index: 4),
            ]),
            if (missed.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('review these', style: body(14, color: K.muted)),
              const SizedBox(height: 8),
              for (var i = 0; i < missed.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration:
                      BoxDecoration(color: K.tile, borderRadius: BorderRadius.circular(18)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(missed[i].prompt, style: body(16, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Answer: ${missed[i].choices[missed[i].answerIndex]}', style: body(14)),
                    if (missed[i].explanation.isNotEmpty)
                      Text(missed[i].explanation, style: body(13, color: K.muted)),
                  ]),
                ).enter(context, index: 5 + i),
            ],
            const SizedBox(height: 20),
            Row(children: [
              PillButton(label: 'Try again', onPressed: onRetry),
              const SizedBox(width: 12),
              PillButton(
                  label: 'Done', dark: true, onPressed: () => Navigator.of(context).maybePop()),
            ]),
          ]),
        ),
      ),
      if (pct >= 70) const Positioned.fill(child: Confetti()),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.n, this.label, this.bg, this.fg);
  final int n;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Text('$n', style: display(40, color: fg)),
        ),
        const SizedBox(height: 6),
        Text(label, style: body(12, color: K.muted)),
      ]);
}

/// Loads a saved set, runs the quiz, saves the attempt.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.repo, required this.setId});
  final StudyRepository repo;
  final int setId;

  @override
  Widget build(BuildContext context) => PanelPage(
        child: FutureBuilder(
          future: repo.getSet(setId),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final d = snap.data!;
            final questions = [
              for (final r in d.questions)
                QuizQuestion(
                  prompt: r.prompt,
                  choices: List<String>.from(jsonDecode(r.choices) as List),
                  answerIndex: r.answerIndex,
                  explanation: r.explanation,
                )
            ];
            if (questions.isEmpty) {
              return const Center(child: Text('This set has no quiz questions.'));
            }
            return QuizBody(
              title: d.set.title,
              questions: questions,
              onFinished: (score, total, seconds, results) => repo.saveAttempt(
                  setId: setId,
                  score: score,
                  total: total,
                  durationSeconds: seconds,
                  results: results),
            );
          },
        ),
      );
}
