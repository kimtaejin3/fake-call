#!/usr/bin/env python3
"""Google Play 스토어 등록용 이미지 자료를 만든다.

원본 스크린샷(raw/*.png, 1080x1920)을 배경·카피와 함께 합성해 스토어
스크린샷을 만들고, 피처 그래픽도 함께 렌더한다. 렌더러는 headless Chrome
이라 지정한 픽셀 크기가 그대로 나온다 — Play 는 규격을 엄격히 검사한다.

사용법:  python3 build.py
"""

import subprocess
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent
OUT = SRC.parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Play Console 규격
PHONE_W, PHONE_H = 1080, 1920      # 폰 스크린샷 (9:16)
FEATURE_W, FEATURE_H = 1024, 500   # 피처 그래픽 (정확히 이 크기여야 함)

# (원본, 출력 파일명, 카피)
#
# 1번은 이 앱이 무엇인지부터 말한다 — 스토어 목록에서 이 한 장만 보고
# 지나가는 사람이 대부분이라, 여기서 "가짜 전화" 라는 말이 빠지면 그냥
# 통화 화면 스크린샷으로 보인다. 2번부터가 부수 기능이다.
#
# 어조는 앱 캐치프라이즈("전화 한 통이면 돼요")와 같은 ~어요 로 맞춘다.
# 주장("진짜와 구분되지 않아요")이나 이야기 만들기("일어날 이유가
# 생겼어요") 는 쓰지 않는다. "최대한", "거의" 같은 유보하는 말도 빼서
# 자신 없어 보이지 않게 한다.
SCREENS = [
    ("p_incoming.png", "01-incoming", "가짜 전화를<br>걸어줄 수 있어요"),
    ("p_home.png", "02-home", "이름과 시간만<br>정하면 돼요"),
    ("p_active.png", "03-active", "통화 화면까지<br>똑같이 만들었어요"),
]


def screenshot_html(raw: str, big: str) -> str:
    """스토어 스크린샷 한 장의 HTML."""
    return f"""<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="_base.css">
<style>
  html,body {{ width:{PHONE_W}px; height:{PHONE_H}px; }}
  .blob.a {{ width:620px; height:620px; top:-190px; left:-170px;
             background:radial-gradient(circle,rgba(139,124,246,.30),transparent 70%); }}
  .blob.b {{ width:520px; height:520px; top:-90px; right:-190px;
             background:radial-gradient(circle,rgba(124,155,248,.26),transparent 70%); }}
  .blob.c {{ width:560px; height:560px; bottom:-210px; left:-140px;
             background:radial-gradient(circle,rgba(196,181,253,.28),transparent 70%); }}
  .wrap {{ position:relative; height:100%;
           display:flex; flex-direction:column; align-items:center; }}
  h1 {{ margin:132px 0 0; font-size:80px; line-height:1.24; font-weight:700;
        color:#332E52; text-align:center; letter-spacing:-1.8px;
        word-break:keep-all; }}
  /* 흰 베젤 + 부드러운 그림자로 기기처럼 보이게 */
  .device {{ margin-top:96px; width:716px; padding:11px; background:#fff;
             border-radius:56px; box-shadow:0 30px 70px rgba(74,58,140,.22); }}
  .device img {{ display:block; width:100%; border-radius:46px; }}
</style></head><body>
<div class="bg"></div>
<div class="blob a"></div><div class="blob b"></div><div class="blob c"></div>
<div class="wrap">
  <h1>{big}</h1>
  <div class="device"><img src="raw/{raw}"></div>
</div></body></html>"""


FEATURE_HTML = f"""<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="_base.css">
<link rel="stylesheet" href="_orb.css">
<style>
  html,body {{ width:{FEATURE_W}px; height:{FEATURE_H}px; }}
  .blob.a {{ width:420px; height:420px; top:-150px; left:-110px;
             background:radial-gradient(circle,rgba(139,124,246,.34),transparent 70%); }}
  .blob.b {{ width:360px; height:360px; bottom:-150px; left:280px;
             background:radial-gradient(circle,rgba(196,181,253,.30),transparent 70%); }}
  .wrap {{ position:relative; height:100%; display:flex; align-items:center;
           /* Play 는 가장자리를 잘라낼 수 있어 여백을 넉넉히 둔다 */
           padding:0 64px; box-sizing:border-box; gap:36px; }}
  .copy {{ flex:1; }}
  /* word-break:keep-all — 한글은 기본 줄바꿈이 단어 중간을 끊어서
     "괜찮아 / 요" 처럼 갈라진다. 어절 단위로 끊게 강제한다. */
  .copy h1 {{ margin:0; font-size:50px; line-height:1.26; font-weight:700;
              color:#332E52; letter-spacing:-1.4px; word-break:keep-all; }}
  .copy p {{ margin:20px 0 0; font-size:25px; font-weight:500;
             color:#7E77A6; word-break:keep-all; }}
  .art {{ position:relative; width:250px; display:flex;
          align-items:center; justify-content:center; }}
  .orb {{ width:210px; height:210px;
          --eye-w:27px; --eye-h:60px; --eye-gap:31px; --shadow-blur:18px; }}
</style></head><body>
<div class="bg"></div>
<div class="blob a"></div><div class="blob b"></div>
<div class="wrap">
  <div class="copy">
    <h1>곤란한 자리에선,<br>전화 한 통이면 돼요</h1>
    <p>정해둔 시간에 걸려오는 전화</p>
  </div>
  <div class="art">
    <div class="orb"><div class="eyes"><div class="eye"></div><div class="eye"></div></div></div>
  </div>
</div></body></html>"""


def render(html: str, name: str, w: int, h: int) -> Path:
    """HTML 을 정확히 w×h 픽셀 PNG 로 렌더한다."""
    page = SRC / f"_{name}.html"
    page.write_text(html, encoding="utf-8")
    out = OUT / f"{name}.png"
    subprocess.run(
        [CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1",
         # 로컬 폰트/이미지를 file:// 로 읽어야 한다
         "--allow-file-access-from-files",
         # 가상 시간을 미리 돌려 폰트/이미지 로딩이 끝난 뒤 캡처한다.
         # 없으면 이미지가 없는 페이지(피처 그래픽)가 폰트보다 먼저 찍혀
         # 글자가 빈 채로 나온다.
         "--virtual-time-budget=4000",
         f"--screenshot={out}", f"--window-size={w},{h}",
         f"file://{page}"],
        capture_output=True, check=False,
    )
    if not out.exists():
        sys.exit(f"렌더 실패: {name}")
    return out


def main() -> None:
    made = []
    for raw, name, big in SCREENS:
        if not (SRC / "raw" / raw).exists():
            print(f"  건너뜀 (원본 없음): {raw}")
            continue
        made.append(render(screenshot_html(raw, big), name, PHONE_W, PHONE_H))
    made.append(render(FEATURE_HTML, "feature-graphic", FEATURE_W, FEATURE_H))

    for f in made:
        print(f"  {f.name}")


if __name__ == "__main__":
    main()
