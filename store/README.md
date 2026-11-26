# Google Play 스토어 등록 자료

| 항목 | 파일 | 규격 |
|---|---|---|
| 앱 아이콘 | `graphics/icon-512.png` | 512×512 PNG |
| 그래픽 이미지(피처) | `graphics/feature-graphic-{ko,en,ja,es}.png` | 1024×500 PNG (알파 없음) |
| 휴대전화 스크린샷 | `screenshots/{ko,en,ja,es}/01~06-*.png` | 1080×1920 PNG, 언어당 6장 |
| 제목 / 짧은 설명 / 자세한 설명 | `listing/{ko,en,ja,es}/*.txt` | 30자 / 80자 / 4000자 이내 (검증됨) |

기본 언어는 한국어(ko)를 추천합니다. 나머지 언어는 Play Console → 스토어 설정 → 스토어 등록정보 → 번역 추가에서 같은 이름의 파일을 넣으세요.
일본어·스페인어 문구는 출시 전에 원어민 검수를 권장합니다.

## 스크린샷은 실제 앱 화면입니다
`tool/store/render_screens_test.dart`가 **앱의 실제 화면 코드**를 가상의 샘플 서류(`tool/store/make_samples.py`)로 렌더링하고,
`tool/store/compose.py`가 캡션과 기기 프레임을 입힙니다. 앱 UI가 바뀌면 아래 순서로 다시 만드세요.

```bash
python3 tool/store/make_samples.py build/store/samples
flutter test tool/store/render_screens_test.dart      # build/store/raw/*.png
python3 tool/store/compose.py                         # store/graphics, store/screenshots
```
(렌더링은 이 저장소 개발 환경의 글꼴 경로를 사용합니다. 샘플 서류는 모두 가상의 내용입니다.)

## 등록 전에 사용자가 직접 해야 하는 것
- **개인정보 처리방침 URL** (필수): 사진·PDF는 서버로 전송하지 않고, AdMob이 광고 식별자를 수집한다는 내용을 포함해야 합니다.
- **데이터 보안 양식**: 광고 ID(AdMob) 수집·공유 항목 신고.
- **광고 포함 앱: 예**로 선택.
- **콘텐츠 등급 설문**, 앱 카테고리(도구 또는 생산성), 연락처 이메일.
- **광고 ID**: 실제 AdMob ID가 릴리스 빌드에 적용돼 있습니다(디버그·테스트는 테스트 ID). 본인 폰에서 릴리스 APK를 쓸 때는 AdMob 콘솔 → 설정 → 테스트 기기에 그 폰을 등록해 두세요. 실제 광고를 직접 누르면 계정이 제한될 수 있습니다.
- **릴리스 서명 키 + AAB**: CI가 시크릿의 키스토어로 서명한 `.aab`를 프리릴리즈에 올립니다. Play에는 그 `.aab`를 올리세요(Play 앱 서명 사용을 권장). 키스토어 파일과 비밀번호는 잃어버리지 않게 따로 보관하세요.
