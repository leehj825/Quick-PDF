import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../models.dart';

/// On-device English (Latin script) OCR via ML Kit. Nothing leaves the device.
class OcrService {
  OcrService() : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final TextRecognizer _recognizer;

  Future<List<OcrLine>> recognize(Uint8List jpeg) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await f.writeAsBytes(jpeg, flush: true);
    try {
      final result = await _recognizer.processImage(InputImage.fromFilePath(f.path));
      return [
        for (final b in result.blocks)
          for (final l in b.lines)
            OcrLine(l.text, l.boundingBox.left, l.boundingBox.top, l.boundingBox.width, l.boundingBox.height),
      ];
    } finally {
      f.deleteSync(); // temp cache cleanup right after use
    }
  }

  Future<void> close() => _recognizer.close();
}
