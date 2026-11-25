enum DocFilter { original, vivid, mono }

enum Quality {
  high(2400, 90),
  standard(1600, 75),
  low(1080, 55);

  const Quality(this.maxEdge, this.jpegQuality);
  final int maxEdge;
  final int jpegQuality;
}

/// Page size in PDF points (1/72 in). [original] uses the photo's own size.
enum PageSizeMode {
  letter(612, 792),
  a4(595.28, 841.89),
  original(0, 0);

  const PageSizeMode(this.width, this.height);
  final double width;
  final double height;
}

class PageItem {
  PageItem({required this.id, required this.path});
  final int id;
  String path;
  int quarterTurns = 0; // 90° steps clockwise
  int brightness = 0; // -50..50
  int contrast = 0; // -50..50

  bool get adjusted => brightness != 0 || contrast != 0;

  void reset() {
    quarterTurns = 0;
    brightness = 0;
    contrast = 0;
  }
}

class PdfOptions {
  const PdfOptions({
    this.quality = Quality.standard,
    this.filter = DocFilter.original,
    this.pageSize = PageSizeMode.letter, // default: Letter
    this.margin = false,
    this.ocr = false,
  });
  final Quality quality;
  final DocFilter filter;
  final PageSizeMode pageSize;
  final bool margin;

  /// Add an invisible text layer (searchable PDF). Pro, English only.
  final bool ocr;
}

/// One recognized line of text, in pixel coordinates of the page image.
class OcrLine {
  const OcrLine(this.text, this.left, this.top, this.width, this.height);
  final String text;
  final double left, top, width, height;
}

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.name,
    required this.path,
    required this.pages,
    required this.size,
    required this.createdAt,
  });
  final String id;
  final String name;
  final String path;
  final int pages;
  final int size;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'pages': pages,
        'size': size,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as String,
        name: j['name'] as String,
        path: j['path'] as String,
        pages: j['pages'] as int,
        size: j['size'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
      );
}
