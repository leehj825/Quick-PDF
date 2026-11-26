import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_pdf/services/ad_ids.dart';

void main() {
  test('tests / debug use Google TEST ad units, never the real ones', () {
    expect(kReleaseMode, isFalse);
    expect(AdIds.banner, startsWith('ca-app-pub-3940256099942544/'));
    expect(AdIds.rewarded, startsWith('ca-app-pub-3940256099942544/'));
  });
}
