import 'package:flutter/material.dart';

import '../domain/card_assist.dart';
import 'theme.dart';
import 'widgets.dart';

/// Asks the local AI for the missing side of a card: the definition for [term], or
/// the term for [definition]. Throws [CardAssistFailed] with a message for the student.
typedef CardSuggester = Future<CardSuggestion> Function(
  AssistField want,
  String term,
  String definition,
);

/// The form shared by "Add card" and by editing a card in place: a term, a
/// definition, and an "Ask AI" button next to each. The button by the term writes
/// the definition from it; the one by the definition writes the term.
class CardEditorForm extends StatefulWidget {
  const CardEditorForm({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.initialTerm = '',
    this.initialDefinition = '',
    this.suggest,
    this.termLabel = 'Term',
    this.definitionLabel = 'Definition',
    this.saveLabel = 'Save card',
  });

  final String initialTerm;
  final String initialDefinition;

  /// Saves the card. May throw; the form shows a message and stays open.
  final Future<void> Function(String term, String definition) onSave;
  final VoidCallback onCancel;

  /// Null hides the Ask AI buttons (no model available).
  final CardSuggester? suggest;
  final String termLabel;
  final String definitionLabel;
  final String saveLabel;

  @override
  State<CardEditorForm> createState() => _CardEditorFormState();
}

class _CardEditorFormState extends State<CardEditorForm> {
  late final _term = TextEditingController(text: widget.initialTerm);
  late final _definition = TextEditingController(
    text: widget.initialDefinition,
  );
  AssistField? _asking; // the field being written by the AI right now
  bool _saving = false;
  String? _error;

  /// What the AI just replaced, so one tap puts it back; and where its suggestion came from.
  ({AssistField field, String text})? _undo;
  CardSuggestion? _suggestion;

  @override
  void initState() {
    super.initState();
    _term.addListener(_changed);
    _definition.addListener(_changed);
  }

  @override
  void dispose() {
    _term.dispose();
    _definition.dispose();
    super.dispose();
  }

  void _changed() =>
      setState(() {}); // the Save button and the hints follow the text

  bool get _busy => _asking != null || _saving;
  bool get _canSave =>
      !_busy &&
      _term.text.trim().isNotEmpty &&
      _definition.text.trim().isNotEmpty;

  TextEditingController _controllerFor(AssistField f) =>
      f == AssistField.term ? _term : _definition;

  Future<void> _ask(AssistField want) async {
    final suggest = widget.suggest;
    if (suggest == null || _busy) return;
    setState(() {
      _asking = want;
      _error = null;
      _undo = null;
      _suggestion = null;
    });
    try {
      final got = await suggest(want, _term.text, _definition.text);
      if (!mounted) return;
      final target = _controllerFor(want);
      final before = target.text;
      setState(() {
        _undo = before.trim().isEmpty ? null : (field: want, text: before);
        _suggestion = got;
        target.text = got.text;
        target.selection = TextSelection.collapsed(offset: got.text.length);
      });
    } on CardAssistFailed catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = "Couldn't get a suggestion. Try again.");
      }
    } finally {
      if (mounted) setState(() => _asking = null);
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_term.text.trim(), _definition.text.trim());
    } on ArgumentError catch (e) {
      if (mounted) {
        setState(() => _error = e.message?.toString() ?? 'Fill in both sides.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = "Couldn't save the card. Try again.");
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field({
    required AssistField field,
    required String label,
    required String askTooltip,
    required String hint,
    required int minLines,
    required int maxLines,
    required bool autofocus,
  }) {
    final c = _controllerFor(field);
    // The button beside a field asks for the OTHER side, written from this one.
    final want = field == AssistField.term
        ? AssistField.definition
        : AssistField.term;
    final asking = _asking == want;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: body(14, weight: FontWeight.w800)),
            ),
            if (widget.suggest != null)
              Tooltip(
                message: askTooltip,
                child: TextButton.icon(
                  onPressed: _busy ? null : () => _ask(want),
                  icon: asking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(asking ? 'Thinking…' : 'Ask AI'),
                ),
              ),
          ],
        ),
        TextField(
          key: ValueKey('card-${field.name}'),
          controller: c,
          autofocus: autofocus,
          minLines: minLines,
          maxLines: maxLines,
          readOnly: _asking == field, // the AI is writing this one
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final termFilled = _term.text.trim().isNotEmpty;
    final defFilled = _definition.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "Ask AI" beside the term writes the DEFINITION from the term (and the other way round).
        _field(
          field: AssistField.term,
          label: widget.termLabel,
          askTooltip: 'Suggest the definition from this term',
          hint: 'A word, name or question',
          minLines: 1,
          maxLines: 3,
          autofocus: true,
        ),
        if (widget.suggest != null && termFilled && !defFilled)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Tap Ask AI above to write the definition from this term.',
              style: body(12, color: K.muted),
            ),
          ),
        const SizedBox(height: 16),
        _field(
          field: AssistField.definition,
          label: widget.definitionLabel,
          askTooltip: 'Suggest the term from this definition',
          hint: 'What it means, or the answer',
          minLines: 3,
          maxLines: 8,
          autofocus: false,
        ),
        if (widget.suggest != null && defFilled && !termFilled)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Tap Ask AI above to suggest a term for this definition.',
              style: body(12, color: K.muted),
            ),
          ),
        if (_suggestion != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(
                  _suggestion!.fromNotes ? Icons.menu_book_outlined : Icons.info_outline,
                  size: 16,
                  color: K.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _suggestion!.fromNotes
                        ? 'AI suggestion, based on your notes. Check it before you save.'
                        : "AI suggestion from its general knowledge, not your notes. It can be wrong, so double-check it.",
                    style: body(12, color: K.muted),
                  ),
                ),
                if (_undo != null)
                  TextButton(
                    onPressed: () => setState(() {
                      _controllerFor(_undo!.field).text = _undo!.text;
                      _undo = null;
                      _suggestion = null;
                    }),
                    child: const Text('Undo'),
                  ),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: body(
                  13,
                  color: Colors.redAccent,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _saving ? null : widget.onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            PillButton(
              label: _saving ? 'Saving…' : widget.saveLabel,
              icon: Icons.check,
              onPressed: _canSave ? _save : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// The "Add card" dialog. [onSave] adds the card; the dialog closes (returning true)
/// when it succeeds.
Future<bool?> showAddCardDialog(
  BuildContext context, {
  required Future<void> Function(String term, String definition) onSave,
  CardSuggester? suggest,
}) => showDialog<bool>(
  context: context,
  builder: (ctx) => Dialog(
    backgroundColor: K.card,
    insetPadding: const EdgeInsets.all(24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a card', style: display(28)),
            const SizedBox(height: 18),
            CardEditorForm(
              suggest: suggest,
              onSave: (t, d) async {
                await onSave(t, d);
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              onCancel: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    ),
  ),
);
