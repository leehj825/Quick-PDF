import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_ids.dart';

/// Rewarded-ad "one use" credits. Watching one ad grants one credit; a credit is consumed
/// only when a conversion actually used a premium feature (text recognition or >20 pages).
class RewardService {
  RewardService._();
  static final RewardService instance = RewardService._();

  static const freePageLimit = 20;
  static const _key = 'quickpdf.rewardCredits';

  /// Stock is capped at 1 so credits cannot be hoarded ("1 ad = 1 use").
  final ValueNotifier<int> credits = ValueNotifier(0);

  RewardedAd? _ad;
  Future<void>? _loading;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    credits.value = (p.getInt(_key) ?? 0).clamp(0, 1);
  }

  Future<void> _store() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_key, credits.value);
  }

  Future<void> grant() async {
    credits.value = 1;
    await _store();
  }

  Future<void> consume() async {
    if (credits.value > 0) {
      credits.value = 0;
      await _store();
    }
  }

  /// Loads an ad in the background so it is ready when the user asks for it.
  void preload() => _loading ??= _load();

  Future<void> _load() async {
    final done = Completer<void>();
    try {
      RewardedAd.load(
        adUnitId: AdIds.rewarded,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            done.complete();
          },
          onAdFailedToLoad: (_) => done.complete(),
        ),
      );
      await done.future;
    } catch (_) {
      // Ads unavailable (offline / SDK not ready): callers fall back to a message.
    } finally {
      _loading = null;
    }
  }

  /// Shows a rewarded ad. Resolves true only if the user earned the reward.
  Future<bool> watchAd() async {
    if (_ad == null) {
      preload();
      await (_loading ?? Future<void>.value()).timeout(const Duration(seconds: 10), onTimeout: () {});
    }
    final ad = _ad;
    if (ad == null) return false;
    _ad = null;

    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        result.complete(earned);
        preload();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        result.complete(false);
        preload();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return result.future;
  }
}
