import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models.dart';
import 'filters.dart';
import 'pdf_import.dart';

class _PageJob {
  _PageJob(this.path, this.turns, this.brightness, this.contrast, this.filter,
      this.maxEdge, this.jpegQuality);
  final String path;
  final int turns, brightness, contrast, maxEdge, jpegQuality;
  final DocFilter filter;
}

class _PageResult {
  _PageResult(this.jpeg, this.width, this.height);
  final Uint8List jpeg;
  final int width, height;
}

/// Runs in a background isolate: decode → orient → rotate → resize → filter → JPEG.
_PageResult _processPage(_PageJob j) {
  var image = img.decodeImage(File(j.path).readAsBytesSync());
  if (image == null) throw const FormatException('decode failed');
  image = img.bakeOrientation(image);
  if (j.turns % 4 != 0) image = img.copyRotate(image, angle: 90.0 * (j.turns % 4));

  final longEdge = image.width > image.height ? image.width : image.height;
  if (longEdge > j.maxEdge) {
    image = image.width >= image.height
        ? img.copyResize(image, width: j.maxEdge, interpolation: img.Interpolation.average)
        : img.copyResize(image, height: j.maxEdge, interpolation: img.Interpolation.average);
  }

  if (j.filter != DocFilter.original || j.brightness != 0 || j.contrast != 0) {
    _applyMatrix(image, buildColorMatrix(j.filter, j.brightness, j.contrast));
  }
  final out = Uint8List.fromList(img.encodeJpg(image, quality: j.jpegQuality));
  return _PageResult(out, image.width, image.height);
}

void _applyMatrix(img.Image im, List<double> m) {
  for (final p in im) {
    final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
    p
      ..r = (m[0] * r + m[1] * g + m[2] * b + m[4]).clamp(0, 255)
      ..g = (m[5] * r + m[6] * g + m[7] * b + m[9]).clamp(0, 255)
      ..b = (m[10] * r + m[11] * g + m[12] * b + m[14]).clamp(0, 255);
  }
}

/// Latin-1 only: the built-in Helvetica font cannot encode other scripts.
String _latin1(String t) => String.fromCharCodes(t.runes.where((c) => c >= 0x20 && c < 0x100));

void _paintTextLayer(PdfGraphics canvas, pw.Document doc, List<OcrLine> lines, double k, int imgH) {
  final font = PdfFont.helvetica(doc.document);
  for (final l in lines) {
    final text = _latin1(l.text).trim();
    if (text.isEmpty || l.width <= 0 || l.height <= 0) continue;
    final size = (l.height * k * 0.85).clamp(1.0, 200.0);
    final natural = font.stringMetrics(text).width * size;
    if (natural <= 0) continue;
    final hScale = (l.width * k) / natural; // stretch glyph run to the detected line width
    canvas.drawString(
      font,
      size,
      text,
      l.left * k,
      (imgH - (l.top + l.height)) * k + l.height * k * 0.2, // approx. baseline
      scale: hScale,
      mode: PdfTextRenderingMode.invisible,
    );
  }
}

class PdfService {
  static const double _margin = 24;

  /// Builds a PDF sequentially, one page at a time, then writes it to [outPath].
  static Future<int> build({
    required List<PageItem> pages,
    required PdfOptions options,
    required String outPath,
    void Function(int done, int total)? onProgress,
    Future<List<OcrLine>> Function(Uint8List jpeg)? recognize,
  }) async {
    final doc = pw.Document(compress: true);
    for (var i = 0; i < pages.length; i++) {
      onProgress?.call(i + 1, pages.length);
      final p = pages[i];
      // Imported PDF pages are rasterized (at the chosen quality) so they can be mixed with photos.
      final src = p.isPdfPage ? await PdfImport.rasterize(p, options.quality.maxEdge) : p.path;
      final job = _PageJob(src, p.quarterTurns, p.brightness, p.contrast,
          options.filter, options.quality.maxEdge, options.quality.jpegQuality);
      final _PageResult r;
      try {
        r = await Isolate.run(() => _processPage(job));
      } finally {
        if (p.isPdfPage) File(src).deleteSync();
      }
      final image = pw.MemoryImage(r.jpeg);
      final m = options.margin ? _margin : 0.0;

      final PdfPageFormat format;
      if (options.pageSize == PageSizeMode.original) {
        format = PdfPageFormat(r.width + m * 2, r.height + m * 2);
      } else {
        final landscape = r.width > r.height;
        final w = options.pageSize.width, h = options.pageSize.height;
        format = landscape ? PdfPageFormat(h, w) : PdfPageFormat(w, h);
      }
      final lines = options.ocr && recognize != null ? await recognize(r.jpeg) : const <OcrLine>[];

      // Image rect inside the page's printable area (contain).
      final availW = format.width - m * 2, availH = format.height - m * 2;
      final k = (availW / r.width) < (availH / r.height) ? availW / r.width : availH / r.height;
      final w = r.width * k, h = r.height * k;
      final left = m + (availW - w) / 2, top = m + (availH - h) / 2;

      doc.addPage(pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Stack(children: [
          pw.Positioned(
            left: left,
            top: top,
            child: pw.SizedBox(
              width: w,
              height: h,
              child: pw.Stack(children: [
                pw.Positioned.fill(child: pw.Image(image, fit: pw.BoxFit.fill)),
                if (lines.isNotEmpty)
                  pw.Positioned.fill(
                    child: pw.CustomPaint(painter: (canvas, size) => _paintTextLayer(canvas, doc, lines, k, r.height)),
                  ),
              ]),
            ),
          ),
        ]),
      ));
    }
    final bytes = await doc.save();
    await File(outPath).writeAsBytes(bytes, flush: true);
    return bytes.length;
  }

  /// Rough estimate (no rendering) shown before conversion.
  static int estimateSize(List<PageItem> pages, Quality q) {
    var total = 0;
    for (final p in pages) {
      try {
        total += File(p.path).lengthSync();
      } catch (_) {}
    }
    final ratio = switch (q) { Quality.high => 0.9, Quality.standard => 0.45, Quality.low => 0.18 };
    final capped = pages.length * (q.maxEdge * q.maxEdge * 0.35 * q.jpegQuality / 100);
    final est = total * ratio;
    return (est < capped ? est : capped).round().clamp(20 * 1024, 1 << 31);
  }
}
