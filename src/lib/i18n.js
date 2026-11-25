const dict = {
  ko: {
    title: '사진 → PDF 묶기', emptyTitle: '사진을 선택해 1초 만에 PDF로 묶어보세요.',
    emptySub: '모든 작업은 기기 안에서 안전하게 처리됩니다.', fab: '사진으로 PDF 만들기',
    total: (n) => `총 ${n}장`, add: '추가', rotate: '회전', del: '삭제', filename: '파일명',
    quality: '이미지 압축', high: '고화질', highSub: '(원본)', std: '일반화질', low: '저용량', lowSub: '(공공기관용)',
    pageSize: '페이지 크기', a4: 'A4 맞춤', orig: '원본 크기', margin: '여백', make: '1초 만에 PDF 변환',
    est: '예상 용량', progress: (a, b) => `${a} / ${b} 페이지 변환 중...`, done: '변환 완료!',
    share: '바로 공유하기', open: 'PDF 미리보기(열기)', home: '홈으로 돌아가기', pages: (n) => `${n}페이지`,
    cancel: '취소', limit: (n) => `무료 버전은 한 번에 최대 ${n}장까지 가능해요.`, error: '변환 중 오류가 발생했어요.',
    ad: '가벼운 배너 광고 영역', recent: '최근 PDF', pro: 'PRO', confirmDel: '이 PDF를 삭제할까요?',
  },
  en: {
    title: 'Photos → PDF', emptyTitle: 'Pick photos and bundle them into a PDF in 1 second.',
    emptySub: 'Everything is processed safely on your device.', fab: 'Make PDF from photos',
    total: (n) => `${n} photos`, add: 'Add', rotate: 'Rotate', del: 'Delete', filename: 'File name',
    quality: 'Image compression', high: 'High', highSub: '(original)', std: 'Standard', low: 'Small', lowSub: '(for web upload)',
    pageSize: 'Page size', a4: 'Fit A4', orig: 'Original size', margin: 'Margin', make: 'Convert to PDF',
    est: 'Estimated size', progress: (a, b) => `Converting page ${a} / ${b}...`, done: 'Done!',
    share: 'Share now', open: 'Open PDF', home: 'Back to home', pages: (n) => `${n} pages`,
    cancel: 'Cancel', limit: (n) => `Free version allows up to ${n} photos at a time.`, error: 'Conversion failed.',
    ad: 'Banner ad area', recent: 'Recent PDFs', pro: 'PRO', confirmDel: 'Delete this PDF?',
  },
};
const lang = (navigator.language || 'en').startsWith('ko') ? 'ko' : 'en';
export const t = dict[lang];
