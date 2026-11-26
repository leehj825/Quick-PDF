import 'package:flutter/foundation.dart';

/// AdMob ad unit ids. Release builds use the real units; every other build (debug / profile,
/// emulator tests, store-screenshot runs) uses Google's public TEST units so that developers never
/// load or click real ads (invalid traffic can get the AdMob account limited).
class AdIds {
  AdIds._();

  static const _realBanner = 'ca-app-pub-4400173019354346/2497058321';
  static const _realRewarded = 'ca-app-pub-4400173019354346/9412539209';

  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static String get banner => kReleaseMode ? _realBanner : _testBanner;
  static String get rewarded => kReleaseMode ? _realRewarded : _testRewarded;
}
