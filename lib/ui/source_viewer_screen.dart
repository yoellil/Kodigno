import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../domain/source_ref.dart';
import '../sources/slide_render.dart';
import 'theme.dart';
import 'widgets.dart';

const _imageTypes = {'png', 'jpg', 'jpeg', 'bmp', 'tif', 'tiff'};

/// Shows the slide that a piece of material rests on: the real page of the
/// student's PDF with the matching lines highlighted, or the photo itself, or,
/// when the file has moved or has no pages, the page's text.
class SourceViewerScreen extends StatefulWidget {
  const SourceViewerScreen({
    super.key,
    required this.source,
    required this.title,
    required this.paths,
    required this.pages,
  });
  final SourceRef source;
  final String title;
  final List<String> paths;
  final List<PageText> pages;

  @override
  State<SourceViewerScreen> createState() => _SourceViewerScreenState();
}

class _SourceViewerScreenState extends State<SourceViewerScreen> {
  int _i = 0; // which of the source's pages is shown
  RenderedSlide? _slide;
  bool _loading = false;

  int? get _page => _i < widget.source.pages.length ? widget.source.pages[_i] : null;

  String? get _path {
    final f = widget.source.file;
    return f >= 0 && f < widget.paths.length ? widget.paths[f] : null;
  }

  String get _ext => _path == null ? '' : p.extension(_path!).toLowerCase().replaceFirst('.', '');

  bool get _isPdf => _ext == 'pdf' && _path != null && File(_path!).existsSync();
  bool get _isImage => _imageTypes.contains(_ext) && _path != null && File(_path!).existsSync();

  String? get _pageText {
    for (final pg in widget.pages) {
      if (pg.number == _page) return pg.text;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _show();
  }

  @override
  void dispose() {
    _slide?.dispose();
    super.dispose();
  }

  Future<void> _show() async {
    final page = _page;
    if (page == null || !_isPdf) return;
    setState(() => _loading = true);
    final slide = await renderSlide(_path!, page, quote: widget.source.quote);
    if (!mounted || page != _page) {
      slide?.dispose();
      return;
    }
    setState(() {
      _slide?.dispose();
      _slide = slide;
      _loading = false;
    });
  }

  void _go(int step) {
    setState(() {
      _i = (_i + step).clamp(0, widget.source.pages.length - 1);
      _slide?.dispose();
      _slide = null;
    });
    _show();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.source.pages;
    return PanelPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 12, 0),
              child: Row(children: [
                Expanded(
                    child: Text(_page == null ? widget.title : 'Slide $_page of ${widget.title}',
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: display(22))),
                const CloseX(),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 10, 28, 10),
              child: _Banner(widget.source),
            ),
            Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(28, 0, 28, 8), child: _body())),
            if (pages.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton.filledTonal(
                    tooltip: 'Previous slide',
                    onPressed: _i > 0 ? () => _go(-1) : null,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 14),
                  Text('${_i + 1} of ${pages.length}', style: body(13, color: K.muted)),
                  const SizedBox(width: 14),
                  IconButton.filledTonal(
                    tooltip: 'Next slide',
                    onPressed: _i < pages.length - 1 ? () => _go(1) : null,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _body() {
    final page = _page;
    if (page == null) {
      return Center(
        child: Text('Nothing in your file looks like this, so there is no slide to show.',
            textAlign: TextAlign.center, style: body(15, color: K.muted)),
      );
    }
    if (_isPdf) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      final slide = _slide;
      if (slide != null) return _SlideImage(slide);
    } else if (_isImage) {
      return InteractiveViewer(
        maxScale: 4,
        child: Center(child: Image.file(File(_path!), fit: BoxFit.contain)),
      );
    }
    // The file has moved or has no pages: show the page's text instead.
    return _PageText(text: _pageText, quote: widget.source.quote, fileMissing: _path != null && !_isPdf && !_isImage);
  }
}

/// The line that says how far to trust the tag.
class _Banner extends StatelessWidget {
  const _Banner(this.source);
  final SourceRef source;

  @override
  Widget build(BuildContext context) {
    final many = source.pages.length > 1;
    final (color, icon, text) = switch (source.kind) {
      SourceKind.copied => (
          K.mint,
          Icons.check_circle_outline,
          many ? 'Copied word for word from these slides.' : 'Copied word for word from this slide.'
        ),
      SourceKind.explained => (
          K.yellow,
          Icons.auto_awesome,
          'Written by the AI from ${many ? 'these slides' : 'this slide'} (${(source.score * 100).round()}% alike). '
              'The highlighted line is the closest.'
        ),
      SourceKind.unmatched => (
          K.pink,
          Icons.help_outline,
          source.pages.isEmpty
              ? 'No slide supports this. Check it against your own notes.'
              : 'No slide supports this well. The closest one is shown. Check it yourself.'
        ),
    };
    return Panel(
      color: color,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: body(13, weight: FontWeight.w700))),
      ]),
    );
  }
}

/// The picture of the slide, zoomable, with the matching lines boxed in.
class _SlideImage extends StatelessWidget {
  const _SlideImage(this.slide);
  final RenderedSlide slide;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final scale = c.maxWidth / slide.image.width;
        final height = slide.image.height * scale;
        return InteractiveViewer(
          maxScale: 5,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: c.maxWidth,
              height: height,
              child: Stack(children: [
                Positioned.fill(child: RawImage(image: slide.image, fit: BoxFit.fill)),
                Positioned.fill(child: CustomPaint(painter: _Boxes(slide.highlights, scale))),
              ]),
            ),
          ),
        );
      });
}

class _Boxes extends CustomPainter {
  _Boxes(this.boxes, this.scale);
  final List<ui.Rect> boxes;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = K.yellow.withValues(alpha: 0.35);
    final edge = Paint()
      ..color = K.ink.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final b in boxes) {
      final r = RRect.fromRectAndRadius(
          Rect.fromLTRB(b.left * scale, b.top * scale, b.right * scale, b.bottom * scale).inflate(2),
          const Radius.circular(4));
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, edge);
    }
  }

  @override
  bool shouldRepaint(_Boxes old) => old.boxes != boxes || old.scale != scale;
}

/// The page's text, with the matching line highlighted: for a file that has
/// moved, or that has no pages.
class _PageText extends StatelessWidget {
  const _PageText({required this.text, required this.quote, required this.fileMissing});
  final String? text;
  final String quote;
  final bool fileMissing;

  @override
  Widget build(BuildContext context) {
    final t = text ?? quote;
    final range = text == null ? null : findQuoteRange(text!, quote);
    final style = body(15);
    return ListView(children: [
      if (fileMissing || text != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('The original file is not available, so this is the text of the slide.',
              style: body(12, color: K.muted)),
        ),
      Panel(
        color: K.tile,
        padding: const EdgeInsets.all(18),
        child: SelectableText.rich(
          range == null
              ? TextSpan(text: t, style: style)
              : TextSpan(style: style, children: [
                  TextSpan(text: t.substring(0, range.$1)),
                  TextSpan(
                    text: t.substring(range.$1, range.$2 + 1),
                    style: TextStyle(backgroundColor: K.yellow.withValues(alpha: 0.6), fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: t.substring(range.$2 + 1)),
                ]),
        ),
      ),
    ]);
  }
}
