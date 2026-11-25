import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../services/reward_service.dart';

/// Asks the user to watch a rewarded ad for one use of the premium features.
/// Returns true if the reward was earned (a credit is granted).
Future<bool> showRewardSheet(BuildContext context, {required String reasonKey}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => _RewardSheet(reasonKey),
  );
  return r == true;
}

class _RewardSheet extends StatefulWidget {
  const _RewardSheet(this.reasonKey);
  final String reasonKey;
  @override
  State<_RewardSheet> createState() => _RewardSheetState();
}

class _RewardSheetState extends State<_RewardSheet> {
  bool _loading = false;
  bool _failed = false;

  Future<void> _watch() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final ok = await RewardService.instance.watchAd();
    if (!mounted) return;
    if (ok) {
      await RewardService.instance.grant();
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.play_circle_outline, size: 30, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(child: Text(s('rewardTitle'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 10),
          Text(s(widget.reasonKey, {'n': RewardService.freePageLimit})),
          const SizedBox(height: 6),
          Text(s('rewardDesc'), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(s('adNotReady'), style: const TextStyle(color: Color(0xFFE11D48))),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _watch,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.ondemand_video),
            label: Text(s('watchAd')),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _loading ? null : () => Navigator.pop(context, false),
            child: Text(s('cancel')),
          ),
        ]),
      ),
    );
  }
}
