import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/database.dart';
import '../domain/source_ref.dart';
import 'source_viewer_screen.dart';
import 'theme.dart';

/// What a screen knows about the file behind a study set, so any [SlideTag]
/// under it can open the slide it points at.
class SourceScope extends InheritedWidget {
  const SourceScope({
    super.key,
    required this.title,
    required this.paths,
    required this.pages,
    required super.child,
  });

  /// The scope for [set]: its title, its files, and its pages (read from the
  /// page markers in its text; none for a file without pages).
  factory SourceScope.forSet(StudySet set, {Key? key, required Widget child}) {
    var paths = <String>[];
    try {
      paths = [for (final p in jsonDecode(set.sourcePaths) as List) '$p'];
    } on FormatException {
      // no usable file list: the viewer falls back to the page's text
    }
    return SourceScope(
        key: key, title: set.title, paths: paths, pages: parsePages(set.sourceText), child: child);
  }

  final String title;
  final List<String> paths;
  final List<PageText> pages;

  static SourceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SourceScope>();

  @override
  bool updateShouldNotify(SourceScope old) =>
      old.title != title || old.paths != paths || old.pages != pages;
}

/// A small tag that says which slide a piece of material rests on, and how
/// sure that is: green for text copied word for word, yellow for AI-written
/// text with a supporting slide, pink for text no slide supports. Tap to see
/// the slide.
class SlideTag extends StatelessWidget {
  const SlideTag(this.source, {super.key});
  final SourceRef source;

  String get _label {
    final pages = source.pages.join(', ');
    return switch (source.kind) {
      SourceKind.copied => pages.isEmpty ? 'Copied' : 'Slide $pages',
      SourceKind.explained => pages.isEmpty ? 'AI-written' : 'Slide $pages',
      SourceKind.unmatched => 'No match',
    };
  }

  Color get _color => switch (source.kind) {
        SourceKind.copied => K.mint,
        SourceKind.explained => K.yellow,
        SourceKind.unmatched => K.pink,
      };

  IconData get _icon => switch (source.kind) {
        SourceKind.copied => Icons.check_circle_outline,
        SourceKind.explained => Icons.auto_awesome,
        SourceKind.unmatched => Icons.help_outline,
      };

  String get _hint => switch (source.kind) {
        SourceKind.copied => 'Copied word for word from the slide. Tap to see it.',
        SourceKind.explained => 'Written by the AI from the slide. Tap to see it.',
        SourceKind.unmatched => 'No slide supports this. Tap to see the closest one.',
      };

  @override
  Widget build(BuildContext context) {
    final scope = SourceScope.maybeOf(context);
    return Tooltip(
      message: _hint,
      child: MouseRegion(
        cursor: scope == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: scope == null
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SourceViewerScreen(
                        source: source, title: scope.title, paths: scope.paths, pages: scope.pages),
                  )),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: K.ink, width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_icon, size: 12, color: K.ink),
              const SizedBox(width: 4),
              Text(_label, style: body(11, weight: FontWeight.w800, color: K.ink)),
            ]),
          ),
        ),
      ),
    );
  }
}
