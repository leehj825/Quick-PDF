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
- **텍스트 인식 (보상 광고 1회, 영어):** ML Kit 온디바이스 OCR → 이미지 위에 보이지 않는 텍스트 레이어를 얹은 *검색 가능한 PDF*. 서버 전송 없음. Helvetica(Latin-1)만 지원
- **PDF 가져오기 (무료):** 홈/편집 화면에서 PDF 선택(시스템 파일 선택기, 저장소 권한 불필요). **PDF + 사진 섞으면** PDF 페이지를 이미지로 변환해(선택한 화질) 함께 편집, **PDF끼리만 합치면** PDFium(`pdfrx`)으로 원본 그대로 합침(글자·벡터·화질 유지, 순서/삭제/회전만 적용). 비밀번호가 있는 PDF는 미지원
- **수익화:** 홈 하단 AdMob 배너 + **보상형 광고**: 광고를 끝까지 보면 *1회권*이 생기고, 텍스트 인식 또는 20장 초과 변환을 **실제로 쓴 변환이 끝났을 때만** 소모(안 쓰면 보존, 최대 1개 보관). 결제(IAP)/구독 없음. 무료 기본 한도는 한 번에 20장
- **i18n:** 한국어 / 영어 / 일본어 / 스페인어, 다크 모드

## 출시 전 교체/설정할 것
- **광고 ID**: 릴리스 빌드는 실제 AdMob ID를, 디버그/테스트 빌드는 Google 테스트 ID를 씁니다(`lib/services/ad_ids.dart`, `android/app/build.gradle.kts`의 `admobAppId`). 개발 중 실제 광고를 로드·클릭하면 AdMob 계정이 제한될 수 있어 분리했습니다. 새 광고 단위는 노출까지 최대 1시간 걸릴 수 있고, 처음에는 `No fill`이 정상입니다.
- `applicationId`(`app.quickpdf.quick_pdf`)는 Play에 올린 뒤에는 바꿀 수 없습니다.

## 릴리스 서명 (CI)
GitHub Secrets `KEYSTORE_B64`(키스토어를 base64로 인코딩), `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`를 쓰면
CI가 키스토어를 러너 임시 폴더에 복원해 APK와 **AAB(Play 업로드용)**를 서명하고, 서명이 디버그 키가 아닌지 검증한 뒤 프리릴리즈에 올립니다.
시크릿이 없으면(포크 등) 디버그 키로 서명됩니다. 로컬에서 서명하려면 환경변수 또는 `android/key.properties`(git 제외)를 쓰세요.
> 디버그 키로 설치한 이전 APK 위에는 덮어 설치되지 않습니다(서명이 달라서). 한 번 삭제한 뒤 설치하세요.

## 미구현 (TODO)
PDF 비밀번호 잠금(`pdf` 패키지는 암호화 구현체 미포함), 설정 화면, 저사양 기기 20~30장 스트레스 테스트
