#!/usr/bin/env python3
"""마스코트 아이콘을 각 플랫폼이 요구하는 크기로 내보낸다.

icon.html 을 headless Chrome 으로 창 크기만 바꿔가며 렌더한다. 벡터(CSS
그라데이션 + SVG)라 어느 크기에서도 다시 그려지므로, 큰 이미지를 축소할
때 생기는 뭉개짐이 없다.

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


def render(out: Path, size: int) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1", "--allow-file-access-from-files",
         "--virtual-time-budget=3000",
         f"--screenshot={out}", f"--window-size={size},{size}",
         f"file://{SRC / 'icon.html'}"],
        capture_output=True, check=False,
    )
    assert out.exists(), f"렌더 실패: {out}"


def main() -> None:
    for density, size in ANDROID.items():
        render(ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png",
               size)
    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for name, size in IOS.items():
        render(ios_dir / name, size)
    render(SRC.parent / "icon-512.png", 512)   # Play 스토어 등록용
    print(f"  Android {len(ANDROID)}개, iOS {len(IOS)}개, 스토어 1개 생성")


if __name__ == "__main__":
    main()
