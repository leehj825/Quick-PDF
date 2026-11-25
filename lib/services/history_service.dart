import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

class HistoryService {
  static const _key = 'quickpdf.history';
  static const _countKey = 'quickpdf.successCount';

  static Future<Directory> pdfDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/pdfs');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<List<HistoryEntry>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .where((e) => File(e.path).existsSync())
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<HistoryEntry> l) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(l.map((e) => e.toJson()).toList()));
  }

  static Future<void> add(HistoryEntry e) async => _save([e, ...await load()]);

  static Future<void> remove(HistoryEntry e) async {
    try {
      File(e.path).deleteSync();
    } catch (_) {}
    await _save((await load()).where((x) => x.id != e.id).toList());
  }

  /// Returns the new count of successful conversions.
  static Future<int> bumpSuccessCount() async {
    final p = await SharedPreferences.getInstance();
    final n = (p.getInt(_countKey) ?? 0) + 1;
    await p.setInt(_countKey, n);
    return n;
  }

  /// Safe file name: strips path/illegal chars.
  static String sanitize(String name) {
    final s = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return s.isEmpty ? defaultName() : s;
  }

  static String defaultName() {
    final d = DateTime.now();
    String p(int n) => n.toString().padLeft(2, '0');
    return 'PDF_${d.year}${p(d.month)}${p(d.day)}_${p(d.hour)}${p(d.minute)}';
  }

  static String formatSize(int b) => b >= 1048576
      ? '${(b / 1048576).toStringAsFixed(1)} MB'
      : '${(b / 1024).round().clamp(1, 1 << 30)} KB';
}
