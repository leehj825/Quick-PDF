// Runs the REAL app (lib/main.dart) on an Android emulator and takes screenshots of it while it is
// operated: Home -> pick photos -> Editor -> filter -> per-page adjust -> convert -> result -> merge.
// Only the two system pickers (photo picker / file picker) are replaced by fakes that return the
// chosen files; everything else is the app's own code, services and navigation.
//
// CI: .github/workflows/store-screenshots.yml  (flutter drive, output in build/store/device/)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quick_pdf/main.dart' as app;
import 'package:quick_pdf/services/history_service.dart';

import 'sample_data.dart';

class _FakeImagePicker extends ImagePickerPlatform {
  List<String> next = [];
  @override
  Future<List<XFile>> getMultiImageWithOptions({MultiImagePickerOptions options = const MultiImagePickerOptions()}) async =>
      [for (final p in next) XFile(p)];
}

/// A picked file on local disk (PlatformFile is a `base` class, so it has to be extended).
final class _LocalFile extends PlatformFile {
  _LocalFile(this._path);
  final String _path;
  @override
  String get name => _path.split('/').last;
  @override
  Uri get uri => Uri.file(_path);
  @override
  XFile get xFile => XFile(_path);
  @override
  int? lengthSync() => File(_path).lengthSync();
  @override
  Future<int?> length() async => File(_path).length();
  @override
  Future<Uint8List> readAsBytes() => File(_path).readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() => File(_path).openRead().map(Uint8List.fromList);
}

class _FakeFilePicker extends FilePickerPlatform {
  List<String> next = [];
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async =>
      [for (final p in next) _LocalFile(p)];
}

// ignore: avoid_print
void step(String message) => print('STEP: $message'); // visible in logcat (tag: flutter)

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshots of the real app', (t) async {
    // --- sample documents (fictional) -> files on the device
    final dir = Directory('${Directory.systemTemp.path}/store_samples')..createSync(recursive: true);
    final f = <String, String>{};
    sampleJpegsBase64.forEach((name, b64) {
      f[name] = (File('${dir.path}/$name.jpg')..writeAsBytesSync(base64Decode(b64))).path;
    });
    expect(f.length, 6, reason: 'integration_test/sample_data.dart was not generated (tool/store/embed_samples.py)');

    final imagePicker = _FakeImagePicker();
    final filePicker = _FakeFilePicker();
    ImagePickerPlatform.instance = imagePicker;
    FilePickerPlatform.instance = filePicker;

    // --- helpers
    Future<void> wait(Duration d) async {
      final end = DateTime.now().add(d);
      while (DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await t.pump();
      }
    }

    Future<void> waitFor(Finder finder, {Duration timeout = const Duration(seconds: 120)}) async {
      step('waiting for $finder');
      final end = DateTime.now().add(timeout);
      while (finder.evaluate().isEmpty) {
        if (DateTime.now().isAfter(end)) throw TestFailure('timed out waiting for $finder');
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await t.pump();
      }
      await wait(const Duration(milliseconds: 400));
      step('found $finder');
    }

    Future<void> tap(Finder finder) async {
      await waitFor(finder);
      await t.ensureVisible(finder.first);
      await t.tap(finder.first);
      await wait(const Duration(milliseconds: 500));
    }

    Future<void> shot(String name, {Duration settle = const Duration(milliseconds: 1500)}) async {
      await wait(settle);
      step('screenshot $name');
      await binding.takeScreenshot(name);
      step('screenshot $name saved');
    }

    /// Home -> Gallery -> (fake picker) -> Editor -> [optional name] -> Create PDF -> Done -> Home
    Future<void> makePdf(List<String> pages, {String? name}) async {
      imagePicker.next = pages;
      await tap(find.text('Gallery'));
      await waitFor(find.text('${pages.length} pages'));
      await wait(const Duration(seconds: 2)); // let the thumbnails decode
      if (name != null) await t.enterText(find.byType(TextField), name);
      await tap(find.text('Create PDF'));
      await waitFor(find.text('Done!'));
      await tap(find.text('Home'));
    }

    // --- start the real app
    step('convert surface');
    await binding.convertFlutterSurfaceToImage();
    step('start app.main()');
    await app.main();
    step('app.main() returned');
    await wait(const Duration(seconds: 6));
    step('first frames done');

    step('make earlier PDFs');
    // 1) earlier work, so the Home screen has a real history
    await makePdf([f['invoice_photo']!, f['letter_photo']!], name: 'Invoice_Sample');
    await makePdf([f['receipt_photo']!, f['idcard_photo']!, f['form_photo']!], name: 'Contract_Scan');

    step('main flow');
    // 2) the main flow, with screenshots
    final six = [f['receipt_photo']!, f['invoice_photo']!, f['letter_photo']!, f['form_photo']!, f['idcard_photo']!, f['notes_photo']!];
    imagePicker.next = six;
    await tap(find.text('Gallery'));
    await waitFor(find.text('6 pages'));
    await shot('02-editor', settle: const Duration(seconds: 3));

    await tap(find.text('B&W'));
    await shot('03-filter');

    await tap(find.byType(ColorFiltered)); // first page thumbnail -> per-page editor
    await waitFor(find.text('Apply'));
    await t.drag(find.byType(Slider).first, const Offset(40, 0));
    await shot('04-adjust', settle: const Duration(seconds: 2));
    await tap(find.text('Apply'));

    await tap(find.text('Create PDF'));
    await waitFor(find.text('Done!'));
    await shot('06-share');
    await tap(find.text('Home'));

    // 3) Home with the three PDFs that were really created above
    await shot('01-home', settle: const Duration(seconds: 4));

    step('merge');
    // 4) merge two of those PDFs (PDF + PDF only -> lossless merge screen)
    final history = await HistoryService.load();
    expect(history.length, greaterThanOrEqualTo(3));
    filePicker.next = [history[0].path, history[1].path];
    await tap(find.byIcon(Icons.picture_as_pdf_outlined));
    await waitFor(find.textContaining('Merging PDFs only'));
    await shot('05-merge', settle: const Duration(seconds: 3));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
