import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models.dart';
import 'filters.dart';

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

class PdfService {
  static const double _margin = 24;

  /// Builds a PDF sequentially, one page at a time, then writes it to [outPath].
  static Future<int> build({
    required List<PageItem> pages,
    required PdfOptions options,
    required String outPath,
    void Function(int done, int total)? onProgress,
  }) async {
    final doc = pw.Document(compress: true);
    for (var i = 0; i < pages.length; i++) {
      onProgress?.call(i + 1, pages.length);
      final p = pages[i];
      final job = _PageJob(p.path, p.quarterTurns, p.brightness, p.contrast,
          options.filter, options.quality.maxEdge, options.quality.jpegQuality);
      final r = await Isolate.run(() => _processPage(job));
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
      doc.addPage(pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.all(m),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
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
