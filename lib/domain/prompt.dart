/// Splits [text] into chunks of at most [maxChars], preferring paragraph and
/// sentence boundaries. Never drops words.
List<String> chunkText(String text, int maxChars) {
  final pieces = <String>[];
  for (final p in text.split('\n')) {
    var s = p.trim();
    while (s.length > maxChars) {
      var cut = s.lastIndexOf(RegExp(r'[.!?]\s'), maxChars - 2) + 1;
      if (cut <= 0) cut = s.lastIndexOf(' ', maxChars);
      if (cut <= 0) cut = maxChars;
      pieces.add(s.substring(0, cut).trim());
      s = s.substring(cut).trim();
    }
    if (s.isNotEmpty) pieces.add(s);
  }

  final chunks = <String>[];
  var cur = '';
  for (final piece in pieces) {
    if (cur.isEmpty) {
      cur = piece;
    } else if (cur.length + 1 + piece.length <= maxChars) {
      cur = '$cur\n$piece';
    } else {
      chunks.add(cur);
      cur = piece;
    }
  }
  if (cur.isNotEmpty) chunks.add(cur);
  return chunks;
}

/// The worked example shown to the model. It is about a made-up planet so
/// that a small model copying it is easy to spot and drop (see LlmAiEngine).
const exampleQuestionPrompt = 'On the planet Zorblax, what do the Quibs eat?';
const exampleCardFront = 'Quib';

String buildPrompt(String notes, {required int questions, required int cards}) => '''
You are a study assistant. Using ONLY the notes below, write $questions multiple-choice questions and $cards flashcards.
Each question has exactly 4 choices and exactly one correct choice.
Reply with JSON only and stop after the closing brace. Format example (made-up topic, never reuse it):
{"questions":[{"prompt":"$exampleQuestionPrompt","choices":["Moss","Rocks","Glass","Clouds"],"answer_index":0,"explanation":"Quibs graze on moss."}],"flashcards":[{"front":"$exampleCardFront","back":"A small moss-eating creature of Zorblax"}]}
"answer_index" is the 0-based index of the correct choice.

NOTES:
$notes
''';
