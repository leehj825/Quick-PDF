// Renders the REAL app screens (not mock-ups) with fictional sample documents into PNGs for the
// Play Store listing. Run from the repo root:
//   python3 tool/store/make_samples.py build/store/samples
//   flutter test tool/store/render_screens_test.dart
// Output: build/store/raw/<lang>_<name>.png (1080x2280)
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quick_pdf/l10n.dart';
import 'package:quick_pdf/main.dart';
import 'package:quick_pdf/models.dart';
import 'package:quick_pdf/screens/editor_screen.dart';
import 'package:quick_pdf/screens/page_editor_screen.dart';
import 'package:quick_pdf/screens/result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _samples = 'build/store/samples';
const _out = 'build/store/raw';
const _flutterFonts = '/opt/flutter/bin/cache/artifacts/material_fonts';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _settle(WidgetTester t) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 900)));
  await t.pump();
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await t.pump(const Duration(milliseconds: 800));
}

Future<void> _shot(WidgetTester t, GlobalKey key, String name) async {
  await _settle(t);
  await t.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(_out).createSync(recursive: true);
    File('$_out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<GlobalKey> _pump(WidgetTester t, String lang, {Widget? home, List<String> images = const [], int? resizeWidth}) async {
  t.view.physicalSize = const Size(1080, 2280); // 360x760 dp, a typical modern phone
  t.view.devicePixelRatio = 3.0;
  addTearDown(t.view.reset);
  if (images.isNotEmpty) {
    // Decode the sample photos BEFORE the screen is built: if the widget asks for them first, its
    // image request starts inside the fake-async zone and never completes in a widget test.
    await t.pumpWidget(const Directionality(textDirection: TextDirection.ltr, child: SizedBox()));
    final ctx = t.element(find.byType(SizedBox));
    await t.runAsync(() async {
      for (final p in images) {
        final file = FileImage(File(p));
        await precacheImage(resizeWidth == null ? file : ResizeImage(file, width: resizeWidth), ctx);
      }
    });
  }
  final key = GlobalKey();
  await t.pumpWidget(RepaintBoundary(
    key: key,
    child: QuickPdfApp(locale: Locale(lang), home: home, fontFamily: 'Roboto', fontFamilyFallback: const ['CJK']),
  ));
  return key;
}

List<String> _paths(List<PageItem> items) => [for (final i in items) i.path];

PageItem _img(int id, String file) => PageItem(id: id, path: '$_samples/$file.jpg');
PageItem _pdf(int id, String file) =>
    PageItem.pdfPage(id: id, thumbPath: '$_samples/$file.jpg', pdfPath: '/sample/$file.pdf', index: 0);

void main() {
  setUpAll(() async {
    await _loadFont('Roboto', ['$_flutterFonts/Roboto-Regular.ttf', '$_flutterFonts/Roboto-Bold.ttf']);
    await _loadFont('MaterialIcons', ['$_flutterFonts/MaterialIcons-Regular.otf']);
    await _loadFont('CJK', ['/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc']);
    // Ads plugin has no native side in tests; the banner just stays blank.
    // (The plugin uses its own message codec, so answer at the byte level: "success, null".)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'plugins.flutter.io/google_mobile_ads', (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null));
  });

  for (final lang in ['ko', 'en', 'ja', 'es']) {
    group(lang, () {
      testWidgets('home', (t) async {
        final dir = Directory('build/store/pdfs')..createSync(recursive: true);
        final now = DateTime(2026, 11, 26, 9, 12);
        final entries = [
          ['PDF_20261126_0912.pdf', 6, 1468006],
          ['Invoice_Sample.pdf', 2, 612352],
          ['Contract_Scan.pdf', 12, 3250585],
        ];
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({
          'quickpdf.history': jsonEncode([
            for (var i = 0; i < entries.length; i++)
              {
                'id': 'h$i',
                'name': entries[i][0],
                'path': (File('${dir.path}/h$i.pdf')..writeAsBytesSync([0])).path,
                'pages': entries[i][1],
                'size': entries[i][2],
                'createdAt': now.subtract(Duration(days: i * 2)).millisecondsSinceEpoch,
              }
          ]),
        });
        final key = await _pump(t, lang);
        await _shot(t, key, '${lang}_1_home');
      });

      testWidgets('editor grid', (t) async {
        final items = [_img(1, 'invoice'), _img(2, 'letter'), _img(3, 'receipt'), _img(4, 'idcard'), _img(5, 'form'), _img(6, 'invoice')];
        final key = await _pump(t, lang, home: EditorScreen(initialItems: items), images: _paths(items), resizeWidth: 360);
        await _shot(t, key, '${lang}_2_editor');
      });

      testWidgets('editor b&w filter on photos', (t) async {
        final items = [
          PageItem(id: 1, path: '$_samples/receipt_photo.jpg'),
          PageItem(id: 2, path: '$_samples/invoice_photo.jpg'),
          PageItem(id: 3, path: '$_samples/receipt_photo.jpg'),
          PageItem(id: 4, path: '$_samples/invoice_photo.jpg'),
        ];
        final key = await _pump(t, lang, home: EditorScreen(initialItems: items), images: _paths(items), resizeWidth: 360);
        await t.pump();
        await t.tap(find.text(S(lang)('fMono')));
        await _shot(t, key, '${lang}_3_filter');
      });

      testWidgets('single page editor', (t) async {
        final item = PageItem(id: 1, path: '$_samples/receipt_photo.jpg')
          ..brightness = 8
          ..contrast = 10;
        final key = await _pump(t, lang, home: PageEditorScreen(item: item, filter: DocFilter.mono), images: [item.path]);
        await _shot(t, key, '${lang}_4_page');
      });

      testWidgets('pdf merge', (t) async {
        final items = [_pdf(1, 'invoice'), _pdf(2, 'letter'), _pdf(3, 'form'), _pdf(4, 'receipt')];
        final key = await _pump(t, lang, home: EditorScreen(initialItems: items), images: _paths(items), resizeWidth: 360);
        await _shot(t, key, '${lang}_5_merge');
      });

      testWidgets('result', (t) async {
        final entry = HistoryEntry(id: 'r', name: 'PDF_20261126_0912.pdf', path: '/x.pdf', pages: 6, size: 1468006, createdAt: DateTime(2026, 11, 26));
        final key = await _pump(t, lang, home: ResultScreen(entry: entry));
        await _shot(t, key, '${lang}_6_result');
      });
    });
  }
}
