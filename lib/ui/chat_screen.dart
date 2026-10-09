import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ai/ai_engine.dart';
import '../app_controller.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

const _suggestions = [
  'Explain this lesson simply',
  'What are the key points?',
  'Give me an example',
];

/// Ask-the-tutor chat about one lesson. The conversation is not saved.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.title, required this.notes});
  final String title;
  final String notes;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _turns = <ChatTurn>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: reduceMotion(context) ? Duration.zero : Motion.medium,
              curve: Motion.curve);
        }
      });

  Future<void> _send([String? text]) async {
    final q = (text ?? _input.text).trim();
    if (q.isEmpty || _busy) return;
    final app = context.read<AppController>();
    setState(() {
      _turns.add(ChatTurn('user', q));
      _input.clear();
      _busy = true;
      _error = null;
    });
    _toEnd();
    try {
      final reply = await app.ask(widget.notes, List.of(_turns));
      if (!mounted) return;
      setState(() => _turns.add(ChatTurn('assistant', reply.isEmpty ? '…' : reply)));
    } on ChatFailed catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _toEnd();
        _focus.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) => PanelPage(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 12, 0),
                child: Row(children: [
                  Expanded(
                      child: Text('Ask about ${widget.title}',
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: display(24))),
                  const CloseX(),
                ]),
              ),
              Expanded(
                child: _turns.isEmpty && !_busy
                    ? _Empty(onPick: _send)
                    : ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
                        children: [
                          for (final t in _turns) _Bubble(t),
                          if (_busy) const _Thinking(),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(_error!, style: body(13, color: Colors.red.shade400)),
                            ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      autofocus: true,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about this lesson',
                        hintStyle: body(15, color: K.muted),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Send',
                    style: IconButton.styleFrom(backgroundColor: K.yellow, foregroundColor: K.ink),
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onPick});
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const KSticker(icon: Icons.chat_bubble_outline, color: K.mint, size: 64),
            const SizedBox(height: 20),
            Text('Stuck on something?', style: display(28)),
            const SizedBox(height: 8),
            Text('Ask your tutor. It answers from your notes.',
                textAlign: TextAlign.center, style: body(15, color: K.muted)),
            const SizedBox(height: 20),
            Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
              for (final s in _suggestions)
                ActionChip(label: Text(s), onPressed: () => onPick(s)),
            ]),
          ]),
        ),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.turn);
  final ChatTurn turn;

  @override
  Widget build(BuildContext context) {
    final mine = turn.role == 'user';
    final bg = mine ? K.yellow : K.tile;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: inkOnPastel(bg, SelectableText(turn.text, style: body(15))),
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: K.tile, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Text('Thinking…', style: body(14, color: K.muted)),
          ]),
        ),
      );
}
