import 'package:material_ui/material_ui.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/history_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.entry, this.askReview = false});
  final HistoryEntry entry;
  final bool askReview;
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

  @override
  void initState() {
    super.initState();
    if (widget.askReview) {
      // Light in-app review on the 3rd success instead of an interstitial ad.
      Future.delayed(const Duration(milliseconds: 1200), () async {
        try {
          final r = InAppReview.instance;
          if (await r.isAvailable()) await r.requestReview();
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final e = widget.entry;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ScaleTransition(
                      scale: CurvedAnimation(parent: _ctl, curve: Curves.elasticOut),
                      child: const CircleAvatar(
                          radius: 40, backgroundColor: Color(0xFF10B981), child: Icon(Icons.check, size: 48, color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    Text(s('done'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(e.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${HistoryService.formatSize(e.size)} · ${s('pages', {'n': e.pages})}',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
              onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(e.path, mimeType: 'application/pdf')])),
              icon: const Icon(Icons.share),
              label: Text(s('share')),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => OpenFilex.open(e.path),
              child: Text(s('open')),
            ),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text(s('home')),
            ),
          ]),
        ),
      ),
    );
  }
}
