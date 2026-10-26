// App Store 스크린샷 원본(raw/*.png)을 Flutter 웹 빌드에서 찍는다.
//
// iOS 시뮬레이터 없이도 iOS 룩을 찍기 위해, 웹 빌드를 iPhone 으로 위장한
// headless Chromium 에 띄운다. Flutter 웹은 navigator.platform 으로
// defaultTargetPlatform 을 정하므로 'iPhone' 을 돌려주면 통화 화면이
// CallStyle.ios 로 그려진다.
//
// 웹에는 상태바·홈 인디케이터가 없어서 SafeArea 가 0 이 된다. 그래서 앱은
// 상태바/홈 인디케이터를 뺀 높이(956-62-34)로 찍고, 위아래 띠를 화면 끝
// 색으로 채운 뒤 상태바와 홈 인디케이터를 그려 6.9" 원본(1320×2868)을 만든다.
//
// 사용법 (저장소 루트에서):
//   flutter build web --release --no-web-resources-cdn
//   (cd build/web && python3 -m http.server 8765) &
//   node store/appstore/src/capture.js
//
// playwright 가 필요하다 (npm i -g playwright && npx playwright install chromium).

const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');

const URL = process.env.APP_URL || 'http://localhost:8765/';
const RAW = path.join(__dirname, 'raw');

// iPhone 16 Pro Max (6.9") 의 논리 해상도와 안전 영역
const W = 440, H = 956, TOP = 62, BOTTOM = 34, SCALE = 3;
const APP_H = H - TOP - BOTTOM;

const UA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) ' +
  'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1';

async function main() {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({
    viewport: { width: W, height: APP_H }, deviceScaleFactor: SCALE,
    isMobile: true, hasTouch: true, userAgent: UA, locale: 'ko-KR',
  });
  const page = await ctx.newPage();
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'platform', { get: () => 'iPhone' });
  });
  const tap = (x, y) => page.mouse.click(x, y);
  const shots = {};
  const shoot = async (name) => { shots[name] = await page.screenshot(); };

  await page.goto(URL);
  // 마스코트가 2~5초 간격으로 눈을 깜빡여서, 너무 이르면 감은 눈이 찍힌다.
  await page.waitForTimeout(6500);
  await shoot('home');

  // 전화 버튼 → 기본 30초 카운트다운 → 수신 화면
  await tap(381, APP_H - 131);
  await page.waitForTimeout(32000);
  await shoot('incoming');

  // 응답 → 통화 화면. 통화 시간이 0:0x 보다는 조금 흐른 편이 자연스럽다.
  await tap(360, 750);
  await page.waitForTimeout(13000);
  await shoot('active');

  // 찍은 화면에 상태바/홈 인디케이터를 입혀 1320×2868 로 저장한다.
  const frame = await browser.newPage({
    viewport: { width: W, height: H }, deviceScaleFactor: SCALE,
  });
  frame.on('pageerror', (e) => console.error(e));
  for (const [name, png] of Object.entries(shots)) {
    await frame.evaluate(() => { window.ready = false; });
    await frame.setContent(frameHtml(png.toString('base64')));
    await frame.waitForFunction(() => window.ready === true);
    await frame.screenshot({ path: path.join(RAW, `${name}.png`) });
    console.log(`  raw/${name}.png`);
  }
  await browser.close();
}

function frameHtml(b64) {
  return `<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;width:${W}px;height:${H}px;overflow:hidden;
    font-family:-apple-system,'Pretendard',sans-serif}
  #top,#bot{position:absolute;left:0;width:${W}px}
  #top{top:0;height:${TOP}px} #bot{bottom:0;height:${BOTTOM}px}
  #app{position:absolute;top:${TOP}px;left:0;width:${W}px;height:${APP_H}px}
  .time{position:absolute;top:19px;left:52px;font-size:17px;font-weight:600;letter-spacing:-.3px}
  .island{position:absolute;top:11px;left:${(W - 126) / 2}px;width:126px;height:37px;
    border-radius:19px;background:#000}
  .icons{position:absolute;top:21px;right:34px;display:flex;gap:6px;align-items:center}
  .home{position:absolute;bottom:8px;left:${(W - 144) / 2}px;width:144px;height:5px;border-radius:3px}
</style></head><body>
<canvas id="top"></canvas><canvas id="bot"></canvas>
<img id="app" src="data:image/png;base64,${b64}">
<div class="island"></div>
<div class="time">9:41</div>
<div class="icons">
  <svg width="19" height="12" viewBox="0 0 19 12"><g fill="currentColor">
    <rect x="0" y="8" width="3.2" height="4" rx="1"/><rect x="5" y="5.5" width="3.2" height="6.5" rx="1"/>
    <rect x="10" y="3" width="3.2" height="9" rx="1"/><rect x="15" y="0" width="3.2" height="12" rx="1"/></g></svg>
  <svg width="17" height="12" viewBox="0 0 17 12"><g fill="currentColor">
    <path d="M8.5 2.6c2.4 0 4.6.9 6.2 2.5l1.2-1.2C14 1.9 11.4.9 8.5.9S3 1.9 1.1 3.9l1.2 1.2C3.9 3.5 6.1 2.6 8.5 2.6z"/>
    <path d="M8.5 6c1.5 0 2.8.6 3.8 1.5l1.2-1.2C12.2 5 10.4 4.3 8.5 4.3S4.8 5 3.5 6.3l1.2 1.2C5.7 6.6 7 6 8.5 6z"/>
    <path d="M8.5 9.3c.6 0 1.1.2 1.5.6L8.5 11.5 7 9.9c.4-.4.9-.6 1.5-.6z"/></g></svg>
  <svg width="27" height="13" viewBox="0 0 27 13">
    <rect x=".5" y=".5" width="23" height="12" rx="3.8" fill="none" stroke="currentColor" opacity=".4"/>
    <rect x="2" y="2" width="20" height="9" rx="2.5" fill="currentColor"/>
    <path d="M25 4.5v4c.8-.3 1.3-1.1 1.3-2s-.5-1.7-1.3-2z" fill="currentColor" opacity=".45"/></svg>
</div>
<div class="home"></div>
<script>{
  // setContent 는 document.write 라 전역 const 가 페이지 사이에 남는다 — 블록으로 가둔다
  const img = document.getElementById('app');
  img.decode().then(() => {
    const c = document.createElement('canvas');
    c.width = img.naturalWidth; c.height = img.naturalHeight;
    const g = c.getContext('2d'); g.drawImage(img, 0, 0);
    // 글자색은 상태바/홈 영역 가운데 색의 밝기로 정한다
    const px = (y) => g.getImageData(Math.floor(c.width / 2), y, 1, 1).data;
    const dark = (d) => (0.299 * d[0] + 0.587 * d[1] + 0.114 * d[2]) < 140;
    const t = px(0), b = px(c.height - 1);
    // 맨 윗줄/아랫줄을 세로로 늘여 상태바·홈 영역을 채운다. 통화 화면은
    // 대각선 그라데이션이라 한 색으로 칠하면 경계가 보인다.
    const stretch = (id, y) => {
      const el = document.getElementById(id);
      el.width = c.width; el.height = 1;
      el.getContext('2d').drawImage(c, 0, y, c.width, 1, 0, 0, c.width, 1);
    };
    stretch('top', 0);
    stretch('bot', c.height - 1);
    const fg = dark(t) ? '#fff' : '#000';
    document.querySelector('.time').style.color = fg;
    document.querySelector('.icons').style.color = fg;
    document.querySelector('.home').style.background = dark(b) ? '#fff' : '#000';
    window.ready = true;
  });
}</script></body></html>`;
}

main().catch((e) => { console.error(e); process.exit(1); });
