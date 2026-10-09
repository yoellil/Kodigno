import 'package:flutter/material.dart';

import '../data/repository.dart';
import 'anim.dart';
import 'chat_screen.dart';
import 'flashcards_screen.dart';
import 'motion.dart';
import 'quiz_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class SetDetailScreen extends StatelessWidget {
  const SetDetailScreen({super.key, required this.repo, required this.setId});
  final StudyRepository repo;
  final int setId;

  @override
  Widget build(BuildContext context) => PanelPage(
        child: FutureBuilder<StudySetDetail>(
          future: repo.getSet(setId),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final d = snap.data!;
            void push(Widget w) =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
            final hasQuiz = d.questions.isNotEmpty;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(padding: const EdgeInsets.all(28), shrinkWrap: true, children: [
                  const Align(alignment: Alignment.centerRight, child: CloseX()),
                  Align(alignment: Alignment.centerLeft, child: SourceTag(d.set.sourceType))
                      .enter(context),
                  const SizedBox(height: 12),
                  Text(d.set.title, style: display(42)).enter(context, index: 1),
                  const SizedBox(height: 26),
                  Row(children: [
                    Expanded(
                      child: _Tile(Icons.sticky_note_2_outlined, K.yellow, 'Notes',
                          '${_sections(d.set.sourceText)} sections',
                          onTap: () => push(NotesScreen(title: d.set.title, text: d.set.sourceText)))
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
        ),
      );
}

int _sections(String text) => text.split('\n').where((l) => l.trim().isNotEmpty).length;

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

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key, required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => PanelPage(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 12, 0),
            child: Row(children: [
              Expanded(child: Text(title, style: display(28))),
              const CloseX(),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: SelectableText(text.isEmpty ? 'No notes saved for this set.' : text,
                  style: body(16)),
            ).enter(context),
          ),
        ]),
      );
}
