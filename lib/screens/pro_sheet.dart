import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../services/pro_service.dart';

void showProSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ProSheet(),
  );
}

class _ProSheet extends StatelessWidget {
  const _ProSheet();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget row(String k) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
            const SizedBox(width: 10),
            Expanded(child: Text(s(k))),
          ]),
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: ValueListenableBuilder<bool>(
          valueListenable: ProService.instance.isPro,
          builder: (ctx, pro, _) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(s('proTitle'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            Text(s('proDesc'), style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            row('proF1'),
            row('proF2'),
            row('proF3'),
            const SizedBox(height: 16),
            if (pro)
              Text(s('proActive'), style: const TextStyle(fontWeight: FontWeight.w600))
            else ...[
              FilledButton(
                onPressed: () async {
                  final ok = await ProService.instance.buy();
                  if (!ok && ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(s('proUnavailable'))));
                  }
                },
                child: Text(s('buy')),
              ),
              TextButton(onPressed: ProService.instance.restore, child: Text(s('restore'))),
            ],
          ]),
        ),
      ),
    );
  }
}
