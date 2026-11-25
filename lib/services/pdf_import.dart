import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../models.dart';

class EncryptedPdfException implements Exception {
  const EncryptedPdfException();
}

/// Import PDF pages (as editable page items) and merge PDFs losslessly (PDFium).
class PdfImport {
  static int _seq = 0;

  /// Opens the system picker (no storage permission needed). Returns PDF file paths.
  static Future<List<String>> pickPdfPaths() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    return [for (final f in files) if (f.path != null) f.path!];
  }

  static Future<PdfDocument> _open(String path) async {
    try {
      // Password-protected PDFs are not supported: the provider returns null -> exception.
      return await PdfDocument.openFile(path, passwordProvider: () => null);
    } on PdfPasswordException {
      throw const EncryptedPdfException();
    }
  }

  /// Converts the pages of [paths] into page items with thumbnails. Stops after [maxPages].
  static Future<List<PageItem>> importPages(List<String> paths, {required int maxPages, required int Function() nextId}) async {
    final dir = Directory.systemTemp; // app cache dir on Android
    final items = <PageItem>[];
    for (final path in paths) {
      if (items.length >= maxPages) break;
      final doc = await _open(path);
      try {
        for (var i = 0; i < doc.pages.length && items.length < maxPages; i++) {
          final thumb = '${dir.path}/pdfthumb_${DateTime.now().microsecondsSinceEpoch}_${_seq++}.jpg';
          await _renderToJpeg(doc.pages[i], 420, 80, thumb);
          items.add(PageItem.pdfPage(id: nextId(), thumbPath: thumb, pdfPath: path, index: i));
        }
      } finally {
        doc.dispose();
      }
    }
    return items;
  }

  /// Renders one PDF page with its longest edge = [maxEdge] px into a temp JPEG. Caller deletes it.
  static Future<String> rasterize(PageItem item, int maxEdge) async {
    final dir = Directory.systemTemp; // app cache dir on Android
    final out = '${dir.path}/pdfpage_${DateTime.now().microsecondsSinceEpoch}_${_seq++}.jpg';
    final doc = await _open(item.pdfPath!);
    try {
      await _renderToJpeg(doc.pages[item.pdfPageIndex], maxEdge, 92, out);
    } finally {
      doc.dispose();
    }
    return out;
  }

  static Future<void> _renderToJpeg(PdfPage page, int maxEdge, int quality, String outPath) async {
    final k = maxEdge / (page.width > page.height ? page.width : page.height);
    final w = (page.width * k).round().clamp(1, 1 << 14), h = (page.height * k).round().clamp(1, 1 << 14);
    final image = await page.render(fullWidth: w.toDouble(), fullHeight: h.toDouble(), backgroundColor: 0xFFFFFFFF);
    if (image == null) throw const FormatException('render failed');
    try {
      final bgra = image.pixels;
      final iw = image.width, ih = image.height;
      final bytes = await Isolate.run(() {
        final im = img.Image.fromBytes(
            width: iw, height: ih, bytes: Uint8List.fromList(bgra).buffer, numChannels: 4, order: img.ChannelOrder.bgra);
        return Uint8List.fromList(img.encodeJpg(im, quality: quality));
      });
      await File(outPath).writeAsBytes(bytes, flush: true);
    } finally {
      image.dispose();
    }
  }

  /// PDF-only merge: pages are copied as-is (text/vector/quality kept), only order/rotation/removal applied.
  static Future<Uint8List> mergeLossless(List<PageItem> items) async {
    final docs = <String, PdfDocument>{};
    try {
      for (final it in items) {
        docs[it.pdfPath!] ??= await _open(it.pdfPath!);
      }
      final pages = <PdfPage>[
        for (final it in items)
          docs[it.pdfPath!]!.pages[it.pdfPageIndex].rotatedBy(PdfPageRotation.values[it.quarterTurns % 4]),
      ];
      final dest = docs[items.first.pdfPath!]!;
      dest.pages = pages;
      return await dest.encodePdf();
    } finally {
      for (final d in docs.values) {
        d.dispose();
      }
    }
  }
}
