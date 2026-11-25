import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:image/image.dart' as img;
import 'package:quick_pdf/models.dart';
import 'package:quick_pdf/services/pdf_service.dart';
import 'package:quick_pdf/services/pdf_import.dart';

Future<String> _makePdf(Directory d, String name, List<String> pageTexts) async {
  final doc = pw.Document();
  for (final t in pageTexts) {
    doc.addPage(pw.Page(build: (_) => pw.Center(child: pw.Text(t, style: const pw.TextStyle(fontSize: 40)))));
  }
  final f = File('${d.path}/$name.pdf')..writeAsBytesSync(await doc.save());
  return f.path;
}

void main() {
  late Directory tmp;
  var pdfiumOk = true;

  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('qmerge');
    try {
      await pdfrxInitialize();
    } catch (e) {
      pdfiumOk = false;
      // ignore: avoid_print
      print('PDFium unavailable in this environment: $e');
    }
  });
  tearDownAll(() => tmp.deleteSync(recursive: true));

  test('PDF + PDF merges losslessly: order, removal, rotation, text preserved', () async {
    if (!pdfiumOk) {
      markTestSkipped('PDFium could not be initialized');
      return;
    }
    final a = await _makePdf(tmp, 'a', ['Alpha one', 'Alpha two']);
    final b = await _makePdf(tmp, 'b', ['Bravo one']);
    final items = [
      PageItem.pdfPage(id: 1, thumbPath: '', pdfPath: b, index: 0), // B first
      PageItem.pdfPage(id: 2, thumbPath: '', pdfPath: a, index: 1), // A page 2 (A page 1 removed)
    ]..[1].quarterTurns = 1; // rotate second

    final bytes = await PdfImport.mergeLossless(items);
    final out = File('${tmp.path}/merged.pdf')..writeAsBytesSync(bytes);

    final r = await Process.run('pdftotext', ['-layout', out.path, '-']);
    final text = r.stdout as String;
    expect(text, contains('Bravo one'));
    expect(text, contains('Alpha two'));
    expect(text, isNot(contains('Alpha one'))); // removed page is gone
    expect(text.indexOf('Bravo'), lessThan(text.indexOf('Alpha two'))); // order kept

    final info = (await Process.run('pdfinfo', ['-f', '1', '-l', '2', out.path])).stdout as String;
    expect(RegExp(r'Pages:\s+2').hasMatch(info), isTrue);
    expect(RegExp(r'Page\s+2 rot:\s+90').hasMatch(info), isTrue); // rotation applied
    expect(RegExp(r'Page\s+1 rot:\s+0').hasMatch(info), isTrue);
  });

  test('Photo + PDF page is rasterized into one image-based PDF (default Letter)', () async {
    if (!pdfiumOk) {
      markTestSkipped('PDFium could not be initialized');
      return;
    }
    final a = await _makePdf(tmp, 'mix', ['Rasterized text']);
    final photo = img.Image(width: 800, height: 600);
    img.fill(photo, color: img.ColorRgb8(30, 120, 200));
    final photoPath = '${tmp.path}/photo.jpg';
    File(photoPath).writeAsBytesSync(img.encodeJpg(photo));

    final items = [
      PageItem(id: 1, path: photoPath),
      PageItem.pdfPage(id: 2, thumbPath: '', pdfPath: a, index: 0),
    ];
    final out = '${tmp.path}/mixed.pdf';
    int leftovers() => Directory.systemTemp.listSync().where((e) => e.path.contains('pdfpage_')).length;
    final before = leftovers();
    await PdfService.build(pages: items, options: const PdfOptions(), outPath: out);

    final info = (await Process.run('pdfinfo', [out])).stdout as String;
    expect(RegExp(r'Pages:\s+2').hasMatch(info), isTrue);
    expect(RegExp(r'Page size:\s+792 x 612').hasMatch(info), isTrue); // landscape photo on Letter
    final text = (await Process.run('pdftotext', [out, '-'])).stdout as String;
    expect(text.trim(), isEmpty); // PDF page became an image (no live text)
    expect(leftovers(), before); // temp rasterized pages cleaned up
  });
}
