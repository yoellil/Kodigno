// The teacher's printable class report. It uses the app's own font file so
// Filipino names (ñ, é) print correctly; characters outside Latin-1 print as "?".
import 'dart:typed_data';

import 'package:flutter/services.dart' show ByteData, rootBundle;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'levels.dart';
import 'reading_repository.dart';

String _latin(String s) =>
    String.fromCharCodes(s.runes.map((r) => r < 256 ? r : 63));

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
String reportDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// The font the report is drawn with.
Future<ByteData> loadReportFont() => rootBundle.load('assets/fonts/BricolageGrotesque.ttf');

/// One page set: class summary, reading skills, then one row per reader.
/// Without [font] the PDF uses plain Helvetica, which may print accents wrongly.
Future<Uint8List> buildReportPdf(
  ClassReport rep, {
  required bool classroom,
  DateTime? now,
  ByteData? font,
}) {
  final ttf = font == null ? null : pw.Font.ttf(font);
  final doc = pw.Document(title: 'Kulay report', theme: ttf == null ? null : pw.ThemeData.withFont(base: ttf, bold: ttf));
  final dark = PdfColor.fromInt(0xFF2E2378),
      soft = PdfColor.fromInt(0xFF55507A);
  pw.TextStyle t(double size, {bool bold = false, PdfColor? color}) =>
      pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? dark,
      );

  final weak = rep.focus;
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Text(
          classroom ? 'Kulay class report' : 'Kulay progress report',
          style: t(24, bold: true),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${reportDate(now ?? DateTime.now())}  -  ${rep.readers.length} ${rep.readers.length == 1 ? 'reader' : 'readers'}',
          style: t(11, color: soft),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Reading skills (last 10 stories per reader)',
          style: t(14, bold: true),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Skill', 'Right', 'Answered', 'Percent'],
          data: [
            for (final k in rep.skills.keys)
              [
                k,
                '${rep.skills[k]!.$1}',
                '${rep.skills[k]!.$2}',
                rep.skills[k]!.$2 == 0
                    ? '-'
                    : '${(rep.skills[k]!.$1 * 100 / rep.skills[k]!.$2).round()}%',
              ],
          ],
          headerStyle: t(10, bold: true),
          cellStyle: t(10),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE3E0EF),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          weak == null
              ? 'No skill is under 70% yet.'
              : 'Teach next: ${weak.skill} (${weak.right} of ${weak.total} right).',
          style: t(11, bold: true),
        ),
        pw.SizedBox(height: 18),
        pw.Text('Readers', style: t(14, bold: true)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: [
            'Reader',
            'Color',
            'Stories',
            'Average',
            'Speed',
            'Recent scores',
            'Needs work on',
            'Status',
          ],
          data: [
            for (final r in rep.readers)
              [
                _latin(r.reader.name),
                r.reader.placed ? levels[r.reader.level].name : '-',
                '${r.stories}',
                r.avg == null ? '-' : '${r.avg}%',
                r.wpm == null ? '-' : '${r.wpm} wpm',
                // Oldest to newest, like the screen.
                r.recent.reversed.map((s) => '${s.pct}%').join('  '),
                r.needs == null
                    ? '-'
                    : '${r.needs!.skill} (${r.needs!.right}/${r.needs!.total})',
                readerStatus(r),
              ],
          ],
          headerStyle: t(10, bold: true),
          cellStyle: t(10),
          cellAlignment: pw.Alignment.centerLeft,
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE3E0EF),
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          'Scores stay on this computer. Speed is words a minute from timed stories.',
          style: t(9, color: soft),
        ),
      ],
    ),
  );
  return doc.save();
}
