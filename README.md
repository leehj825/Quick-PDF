# QuickPDF — 사진 → PDF 1초 묶기

광고 팝업·로그인·워터마크 없는 100% 오프라인 사진→PDF 변환 앱 (Vite + React + Tailwind + pdf-lib + Capacitor).

## 개발
```bash
npm install
npm run dev        # 브라우저에서 확인
npm run build
```

## Android 빌드
```bash
npx cap add android   # 최초 1회
npm run cap:sync
npx cap open android
```

## 구현된 MVP
- 다중 사진 선택(`<input type=file>` → Android 포토 피커), 길게 눌러 드래그로 순서 변경(+햅틱), 90° 회전, 삭제
- 품질 프리셋(고화질 2400px/90%, 표준 1600px/75%, 저용량 1080px/55%) + 예상 용량
- A4 맞춤/원본 크기, 여백 ON/OFF, 파일명 지정(기본 `PDF_YYYYMMDD_HHmm`)
- 이미지 1장씩 순차 처리 + canvas 즉시 해제(OOM 방지), 진행률 표시
- 완료 화면(공유/열기/홈), 로컬 히스토리(열기·공유·삭제)
- 한국어/영어 UI, 다크 모드, 무료 한도 20장

## TODO (문서 기준 미구현)
AdMob 배너, Pro IAP(비밀번호 잠금 등), 인앱 리뷰, 일본어/스페인어, 설정 화면
