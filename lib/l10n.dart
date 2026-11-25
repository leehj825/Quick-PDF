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
    'open': 'PDF 열기', 'home': '홈으로', 'pages': '{n}페이지', 'limit': '무료 버전은 한 번에 최대 {n}장까지 가능해요. Pro로 제한을 해제하세요.',
    'error': '변환 중 오류가 발생했어요.', 'delete': '삭제', 'confirmDel': '이 PDF를 삭제할까요?', 'cancel': '취소',
    'brightness': '밝기', 'contrast': '대비', 'rotate': '90° 회전', 'crop': '자르기', 'reset': '초기화', 'apply': '적용',
    'pro': 'Pro', 'proTitle': 'Pro 업그레이드', 'proDesc': '한 번 결제로 평생 사용 (구독 없음)',
    'proF1': '하단 배너 광고 영구 제거', 'proF2': '한 번에 20장 이상 대용량 변환', 'proF3': '텍스트 인식(OCR)으로 검색·복사 가능한 PDF (영어)',
    'buy': '구매하기', 'restore': '구매 복원', 'proActive': 'Pro 사용 중입니다. 감사합니다!', 'proUnavailable': '결제를 사용할 수 없어요.',
    'cropTitle': '자르기', 'noScan': '스캔을 완료하지 못했어요.',
    'ocr': '텍스트 인식 (검색 가능한 PDF)', 'ocrSub': '영어 · 글자 검색·복사 가능. 변환이 조금 느려져요', 'proOnly': 'Pro 기능이에요',
  },
  'en': {
    'title': 'Photos → PDF', 'emptyTitle': 'Pick photos or scan documents and bundle them into a PDF in 1 second.',
    'emptySub': 'Everything is processed safely on your device.', 'gallery': 'Choose from gallery', 'scan': 'Scan',
    'recent': 'Recent PDFs', 'total': '{n} pages', 'add': 'Add', 'filename': 'File name', 'filter': 'Document filter',
    'fOriginal': 'Original', 'fVivid': 'Vivid', 'fMono': 'B&W', 'quality': 'Compression',
    'qHigh': 'High', 'qStd': 'Standard', 'qLow': 'Small', 'estimate': 'Estimated size', 'pageSize': 'Page size',
    'letter': 'Letter', 'a4': 'A4', 'original': 'Original', 'margin': 'Margin', 'make': 'Create PDF',
    'progress': 'Converting page {a} / {b}...', 'done': 'Done!', 'share': 'Share now',
    'open': 'Open PDF', 'home': 'Home', 'pages': '{n} pages', 'limit': 'Free version allows up to {n} pages at a time. Upgrade to Pro to remove the limit.',
    'error': 'Conversion failed.', 'delete': 'Delete', 'confirmDel': 'Delete this PDF?', 'cancel': 'Cancel',
    'brightness': 'Brightness', 'contrast': 'Contrast', 'rotate': 'Rotate 90°', 'crop': 'Crop', 'reset': 'Reset', 'apply': 'Apply',
    'pro': 'Pro', 'proTitle': 'Upgrade to Pro', 'proDesc': 'One-time purchase, yours forever (no subscription)',
    'proF1': 'Remove banner ads forever', 'proF2': 'Convert more than 20 pages at once', 'proF3': 'Text recognition (OCR) for searchable, copyable PDFs (English)',
    'buy': 'Buy', 'restore': 'Restore purchase', 'proActive': 'Pro is active. Thank you!', 'proUnavailable': 'Purchases are unavailable.',
    'cropTitle': 'Crop', 'noScan': 'Scan was not completed.',
    'ocr': 'Text recognition (searchable PDF)', 'ocrSub': 'English only · search & copy text. Conversion is a bit slower', 'proOnly': 'Pro feature',
  },
  'ja': {
    'title': '写真 → PDF', 'emptyTitle': '写真を選ぶか書類をスキャンして、1秒でPDFにまとめましょう。',
    'emptySub': 'すべての処理は端末内で安全に行われます。', 'gallery': 'ギャラリーから選択', 'scan': 'スキャン',
    'recent': '最近のPDF', 'total': '全{n}枚', 'add': '追加', 'filename': 'ファイル名', 'filter': '書類フィルター',
    'fOriginal': '元の色', 'fVivid': '鮮明', 'fMono': '白黒', 'quality': '画像圧縮',
    'qHigh': '高画質', 'qStd': '標準', 'qLow': '低容量', 'estimate': '予想サイズ', 'pageSize': 'ページサイズ',
    'letter': 'Letter', 'a4': 'A4', 'original': '元のサイズ', 'margin': '余白', 'make': 'PDFを作成',
    'progress': '{a} / {b} ページ変換中...', 'done': '変換完了!', 'share': '今すぐ共有',
    'open': 'PDFを開く', 'home': 'ホームへ', 'pages': '{n}ページ', 'limit': '無料版は一度に最大{n}枚までです。Proで制限を解除できます。',
    'error': '変換中にエラーが発生しました。', 'delete': '削除', 'confirmDel': 'このPDFを削除しますか?', 'cancel': 'キャンセル',
    'brightness': '明るさ', 'contrast': 'コントラスト', 'rotate': '90°回転', 'crop': 'トリミング', 'reset': 'リセット', 'apply': '適用',
    'pro': 'Pro', 'proTitle': 'Proにアップグレード', 'proDesc': '買い切り・サブスクなし',
    'proF1': 'バナー広告を完全に削除', 'proF2': '20枚以上を一括変換', 'proF3': '文字認識(OCR)で検索・コピーできるPDF (英語)',
    'buy': '購入', 'restore': '購入を復元', 'proActive': 'Proをご利用中です。ありがとうございます!', 'proUnavailable': '課金を利用できません。',
    'cropTitle': 'トリミング', 'noScan': 'スキャンが完了しませんでした。',
    'ocr': '文字認識 (検索可能なPDF)', 'ocrSub': '英語のみ・文字の検索とコピーが可能。変換が少し遅くなります', 'proOnly': 'Pro機能です',
  },
  'es': {
    'title': 'Fotos → PDF', 'emptyTitle': 'Elige fotos o escanea documentos y únelos en un PDF en 1 segundo.',
    'emptySub': 'Todo se procesa de forma segura en tu dispositivo.', 'gallery': 'Elegir de la galería', 'scan': 'Escanear',
    'recent': 'PDF recientes', 'total': '{n} páginas', 'add': 'Añadir', 'filename': 'Nombre', 'filter': 'Filtro de documento',
    'fOriginal': 'Original', 'fVivid': 'Nítido', 'fMono': 'B/N', 'quality': 'Compresión',
    'qHigh': 'Alta', 'qStd': 'Estándar', 'qLow': 'Ligera', 'estimate': 'Tamaño estimado', 'pageSize': 'Tamaño de página',
    'letter': 'Carta', 'a4': 'A4', 'original': 'Original', 'margin': 'Margen', 'make': 'Crear PDF',
    'progress': 'Convirtiendo página {a} / {b}...', 'done': '¡Listo!', 'share': 'Compartir ahora',
    'open': 'Abrir PDF', 'home': 'Inicio', 'pages': '{n} páginas', 'limit': 'La versión gratuita permite hasta {n} páginas a la vez. Pásate a Pro para quitar el límite.',
    'error': 'Error al convertir.', 'delete': 'Eliminar', 'confirmDel': '¿Eliminar este PDF?', 'cancel': 'Cancelar',
    'brightness': 'Brillo', 'contrast': 'Contraste', 'rotate': 'Girar 90°', 'crop': 'Recortar', 'reset': 'Restablecer', 'apply': 'Aplicar',
    'pro': 'Pro', 'proTitle': 'Mejorar a Pro', 'proDesc': 'Pago único, para siempre (sin suscripción)',
    'proF1': 'Quitar los anuncios de banner', 'proF2': 'Convertir más de 20 páginas a la vez', 'proF3': 'Reconocimiento de texto (OCR) para PDF con búsqueda y copia (inglés)',
    'buy': 'Comprar', 'restore': 'Restaurar compra', 'proActive': 'Pro activo. ¡Gracias!', 'proUnavailable': 'Las compras no están disponibles.',
    'cropTitle': 'Recortar', 'noScan': 'El escaneo no se completó.',
    'ocr': 'Reconocimiento de texto (PDF con búsqueda)', 'ocrSub': 'Solo inglés · buscar y copiar texto. La conversión es algo más lenta', 'proOnly': 'Función Pro',
  },
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
