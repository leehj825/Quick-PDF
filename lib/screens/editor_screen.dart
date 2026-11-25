import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/filters.dart';
import '../services/history_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';
import '../services/reward_service.dart';
import '../services/pdf_import.dart';
import 'page_editor_screen.dart';
import 'reward_sheet.dart';
import 'result_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.initialItems});
  final List<PageItem> initialItems;
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final List<PageItem> _pages = [];
  int _nextId = 0;
  final _name = TextEditingController(text: HistoryService.defaultName());
  Quality _quality = Quality.standard;
  DocFilter _filter = DocFilter.original;
  PageSizeMode _size = PageSizeMode.letter; // default: Letter
  bool _margin = false;
  bool _ocr = false; // searchable PDF (English); needs a rewarded-ad credit
  bool _premium = false; // this conversion uses a credit (OCR and/or more than the free page limit)
  final List<PageItem> _pendingExtra = []; // pages beyond the free limit awaiting an ad
  ({int done, int total})? _progress;

  int get _limit => _premium ? 1 << 30 : RewardService.freePageLimit;

  /// Reserves a credit for this conversion (asks for a rewarded ad if there is none).
  Future<bool> _ensurePremium(String reasonKey) async {
    if (_premium) return true;
    if (RewardService.instance.credits.value > 0) {
      setState(() => _premium = true);
      return true;
    }
    final ok = await showRewardSheet(context, reasonKey: reasonKey);
    if (ok && mounted) setState(() => _premium = true);
    return ok;
  }

  Future<void> _offerExtra() async {
    if (_pendingExtra.isEmpty) return;
    final extra = List<PageItem>.of(_pendingExtra);
    _pendingExtra.clear();
    if (await _ensurePremium('rewardReasonLimit') && mounted) _addItems(extra);
  }

  @override
  void initState() {
    super.initState();
    _addItems(widget.initialItems, notify: false);
  }

  // (extra pages beyond the free limit are offered via a rewarded ad after the first frame)

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// True when every page is an imported PDF page: they are merged as-is (lossless).
  bool get _lossless => _pages.isNotEmpty && _pages.every((p) => p.isPdfPage);

  void _addPaths(List<String> paths, {bool notify = true}) =>
      _addItems([for (final p in paths) PageItem(id: 0, path: p)], notify: notify);

  void _addItems(List<PageItem> items, {bool notify = true}) {
    final room = _limit - _pages.length;
    final add = items.take(room < 0 ? 0 : room).toList();
    final extra = items.skip(add.length).toList();
    for (final it in add) {
      it.id = _nextId++;
    }
    if (notify) {
      setState(() => _pages.addAll(add));
    } else {
      _pages.addAll(add);
    }
    if (extra.isNotEmpty) {
      _pendingExtra.addAll(extra);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _offerExtra();
      });
    }
  }

  Future<void> _addMore() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(s('gallery')),
              onTap: () => Navigator.pop(c, 'gallery')),
          ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(s('scan')),
              onTap: () => Navigator.pop(c, 'scan')),
          ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(s('importPdf')),
              onTap: () => Navigator.pop(c, 'pdf')),
        ]),
      ),
    );
    if (choice == 'gallery') {
      final f = await ImagePicker().pickMultiImage();
      _addPaths(f.map((e) => e.path).toList());
    } else if (choice == 'pdf') {
      try {
        final paths = await PdfImport.pickPdfPaths();
        if (paths.isEmpty) return;
        final items = await PdfImport.importPages(paths, maxPages: 60, nextId: () => 0);
        _addItems(items);
      } on EncryptedPdfException {
        messenger.showSnackBar(SnackBar(content: Text(s('pdfEncrypted'))));
      } catch (_) {
        messenger.showSnackBar(SnackBar(content: Text(s('pdfFailed'))));
      }
    } else if (choice == 'scan') {
      final scanner = DocumentScanner(
          options: DocumentScannerOptions(documentFormats: {DocumentFormat.jpeg}, isGalleryImport: false));
      try {
        final r = await scanner.scanDocument();
        _addPaths(r.images ?? []);
      } catch (_) {} finally {
        scanner.close();
      }
    }
  }

  Future<void> _make() async {
    final s = S.of(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final useOcr = _ocr && _premium;
    final usesPremium = _premium && (useOcr || _pages.length > RewardService.freePageLimit);
    final ocr = useOcr ? OcrService() : null;
    try {
      setState(() => _progress = (done: 0, total: _pages.length));
      final dir = await HistoryService.pdfDir();
      final name = HistoryService.sanitize(_name.text);
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final path = '${dir.path}/$id.pdf';
      final int size;
      if (_lossless) {
        // PDF + PDF only: copy pages as-is.
        final bytes = await PdfImport.mergeLossless(_pages);
        await File(path).writeAsBytes(bytes, flush: true);
        size = bytes.length;
      } else {
        size = await PdfService.build(
          pages: _pages,
          options: PdfOptions(quality: _quality, filter: _filter, pageSize: _size, margin: _margin, ocr: useOcr),
          outPath: path,
          recognize: ocr?.recognize,
          onProgress: (d, t) => mounted ? setState(() => _progress = (done: d, total: t)) : null,
        );
      }
      final entry = HistoryEntry(
          id: id, name: '$name.pdf', path: path, pages: _pages.length, size: size, createdAt: DateTime.now());
      await HistoryService.add(entry);
      if (usesPremium) await RewardService.instance.consume(); // only when a premium feature was really used
      final count = await HistoryService.bumpSuccessCount();
      nav.pushReplacement(MaterialPageRoute(builder: (_) => ResultScreen(entry: entry, askReview: count == 3)));
    } on EncryptedPdfException {
      messenger.showSnackBar(SnackBar(content: Text(s('pdfEncrypted'))));
      if (mounted) setState(() => _progress = null);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(s('error'))));
      if (mounted) setState(() => _progress = null);
    } finally {
      await ocr?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final busy = _progress != null;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s('total', {'n': _pages.length}), style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            TextButton.icon(
              onPressed: busy ? null : _addMore,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(s('add'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: ReorderableGridView.builder(
              padding: const EdgeInsets.all(12),
              dragEnabled: !busy,
              dragStartDelay: const Duration(milliseconds: 250),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: _pages.length,
              onDragStart: (_) => HapticFeedback.mediumImpact(),
              onReorder: (o, n) => setState(() => _pages.insert(n, _pages.removeAt(o))),
              itemBuilder: (_, i) => _thumb(_pages[i], i),
            ),
          ),
          Material(
            elevation: 8,
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SingleChildScrollView(child: _panel(s, busy)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _thumb(PageItem p, int i) {
    return GestureDetector(
      key: ValueKey(p.id),
      onTap: _progress != null || _lossless
          ? null
          : () async {
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => PageEditorScreen(item: p, filter: _filter)));
              setState(() {});
            },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(fit: StackFit.expand, children: [
          ColoredBox(
            color: Colors.black12,
            child: ColorFiltered(
              colorFilter: _lossless ? const ColorFilter.mode(Colors.transparent, BlendMode.dst) : buildColorFilter(_filter, p.brightness, p.contrast),
              child: RotatedBox(
                quarterTurns: p.quarterTurns,
                child: Image.file(File(p.path), fit: BoxFit.cover, cacheWidth: 360),
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 6,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          if (_lossless)
            Positioned(
              left: 0,
              bottom: 0,
              child: InkResponse(
                radius: 24,
                onTap: _progress != null ? null : () => setState(() => p.quarterTurns = (p.quarterTurns + 1) % 4),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircleAvatar(radius: 14, backgroundColor: Colors.black54, child: Icon(Icons.rotate_right, size: 18, color: Colors.white)),
                ),
              ),
            ),
          Positioned(
            right: 0,
            top: 0,
            child: InkResponse(
              radius: 24,
              onTap: _progress != null
                  ? null
                  : () {
                      setState(() => _pages.remove(p));
                      if (_pages.isEmpty) Navigator.of(context).pop();
                    },
              child: const Padding(
                padding: EdgeInsets.all(12), // 48dp touch area with 24dp icon
                child: CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _nameField(S s, bool busy) => TextField(
        controller: _name,
        enabled: !busy,
        decoration: InputDecoration(
          labelText: s('filename'),
          suffixText: '.pdf',
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _panel(S s, bool busy) {
    final est = PdfService.estimateSize(_pages, _quality);
    Widget label(String t, [String? trailing]) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        );
    Widget seg<T>(T value, Map<T, String> opts, ValueChanged<T> on) => SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 44))),
            segments: [for (final e in opts.entries) ButtonSegment(value: e.key, label: Text(e.value, maxLines: 1, overflow: TextOverflow.ellipsis))],
            selected: {value},
            onSelectionChanged: busy ? null : (v) => setState(() => on(v.first)),
          ),
        );
    if (_lossless) {
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(s('pdfMergeNote'), style: const TextStyle(fontSize: 13))),
          ]),
        ),
        _nameField(s, busy),
        const SizedBox(height: 12),
        FilledButton(onPressed: busy || _pages.isEmpty ? null : _make, child: Text(busy ? s('progress', {'a': _progress!.done, 'b': _progress!.total}) : s('make'))),
        if (busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
      ]);
    }
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      label(s('filter')),
      seg(_filter, {DocFilter.original: s('fOriginal'), DocFilter.vivid: s('fVivid'), DocFilter.mono: s('fMono')}, (v) => _filter = v),
      label(s('quality'), '${s('estimate')}: ≈ ${HistoryService.formatSize(est)}'),
      seg(_quality, {Quality.high: s('qHigh'), Quality.standard: s('qStd'), Quality.low: s('qLow')}, (v) => _quality = v),
      label(s('pageSize')),
      seg(_size, {PageSizeMode.letter: s('letter'), PageSizeMode.a4: s('a4'), PageSizeMode.original: s('original')}, (v) => _size = v),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _name,
            enabled: !busy,
            decoration: InputDecoration(
              labelText: s('filename'),
              suffixText: '.pdf',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: Text(s('margin')),
          selected: _margin,
          onSelected: busy ? null : (v) => setState(() => _margin = v),
        ),
      ]),
      ValueListenableBuilder<int>(
        valueListenable: RewardService.instance.credits,
        builder: (ctx, credits, _) {
          final unlocked = _premium || credits > 0;
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Row(children: [
              Flexible(child: Text(s('ocr'), style: const TextStyle(fontWeight: FontWeight.w600))),
              if (!unlocked)
                const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.ondemand_video, size: 16, color: Color(0xFF2563EB))),
            ]),
            subtitle: Text(unlocked ? s('ocrSub') : s('adUnlock'), style: const TextStyle(fontSize: 12)),
            value: _ocr,
            onChanged: busy
                ? null
                : (v) async {
                    if (!v) {
                      setState(() => _ocr = false);
                    } else if (await _ensurePremium('rewardReasonOcr')) {
                      setState(() => _ocr = true);
                    }
                  },
          );
        },
      ),
      const SizedBox(height: 4),
      FilledButton(
        onPressed: busy || _pages.isEmpty ? null : _make,
        child: Text(busy ? s('progress', {'a': _progress!.done, 'b': _progress!.total}) : s('make')),
      ),
      if (busy)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(value: _progress!.total == 0 ? null : _progress!.done / _progress!.total),
        ),
    ]);
  }
}
