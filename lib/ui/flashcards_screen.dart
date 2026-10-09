import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../domain/models.dart';
import 'flash_deck.dart';
import 'theme.dart';
import 'widgets.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key, required this.repo, required this.setId});
  final StudyRepository repo;
  final int setId;

  @override
  Widget build(BuildContext context) => PanelPage(
        child: FutureBuilder<StudySetDetail>(
          future: repo.getSet(setId),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final rows = snap.data!.flashcards;
            if (rows.isEmpty) return const Center(child: Text('No flashcards in this set.'));
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: Text('Flashcards', style: display(28))),
                      const CloseX(),
                    ]),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FlashDeck(
                        cards: [for (final r in rows) Flashcard(front: r.front, back: r.back)],
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      );
}
