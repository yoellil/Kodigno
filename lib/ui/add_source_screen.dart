import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../app_controller.dart';
import '../data/repository.dart';
import '../ocr/ocr_service.dart';
import '../sources/source_reader.dart';
import 'anim.dart';
import 'generating_screen.dart';
import 'motion.dart';
import 'set_detail_screen.dart';
import 'theme.dart';
import 'widgets.dart';

typedef GenerateCallback = void Function(String text, String sourceType, String path);

/// Pick or drop a file, review the extracted text, then generate.
class AddSourceBody extends StatefulWidget {
  const AddSourceBody({
    super.key,
    required this.reader,
    required this.generating,
    required this.onGenerate,
    this.initialPath,
    this.enableDrop = true,
  });
  final SourceReader reader;
  final bool generating;
  final GenerateCallback onGenerate;
  final String? initialPath;
  final bool enableDrop;

  @override
  State<AddSourceBody> createState() => _AddSourceBodyState();
}

class _AddSourceBodyState extends State<AddSourceBody> {
  final _text = TextEditingController();
  String? _path;
  String _type = 'text';
  bool _reading = false;
  bool _noText = false;
  bool _dragging = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    if (widget.initialPath != null) _load(widget.initialPath!);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load(String path) async {
    setState(() {
      _path = path;
      _reading = true;
      _noText = false;
      _error = null;
      _text.clear();
    });
    try {
      final type = SourceReader.typeOf(path);
      final text = await widget.reader.read(path);
      if (!mounted) return;
      setState(() {
        _type = type;
        _text.text = text;
        _noText = text.trim().isEmpty;
      });
    } on UnsupportedSourceException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } on OcrFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not read the file: $e');
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _pick(List<String> extensions) async {
    final file =
        await FilePicker.pickFile(type: FileType.custom, allowedExtensions: extensions);
    final path = file?.path;
    if (path != null) await _load(path);
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate =
        _path != null && !_reading && !widget.generating && _text.text.trim().isNotEmpty;

    final zone = DashedBox(
      highlighted: _dragging,
      child: SizedBox(
        height: 210,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSlide(
              offset: _dragging ? const Offset(0, -0.18) : Offset.zero,
              duration: reduceMotion(context) ? Duration.zero : Motion.medium,
              curve: Motion.pop,
              child: AnimatedScale(
                scale: _dragging ? 1.15 : 1,
                duration: reduceMotion(context) ? Duration.zero : Motion.medium,
                curve: Motion.pop,
                child: const KSticker(
                    icon: Icons.folder_open, color: K.yellow, size: 64, tilt: -0.08),
              ),
            ),
            const SizedBox(height: 14),
            Text(_dragging ? 'Let go to add it' : 'Drop files here', style: display(24)),
            const SizedBox(height: 4),
            Text('Images, PDFs and Word documents', style: body(13, color: K.muted)),
          ]),
        ),
      ),
    );

    return ListView(padding: const EdgeInsets.all(32), children: [
      Text('Add source', style: display(38)).enter(context),
      const SizedBox(height: 22),
      widget.enableDrop
          ? DropTarget(
              onDragEntered: (_) => setState(() => _dragging = true),
              onDragExited: (_) => setState(() => _dragging = false),
              onDragDone: (d) {
                setState(() => _dragging = false);
                if (d.files.isNotEmpty) _load(d.files.first.path);
              },
              child: zone,
            )
          : zone,
      const SizedBox(height: 20),
      Text('or pick a source', style: body(13, color: K.muted)),
      const SizedBox(height: 10),
      Wrap(spacing: 14, runSpacing: 14, children: [
        _SourceTile(Icons.image_outlined, K.pink, 'Image', 'photos & scans',
            onTap: () => _pick(['png', 'jpg', 'jpeg', 'bmp', 'tif', 'tiff'])).enter(context, index: 1),
        _SourceTile(Icons.picture_as_pdf_outlined, K.yellow, 'PDF', 'slides & papers',
            onTap: () => _pick(['pdf'])).enter(context, index: 2),
        _SourceTile(Icons.description_outlined, K.lavender, 'DOCX', 'notes & essays',
            onTap: () => _pick(['docx'])).enter(context, index: 3),
        _SourceTile(Icons.notes, K.mint, 'Text', '.txt & .md',
            onTap: () => _pick(['txt', 'md'])).enter(context, index: 4),
        const _SourceTile(Icons.mic_none, K.pink, 'Record', 'live lecture').enter(context, index: 5),
        const _SourceTile(Icons.smart_display_outlined, K.yellow, 'YouTube', 'paste a link')
            .enter(context, index: 6),
      ]),
      if (_path != null) ...[
        const SizedBox(height: 26),
        Row(children: [
          const Icon(Icons.insert_drive_file_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(p.basename(_path!), style: body(14, weight: FontWeight.w700))),
        ]).enter(context),
        const SizedBox(height: 8),
        if (_reading) const KProgress(value: 0.4),
        if (_error != null)
          Text(_error!, style: body(14, color: Colors.red.shade700))
        else if (_noText)
          Text(
            'No text found. Type or paste your notes below, or choose a clearer file.',
            style: body(14, color: Colors.red.shade700),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _text,
          minLines: 8,
          maxLines: 16,
          decoration: const InputDecoration(hintText: 'Text to study from'),
        ),
      ],
      const SizedBox(height: 24),
      Align(
        alignment: Alignment.centerLeft,
        child: PillButton(
          label: 'Generate study materials',
          icon: Icons.bolt,
          onPressed: canGenerate ? () => widget.onGenerate(_text.text, _type, _path!) : null,
        ),
      ),
    ]);
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile(this.icon, this.color, this.label, this.hint, {this.onTap});
  final IconData icon;
  final Color color;
  final String label;
  final String hint;
  final VoidCallback? onTap; // null = coming soon

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 200,
        child: Opacity(
          opacity: onTap == null ? 0.55 : 1,
          child: Lift(
            onTap: onTap,
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              KSticker(icon: icon, color: color, size: 44, tilt: -0.06),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: body(16, weight: FontWeight.w800)),
                  Text(onTap == null ? 'Coming soon' : hint,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: body(12, color: K.muted)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

/// Wires the body to the controller and runs the generate -> detail flow.
class AddSourceScreen extends StatelessWidget {
  const AddSourceScreen({super.key, required this.repo, required this.reader});
  final StudyRepository repo;
  final SourceReader reader;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    return Column(children: [
      Expanded(
        child: AddSourceBody(
          reader: reader,
          generating: c.generating,
          onGenerate: (text, type, path) async {
            final nav = Navigator.of(context);
            nav.push(MaterialPageRoute(
                builder: (_) => GeneratingScreen(title: p.basename(path))));
            final id = await c.generate(
              title: p.basenameWithoutExtension(path),
              notes: text,
              sourceType: type,
              sourcePaths: [path],
            );
            nav.pop(); // generating screen
            if (id != null) {
              nav.push(MaterialPageRoute(
                  builder: (_) => SetDetailScreen(repo: repo, setId: id)));
            }
          },
        ),
      ),
      if (c.error != null)
        Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            title: Text(c.error!),
            trailing: c.fallbackOffer == null
                ? null
                : TextButton(
                    onPressed: c.acceptFallback,
                    child: Text('Use ${c.fallbackOffer!.label}')),
          ),
        ),
    ]);
  }
}
