// Renders docs/icons/*.svg to @Resources/Icons/<name>.png for Rainmeter.
// Each PNG is 128x128 (IconBox 32 x 4): the 24-unit icon drawn at 96 px in the
// centre, white, with the suite's shadow (0 1px 3px rgba(0,0,0,.45) at 4x)
// baked in. Rainmeter tints the white with ImageTint; the black shadow stays.
//
// Dev-time only: node tools/render-icons.js (needs Playwright + Chromium).
const { chromium } = require('playwright');
const { readFileSync, readdirSync } = require('node:fs');
const { join, basename } = require('node:path');

const root = join(__dirname, '..');
const src = join(root, 'docs', 'icons');
const out = join(root, '@Resources', 'Icons');

(async () => {
const browser = await chromium.launch(
  process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
const page = await browser.newPage({ viewport: { width: 128, height: 128 } });
for (const file of readdirSync(src).filter(f => f.endsWith('.svg')).sort()) {
  const svg = readFileSync(join(src, file), 'utf8')
    .replace(/<metadata>[\s\S]*?<\/metadata>/, '')
    .replace(/width="24" height="24"/, 'width="96" height="96"');
  await page.setContent(`<html><body style="margin:0;background:transparent">
    <div style="width:128px;height:128px;display:flex;align-items:center;justify-content:center;
      filter:drop-shadow(0 4px 12px rgba(0,0,0,.45))">${svg}</div></body></html>`);
  const name = basename(file, '.svg') + '.png';
  await page.locator('div').screenshot({ path: join(out, name), omitBackground: true });
  console.log(name);
}
await browser.close();
})();
