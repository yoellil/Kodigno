import 'package:flutter/material.dart';

import '../study/diagnosis.dart';
import 'slide_tag.dart';
import 'theme.dart';

/// Where a wrong pick came from, in a sentence, with a tag for the slide of the
/// pick and the slide of the answer. It says what happened, never why: the app
/// can see the choice, not the student's thinking. Nothing if there is nothing
/// useful to say.
class DiagnosisLine extends StatelessWidget {
  const DiagnosisLine(this.diagnosis, {super.key});
  final Diagnosis? diagnosis;

  @override
  Widget build(BuildContext context) {
    final d = diagnosis;
    if (d == null || d.message.isEmpty) return const SizedBox.shrink();
    final pick = d.pickedRef, answer = d.answerRef;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: K.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.travel_explore, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text('WHERE YOUR PICK CAME FROM',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(10, weight: FontWeight.w800, color: K.ink.withValues(alpha: 0.6))),
          ),
        ]),
        const SizedBox(height: 6),
        Text(d.message, style: body(13)),
        if (pick != null || answer != null) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 14, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (pick != null) _Labeled('Your pick', SlideTag(pick)),
            if (answer != null) _Labeled('Answer', SlideTag(answer)),
          ]),
        ],
      ]),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.tag);
  final String label;
  final Widget tag;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: body(11, color: K.muted)),
        const SizedBox(width: 6),
        tag,
      ]);
}
