# Google Play 스토어 등록 자료

**앱 이름: `핑계콜`** / 스토어 제목: `핑계콜 - 가짜전화`

경쟁 앱이 전부 "가짜전화", "가짜 전화 알리바이", "심플 가짜전화" 라 그 단어만으로는
구분이 안 되고, 빼면 검색에서 사라진다. 앞에 고유명, 뒤에 검색어를 붙였다.
"핑계" 를 고른 건 이 앱이 파는 게 전화가 아니라 자리를 뜰 명분이기 때문이다.

Play Console 의 "기본 스토어 등록정보"에 올리는 이미지들. 크기가 규격과 다르면
Console 이 업로드를 거부하므로 파일을 직접 편집하지 말고 아래 방법으로 다시 생성한다.

## 파일

| 파일 | 규격 | 용도 |
|---|---|---|
| `icon-512.png` | 512×512 | 앱 아이콘 |
| `feature-graphic.png` | 1024×500 | 피처 그래픽 (필수) |
| `01-incoming.png` … `03-active.png` | 1080×1920 | 휴대전화 스크린샷 (2~8장 가능, 3장 사용) |

## 카피 원칙

**1번이 이 앱이 무엇인지 말한다.** 스토어 목록에서 첫 장만 보고 지나가는 사람이
대부분이라, 여기서 "가짜 전화"라는 말이 빠지면 그냥 통화 화면 스크린샷으로 보인다.
2번부터가 부수 기능이다.

**기능을 다 설명하려 들지 않는다.** 기능마다 한 장씩 붙이면 스토어 카피가 아니라
제품 소개서가 된다. 벨소리/진동, 키패드 같은 건 설치를 결정짓지 않으므로 넣지
않는다 — 쓰다 보면 알게 되는 것들이다.

**과장하지 않는다.** "진짜와 구분되지 않아요" 같은 주장이나 "일어날 이유가
생겼어요" 같은 이야기 만들기는 쓰지 않는다.

**유보하는 말도 빼낸다.** "최대한", "거의" 같은 말은 겸손해 보이지만 스토어에서는
자신 없어 보인다. 할 수 있는 만큼 했으면 했다고 적는다.

어조는 앱 캐치프라이즈("전화 한 통이면 돼요")와 같은 ~어요 로 세 장을 맞춘다.

## 다시 만들기

```bash
python3 src/build.py       # 스크린샷 + 피처 그래픽 + 512 아이콘
python3 src/make_icons.py  # Android/iOS 런처 아이콘 전 해상도
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
