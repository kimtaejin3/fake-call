#!/usr/bin/env python3
"""마스코트 아이콘을 각 플랫폼이 요구하는 크기로 내보낸다.

한 번 크게(1024) 렌더한 뒤 sips 로 줄인다. 크기별로 Chrome 을 다시 부르면
안 되는 이유: headless Chrome 은 창 크기에 최소값이 있어 `--window-size=48,48`
같은 값이 무시되고 더 큰 뷰포트로 렌더된다. vw 로 잡은 요소는 그 큰 뷰포트를
기준으로 배치되는데 스크린샷은 좌상단만 잘라내므로, 가운데 있어야 할 오브가
우측 아래로 밀려 잘린다.

사용법:  python3 make_icons.py
"""
import subprocess
from pathlib import Path

SRC = Path(__file__).resolve().parent
ROOT = SRC.parents[2]                      # 프로젝트 루트
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

ANDROID = {                                # 밀도별 런처 아이콘
    "mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192,
}
IOS = {                                    # Contents.json 이 참조하는 파일명
    "Icon-App-20x20@1x.png": 20, "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60, "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58, "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40, "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120, "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180, "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152, "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


MASTER = 1024


def render_master(out: Path) -> None:
    """원본 한 장을 벡터 그대로 렌더한다."""
    subprocess.run(
        [CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1", "--allow-file-access-from-files",
         "--virtual-time-budget=3000",
         f"--screenshot={out}", f"--window-size={MASTER},{MASTER}",
         f"file://{SRC / 'icon.html'}"],
        capture_output=True, check=False,
    )
    assert out.exists(), "원본 렌더 실패"


def resize(master: Path, out: Path, size: int) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["sips", "-z", str(size), str(size), str(master),
                    "--out", str(out)], capture_output=True, check=True)
    assert out.exists(), f"축소 실패: {out}"


def main() -> None:
    master = SRC / "_icon-master.png"
    render_master(master)

    for density, size in ANDROID.items():
        resize(master,
               ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png",
               size)
    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for name, size in IOS.items():
        resize(master, ios_dir / name, size)
    resize(master, SRC.parent / "icon-512.png", 512)   # Play 스토어 등록용
    master.unlink()
    print(f"  Android {len(ANDROID)}개, iOS {len(IOS)}개, 스토어 1개 생성")


if __name__ == "__main__":
    main()
