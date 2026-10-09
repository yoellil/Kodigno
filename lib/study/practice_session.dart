import 'package:flutter/foundation.dart';

import '../domain/source_ref.dart';
import 'confusions.dart';
import 'session_plan.dart';

/// One flashcard or quiz question, with everything needed to ask it.
class PracticeItem {
  const PracticeItem({
    required this.kind,
    required this.itemId,
    required this.setId,
    required this.setTitle,
    required this.prompt,
    required this.answer,
    this.choices = const [],
    this.answerIndex = -1,
    this.explanation = '',
    this.source,
    this.contrast,
  });

  final ItemKind kind;
  final int itemId;
  final int setId;
  final String setTitle;

  /// The card's front, or the question.
  final String prompt;

  /// The card's back, or the right choice.
  final String answer;

  /// The choices of a question; empty for a card.
  final List<String> choices;
  final int answerIndex;
  final String explanation;

  /// The slide this rests on, if it was looked up.
  final SourceRef? source;

  /// For a contrast card: the two terms that are mixed up.
  final ContrastCard? contrast;

  bool get isQuestion => kind == ItemKind.question;
  bool get isContrast => kind == ItemKind.contrast;
}

/// Records one answer: the item, whether it was right, and the choice picked
/// (for a question).
typedef RecordAnswer = Future<void> Function(PracticeItem item, bool correct, int? chosen);

/// One practice session: the items in order, one answered at a time. An answer
/// is recorded at once, then the item stays on screen with its result until
/// [next]. A second answer to the same item is ignored, so a double tap cannot
/// count twice.
class PracticeSession extends ChangeNotifier {
  PracticeSession(this.items, this.record);

  final List<PracticeItem> items;
  final RecordAnswer record;

  int _index = 0;
  bool _answered = false;
  bool? _lastCorrect;
  int? _lastChosen;
  int _correct = 0;
  bool _saveFailed = false;
  final _missed = <PracticeItem>[];

  int get total => items.length;

  /// How many items are asked: a contrast card is shown, not asked.
  int get gradedTotal => items.where((i) => !i.isContrast).length;

  /// How many asked items come before the current one.
  int get gradedIndex => items.take(_index).where((i) => !i.isContrast).length;

  /// True if the current item is the last one that is asked.
  bool get isLastGraded => isDone || !items.skip(_index + 1).any((i) => !i.isContrast);

  /// True if the current item is a contrast card.
  bool get isInterlude => !isDone && current.isContrast;

  /// The position of the current item, counting from 0.
  int get index => _index;
  bool get isDone => _index >= items.length;
  PracticeItem get current => items[_index];

  /// True from the answer to [next].
  bool get answered => _answered;

  /// Whether the current item was answered right; null until it is answered.
  bool? get lastCorrect => _lastCorrect;

  /// The choice picked for the current question, if it was answered.
  int? get lastChosen => _lastChosen;

  int get correctCount => _correct;

  /// The items answered wrong, in the order they were asked.
  List<PracticeItem> get missed => List.unmodifiable(_missed);

  /// True if an answer could not be saved, so its schedule did not move.
  bool get saveFailed => _saveFailed;

  /// Answers the current item. [chosen] is the choice picked, for a question.
  Future<void> answer({required bool correct, int? chosen}) async {
    if (isDone || _answered || current.isContrast) return;
    final item = current;
    _answered = true;
    _lastCorrect = correct;
    _lastChosen = chosen;
    if (correct) {
      _correct++;
    } else {
      _missed.add(item);
    }
    notifyListeners();
    try {
      await record(item, correct, chosen);
    } catch (_) {
      _saveFailed = true;
      notifyListeners();
    }
  }

  /// The contrast card has been seen. It is noted, and is not an answer: it adds
  /// nothing to the score or to what was missed.
  Future<void> acknowledge() async {
    if (isDone || _answered || !current.isContrast) return;
    final item = current;
    _answered = true;
    notifyListeners();
    try {
      await record(item, true, null);
    } catch (_) {
      _saveFailed = true;
      notifyListeners();
    }
  }

  /// Answers the current question by the choice picked.
  Future<void> choose(int choice) =>
      answer(correct: !isDone && choice == current.answerIndex, chosen: choice);

  /// Moves on to the next item. Does nothing until the current one is answered.
  void next() {
    if (isDone || !_answered) return;
    _index++;
    _answered = false;
    _lastCorrect = null;
    _lastChosen = null;
    notifyListeners();
  }
}
