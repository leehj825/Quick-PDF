import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'pro_service.dart';

/// Adaptive banner for the home screen only. Hidden for Pro users.
/// Uses Google's public TEST unit id; replace with a real one before release.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  static const _testUnit = 'ca-app-pub-3940256099942544/9214589741';
  BannerAd? _ad;
  bool _loaded = false;
  int _width = 0;

  Future<void> _load(int width) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    _ad?.dispose();
    _ad = BannerAd(
      adUnitId: _testUnit,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ProService.instance.isPro,
      builder: (_, pro, _) {
        if (pro) return const SizedBox.shrink();
        final w = MediaQuery.sizeOf(context).width.truncate();
        if (w != _width) {
          _width = w;
          _loaded = false;
          _load(w);
        }
        if (!_loaded || _ad == null) return const SizedBox(height: 50);
        return SizedBox(
            width: _ad!.size.width.toDouble(),
            height: _ad!.size.height.toDouble(),
            child: AdWidget(ad: _ad!));
      },
    );
  }
}
