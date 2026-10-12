// Renders docs/icons/*.svg to @Resources/Icons/<name>.png for Rainmeter.
// Each PNG is drawn at the exact pixel size its skin shows it at (scale 1),
// so Rainmeter never resamples it: resampling a larger PNG down is what made
// the icons soft. The 24-unit icon fills 3/4 of a square box (IconBox 32 for
// most icons), white, no shadow. Rainmeter tints the white with ImageTint.
// At a Scale other than 1 the PNGs are resampled, so re-render with
// ICON_SCALE=<Scale> for the sharpest result.
//
// Dev-time only: node tools/render-icons.js (needs Playwright + Chromium).
const { chromium } = require('playwright');
const { readFileSync, readdirSync } = require('node:fs');
const { join, basename } = require('node:path');

const root = join(__dirname, '..');
const src = join(root, 'docs', 'icons');
const out = join(root, '@Resources', 'Icons');
const scale = Number(process.env.ICON_SCALE || 1);

// Box size (px at scale 1) per icon; everything else uses IconBox (32).
const BOX = {
  'trash': 56, 'trash-empty': 56,                    // RecycleBin IconW
  'controller-xbox': 44, 'controller-dualsense': 44, // Controllers CtlIcon 33
  'wheel-moza': 44,
  'gauge': 24,                                       // WiFi speed test button
  'snowflake': 24, 'move-horizontal': 24,                                  // FanControl MAX switch
  'arrow-down': 16, 'arrow-up': 16,                  // WiFi speed test result
};

(async () => {
const browser = await chromium.launch(
  process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
for (const file of readdirSync(src).filter(f => f.endsWith('.svg')).sort()) {
  const name = basename(file, '.svg');
  const box = Math.round((BOX[name] || 32) * scale);
  const icon = box * 3 / 4;
  const page = await browser.newPage({ viewport: { width: box, height: box } });
  const svg = readFileSync(join(src, file), 'utf8')
    .replace(/<metadata>[\s\S]*?<\/metadata>/, '')
    .replace(/width="24" height="24"/, `width="${icon}" height="${icon}"`)
    // 2.2 units is 2.2 px at 24 px: snap to 2 px so straight lines land on
    // whole pixels instead of smearing over three.
    .replace(/stroke-width="2\.2"/g, `stroke-width="${2 * 24 / icon}"`);
  await page.setContent(`<html><body style="margin:0;background:transparent">
    <div style="width:${box}px;height:${box}px;display:flex;align-items:center;justify-content:center">
    ${svg}</div></body></html>`);
  await page.locator('div').screenshot({ path: join(out, name + '.png'), omitBackground: true });
  await page.close();
  console.log(name + '.png', box);
}
await browser.close();
})();
