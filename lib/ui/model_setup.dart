import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_controller.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

/// Tier picker + one-time model download. Used on first run and in Settings.
class ModelSetupPanel extends StatelessWidget {
  const ModelSetupPanel({super.key, required this.heading});
  final String heading;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final tier = c.tier!;
    final tooBig = c.tiers.tiers.indexOf(tier) > c.tiers.tiers.indexOf(c.recommended);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(heading, style: display(30)),
      const SizedBox(height: 12),
      Text(
        'Kodigno downloads its AI model once. After that it works fully offline and your notes never leave this computer.',
        style: body(15, color: K.muted),
      ),
      const SizedBox(height: 20),
      DropdownButton<String>(
        value: tier.id,
        isExpanded: true,
        items: [
          for (final t in c.tiers.tiers)
            DropdownMenuItem(
              value: t.id,
              child: Text('${t.label} (~${t.sizeMb} MB)'
                  '${t.id == c.recommended.id ? ' · recommended' : ''}'),
            ),
        ],
        onChanged:
            c.downloadFraction != null ? null : (id) => c.chooseTier(c.tiers.byId(id!)),
      ),
      if (tooBig)
        Text('Larger than recommended for this computer; it may be slow or run out of memory.',
            style: body(13, color: Colors.orange.shade900)),
      if (tier.id == 'low')
        Text(
            'Basic is small and fast, but it can write wrong or odd questions. '
            'Pick Standard or High quality for better results if your computer can run it.',
            style: body(13, color: K.muted)),
      if (c.storageTooLow)
        Text('Not enough free disk space for this model.',
            style: body(13, color: Colors.red.shade700)),
      if (c.error != null) Text(c.error!, style: body(13, color: Colors.red.shade700)),
      const SizedBox(height: 20),
      if (c.downloadFraction != null) ...[
        KProgress(value: c.downloadFraction!, height: 8),
        const SizedBox(height: 6),
        Text('${(c.downloadFraction! * 100).floor()}%', style: body(14, weight: FontWeight.w700)),
      ] else if (c.modelReady)
        Row(children: [
          const Icon(Icons.check_circle),
          const SizedBox(width: 8),
          Text('Model installed', style: body(15, weight: FontWeight.w700)),
        ])
      else
        PillButton(label: 'Download model', icon: Icons.download, onPressed: c.downloadModel),
    ]);
  }
}

/// First run (and whenever the chosen model is not installed).
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: K.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: K.line),
              ),
              child: const ModelSetupPanel(heading: 'Set up Kodigno'),
            ).enter(context),
          ),
        ),
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text('Settings', style: display(34)),
        const SizedBox(height: 24),
        Text('Appearance', style: display(30)),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
          ],
          selected: {c.themeMode},
          onSelectionChanged: (s) => c.setThemeMode(s.first),
        ),
        const SizedBox(height: 32),
        const ModelSetupPanel(heading: 'AI model'),
      ],
    );
  }
}
