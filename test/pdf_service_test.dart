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
}
