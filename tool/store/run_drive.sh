#!/usr/bin/env bash
# Runs the real-app screenshot test with a time limit and prints diagnostics, so a stuck run
# explains itself instead of hanging until the CI job times out.
set +e
mkdir -p build/store
adb logcat -c
(adb logcat -v time > build/store/logcat.txt 2>&1 &)
timeout 1200 flutter drive -v --driver=test_driver/integration_test.dart \
  --target=integration_test/store_screenshots_test.dart -d emulator-5554 > build/store/drive.log 2>&1
code=$?
echo "flutter drive exit code: $code (124 = timed out)"
echo "=== step markers from the app ==="; grep -a "STEP:" build/store/logcat.txt | sed 's/^.*flutter *: //' | tail -60
echo "=== drive.log: last 40 lines ==="; tail -40 build/store/drive.log | cut -c1-240
echo "=== crash (first fatal, with stack) ==="; grep -a -n -m1 -E "FATAL EXCEPTION|Fatal signal" build/store/logcat.txt | cut -d: -f1 | while read n; do sed -n "$((n-2)),$((n+40))p" build/store/logcat.txt | cut -c1-240; done
echo "=== Flutter errors in logcat ==="; grep -a -E "flutter *:.*(Exception|EXCEPTION|Error:|failed)" build/store/logcat.txt | tail -30 | cut -c1-260
echo "=== screenshots ==="; ls -la build/store/device 2>/dev/null || echo "none"
exit 0
