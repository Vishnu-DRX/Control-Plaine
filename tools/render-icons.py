"""Renders docs/icons/*.svg to @Resources/Icons/<name>.png for Rainmeter.

Each PNG is drawn at the exact pixel size its skin shows it at (scale 1), so
Rainmeter never resamples it: resampling a larger PNG down is what made the
icons soft. The 24-unit icon fills 3/4 of a square box (IconBox 32 for most
icons), white, no shadow. Rainmeter tints the white with ImageTint. At a Scale
other than 1 the PNGs are resampled, so re-render with ICON_SCALE=<Scale> for
the sharpest result.

Sizes and stroke widths follow the rules of tools/render-icons.js (keep the two in
step; this one adds the offset search) (2.2 units
becomes 2 px; boosted icons keep their line weight in px; the rest are as
drawn). On top of that each icon is rendered at a range of sub-pixel offsets
(at most half a pixel either way) and the one with the fewest half-covered
pixels is kept: Lucide's coordinates sit on .5 as often as on whole units, so
no single fixed offset suits every icon, and a stroke on a half pixel is what
makes lines look soft. Variants that swap in one slot (the Wi-Fi icons) share
one offset.

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
       'globe-disconnected', 'lightbulb', 'move-horizontal', 'rgb', 'snowflake', 'wifi', 'wifi-1',
       'wifi-2', 'wifi-no-internet-badge'}
APP_SCALE = SCALE * BOOST   # the Controllers canvas below is boosted too

# Box size (px at scale 1) per icon; everything else uses IconBox (32).
BOX = {
    'trash': 56, 'trash-empty': 56,          # RecycleBin IconW
    'lightbulb': 24,                         # DeepCool label
    'gauge': 24,                             # WiFi speed test button
    'snowflake': 24, 'move-horizontal': 24,  # FanControl MAX switch
    'arrow-down': 16, 'arrow-up': 16,        # WiFi speed test result
}

# Controllers icons are drawn larger than the rest (CTL px per 24-unit icon)
# and fitted to one common canvas: IconBox high like every other row, as wide
# as the widest glyph plus IconPad each side. Each glyph sits IconPad from the
# left edge and centred vertically, so the three icons share a left edge and
# the skin lines up with the others (icon at 0,0, text at width + 4).
FIT = ['controller-xbox', 'controller-dualsense', 'wheel-moza']
CTL = 33
PAD = 4
# Trimmed so the three glyphs match the 28 px of the other row icons (a wide
# gamepad or wheel drawn at CTL px per unit is 36-39 px wide).
TRIM = {'controller-xbox': 0.8, 'controller-dualsense': 0.75, 'wheel-moza': 0.85}

# Line weight in px for the row icons that sit side by side in the app skins
# (the Controllers glyphs get the 2 px of the Fan Control, DeepCool ... icons
# instead of 2.3-2.6 px) and for Wi-Fi, three thin arcs that carry about half
# the ink of the others at 2 px and read dimmer.
FIT_STROKE = 2
STROKE_PX = {'wifi': 3, 'wifi-1': 3, 'wifi-2': 3}

# Icons that are not rendered from an SVG (the app's own bitmap logo).
SKIP = {'signalrgb'}
# Variants that swap into one slot share one sub-pixel offset, so they do not
# jump when the skin changes icon.
SAME_SHIFT = {'wifi-1': 'wifi', 'wifi-2': 'wifi', 'wifi-no-internet-badge': 'wifi'}

# Icons with colour (the Warn orange badge) also get a <name>-light.png for
# light mode: a tint multiplies, so black ink would turn the badge black. The
# twin has a black body and the light-mode orange (WarnLight in Theme.inc). The
# skin draws both untinted. Keep in step with COLOURED in tools/check_icons.py.
LIGHT = {'globe-disconnected', 'wifi-no-internet-badge'}


def light_svg(svg):
    s = re.sub(r'#fff\b', '#000', svg).replace('#ffaa3c', '#d66e00')
    # The dark disc that hides the globe behind the badge becomes a cut-out.
    if ' fill="#1a1d22"' in s:
        cut = ('<defs><mask id="cut" maskUnits="userSpaceOnUse" x="0" y="0" width="24" height="24">'
               '<rect width="24" height="24" fill="#fff" stroke="none"/>'
               '<circle cx="19" cy="18" r="5" fill="#000" stroke="none"/></mask></defs><g mask="url(#cut)">')
        s = (s.replace(' fill="#1a1d22"', '').replace('<circle cx="19"', '</g><circle cx="19"', 1)
             .replace('<circle cx="11"', cut + '<circle cx="11"', 1))
    return s


# Sub-pixel offsets tried per axis, in px. Kept within half a pixel so an icon
# never drifts visibly off centre.
STEPS = [(i - 4) / 8 for i in range(8)]   # -0.5 .. +0.375


def strip(svg):
    return re.sub(r'<metadata>[\s\S]*?</metadata>', '', svg)


def with_view(svg, w, h, vx, vy, vw, vh):
    """Give the root <svg> a w x h px box showing the user-space rectangle
    vx vy vw vh (so a sub-pixel shift is just a different vx, vy)."""
    def root(m):
        tag = re.sub(r'\s(width|height|viewBox)="[^"]*"', '', m.group(0))
        return tag[:-1] + ' width="%s" height="%s" viewBox="%s %s %s %s" ' \
            'style="display:block;overflow:visible">' % (w, h, vx, vy, vw, vh)
    return re.sub(r'<svg\b[^>]*>', root, svg, count=1)


def measure(page, svg):
    page.set_content('<html><body>%s</body></html>' % svg)
    return page.evaluate("""() => {
        const el = document.querySelector('svg');
        const b = el.getBBox();
        return {x: b.x, y: b.y, w: b.width, h: b.height,
                sw: parseFloat(el.getAttribute('stroke-width') || '0')};
    }""")


def roughness(a):
    """Amount of half-covered pixels in an alpha channel: 0 = every pixel is
    either solid or empty."""
    a = a.astype(np.float32)
    return float(np.minimum(a, 255 - a).sum())


def best_of(page, cells, w, h, force=None):
    """cells: list of (dx, dy, svg). Renders them on one sheet and returns the
    least rough tile, its roughness, the unshifted one's and the shift."""
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
        if force is not None and (dx, dy) != force:
            continue
        # Prefer the smaller shift when roughness is (nearly) the same.
        score = r + 25 * (abs(dx) + abs(dy))
        if best is None or score < best[0]:
            best = (score, r, tile, dx, dy)
    return best[2], best[1], base, best[3], best[4]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    shifts = {}
    with sync_playwright() as p:
        opts = {}
        if os.environ.get('CHROMIUM_PATH'):
            opts['executable_path'] = os.environ['CHROMIUM_PATH']
        browser = p.chromium.launch(**opts)
        page = browser.new_page()

        def save(name, cw, ch, cells):
            tile, r, base, dx, dy = best_of(page, cells, cw, ch, shifts.get(SAME_SHIFT.get(name)))
            shifts[name] = (dx, dy)
            tile.save(OUT / (name + '.png'))
            print('%s.png %dx%d  rough %.0f -> %.0f  shift %+.3f,%+.3f' % (name, cw, ch, base, r, dx, dy))

        # ---- Controllers: one canvas, glyphs fitted to it ----
        fit = {}
        for name in FIT:
            svg = strip((SRC / (name + '.svg')).read_text(encoding='utf8'))
            m = measure(page, svg)
            k = CTL * APP_SCALE / 24 * TRIM.get(name, 1)
            if m['sw']:
                svg = re.sub(r'stroke-width="[\d.]+"', 'stroke-width="%s"' % (FIT_STROKE * SCALE / k), svg)
                m['sw'] = FIT_STROKE * SCALE / k
            fit[name] = (svg, m, k)
        fit_w = math.ceil(max((m['w'] + m['sw']) * k for _, m, k in fit.values()) + 2 * PAD * APP_SCALE)
        fit_h = round(32 * APP_SCALE)
        for name in FIT:
            svg, m, k = fit[name]
            sw = m['sw']
            gh = (m['h'] + sw) * k
            left, top = round(PAD * APP_SCALE), round((fit_h - gh) / 2)
            cells = []
            for dy in STEPS:
                for dx in STEPS:
                    # The glyph's top-left (bbox minus half a stroke) lands at
                    # (left + dx, top + dy) px.
                    vx = m['x'] - sw / 2 - (left + dx) / k
                    vy = m['y'] - sw / 2 - (top + dy) / k
                    cells.append((dx, dy, with_view(svg, fit_w, fit_h, vx, vy, fit_w / k, fit_h / k)))
            save(name, fit_w, fit_h, cells)

        # ---- Everything else: icon centred in a square box ----
        files = sorted(SRC.glob('*.svg'), key=lambda f: (f.stem in SAME_SHIFT, f.stem))
        jobs = []
        for f in files:
            jobs.append((f, False))
            if f.stem in LIGHT:
                jobs.append((f, True))
        for f, light in jobs:
            name = f.stem
            if name in FIT or name in SKIP:
                continue
            box =round(BOX.get(name, 32) * (APP_SCALE if name in APP else SCALE))
            # The DeepCool logo sits on a 3-unit grid: 4 px cells keep every
            # block the same size.
            icon = round(box * 0.8) if name == 'deepcool' else box * 3 / 4
            k = icon / 24
            svg = strip(f.read_text(encoding='utf8'))
            if light:
                svg = light_svg(svg)
            # Block logos on a pixel grid (deepcool) snap to whole pixels.
            svg = svg.replace('fill="#fff" stroke="none"', 'fill="#fff" stroke="none" shape-rendering="crispEdges"')

            def stroke(m, name=name, icon=icon):
                w = m.group(1)
                if w != '2.2' and name not in APP:
                    return m.group(0)
                # 2.2 units snaps to 2 px; boosted icons keep their line
                # weight in px, only the shape grows.
                px = STROKE_PX.get(name, 2 if w == '2.2' else float(w))
                return 'stroke-width="%s"' % (px * SCALE * 24 / icon)
            svg = re.sub(r'stroke-width="([\d.]+)"', stroke, svg)
            lead = (box - icon) / 2
            cells = []
            for dy in STEPS:
                for dx in STEPS:
                    cells.append((dx, dy, with_view(svg, box, box, -(lead + dx) / k, -(lead + dy) / k, box / k, box / k)))
            if light:
                # The twin shares its original's sub-pixel offset.
                SAME_SHIFT[name + '-light'] = name
            save(name + ('-light' if light else ''), box, box, cells)
        browser.close()


if __name__ == '__main__':
    main()
