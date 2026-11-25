import 'package:flutter/painting.dart';
import '../models.dart';

/// 4x5 color matrix (Flutter ColorFilter.matrix format) for live GPU preview.
List<double> buildColorMatrix(DocFilter filter, int brightness, int contrast) {
  // Base contrast/brightness.
  var c = 1.0 + contrast / 100.0; // 0.5..1.5
  var b = brightness * 2.55; // -127..127 (0..255 scale)
  var sat = 1.0;

  switch (filter) {
    case DocFilter.original:
      break;
    case DocFilter.vivid:
      c *= 1.25;
      b += 22;
      sat = 1.15;
    case DocFilter.mono:
      c *= 2.2;
      b += 40;
      sat = 0;
  }

  // Saturation matrix (luma weights).
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final s = sat;
  final sr = (1 - s) * lr, sg = (1 - s) * lg, sb = (1 - s) * lb;
  final cs = [
    sr + s, sg, sb, 0, 0, //
    sr, sg + s, sb, 0, 0,
    sr, sg, sb + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
  // Contrast pivots around mid-gray 128.
  final t = 128 * (1 - c) + b;
  List<double> scaled(int row) => [
        cs[row * 5] * c,
        cs[row * 5 + 1] * c,
        cs[row * 5 + 2] * c,
        0,
        t,
      ];
  return [
    ...scaled(0),
    ...scaled(1),
    ...scaled(2),
    0, 0, 0, 1, 0,
  ];
}

ColorFilter buildColorFilter(DocFilter f, int brightness, int contrast) =>
    ColorFilter.matrix(buildColorMatrix(f, brightness, contrast));
