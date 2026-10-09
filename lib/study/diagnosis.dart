import '../domain/source_ref.dart';

/// How a wrong choice relates to the right one, judged only by where each comes
/// from in the student's own pages. It says what happened, not why.
enum MixUp {
  /// Both are on the same slide.
  sameSlide,

  /// The slides are a few pages apart.
  nearby,

  /// Different parts of the lesson.
  farAway,

  /// The wrong choice is not in the pages at all: not from the lesson.
  notInSlides,

  /// The pages could not say (no pages, or the right answer cannot be placed).
  unknown,
}

/// The nearest slides count as "close by" up to this many pages apart.
const nearbyPages = 3;

/// What was picked, what was right, and where each comes from.
class Diagnosis {
  const Diagnosis({
    required this.kind,
    required this.picked,
    required this.answer,
    this.pickedRef,
    this.answerRef,
    this.repeated = false,
  });

  final MixUp kind;
  final String picked;
  final String answer;

  /// Where the wrong choice is in the pages, if it is.
  final SourceRef? pickedRef;

  /// Where the right answer is in the pages, if it can be placed.
  final SourceRef? answerRef;

  /// True if the student picked this same wrong choice for this question before.
  final bool repeated;

  int? get pickedPage => pickedRef?.page;
  int? get answerPage => answerRef?.page;

  /// One or two plain sentences, or '' if there is nothing useful to say.
  String get message {
    final p = _short(picked), a = _short(answer);
    final again = repeated ? ' You picked it before, too.' : '';
    switch (kind) {
      case MixUp.sameSlide:
        return 'You picked "$p", which is on the same slide as the answer (slide $answerPage). '
            'They are easy to mix up.$again';
      case MixUp.nearby:
        return 'You picked "$p" (slide $pickedPage). The answer, "$a", is on slide $answerPage, close by.$again';
      case MixUp.farAway:
        return 'You picked "$p" (slide $pickedPage), a different part of the lesson from the answer '
            '(slide $answerPage). It may be worth reviewing slide $pickedPage.$again';
      case MixUp.notInSlides:
        return 'You picked "$p", which is not in your slides, so it may have been a guess.$again';
      case MixUp.unknown:
        return pickedPage == null ? (repeated ? 'You picked this one before, too.' : '') : 'You picked "$p" (slide $pickedPage).$again';
    }
  }

  static String _short(String s) => s.length <= 60 ? s : '${s.substring(0, 57).trimRight()}...';
}

/// Where a phrase is in a set of pages: by quote, whole words, for a term; and
/// for a longer phrase by how alike the page is.
class PageIndex {
  PageIndex(List<PageText> pages, {this.minScore = 0.5})
      : _pages = pages,
        _locator = SourceLocator(pages, minScore: minScore) {
    for (final p in pages) {
      _squashed.add(' ${_squash(p.text)} ');
    }
  }

  final List<PageText> _pages;
  final SourceLocator _locator;

  /// A longer phrase needs a page at least this alike to count as being on it.
  final double minScore;
  final _squashed = <String>[];

  bool get isEmpty => _pages.isEmpty;

  /// Every page that has [phrase] in whole words, with no limit: for picking the
  /// best page to read about it.
  List<int> allPages(String phrase) {
    final needle = _squash(phrase);
    if (needle.length < 3) return const [];
    return [for (var i = 0; i < _pages.length; i++) if (_squashed[i].contains(' $needle ')) _pages[i].number];
  }

  static String _squash(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  /// Where [phrase] is, or null if nowhere in the pages. A phrase on very many
  /// pages ("law") says nothing about one slide, so it is null too.
  SourceRef? find(String phrase) {
    final needle = _squash(phrase);
    if (needle.length < 3 || _pages.isEmpty) return null;
    final hits = [for (var i = 0; i < _pages.length; i++) if (_squashed[i].contains(' $needle ')) _pages[i].number];
    final tooCommon = hits.length > 3 && hits.length > _pages.length ~/ 4;
    if (hits.isNotEmpty && !tooCommon) {
      return SourceRef(kind: SourceKind.copied, pages: hits.take(3).toList(), score: 1, quote: phrase.trim());
    }
    if (hits.isEmpty && needle.split(' ').length >= 3) {
      final ref = _locator.locate(phrase);
      if (ref.kind != SourceKind.unmatched && ref.pages.isNotEmpty) return ref;
    }
    return null;
  }
}

/// What to tell a student who picked [chosen] for a question with [choices],
/// the right one being [answerIndex]. [pages] are the student's own pages;
/// [questionSource] is where the question itself came from, used to place the
/// right answer when its own words are not on a page. [earlierPicks] is how many
/// times this same wrong choice was picked for this question before. Null if the
/// answer was right, or the indexes are out of range.
Diagnosis? diagnose({
  required List<String> choices,
  required int answerIndex,
  required int chosen,
  required PageIndex pages,
  SourceRef? questionSource,
  int earlierPicks = 0,
}) {
  if (answerIndex < 0 || answerIndex >= choices.length) return null;
  if (chosen < 0 || chosen >= choices.length || chosen == answerIndex) return null;
  final picked = choices[chosen], answer = choices[answerIndex];
  final repeated = earlierPicks > 0;

  if (pages.isEmpty) {
    return Diagnosis(kind: MixUp.unknown, picked: picked, answer: answer, repeated: repeated);
  }
  final pickedRef = pages.find(picked);
  var answerRef = pages.find(answer);
  if (answerRef == null && questionSource != null && questionSource.kind != SourceKind.unmatched && questionSource.pages.isNotEmpty) {
    answerRef = questionSource;
  }

  if (pickedRef == null) {
    return Diagnosis(kind: MixUp.notInSlides, picked: picked, answer: answer, answerRef: answerRef, repeated: repeated);
  }
  if (answerRef == null) {
    return Diagnosis(kind: MixUp.unknown, picked: picked, answer: answer, pickedRef: pickedRef, repeated: repeated);
  }
  var gap = 1 << 30;
  for (final p in pickedRef.pages) {
    for (final a in answerRef.pages) {
      final d = (p - a).abs();
      if (d < gap) gap = d;
    }
  }
  final kind = gap == 0 ? MixUp.sameSlide : gap <= nearbyPages ? MixUp.nearby : MixUp.farAway;
  return Diagnosis(
    kind: kind,
    picked: picked,
    answer: answer,
    pickedRef: pickedRef,
    answerRef: answerRef,
    repeated: repeated,
  );
}
