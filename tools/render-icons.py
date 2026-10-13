"""Renders docs/icons/*.svg to @Resources/Icons/<name>.png for Rainmeter.

Each PNG is drawn at the exact pixel size its skin shows it at (scale 1), so
Rainmeter never resamples it: resampling a larger PNG down is what made the
icons soft. The 24-unit icon fills 3/4 of a square box (IconBox 32 for most
icons), white, no shadow. Rainmeter tints the white with ImageTint. At a Scale
other than 1 the PNGs are resampled, so re-render with ICON_SCALE=<Scale> for
the sharpest result.

Two things keep straight lines on whole pixels instead of smeared over three:
  * every stroke width is rounded to a whole number of pixels, and
  * each icon is rendered at a range of sub-pixel offsets (at most half a
    pixel either way) and the one with the fewest half-covered pixels is kept.
    Lucide's coordinates sit on .5 as often as on whole units, so no single
    fixed offset suits every icon.

Dev-time only: python tools/render-icons.py
(needs `pip install playwright pillow numpy` and Chromium, either the one
Playwright installs or CHROMIUM_PATH=<chrome.exe>).
"""
import io
import math
import os
import pathlib
import re

import numpy as np
from PIL import Image
from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'docs' / 'icons'
OUT = ROOT / '@Resources' / 'Icons'
SCALE = float(os.environ.get('ICON_SCALE', 1))
# Extra size of the skins that use SizeBoost (Controllers, DeepCool, Fan
# Control, SignalRGB, Wi-Fi): keep in step with SizeBoost in
# @Resources\Defaults.inc.
BOOST = 1.25
APP = {'airplane', 'arrow-down', 'arrow-up', 'deepcool', 'ethernet', 'fan', 'gauge',
       'globe-disconnected', 'lightbulb', 'move-horizontal', 'rgb', 'signalrgb', 'snowflake', 'wifi',
       'wifi-1', 'wifi-2', 'wifi-no-internet-badge'}
APP_SCALE = SCALE * BOOST   # the Controllers canvas below is boosted too

# Box size (px at scale 1) per icon; everything else uses IconBox (32).
BOX = {
    'trash': 56, 'trash-empty': 56,          # RecycleBin IconW
    'lightbulb': 24,                         # DeepCool label
    'gauge': 24,                             # WiFi speed test button
    'snowflake': 24, 'move-horizontal': 24,  # FanControl MAX switch
    'arrow-down': 16, 'arrow-up': 16,        # WiFi speed test result
}

# The row icons of Fan Control, SignalRGB, DeepCool, Wi-Fi and Controllers are
# drawn to one size and one line weight, so they read as a set: each glyph is
# scaled until its longer side (stroke included) is MATCH_PX px, and every
# stroke is MATCH_STROKE px. A wide glyph (a gamepad, Wi-Fi) is therefore
# shorter than a tall one, as in any icon set, but none is bigger or bolder.
MATCH = {'fan', 'signalrgb', 'deepcool', 'wifi', 'wifi-1', 'wifi-2', 'wifi-no-internet-badge',
         'ethernet', 'airplane', 'globe-disconnected'}
# Variants drawn on the same grid as another icon (same size, same position),
# so swapping them in the skin changes nothing but the glyph.
SAME_GRID = {'wifi-1': 'wifi', 'wifi-2': 'wifi', 'wifi-no-internet-badge': 'wifi'}
MATCH_PX = 28
MATCH_STROKE = 2
# Wi-Fi is three thin arcs and a dot: at the common weight it carries about
# 60% of the ink of the others and reads dimmer, so its strokes are one pixel
# heavier. (px at scale 1; the variants share the wifi grid.)
STROKE_EXTRA = {'wifi': 1, 'wifi-1': 1, 'wifi-2': 1}
# The Controllers icons share one canvas: IconBox high like every other row and
# as wide as the widest glyph plus the same side margin the 40 px boxes above
# give a 28 px glyph. The glyphs sit that margin from the left edge and are
# centred vertically, so the skin lines up with the others (icon at 0,0, text
# at width + 4).
FIT = ['controller-xbox', 'controller-dualsense', 'wheel-moza']

# Sub-pixel offsets tried per axis, in px. Kept within half a pixel so an icon
# never drifts visibly off centre.
STEPS = [(i - 4) / 8 for i in range(8)]   # -0.5 .. +0.375


def strip(svg):
    return re.sub(r'<metadata>[\s\S]*?</metadata>', '', svg)


def snap_strokes(svg, k):
    """Round every stroke-width to whole pixels (k = px per user unit)."""
    def fix(m):
        px = max(1, round(float(m.group(1)) * k))
        return 'stroke-width="%s"' % (px / k)
    return re.sub(r'stroke-width="([\d.]+)"', fix, svg)


def with_view(svg, w, h, vx, vy, vw, vh):
    """Give the root <svg> a w x h px box showing the user-space rectangle
    vx vy vw vh (so a sub-pixel shift is just a different vx, vy)."""
    def root(m):
        tag = m.group(0)
        tag = re.sub(r'\s(width|height|viewBox)="[^"]*"', '', tag)
        return tag[:-1] + ' width="%s" height="%s" viewBox="%s %s %s %s" ' \
            'style="display:block;overflow:visible">' % (w, h, vx, vy, vw, vh)
    return re.sub(r'<svg\b[^>]*>', root, svg, count=1)


def measure(page, svg):
    page.set_content('<html><body>%s</body></html>' % svg)
    return page.evaluate('''() => {
        const el = document.querySelector('svg');
        const b = el.getBBox();
        return {x: b.x, y: b.y, w: b.width, h: b.height,
                sw: parseFloat(el.getAttribute('stroke-width') || '0')};
    }''')


def roughness(a):
    """Amount of half-covered pixels in an alpha channel: 0 = every pixel is
    either solid or empty."""
    a = a.astype(np.float32)
    return float(np.minimum(a, 255 - a).sum())


def best_of(page, cells, w, h, force=None):
    """cells: list of (dx, dy, svg). Renders them on one sheet and returns the
    PNG bytes of the least rough one, plus its roughness, the roughness of the
    unshifted one and the shift chosen."""
    cols = len(STEPS)
    rows = math.ceil(len(cells) / cols)
    divs = ''.join(
        '<div style="position:absolute;left:%dpx;top:%dpx;width:%dpx;height:%dpx">%s</div>'
        % ((i % cols) * w, (i // cols) * h, w, h, svg) for i, (_, _, svg) in enumerate(cells))
    page.set_viewport_size({'width': cols * w, 'height': rows * h})
    page.set_content('<html><body style="margin:0;background:transparent">%s</body></html>' % divs)
    sheet = Image.open(io.BytesIO(page.screenshot(omit_background=True))).convert('RGBA')
    best = None
    base = None
    for i, (dx, dy, _) in enumerate(cells):
        x, y = (i % cols) * w, (i // cols) * h
        tile = sheet.crop((x, y, x + w, y + h))
        r = roughness(np.array(tile)[:, :, 3])
        if dx == 0 and dy == 0:
            base = r
        # Prefer the smaller shift when roughness is (nearly) the same.
        score = r + 25 * (abs(dx) + abs(dy))
        if force is not None and (dx, dy) != force:
            continue
        if best is None or score < best[0]:
            best = (score, r, tile, dx, dy)
    return best[2], best[1], base, best[3], best[4]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        opts = {}
        if os.environ.get('CHROMIUM_PATH'):
            opts['executable_path'] = os.environ['CHROMIUM_PATH']
        browser = p.chromium.launch(**opts)
        page = browser.new_page()

        # ---- Row icons drawn to one size (Controllers share a canvas) ----
        stroke_px = max(1, round(MATCH_STROKE * SCALE))
        target = MATCH_PX * SCALE
        pad = round((32 * APP_SCALE - target) / 2)

        def matched(name):
            """(svg, glyph w, glyph h, k, bbox, stroke px) with strokes and size matched."""
            svg = strip((SRC / (name + '.svg')).read_text(encoding='utf8'))
            ref = SAME_GRID.get(name, name)
            m = measure(page, strip((SRC / (ref + '.svg')).read_text(encoding='utf8')))
            sw = m['sw']
            spx = stroke_px + round(STROKE_EXTRA.get(name, 0) * SCALE)
            span = max(m['w'], m['h'])
            k = (target - (spx if sw else 0)) / span
            svg = re.sub(r'stroke-width="[\d.]+"', 'stroke-width="%s"' % (spx / k), svg)
            ex = spx if sw else 0
            return svg, m['w'] * k + ex, m['h'] * k + ex, k, m, spx

        shifts = {}

        def render(name, svg, k, m, cw, ch, left, top, spx):
            ex = (spx / k) / 2 if m['sw'] else 0
            cells = []
            for dy in STEPS:
                for dx in STEPS:
                    # The glyph's top-left (bbox minus half a stroke) lands at
                    # (left + dx, top + dy) px.
                    vx = m['x'] - ex - (left + dx) / k
                    vy = m['y'] - ex - (top + dy) / k
                    cells.append((dx, dy, with_view(svg, cw, ch, vx, vy, cw / k, ch / k)))
            ref = SAME_GRID.get(name)
            tile, r, base, dx, dy = best_of(page, cells, cw, ch, shifts.get(ref))
            shifts[name] = (dx, dy)
            tile.save(OUT / (name + '.png'))
            print('%s.png %dx%d  rough %.0f -> %.0f  shift %+.3f,%+.3f' % (name, cw, ch, base, r, dx, dy))

        fit = {n: matched(n) for n in FIT}
        fit_w = math.ceil(max(g[1] for g in fit.values()) + 2 * pad)
        fit_h = round(32 * APP_SCALE)
        for name, (svg, gw, gh, k, m, spx) in fit.items():
            render(name, svg, k, m, fit_w, fit_h, pad, (fit_h - gh) / 2, spx)
        box = round(32 * APP_SCALE)
        for name in sorted(MATCH):
            svg, gw, gh, k, m, spx = matched(name)
            if name == 'deepcool':
                # Block logo: edges snap to whole pixels.
                svg = svg.replace('fill="#fff" stroke="none"',
                                  'fill="#fff" stroke="none" shape-rendering="crispEdges"')
            render(name, svg, k, m, box, box, (box - gw) / 2, (box - gh) / 2, spx)

        # ---- Everything else: icon centred in a square box ----
        for f in sorted(SRC.glob('*.svg')):
            name = f.stem
            if name in FIT or name in MATCH:
                continue
            box = round(BOX.get(name, 32) * (APP_SCALE if name in APP else SCALE))
            icon = box * 3 / 4
            k = icon / 24
            svg = strip(f.read_text(encoding='utf8'))
            # Block logos on a pixel grid (deepcool) snap to whole pixels.
            svg = svg.replace('fill="#fff" stroke="none"', 'fill="#fff" stroke="none" shape-rendering="crispEdges"')
            svg = snap_strokes(svg, k)
            lead = (box - icon) / 2
            cells = []
            for dy in STEPS:
                for dx in STEPS:
                    cells.append((dx, dy, with_view(svg, box, box, -(lead + dx) / k, -(lead + dy) / k, box / k, box / k)))
            tile, r, base, dx, dy = best_of(page, cells, box, box)
            tile.save(OUT / (name + '.png'))
            print('%s.png %d  rough %.0f -> %.0f  shift %+.3f,%+.3f' % (name, box, base, r, dx, dy))
        browser.close()


if __name__ == '__main__':
    main()
