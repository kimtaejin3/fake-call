# App Store 등록 자료

App Store Connect 의 "iPhone 6.9" 디스플레이" 칸에 올리는 스크린샷. 6.9" 만
올리면 더 작은 iPhone 크기는 App Store Connect 가 알아서 축소해 쓴다.

카피와 배경은 Play 스토어 자료(`../play`)와 같다. 카피 원칙은
`../play/README.md` 참고.

## 파일

| 파일 | 규격 | 용도 |
|---|---|---|
| `01-incoming.png` … `03-active.png` | 1320×2868 | iPhone 6.9" 스크린샷 |

앱 아이콘은 `ios/Runner/Assets.xcassets/AppIcon.appiconset` 의 1024×1024 가
빌드에 실려 올라가므로 따로 올리지 않는다.

## 다시 만들기

```bash
# 1) 원본 캡처 (저장소 루트에서) — raw/*.png, 1320×2868
flutter build web --release --no-web-resources-cdn
(cd build/web && python3 -m http.server 8765) &
node store/appstore/src/capture.js

# 2) 카피·배경 합성
python3 store/appstore/src/build.py
```

원본은 iOS 시뮬레이터가 아니라 **웹 빌드를 iPhone 으로 위장해** 찍는다.
Flutter 웹은 `navigator.platform` 으로 플랫폼을 정해서, `'iPhone'` 을 돌려주면
통화 화면이 iOS 룩으로 그려진다. 웹에는 상태바가 없어서 `capture.js` 가 상태바
(9:41, 다이나믹 아일랜드)와 홈 인디케이터를 직접 그려 넣는다.

시뮬레이터에서 찍은 걸 쓰고 싶으면 iPhone 16 Pro Max 시뮬레이터에서
`xcrun simctl io booted screenshot raw/home.png` 처럼 찍어 `raw/` 에 같은
이름으로 넣고 `build.py` 만 돌리면 된다 (해상도가 1320×2868 로 같다).

## 아직 남은 것

App Store Connect 에서 직접 채워야 하는 것들.

- 부제(30자), 프로모션 텍스트(170자), 설명, 키워드(100자)
- 개인정보처리방침 URL, 지원 URL (둘 다 필수)
- 연령 등급 설문, 앱 개인정보(데이터 수집) 설문 — 마이크는 통화 중 말소리
  감지에만 쓰고 녹음·저장하지 않는다
- iPad 지원이 켜져 있으면(`TARGETED_DEVICE_FAMILY = "1,2"`) 13" iPad
  스크린샷도 필수. iPhone 전용으로 내면 필요 없다.
