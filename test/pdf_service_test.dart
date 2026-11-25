import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:quick_pdf/models.dart';
import 'package:quick_pdf/services/filters.dart';
import 'package:quick_pdf/services/pdf_service.dart';

void main() {
  late Directory tmp;
  late List<PageItem> pages;

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('qpdf');
    pages = [];
    for (var i = 0; i < 3; i++) {
      final w = i == 1 ? 2000 : 1200, h = i == 1 ? 1200 : 1800; // page 2 is landscape
      final im = img.Image(width: w, height: h);
      img.fill(im, color: img.ColorRgb8(200, 60 + i * 50, 90));
      final f = File('${tmp.path}/p$i.jpg')..writeAsBytesSync(img.encodeJpg(im));
      pages.add(PageItem(id: i, path: f.path));
    }
  });
  tearDownAll(() => tmp.deleteSync(recursive: true));

  test('default page size is Letter', () {
    expect(const PdfOptions().pageSize, PageSizeMode.letter);
    expect(PageSizeMode.letter.width, 612);
    expect(PageSizeMode.letter.height, 792);
  });

  test('builds Letter PDF sequentially with portrait/landscape pages', () async {
    final progress = <int>[];
    final out = '${tmp.path}/out.pdf';
    final size = await PdfService.build(
      pages: pages,
      options: const PdfOptions(),
      outPath: out,
      onProgress: (d, t) => progress.add(d),
    );
    expect(progress, [1, 2, 3]);
    final bytes = File(out).readAsBytesSync();
    expect(size, bytes.length);
    final text = String.fromCharCodes(bytes);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(text).length, 3);
    final boxes = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]').allMatches(text).map((m) => '${m[1]}x${m[2]}').toList();
    expect(boxes, ['612x792', '792x612', '612x792']);
  });

  test('A4 and rotation/filters/low quality work', () async {
    pages[0].quarterTurns = 1; // portrait -> landscape
    final out = '${tmp.path}/a4.pdf';
    await PdfService.build(
      pages: pages.take(1).toList(),
      options: const PdfOptions(quality: Quality.low, filter: DocFilter.mono, pageSize: PageSizeMode.a4),
      outPath: out,
    );
    final text = String.fromCharCodes(File(out).readAsBytesSync());
    expect(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]').firstMatch(text)![1], startsWith('841.89'));
  });

  test('mono matrix has zero saturation and boosted contrast', () {
    final m = buildColorMatrix(DocFilter.mono, 0, 0);
    expect(m[0], closeTo(m[5], 1e-9)); // grayscale rows identical
    expect(m[0], greaterThan(0.4));
    expect(buildColorMatrix(DocFilter.original, 0, 0), [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]);
  });

  test('OCR adds an invisible, correctly positioned text layer (searchable PDF)', () async {
    final out = '${tmp.path}/ocr.pdf';
    // Standard quality downsizes 1200x1800 -> 1067x1600 (OCR coords are in that space).
    // Letter 612x792 contain => k = 792/1600, image ~528x792 centered.
    final p0 = PageItem(id: 99, path: pages[0].path); // unrotated
    await PdfService.build(
      pages: [p0],
      options: const PdfOptions(ocr: true),
      outPath: out,
      recognize: (_) async => [
        const OcrLine('Hello World', 120, 300, 600, 90), // px in the 1067x1600 processed image
        const OcrLine('한글 only café', 120, 900, 700, 80), // non-Latin-1 chars must not break
      ],
    );
    ProcessResult r;
    try {
      r = await Process.run('pdftotext', ['-bbox', out, '-']);
    } on ProcessException {
      markTestSkipped('pdftotext (poppler) not installed');
      return;
    }
    expect(r.exitCode, 0);
    final text = r.stdout as String;
    expect(text, contains('>Hello<'));
    expect(text, contains('>World<'));
    expect(text, contains('>café<'));
    final m = RegExp(r'xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">Hello<').firstMatch(text)!;
    final k = 792 / 1600, offX = (612 - 1067 * k) / 2;
    expect(double.parse(m[1]!), closeTo(offX + 120 * k, 2)); // left edge
    final w = RegExp(r'xMax="([\d.]+)" yMax="[\d.]+">World<').firstMatch(text)!;
    expect(double.parse(w[1]!) - double.parse(m[1]!), closeTo(600 * k, 3)); // line stretched to detected width
    expect(double.parse(m[2]!), closeTo(300 * k, 12)); // top edge (from page top, incl. ascender)
    // Image is still drawn and nothing visible was added: the page has an image, text is invisible.
    expect(RegExp(r'/Subtype\s*/Image').hasMatch(String.fromCharCodes(File(out).readAsBytesSync())), isTrue);
  });

  test('OCR off ignores recognizer', () async {
    var called = false;
    await PdfService.build(
      pages: [PageItem(id: 98, path: pages[0].path)],
      options: const PdfOptions(),
      outPath: '${tmp.path}/noocr.pdf',
      recognize: (_) async {
        called = true;
        return [];
      },
    );
    expect(called, isFalse);
  });
}
