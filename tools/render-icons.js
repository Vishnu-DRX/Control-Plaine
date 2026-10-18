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
// Extra size of the skins that use SizeBoost (Controllers, DeepCool, Fan
// Control, SignalRGB, Wi-Fi): keep in step with SizeBoost in
// @Resources\Defaults.inc.
const BOOST = 1.25;
const APP = new Set(['airplane', 'arrow-down', 'arrow-up', 'deepcool', 'ethernet', 'fan', 'gauge',
  'globe-disconnected', 'lightbulb', 'move-horizontal', 'rgb', 'snowflake', 'wifi', 'wifi-1', 'wifi-2',
  'wifi-no-internet-badge']);
const appScale = scale * BOOST;

// Icons with colour (the Warn orange badge) also get a <name>-light.png for
// light mode: a tint multiplies, so black ink would turn the badge black. The
// twin has a black body and the light-mode orange (WarnLight in Theme.inc). The
// skin draws both untinted. Keep in step with COLOURED in tools/check_icons.py.
const LIGHT = new Set(['globe-disconnected', 'wifi-no-internet-badge']);
function lightSvg(svg) {
  let s = svg.replace(/#fff\b/g, '#000').replace(/#ffaa3c/g, '#d66e00');
  // The dark disc that hides the globe behind the badge becomes a cut-out.
  if (s.includes(' fill="#1a1d22"')) {
    const cut = '<defs><mask id="cut" maskUnits="userSpaceOnUse" x="0" y="0" width="24" height="24">' +
      '<rect width="24" height="24" fill="#fff" stroke="none"/>' +
      '<circle cx="19" cy="18" r="5" fill="#000" stroke="none"/></mask></defs><g mask="url(#cut)">';
    s = s.replace(' fill="#1a1d22"', '').replace('<circle cx="19"', '</g><circle cx="19"')
      .replace('<circle cx="11"', cut + '<circle cx="11"');
  }
  return s;
}   // the Controllers canvas below is boosted too

// Box size (px at scale 1) per icon; everything else uses IconBox (32).
const BOX = {
  'trash': 56, 'trash-empty': 56,                    // RecycleBin IconW
  'lightbulb': 24,                                   // DeepCool label
  'gauge': 24,                                       // WiFi speed test button
  'snowflake': 24, 'move-horizontal': 24,                                  // FanControl MAX switch
  'arrow-down': 16, 'arrow-up': 16,                  // WiFi speed test result
};

// Controllers icons are drawn larger than the rest (CTL px per 24-unit icon)
// and fitted to one common canvas: IconBox high like every other row, as wide
// as the widest glyph plus IconPad each side. Each glyph sits IconPad from the
// left edge and centred vertically, so the three icons share a left edge and
// the skin lines up with the others (icon at 0,0, text at width + 4).
const FIT = ['controller-xbox', 'controller-dualsense', 'wheel-moza'];
const CTL = 33;
const PAD = 4;
// The wheel reads larger than the pads at the same size: draw it a bit smaller.
const TRIM = { 'wheel-moza': 0.9 };

// Glyph size in px (stroke included) at CTL px per 24 units, and the viewBox
// that crops the SVG to it.
async function measure(browser, name) {
  const svg = readFileSync(join(src, name + '.svg'), 'utf8').replace(/<metadata>[\s\S]*?<\/metadata>/, '');
  const page = await browser.newPage();
  await page.setContent(`<html><body>${svg}</body></html>`);
  const m = await page.evaluate(() => {
    const el = document.querySelector('svg');
    const b = el.getBBox();
    return { x: b.x, y: b.y, w: b.width, h: b.height, sw: parseFloat(el.getAttribute('stroke-width') || '0') };
  });
  await page.close();
  const k = CTL * appScale / 24 * (TRIM[name] || 1);
  return { svg, vb: [m.x - m.sw / 2, m.y - m.sw / 2, m.w + m.sw, m.h + m.sw], k };
}

(async () => {
const browser = await chromium.launch(
  process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});

const fit = {};
for (const name of FIT) fit[name] = await measure(browser, name);
const fitW = Math.ceil(Math.max(...FIT.map(n => fit[n].vb[2] * fit[n].k)) + 2 * PAD * appScale);
const fitH = Math.round(32 * appScale);
for (const name of FIT) {
  const { svg, vb, k } = fit[name];
  const w = vb[2] * k, h = vb[3] * k;
  const page = await browser.newPage({ viewport: { width: fitW, height: fitH } });
  const body = svg
    .replace(/viewBox="[^"]*"/, `viewBox="${vb.join(' ')}"`)
    .replace(/width="24" height="24"/, `width="${w}" height="${h}"`);
  await page.setContent(`<html><body style="margin:0;background:transparent">
    <div style="position:relative;width:${fitW}px;height:${fitH}px">
    <div style="position:absolute;left:${Math.round(PAD * appScale)}px;top:${Math.round((fitH - h) / 2)}px">${body}</div></div></body></html>`);
  await page.locator('div').first().screenshot({ path: join(out, name + '.png'), omitBackground: true });
  await page.close();
  console.log(name + '.png', fitW + 'x' + fitH);
}

const jobs = [];
for (const file of readdirSync(src).filter(f => f.endsWith('.svg')).sort()) {
  jobs.push({ file, light: false });
  if (LIGHT.has(basename(file, '.svg'))) jobs.push({ file, light: true });
}
for (const { file, light } of jobs) {
  const name = basename(file, '.svg');
  if (FIT.includes(name)) continue;
  // signalrgb.png is the app's own bitmap logo, not rendered from an SVG.
  if (name === 'signalrgb') continue;
  const box = Math.round((BOX[name] || 32) * (APP.has(name) ? appScale : scale));
  // The DeepCool logo sits on a 3-unit grid: 4 px cells keep every block the same size.
  const icon = name === 'deepcool' ? Math.round(box * 0.8) : box * 3 / 4;
  const page = await browser.newPage({ viewport: { width: box, height: box } });
  const svg = (light ? lightSvg : (x) => x)(readFileSync(join(src, file), 'utf8'))
    .replace(/<metadata>[\s\S]*?<\/metadata>/, '')
    // Block logos on a pixel grid (deepcool) snap to whole pixels instead of blurring.
    .replace('fill="#fff" stroke="none"', 'fill="#fff" stroke="none" shape-rendering="crispEdges"')
    .replace(/width="24" height="24"/, `width="${icon}" height="${icon}"`)
    // 2.2 units is 2.2 px at 24 px: snap to 2 px so straight lines land on
    // whole pixels instead of smearing over three.
    // Boosted icons keep their original line weight in pixels (2.2 -> 2, others
    // as drawn); only the shape grows, so lines do not get heavier.
    .replace(/stroke-width="([\d.]+)"/g, (m, w) => (w !== '2.2' && !APP.has(name) ? m : `stroke-width="${(w === '2.2' ? 2 : Number(w)) * 24 / icon}"`));
  await page.setContent(`<html><body style="margin:0;background:transparent">
    <div style="width:${box}px;height:${box}px;display:flex;align-items:center;justify-content:center">
    ${svg}</div></body></html>`);
  await page.locator('div').screenshot({ path: join(out, name + (light ? '-light' : '') + '.png'), omitBackground: true });
  await page.close();
  console.log(name + (light ? '-light' : '') + '.png', box);
}
await browser.close();
})();
