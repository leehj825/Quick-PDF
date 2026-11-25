import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_cropper/image_cropper.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/filters.dart';

/// Single page editor: live GPU preview via ColorFiltered, edits mutate [item].
class PageEditorScreen extends StatefulWidget {
  const PageEditorScreen({super.key, required this.item, required this.filter});
  final PageItem item;
  final DocFilter filter;
  @override
  State<PageEditorScreen> createState() => _PageEditorScreenState();
}

class _PageEditorScreenState extends State<PageEditorScreen> {
  late final String _origPath = widget.item.path;
  late String _path = widget.item.path;
  late int _turns = widget.item.quarterTurns;
  late int _b = widget.item.brightness;
  late int _c = widget.item.contrast;

  Future<void> _crop() async {
    final s = S.of(context);
    final cropped = await ImageCropper().cropImage(
      sourcePath: _path,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: s('cropTitle'), toolbarColor: const Color(0xFF1E1B4B), toolbarWidgetColor: Colors.white),
      ],
    );
    if (cropped != null) setState(() => _path = cropped.path);
  }

  void _apply() {
    widget.item
      ..path = _path
      ..quarterTurns = _turns
      ..brightness = _b
      ..contrast = _c;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget slider(String label, int v, ValueChanged<int> on) => Row(children: [
          SizedBox(width: 56, child: Text(label)),
          Expanded(
            child: Slider(value: v.toDouble(), min: -50, max: 50, divisions: 100, label: '$v', onChanged: (x) => setState(() => on(x.round()))),
          ),
          SizedBox(width: 32, child: Text('$v', textAlign: TextAlign.end)),
        ]);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [TextButton(onPressed: _apply, child: Text(s('apply'), style: const TextStyle(color: Colors.white, fontSize: 16)))],
      ),
      body: Column(children: [
        Expanded(
          child: Container(
            color: Colors.black,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: InteractiveViewer(
              child: ColorFiltered(
                colorFilter: buildColorFilter(widget.filter, _b, _c),
                child: RotatedBox(quarterTurns: _turns, child: Image.file(File(_path), fit: BoxFit.contain)),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              slider(s('brightness'), _b, (x) => _b = x),
              slider(s('contrast'), _c, (x) => _c = x),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _action(Icons.rotate_right, s('rotate'), () => setState(() => _turns = (_turns + 1) % 4)),
                if (!widget.item.isPdfPage) _action(Icons.crop, s('crop'), _crop),
                _action(Icons.restart_alt, s('reset'), () => setState(() {
                      _path = _origPath;
                      _turns = 0;
                      _b = 0;
                      _c = 0;
                    })),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _action(IconData i, String t, VoidCallback on) => InkWell(
        onTap: on,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 72, minHeight: 56),
          child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i),
            Text(t, style: const TextStyle(fontSize: 12)),
          ]),
        ),
      );
}
