import 'package:material_ui/material_ui.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/ad_banner.dart';
import '../services/history_service.dart';
import '../services/reward_service.dart';
import '../services/pdf_import.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<HistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final h = await HistoryService.load();
    if (mounted) setState(() => _history = h);
  }

  int _id = 0;

  Future<void> _openEditor(List<String> paths) async {
    if (paths.isEmpty || !mounted) return;
    await _openItems([for (final p in paths) PageItem(id: _id++, path: p)]);
  }

  Future<void> _openItems(List<PageItem> items) async {
    if (items.isEmpty || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditorScreen(initialItems: items)));
    _reload();
  }

  Future<void> _importPdf() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final paths = await PdfImport.pickPdfPaths();
      if (paths.isEmpty) return;
      // Import up to a sane cap; the editor asks for a rewarded ad if it exceeds the free limit.
      final items = await PdfImport.importPages(paths, maxPages: 60, nextId: () => _id++);
      await _openItems(items);
    } on EncryptedPdfException {
      messenger.showSnackBar(SnackBar(content: Text(s('pdfEncrypted'))));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(s('pdfFailed'))));
    }
  }

  Future<void> _pickGallery() async {
    final files = await ImagePicker().pickMultiImage();
    await _openEditor(files.map((e) => e.path).toList());
  }

  Future<void> _scan() async {
    final s = S.of(context);
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: RewardService.freePageLimit,
        isGalleryImport: false,
      ),
    );
    try {
      final r = await scanner.scanDocument();
      await _openEditor(r.images ?? []);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('noScan'))));
    } finally {
      scanner.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s('title'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _history.isEmpty ? _empty(s) : _list(s),
      bottomNavigationBar: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // >=16dp safe gap above the ad
            child: Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _pickGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(s('gallery')),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 56,
                height: 52,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(minimumSize: const Size(56, 52), padding: EdgeInsets.zero),
                  onPressed: _scan,
                  child: Tooltip(message: s('scan'), child: const Icon(Icons.document_scanner_outlined)),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                height: 52,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(minimumSize: const Size(56, 52), padding: EdgeInsets.zero),
                  onPressed: _importPdf,
                  child: Tooltip(message: s('importPdf'), child: const Icon(Icons.picture_as_pdf_outlined)),
                ),
              ),
            ]),
          ),
          const AdBanner(),
        ]),
      ),
    );
  }

  Widget _empty(S s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.picture_as_pdf_outlined, size: 88, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(s('emptyTitle'),
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(s('emptySub'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ]),
        ),
      );

  Widget _list(S s) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Text(s('recent'), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600));
          }
          final h = _history[i - 1];
          return Card(
            child: ListTile(
              minTileHeight: 64,
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFE11D48)),
              title: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              isThreeLine: true,
              // Two short lines instead of one long line that wrapped mid-word ("6페이/지").
              subtitle: Text(
                  '${h.createdAt.toLocal().toString().substring(0, 10)}\n${s('pages', {'n': h.pages})} · ${HistoryService.formatSize(h.size)}'),
              onTap: () => OpenFilex.open(h.path),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(h.path, mimeType: 'application/pdf')])),
                ),
                PopupMenuButton<String>(
                  onSelected: (_) async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        content: Text(s('confirmDel')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s('cancel'))),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(s('delete'))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await HistoryService.remove(h);
                      _reload();
                    }
                  },
                  itemBuilder: (_) => [PopupMenuItem(value: 'del', child: Text(s('delete')))],
                ),
              ]),
            ),
          );
        },
      );
}

