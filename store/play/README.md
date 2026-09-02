# Google Play 스토어 등록 자료

Play Console 의 "기본 스토어 등록정보"에 올리는 이미지들. 크기가 규격과 다르면
Console 이 업로드를 거부하므로 파일을 직접 편집하지 말고 아래 방법으로 다시 생성한다.

## 파일

| 파일 | 규격 | 용도 |
|---|---|---|
| `icon-512.png` | 512×512 | 앱 아이콘 |
| `feature-graphic.png` | 1024×500 | 피처 그래픽 (필수) |
| `01-incoming.png` … `06-keypad.png` | 1080×1920 | 휴대전화 스크린샷 (2~8장) |

스크린샷 순서가 곧 스토어 노출 순서다. 목록에서 가장 먼저 보이는 1~3번이 설치를
좌우하므로, 이 앱의 핵심인 수신 화면을 1번에 뒀다.

## 다시 만들기

```bash
python3 src/build.py
```

원본 스크린샷은 `src/raw/` 에 있다(1080×1920). 카피 문구는 `src/build.py` 의
`SCREENS` 상수에 있고, 파일을 바꾸지 않고 문구만 고쳐 다시 돌릴 수 있다.

원본을 새로 찍으려면 에뮬레이터를 Play 규격으로 맞춘 뒤 캡처한다. 이 머신의
AVD 는 폴더블(2208×1840, 태블릿 비율)뿐이라 그대로 찍으면 폰 스크린샷으로 쓸 수
없어서, 해상도를 덮어씌운다:

```bash
adb shell wm size 1080x1920
adb shell wm density 440
# 앱을 다시 실행해야 새 크기로 레이아웃된다
adb shell monkey -p com.aifakecall.ai_fake_call -c android.intent.category.LAUNCHER 1
adb shell screencap -p /sdcard/s.png && adb pull /sdcard/s.png src/raw/p_home.png
adb shell wm size reset && adb shell wm density reset   # 끝나면 원복
```

렌더러는 headless Chrome 이다. 지정한 `--window-size` 가 그대로 픽셀 크기가 되고,
한글 조판은 `word-break: keep-all` 로 어절 단위 줄바꿈을 강제한다(기본값은 단어
중간에서 끊어 "괜찮아 / 요" 처럼 갈라진다).

## 아직 남은 것

이미지 외에 Play Console 이 요구하는 것들 — 여기서 만들 수 없어 직접 채워야 한다.

- **앱 이름** — 현재 `android:label="ai_fake_call"` (프로젝트 폴더명 그대로).
  기기 홈 화면과 스토어에 이대로 노출된다. 한국어 이름으로 바꿔야 한다.
- **런처 아이콘** — `android/app/src/main/res/mipmap-*/ic_launcher.png` 가 아직
  Flutter 기본 아이콘이다. 위 `icon-512.png` 를 각 해상도로 내보내 교체해야 한다.
- 짧은 설명(80자), 자세한 설명(4000자)
- 개인정보처리방침 URL — 이 앱은 마이크 권한을 선언하고 있어(현재 미사용) 설명이 필요하다
- 콘텐츠 등급 설문, 대상 연령층, 데이터 보안 양식

## 참고

스크린샷에 찍힌 상태바 시각·배터리는 에뮬레이터의 것이다. Play 는 이를 문제
삼지 않지만, 더 깔끔하게 하려면 캡처 전에 데모 모드를 켜면 된다:

```bash
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0900
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
```
