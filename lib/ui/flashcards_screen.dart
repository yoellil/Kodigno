import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../data/repository.dart';
import '../domain/models.dart';
import 'card_editor.dart';
import 'flash_deck.dart';
import 'theme.dart';
import 'widgets.dart';

/// A set's flashcards: study them, correct any of them (AI-written or your own), and
/// add cards of your own, with the AI offering the missing side as you type.
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key, required this.repo, required this.setId, this.suggest});
  final StudyRepository repo;
  final int setId;

  /// Asks the AI for a card's missing side. Defaults to the app's local model.
  final CardSuggester? suggest;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  /// The set as last loaded. Held directly (not behind a FutureBuilder) so that a save
  /// replaces it in one step: a FutureBuilder keeps showing the old data while a new
  /// future loads, which would rebuild the deck on the old cards.
  StudySetDetail? _d;
  bool _loadFailed = false;

  /// Bumped when the deck should start over on a particular card (after adding one).
  int _deckRevision = 0;
  int _startAt = 0;

  @override
  void initState() {
    super.initState();
    widget.repo.getSet(widget.setId).then((d) {
      if (mounted) setState(() => _d = d);
    }, onError: (Object _) {
      if (mounted) setState(() => _loadFailed = true);
    });
  }

  CardSuggester _suggester(StudySetDetail d) =>
      widget.suggest ??
      (want, term, definition) => context.read<AppController>().suggestCard(
            want: want,
            term: term,
            definition: definition,
            notes: d.set.sourceText,
            setTitle: d.set.title,
          );

  Future<void> _add(StudySetDetail d) async {
    final added = await showAddCardDialog(
      context,
      suggest: _suggester(d),
      onSave: (term, definition) => widget.repo.addFlashcard(widget.setId, term, definition),
    );
    if (added != true || !mounted) return;
    final fresh = await widget.repo.getSet(widget.setId);
    if (!mounted) return;
    setState(() {
      _d = fresh;
      _startAt = fresh.flashcards.length - 1; // land on the card just added
      _deckRevision++;
    });
  }

  Future<void> _saveEdit(Flashcard card, String front, String back) async {
    await widget.repo.updateFlashcard(card.id!, front, back);
    final fresh = await widget.repo.getSet(widget.setId);
    if (mounted) setState(() => _d = fresh); // same deck, same card, new text
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    if (d == null) {
      return PanelPage(
        child: Center(
          child: _loadFailed
              ? Text("Couldn't open this set.", style: body(16, color: K.muted))
              : const CircularProgressIndicator(),
        ),
      );
    }
    final rows = [...d.flashcards]..sort((a, b) => a.id.compareTo(b.id));
    return PanelPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text('Flashcards', style: display(28))),
                PillButton(label: 'Add card', icon: Icons.add, onPressed: () => _add(d)),
                const SizedBox(width: 8),
                const CloseX(),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: rows.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('No flashcards in this set yet.', style: body(16, color: K.muted)),
                          const SizedBox(height: 14),
                          PillButton(
                              label: 'Write your first card',
                              icon: Icons.edit_outlined,
                              onPressed: () => _add(d)),
                        ]),
                      )
                    : FlashDeck(
                        key: ValueKey('deck-$_deckRevision'),
                        startAt: _startAt,
                        cards: [for (final r in rows) Flashcard(front: r.front, back: r.back, id: r.id)],
                        onSave: _saveEdit,
                        suggest: _suggester(d),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
