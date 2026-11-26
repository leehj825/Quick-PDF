import 'package:flutter_test/flutter_test.dart';
import 'package:quick_pdf/l10n.dart';
import 'package:quick_pdf/services/reward_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('credit: grant is capped at 1, consume uses it up, persisted across restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final r = RewardService.instance;
    await r.init();
    expect(r.credits.value, 0);

    await r.grant();
    await r.grant(); // watching twice must not stockpile
    expect(r.credits.value, 1);

    // "restart": a fresh read from storage still has the credit
    r.credits.value = 0;
    await r.init();
    expect(r.credits.value, 1);

    await r.consume();
    expect(r.credits.value, 0);
    await r.consume(); // no negative credits
    expect(r.credits.value, 0);
    r.credits.value = 0;
    await r.init();
    expect(r.credits.value, 0);
  });

  test('free page limit is 20', () => expect(RewardService.freePageLimit, 20));

  test('all languages have the reward strings and no leftover Pro purchase strings', () {
    for (final lang in supportedLangs) {
      final s = S(lang);
      for (final k in ['rewardTitle', 'rewardDesc', 'rewardReasonLimit', 'rewardReasonOcr', 'watchAd', 'adNotReady', 'adUnlock']) {
        expect(s(k), isNot(k), reason: '$lang missing $k');
      }
      expect(s('rewardReasonLimit', {'n': 20}), contains('20'), reason: '$lang limit text should show the number');
      for (final k in ['proTitle', 'buy', 'restore']) {
        expect(s(k), k, reason: '$lang still has $k');
      }
    }
  });
}
