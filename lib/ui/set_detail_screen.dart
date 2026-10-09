import 'package:flutter/material.dart';

import '../data/repository.dart';
import 'anim.dart';
import 'chat_screen.dart';
import 'flashcards_screen.dart';
import 'motion.dart';
import 'quiz_screen.dart';
import 'summary_screen.dart';
import 'theme.dart';
import 'waves.dart';
import 'widgets.dart';

class SetDetailScreen extends StatelessWidget {
  const SetDetailScreen({super.key, required this.repo, required this.setId});
  final StudyRepository repo;
  final int setId;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          const Positioned.fill(child: WavyBackground()),
          SafeArea(child: FutureBuilder<StudySetDetail>(
          future: repo.getSet(setId),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final d = snap.data!;
            void push(Widget w) =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
            final hasQuiz = d.questions.isNotEmpty;
            // Left-aligned, so the waves have the right side to themselves.
            return Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(padding: const EdgeInsets.fromLTRB(56, 28, 28, 28), shrinkWrap: true, children: [
                  Row(children: [
                    SourceTag(d.set.sourceType).enter(context),
                    const Spacer(),
                    const CloseX(),
                  ]),
                  const SizedBox(height: 12),
                  Text(d.set.title, style: display(42)).enter(context, index: 1),
                  const SizedBox(height: 26),
                  Row(children: [
                    Expanded(
                      child: _Tile(Icons.auto_stories_outlined, K.yellow, 'Summary', 'Key lesson',
                          onTap: d.set.sourceText.trim().isEmpty
                              ? null
                              : () => push(SummaryScreen(
                                  repo: repo,
                                  setId: setId,
                                  title: d.set.title,
                                  notes: d.set.sourceText)))
                          .enter(context, index: 2),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Tile(Icons.style_outlined, K.pink, 'Flashcards',
                          '${d.flashcards.length} cards',
                          onTap: d.flashcards.isEmpty
                              ? null
                              : () => push(FlashcardsScreen(repo: repo, setId: setId)))
                          .enter(context, index: 3),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: _Tile(Icons.quiz_outlined, K.lavender, 'Quiz',
                          '${d.questions.length} questions',
                          onTap: hasQuiz ? () => push(QuizScreen(repo: repo, setId: setId)) : null)
                          .enter(context, index: 4),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Tile(Icons.chat_bubble_outline, K.mint, 'Ask AI', 'Explain this lesson',
                          onTap: d.set.sourceText.trim().isEmpty
                              ? null
                              : () => push(ChatScreen(title: d.set.title, notes: d.set.sourceText)))
                          .enter(context, index: 5),
                    ),
                  ]),
                  const SizedBox(height: 26),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PillButton(
                      label: 'Start studying',
                      icon: Icons.bolt,
                      onPressed: hasQuiz
                          ? () => push(QuizScreen(repo: repo, setId: setId))
                          : d.flashcards.isNotEmpty
                              ? () => push(FlashcardsScreen(repo: repo, setId: setId))
                              : null,
                    ),
                  ).enter(context, index: 6),
                ]),
              ),
            );
          },
        )),
        ]),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.color, this.title, this.subtitle, {this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap; // null = disabled

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Lift(
          onTap: onTap,
          radius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            KSticker(icon: icon, color: color, size: 52),
            const SizedBox(height: 16),
            Text(title, style: body(18, weight: FontWeight.w800)),
            Text(subtitle, style: body(13, color: K.muted)),
          ]),
        ),
      );
}
