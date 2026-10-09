import 'dart:convert';

import 'definitions.dart' show shortenDefinition;
import 'prompt.dart' show pickContext;

/// "Ask AI" in the card form: given the term, suggest the definition; given the
/// definition, suggest the term. The same small local model that writes the study
/// sets answers, so this builds one short chat (a system message with the rules and
/// one user message with the card and, if the set has notes, the part of them that
/// covers it) and cleans what comes back.

/// What the AI is asked to write.
enum AssistField { definition, term }

/// The system message. The rules matter more than the wording: a small model
/// told to be brief, to stay with the notes and to say nothing when unsure writes
/// far fewer made-up facts.
const cardAssistSystemPrompt = '''
You help a student write study flashcards. A flashcard has a TERM on the front (a word, name, concept or short question) and a DEFINITION on the back (its answer).
Rules:
- A definition is one or two plain sentences, at most 30 words: what the term is or means, with the one detail a student must remember. No filler such as "The term X means".
- A term is a short phrase of at most 8 words that the definition describes. Do not reuse the definition's own sentences.
- If NOTES from the student's lesson are given and cover the subject, use their facts and wording, and never contradict them.
- If the notes do not cover it, answer from general knowledge only when you are sure. If you are not sure, answer with an empty string instead of guessing.
- Reply with JSON only.''';

/// The chat to send for [want]. [term] or [definition] is what the student typed;
/// [notes] is the set's source text (may be empty) and [setTitle] its name.
List<Map<String, String>> buildCardAssistMessages({
  required AssistField want,
  String term = '',
  String definition = '',
  String notes = '',
  String setTitle = '',
}) {
  String clip(String s) => s.trim().length > 400 ? s.trim().substring(0, 400) : s.trim();
  final given = want == AssistField.definition ? clip(term) : clip(definition);
  final context = notes.trim().isEmpty
      ? ''
      : '\nNOTES from the lesson${setTitle.trim().isEmpty ? '' : ' "${setTitle.trim()}"'}:\n'
          '${pickContext(notes, given, maxChars: 1500)}\n';
  final task = want == AssistField.definition
      ? 'TERM: $given\nWrite the DEFINITION for this term.'
      : 'DEFINITION: $given\nWrite the short TERM that this definition describes.';
  return [
    {'role': 'system', 'content': cardAssistSystemPrompt},
    {'role': 'user', 'content': '$context\n$task\nReply as {"${want.name}": "..."}'.trim()},
  ];
}

/// The reply format the server is held to: one key, [want].
Map<String, Object?> cardAssistSchema(AssistField want) => {
      'type': 'object',
      'properties': {
        want.name: {'type': 'string', 'maxLength': want == AssistField.term ? 100 : 320},
      },
      'required': [want.name],
    };

/// A suggestion and where it came from, so the student knows how far to trust it.
class CardSuggestion {
  const CardSuggestion(this.text, {this.fromNotes = false});
  final String text;

  /// The subject appears in the set's own notes (so the AI was shown them).
  /// False means the model answered from what it learned in training, and may be wrong.
  final bool fromNotes;
}

/// True if [subject] (a term, or the term the AI came up with) is in [notes].
bool mentionedIn(String subject, String notes) {
  String flat(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u00C0-\u024F ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final s = flat(subject);
  return s.length >= 3 && flat(notes).contains(s);
}

/// [definition] without a lead-in that repeats [term] ("Mercado means 'market'" becomes
/// "Market."): the card already shows the term.
String withoutEchoedTerm(String definition, String term) {
  final t = RegExp.escape(term.trim());
  if (t.isEmpty) return definition;
  final m = RegExp("^[\"'\u201C\u2018]?$t[\"'\u201D\u2019]?\\s*(?:means|is|are|refers to|is defined as|stands for|:|-|\u2013)\\s+(.{3,})\$",
          caseSensitive: false)
      .firstMatch(definition.trim());
  if (m == null) return definition;
  var rest = m[1]!.trim().replaceFirst(RegExp("^[\"'\u201C\u2018]+"), '').replaceFirst(RegExp("[\"'\u201D\u2019]+(?=[.!]?\$)"), '');
  if (rest.isEmpty) return definition;
  return rest[0].toUpperCase() + rest.substring(1);
}

/// The suggestion in [raw], tidied: no quotes, no "Definition:" label, one line for a
/// term and at most about 240 characters for a definition. '' means the model
/// was not sure. Throws [FormatException] if [raw] is not the JSON asked for.
String parseCardAssist(String raw, AssistField want) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) throw const FormatException('no JSON object in reply');
  final j = jsonDecode(raw.substring(start, end + 1));
  if (j is! Map || j[want.name] is! String) throw FormatException('no "${want.name}" in reply');
  var s = (j[want.name] as String)
      .replaceFirst(RegExp(r'^\s*(?:definition|term)\s*[:\-–]\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (s.length > 1 && RegExp('^["“\'].*["”\']\$').hasMatch(s)) s = s.substring(1, s.length - 1).trim();
  if (s.isEmpty) return '';
  if (want == AssistField.term) return s.replaceFirst(RegExp(r'[.!?]+$'), '');
  return shortenDefinition(s, max: 240);
}

/// Why a card suggestion could not be made, in words for the student.
class CardAssistFailed implements Exception {
  CardAssistFailed(this.message);
  final String message;
  @override
  String toString() => message;
}
