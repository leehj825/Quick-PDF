import 'package:flutter/widgets.dart';

const supportedLangs = ['ko', 'en', 'ja', 'es'];

const _s = <String, Map<String, String>>{
  'ko': {
    'title': '사진 → PDF 묶기', 'emptyTitle': '사진을 고르거나 서류를 스캔해 1초 만에 PDF로 묶어보세요.',
    'emptySub': '모든 작업은 기기 안에서 안전하게 처리됩니다.', 'gallery': '갤러리에서 선택', 'scan': '카메라 스캔',
    'recent': '최근 PDF', 'total': '총 {n}장', 'add': '추가', 'filename': '파일명', 'filter': '문서 필터',
    'fOriginal': '원본', 'fVivid': '문서 선명', 'fMono': '문서 흑백', 'quality': '이미지 압축',
    'qHigh': '고화질', 'qStd': '표준', 'qLow': '저용량', 'estimate': '예상 용량', 'pageSize': '페이지 크기',
    'letter': 'Letter', 'a4': 'A4', 'original': '원본 크기', 'margin': '여백', 'make': 'PDF 만들기',
    'progress': '{a} / {b} 페이지 변환 중...', 'done': '변환 완료!', 'share': '바로 공유하기',
    'open': 'PDF 열기', 'home': '홈으로', 'pages': '{n}페이지', 'error': '변환 중 오류가 발생했어요.', 'delete': '삭제', 'confirmDel': '이 PDF를 삭제할까요?', 'cancel': '취소',
    'brightness': '밝기', 'contrast': '대비', 'rotate': '90° 회전', 'crop': '자르기', 'reset': '초기화', 'apply': '적용',
    'cropTitle': '자르기', 'noScan': '스캔을 완료하지 못했어요.',
    'rewardTitle': '광고 보고 이번 한 번 사용', 'rewardDesc': '짧은 광고를 끝까지 보면 이번 PDF 한 번 쓸 수 있어요. 변환이 끝나야 소모되고, 쓰지 않으면 남아 있어요.', 'rewardReasonLimit': '무료는 한 번에 최대 {n}장까지예요. 광고를 보면 이번 한 번 더 추가할 수 있어요.', 'rewardReasonOcr': '텍스트 인식은 광고를 보고 이번 한 번 쓸 수 있어요.', 'watchAd': '광고 보고 사용', 'adNotReady': '광고를 불러올 수 없어요. 인터넷 연결을 확인하고 다시 시도해 주세요.', 'adUnlock': '광고 보고 1회 사용',
    'importPdf': 'PDF 가져오기', 'pdfMergeNote': 'PDF만 합칠 때는 원본 그대로 합쳐요. 화질·글자는 바뀌지 않아요.', 'pdfEncrypted': '비밀번호가 있는 PDF는 아직 지원하지 않아요.', 'pdfFailed': 'PDF를 열 수 없어요.', 'rotateShort': '회전',
    'ocr': '텍스트 인식 (검색 가능한 PDF)', 'ocrSub': '영어 · 글자 검색·복사 가능. 변환이 조금 느려져요', },
  'en': {
    'title': 'Photos → PDF', 'emptyTitle': 'Pick photos or scan documents and bundle them into a PDF in 1 second.',
    'emptySub': 'Everything is processed safely on your device.', 'gallery': 'Gallery', 'scan': 'Scan',
    'recent': 'Recent PDFs', 'total': '{n} pages', 'add': 'Add', 'filename': 'File name', 'filter': 'Document filter',
    'fOriginal': 'Original', 'fVivid': 'Vivid', 'fMono': 'B&W', 'quality': 'Compression',
    'qHigh': 'High', 'qStd': 'Standard', 'qLow': 'Small', 'estimate': 'Estimated size', 'pageSize': 'Page size',
    'letter': 'Letter', 'a4': 'A4', 'original': 'Original', 'margin': 'Margin', 'make': 'Create PDF',
    'progress': 'Converting page {a} / {b}...', 'done': 'Done!', 'share': 'Share now',
    'open': 'Open PDF', 'home': 'Home', 'pages': '{n} pages', 'error': 'Conversion failed.', 'delete': 'Delete', 'confirmDel': 'Delete this PDF?', 'cancel': 'Cancel',
    'brightness': 'Brightness', 'contrast': 'Contrast', 'rotate': 'Rotate 90°', 'crop': 'Crop', 'reset': 'Reset', 'apply': 'Apply',
    'cropTitle': 'Crop', 'noScan': 'Scan was not completed.',
    'rewardTitle': 'Watch an ad to use once', 'rewardDesc': 'Watch a short ad to use this once. It is only used up when a conversion finishes; unused credit is kept.', 'rewardReasonLimit': 'Free allows up to {n} pages at a time. Watch an ad to add more just this once.', 'rewardReasonOcr': 'Text recognition can be used once after watching an ad.', 'watchAd': 'Watch ad', 'adNotReady': 'Could not load an ad. Check your connection and try again.', 'adUnlock': 'Watch an ad for 1 use',
    'importPdf': 'Import PDF', 'pdfMergeNote': 'Merging PDFs only: pages are combined as-is. Quality and text stay unchanged.', 'pdfEncrypted': 'Password-protected PDFs are not supported yet.', 'pdfFailed': 'Could not open this PDF.', 'rotateShort': 'Rotate',
    'ocr': 'Text recognition (searchable PDF)', 'ocrSub': 'English only · search & copy text. Conversion is a bit slower', },
  'ja': {
    'title': '写真 → PDF', 'emptyTitle': '写真を選ぶか書類をスキャンして、1秒でPDFにまとめましょう。',
    'emptySub': 'すべての処理は端末内で安全に行われます。', 'gallery': 'ギャラリーから選択', 'scan': 'スキャン',
    'recent': '最近のPDF', 'total': '全{n}枚', 'add': '追加', 'filename': 'ファイル名', 'filter': '書類フィルター',
    'fOriginal': '元の色', 'fVivid': '鮮明', 'fMono': '白黒', 'quality': '画像圧縮',
    'qHigh': '高画質', 'qStd': '標準', 'qLow': '低容量', 'estimate': '予想サイズ', 'pageSize': 'ページサイズ',
    'letter': 'Letter', 'a4': 'A4', 'original': '元のサイズ', 'margin': '余白', 'make': 'PDFを作成',
    'progress': '{a} / {b} ページ変換中...', 'done': '変換完了!', 'share': '今すぐ共有',
    'open': 'PDFを開く', 'home': 'ホームへ', 'pages': '{n}ページ', 'error': '変換中にエラーが発生しました。', 'delete': '削除', 'confirmDel': 'このPDFを削除しますか?', 'cancel': 'キャンセル',
    'brightness': '明るさ', 'contrast': 'コントラスト', 'rotate': '90°回転', 'crop': 'トリミング', 'reset': 'リセット', 'apply': '適用',
    'cropTitle': 'トリミング', 'noScan': 'スキャンが完了しませんでした。',
    'rewardTitle': '広告を見て1回使う', 'rewardDesc': '短い広告を最後まで見ると、今回1回だけ使えます。変換が終わると消費され、使わなければ残ります。', 'rewardReasonLimit': '無料版は一度に最大{n}枚までです。広告を見ると、今回だけ追加できます。', 'rewardReasonOcr': '文字認識は広告を見ると1回使えます。', 'watchAd': '広告を見る', 'adNotReady': '広告を読み込めません。接続を確認してもう一度お試しください。', 'adUnlock': '広告を見て1回使う',
    'importPdf': 'PDFを取り込む', 'pdfMergeNote': 'PDFだけを結合する場合は元のまま結合します。画質や文字は変わりません。', 'pdfEncrypted': 'パスワード付きPDFにはまだ対応していません。', 'pdfFailed': 'このPDFを開けません。', 'rotateShort': '回転',
    'ocr': '文字認識 (検索可能なPDF)', 'ocrSub': '英語のみ・文字の検索とコピーが可能。変換が少し遅くなります', },
  'es': {
    'title': 'Fotos → PDF', 'emptyTitle': 'Elige fotos o escanea documentos y únelos en un PDF en 1 segundo.',
    'emptySub': 'Todo se procesa de forma segura en tu dispositivo.', 'gallery': 'Galería', 'scan': 'Escanear',
    'recent': 'PDF recientes', 'total': '{n} páginas', 'add': 'Añadir', 'filename': 'Nombre', 'filter': 'Filtro de documento',
    'fOriginal': 'Original', 'fVivid': 'Nítido', 'fMono': 'B/N', 'quality': 'Compresión',
    'qHigh': 'Alta', 'qStd': 'Estándar', 'qLow': 'Ligera', 'estimate': 'Tamaño estimado', 'pageSize': 'Tamaño de página',
    'letter': 'Carta', 'a4': 'A4', 'original': 'Original', 'margin': 'Margen', 'make': 'Crear PDF',
    'progress': 'Convirtiendo página {a} / {b}...', 'done': '¡Listo!', 'share': 'Compartir ahora',
    'open': 'Abrir PDF', 'home': 'Inicio', 'pages': '{n} páginas', 'error': 'Error al convertir.', 'delete': 'Eliminar', 'confirmDel': '¿Eliminar este PDF?', 'cancel': 'Cancelar',
    'brightness': 'Brillo', 'contrast': 'Contraste', 'rotate': 'Girar 90°', 'crop': 'Recortar', 'reset': 'Restablecer', 'apply': 'Aplicar',
    'cropTitle': 'Recortar', 'noScan': 'El escaneo no se completó.',
    'rewardTitle': 'Mira un anuncio para usarlo una vez', 'rewardDesc': 'Mira un anuncio corto para usarlo esta vez. Solo se gasta al terminar una conversión; si no lo usas, se conserva.', 'rewardReasonLimit': 'La versión gratuita permite hasta {n} páginas a la vez. Mira un anuncio para añadir más solo esta vez.', 'rewardReasonOcr': 'El reconocimiento de texto se puede usar una vez tras ver un anuncio.', 'watchAd': 'Ver anuncio', 'adNotReady': 'No se pudo cargar un anuncio. Revisa tu conexión e inténtalo de nuevo.', 'adUnlock': 'Ver anuncio para 1 uso',
    'importPdf': 'Importar PDF', 'pdfMergeNote': 'Al unir solo PDF, las páginas se combinan tal cual. La calidad y el texto no cambian.', 'pdfEncrypted': 'Los PDF con contraseña aún no son compatibles.', 'pdfFailed': 'No se pudo abrir este PDF.', 'rotateShort': 'Girar',
    'ocr': 'Reconocimiento de texto (PDF con búsqueda)', 'ocrSub': 'Solo inglés · buscar y copiar texto. La conversión es algo más lenta', },
};

class S {
  S(this.lang);
  final String lang;

  static S of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return S(supportedLangs.contains(code) ? code : 'en');
  }

  String call(String key, [Map<String, Object> args = const {}]) {
    var v = _s[lang]![key] ?? _s['en']![key] ?? key;
    args.forEach((k, val) => v = v.replaceAll('{$k}', '$val'));
    return v;
  }
}
