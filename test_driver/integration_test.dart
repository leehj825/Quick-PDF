import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves every `takeScreenshot(name)` from the device test to `build/store/device/NAME.png`.
Future<void> main() async {
  await integrationDriver(onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
    final file = File('build/store/device/$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  });
}
