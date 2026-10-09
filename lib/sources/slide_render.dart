import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart';

/// A page of the student's PDF as a picture, with the lines to point at.
class RenderedSlide {
  RenderedSlide(this.image, this.highlights, this.page);
  final ui.Image image;

  /// One box per highlighted line, in the picture's own pixels.
  final List<ui.Rect> highlights;
  final int page;

  void dispose() => image.dispose();
}

/// The letters and digits of [s], lower case, and where each one sits in [s].
(String, List<int>) _lettersOf(String s) {
  final out = StringBuffer();
  final at = <int>[];
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    final lower = (c >= 0x41 && c <= 0x5A) ? c + 0x20 : c;
    if ((lower >= 0x61 && lower <= 0x7A) || (lower >= 0x30 && lower <= 0x39)) {
      out.writeCharCode(lower);
      at.add(i);
    }
  }
  return (out.toString(), at);
}

/// Where [quote] is in [pageText], as the first and last character index, or
/// null if it is not there. Only letters and digits count, so line breaks,
/// bullets and the spaced-out numbers PDFs leave do not stop a match. If the
/// whole quote is not found, its first or last 60 letters are tried.
(int, int)? findQuoteRange(String pageText, String quote) {
  final (hay, at) = _lettersOf(pageText);
  final (needle, _) = _lettersOf(quote);
  if (needle.length < 8) return null;
  for (final part in [
    needle,
    needle.substring(0, math.min(60, needle.length)),
    needle.substring(math.max(0, needle.length - 60)),
  ]) {
    final start = hay.indexOf(part);
    if (start >= 0) return (at[start], at[start + part.length - 1]);
  }
  return null;
}

/// [rects] as one box per line of text: boxes at about the same height are
/// joined. Empty boxes (spaces) and thin ones (a hyphen, a comma: PDFs report a
/// small box for each) are dropped; the letters around them cover them.
List<ui.Rect> mergeLines(List<ui.Rect> rects) {
  final heights = [for (final r in rects) if (r.width > 0 && r.height > 0) r.height]..sort();
  if (heights.isEmpty) return const [];
  final typical = heights[heights.length ~/ 2];
  final lines = <ui.Rect>[];
  for (final r in rects) {
    if (r.width <= 0 || r.height < typical * 0.6) continue;
    // The same line if the box sits mostly inside the line's height.
    final i = lines.indexWhere((l) => math.min(l.bottom, r.bottom) - math.max(l.top, r.top) > r.height * 0.5);
    if (i < 0) {
      lines.add(r);
    } else {
      lines[i] = lines[i].expandToInclude(r);
    }
  }
  return lines;
}

/// Draws page [pageNumber] (counting from 1) of the PDF at [path], [width] pixels
/// wide, and finds the boxes of [quote] on it. Null if the file or page is not
/// there or cannot be drawn.
Future<RenderedSlide?> renderSlide(String path, int pageNumber, {String quote = '', double width = 1100}) async {
  PdfDocument? doc;
  try {
    doc = await PdfDocument.openFile(path);
    if (pageNumber < 1 || pageNumber > doc.pages.length) return null;
    final page = doc.pages[pageNumber - 1];
    final height = width * page.height / page.width;
    final picture = await page.render(fullWidth: width, fullHeight: height);
    if (picture == null) return null;
    final image = await picture.createImage();
    picture.dispose();

    final boxes = <ui.Rect>[];
    if (quote.trim().isNotEmpty) {
      final text = await page.loadText();
      final range = text == null ? null : findQuoteRange(text.fullText, quote);
      if (text != null && range != null) {
        for (var i = range.$1; i <= range.$2 && i < text.charRects.length; i++) {
          boxes.add(text.charRects[i].toRect(page: page, scaledPageSize: ui.Size(width, height)));
        }
      }
    }
    return RenderedSlide(image, mergeLines(boxes), pageNumber);
  } catch (_) {
    return null; // a moved or damaged file: the viewer shows the page's text instead
  } finally {
    await doc?.dispose();
  }
}
