import '../domain/nlp.dart';
import '../domain/source_ref.dart';
import '../domain/topics.dart' show isCourseHeading, isHeadingLine;
import 'diagnosis.dart';
import 'session_plan.dart' show practiceKey;

/// A wrong answer to a quiz question: what was picked and what was right.
class WrongPick {
  const WrongPick({required this.questionId, required this.setId, required this.picked, required this.answer});
  final int questionId;
  final int setId;
  final String picked;
  final String answer;
}

/// Two things the student keeps mixing up.
class Confusion {
  const Confusion({
    required this.a,
    required this.b,
    required this.times,
    required this.questionId,
    required this.setId,
  });

  /// The right answer of the question missed most recently this way.
  final String a;

  /// What it was mixed up with.
  final String b;

  /// How many times, in all, in either direction.
  final int times;

  /// The question missed most recently this way: the one to ask again.
  final int questionId;
  final int setId;

  String get message => 'You have mixed up "$a" and "$b" $times times.';
}

/// Longer choices are sentences, not things to mix up.
const maxTermWords = 8;

/// The pairs the student keeps mixing up: the same two choices, in either order,
/// missed [minTimes] times or more. [picks] are in the order they happened.
/// A pair is settled, and left out, once every question it came up in has been
/// answered right twice in a row since ([streakByQuestion]). Most often first,
/// then the most recent.
List<Confusion> findConfusions(
  List<WrongPick> picks, {
  Map<int, int> streakByQuestion = const {},
  int minTimes = 2,
}) {
  final groups = <String, List<WrongPick>>{};
  final order = <String>[];
  for (final p in picks) {
    if (p.picked.split(RegExp(r'\s+')).length > maxTermWords || p.answer.split(RegExp(r'\s+')).length > maxTermWords) continue;
    final x = practiceKey(p.picked), y = practiceKey(p.answer);
    if (x.isEmpty || y.isEmpty || x == y) continue;
    final key = x.compareTo(y) < 0 ? '$x|$y' : '$y|$x';
    if (!groups.containsKey(key)) order.add(key);
    groups.putIfAbsent(key, () => []).add(p);
  }
  final out = <(Confusion, int)>[];
  for (var i = 0; i < order.length; i++) {
    final g = groups[order[i]]!;
    if (g.length < minTimes) continue;
    if (g.every((p) => (streakByQuestion[p.questionId] ?? 0) >= 2)) continue; // settled
    final last = g.last;
    out.add((
      Confusion(a: last.answer, b: last.picked, times: g.length, questionId: last.questionId, setId: last.setId),
      picks.lastIndexOf(last),
    ));
  }
  out.sort((x, y) {
    final byTimes = y.$1.times.compareTo(x.$1.times);
    return byTimes != 0 ? byTimes : y.$2.compareTo(x.$2);
  });
  return [for (final (c, _) in out) c];
}

/// One side of a comparison: a term, what the slides say about it, and where.
class ContrastSide {
  const ContrastSide({required this.term, required this.text, required this.page});
  final String term;
  final String text;
  final int page;
}

/// Two confused terms, side by side with what the slides say about each.
class ContrastCard {
  const ContrastCard({required this.a, required this.b, required this.times, required this.questionId, required this.setId});
  final ContrastSide a, b;
  final int times;

  /// The question to ask straight after the card.
  final int questionId;
  final int setId;
}

/// What the slides say about [term], and the page: the best place it is explained.
/// A heading with a line under it, or a sentence that starts with the term, beats
/// a passing mention; a page about the course itself ("Intended Learning
/// Outcomes") is never used. Null if [term] is not on a page, or the slides say
/// nothing more about it.
({String text, int page})? whatSlidesSay(String term, PageIndex index, List<PageText> pages) {
  final word = RegExp('(?<![A-Za-z0-9])${RegExp.escape(term.trim())}(?![A-Za-z0-9])', caseSensitive: false);
  ({String text, int page})? best;
  var bestScore = 0;
  for (final n in index.allPages(term)) {
    final page = pages.firstWhere((p) => p.number == n, orElse: () => const PageText(0, ''));
    if (isCourseHeading(page.text.split('\n').first)) continue;
    final items = textItems(page.text);
    for (var i = 0; i < items.length; i++) {
      final m = word.firstMatch(items[i]);
      if (m == null) continue;
      final words = items[i].split(RegExp(r'\s+')).length;
      final isHeading = words <= 5 && i + 1 < items.length;
      // A heading on its own is described by the lines under it: the short bullets
      // are joined until there is enough to read, and stop at the next heading.
      var text = isHeading ? items[i + 1] : items[i];
      if (isHeading) {
        for (var k = i + 2; k < items.length && k <= i + 3 && text.length < 70 && !isHeadingLine(items[k]); k++) {
          text = '${text.replaceFirst(RegExp(r'[.,;:]$'), '')}. ${items[k]}';
        }
      }
      if (text.split(RegExp(r'\s+')).length < 4) continue;
      // "A patent permits..." defines it; "Many firms protect a patent..." only mentions it.
      final lead = items[i].substring(0, m.start).trim().toLowerCase();
      final startsWithIt = lead.isEmpty || lead == 'a' || lead == 'an' || lead == 'the';
      final score = isHeading ? 3 : startsWithIt ? 2 : 1;
      if (score > bestScore) {
        bestScore = score;
        best = (text: _clip(text), page: n);
      }
      break; // the first place on this page is the one that counts
    }
  }
  return best;
}

String _clip(String s) {
  if (s.length <= 220) return s;
  final cut = s.substring(0, 220);
  final end = cut.lastIndexOf(RegExp(r'[.;]'));
  return end > 80 ? cut.substring(0, end + 1) : '${cut.trimRight()}...';
}
