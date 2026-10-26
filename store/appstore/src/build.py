#!/usr/bin/env python3
"""App Store 등록용 스크린샷을 만든다.

원본(raw/*.png, 1320x2868 — capture.js 가 만든다)을 배경·카피와 함께
합성한다. 카피와 배경은 Play 스토어 자료(store/play)와 같은 톤으로 맞추고,
렌더러도 같은 headless Chrome 이라 지정한 픽셀 크기가 그대로 나온다.

App Store Connect 는 6.9" 스크린샷만 올리면 더 작은 iPhone 에는 알아서
축소해 쓴다. 그래서 6.9" 한 벌만 만든다.

사용법:  python3 build.py
        (Chrome 경로가 다르면 CHROME=/path/to/chrome python3 build.py)
"""

import os
import subprocess
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent
OUT = SRC.parent
CHROME = os.environ.get(
    "CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

# App Store Connect 6.9" 디스플레이 규격 (iPhone 16 Pro Max 세로)
W, H = 1320, 2868

# (원본, 출력 파일명, 카피) — 문구는 store/play/src/build.py 의 SCREENS 와
# 같다. 원칙은 store/play/README.md 의 "카피 원칙" 참고.
SCREENS = [
    ("incoming.png", "01-incoming", "가짜 전화를<br>걸어줄 수 있어요"),
    ("home.png", "02-home", "이름과 시간만<br>정하면 돼요"),
    ("active.png", "03-active", "통화 화면까지<br>똑같이 만들었어요"),
]


def screenshot_html(raw: str, big: str) -> str:
    """스토어 스크린샷 한 장의 HTML. Play 판(1080x1920)을 이 비율로 키웠다."""
    return f"""<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="../../play/src/_base.css">
<style>
  html,body {{ width:{W}px; height:{H}px; }}
  .blob.a {{ width:760px; height:760px; top:-230px; left:-210px;
             background:radial-gradient(circle,rgba(139,124,246,.30),transparent 70%); }}
  .blob.b {{ width:640px; height:640px; top:-110px; right:-230px;
             background:radial-gradient(circle,rgba(124,155,248,.26),transparent 70%); }}
  .blob.c {{ width:900px; height:900px; bottom:-300px; left:-200px;
             background:radial-gradient(circle,rgba(196,181,253,.28),transparent 70%); }}
  .wrap {{ position:relative; height:100%;
           display:flex; flex-direction:column; align-items:center; }}
  h1 {{ margin:190px 0 0; font-size:104px; line-height:1.24; font-weight:700;
        color:#332E52; text-align:center; letter-spacing:-2.4px;
        word-break:keep-all; }}
  /* 흰 베젤 + 부드러운 그림자로 기기처럼 보이게 */
  .device {{ margin-top:120px; width:960px; padding:16px; background:#fff;
             border-radius:120px; box-shadow:0 40px 90px rgba(74,58,140,.22); }}
  .device img {{ display:block; width:100%; border-radius:104px; }}
</style></head><body>
<div class="bg"></div>
<div class="blob a"></div><div class="blob b"></div><div class="blob c"></div>
<div class="wrap">
  <h1>{big}</h1>
  <div class="device"><img src="raw/{raw}"></div>
</div></body></html>"""


def render(html: str, name: str) -> Path:
    """HTML 을 정확히 W×H 픽셀 PNG 로 렌더한다."""
    page = SRC / f"_{name}.html"
    page.write_text(html, encoding="utf-8")
    out = OUT / f"{name}.png"
    subprocess.run(
        [CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1",
         "--allow-file-access-from-files",
         # 폰트/이미지 로딩이 끝난 뒤 캡처한다 (store/play/src/build.py 참고)
         "--virtual-time-budget=4000",
         f"--screenshot={out}", f"--window-size={W},{H}",
         f"file://{page}"],
        capture_output=True, check=False,
    )
    if not out.exists():
        sys.exit(f"렌더 실패: {name}")
    return out


def main() -> None:
    for raw, name, big in SCREENS:
        if not (SRC / "raw" / raw).exists():
            print(f"  건너뜀 (원본 없음): {raw}")
            continue
        print(f"  {render(screenshot_html(raw, big), name).name}")


if __name__ == "__main__":
    main()
