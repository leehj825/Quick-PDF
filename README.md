# QuickPDF — 사진 → PDF 1초 묶기 (Flutter)

전면 광고·로그인·워터마크 없는 100% 오프라인 사진→PDF 변환 + 문서 보정 앱.

## 실행
```bash
flutter pub get
flutter run            # Android 기기/에뮬레이터
flutter test           # PDF 엔진 / 필터 테스트
flutter build appbundle
```

## 구현된 MVP
- **입력:** 갤러리 다중 선택(`image_picker`), 카메라 스캔(`google_mlkit_document_scanner`)
- **보정:** 일괄 필터(원본 / 문서 선명 / 문서 흑백), 썸네일 탭 → 개별 보정(밝기·대비 슬라이더, 90° 회전, 자르기, 초기화). 미리보기는 `ColorFiltered`(GPU), PDF 생성 시에만 픽셀 처리
- **순서 변경:** 길게 눌러 드래그(`reorderable_grid_view`) + 햅틱
- **PDF 옵션:** 파일명, 품질(고화질 2400px/90 · 표준 1600px/75 · 저용량 1080px/55) + 예상 용량, **기본 용지 Letter** (A4 / 원본 크기 선택 가능), 여백 ON/OFF
- **변환:** 페이지당 `Isolate.run`으로 1장씩 순차 처리(UI 멈춤·OOM 방지), 진행률 표시
- **완료/히스토리:** 공유 시트, PDF 열기, 홈 목록에서 열기/공유/삭제, 3번째 성공 시 인앱 리뷰
- **수익화:** 홈 하단 적응형 AdMob 배너(Pro 시 숨김), 일회성 Pro(`quickpdf_pro`) — 무료는 한 번에 20장 제한
- **i18n:** 한국어 / 영어 / 일본어 / 스페인어, 다크 모드

## 출시 전 교체/설정할 것
- `android/app/src/main/AndroidManifest.xml`의 AdMob **테스트 앱 ID**, `lib/services/ad_banner.dart`의 **테스트 광고 단위 ID**
- Play Console에 인앱 상품 `quickpdf_pro`(관리형 일회성) 등록
- `applicationId`(`app.quickpdf.quick_pdf`), 릴리스 서명 키

## 미구현 (TODO)
PDF 비밀번호 잠금(`pdf` 패키지는 암호화 구현체 미포함), 설정 화면, 저사양 기기 20~30장 스트레스 테스트
