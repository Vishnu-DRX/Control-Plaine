"""Checks that every PNG in @Resources/Icons can follow the light/dark mode.

Run: python tools/check_icons.py                 (lists every icon and its class)
     python tools/check_icons.py --write-light   (see light_twin below)

Skins draw icons with ImageTint=#Ink#. A tint multiplies, so a white PNG with
alpha becomes black in light mode with its own alpha and anti-aliasing intact:
no second icon set is needed. That only holds while the PNG is white. A pixel
with colour (an orange badge) multiplied by black is black, so the badge would
lose its colour in light mode. Hence rule L7 (tools/lint.py): every icon is
white with alpha ("tintable"), or is on an explicit list below with the reason.

Classes:
  tintable   every visible pixel is white (>= WHITE_MIN per channel; the app's
             own signalrgb.png has 254) and only alpha varies.
  coloured   has non-white pixels. Must be in COLOURED. Drawn with
             ImageTint=255,255,255 (no tint) in both modes, and in light mode
             the skin shows the matching <name>-light.png instead.
  light      <name>-light.png of a coloured icon: black body, light-mode orange,
             otherwise the same pixels. Must derive from a COLOURED icon.
             Also drawn with no tint.

Standard library only (CI has no Pillow). Reads 8-bit RGB/RGBA PNGs.
"""
import pathlib
import struct
import sys
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
ICONS = ROOT / '@Resources' / 'Icons'
WHITE_MIN = 250

# Icons with colour on purpose, and why. Both are drawn untinted; the skin picks
# the -light file when Mode is light (docs/dev/conventions.md).
COLOURED = {
    'globe-disconnected': 'orange (Warn) badge on a white globe; a tint would turn the badge black',
    'wifi-no-internet-badge': 'orange (Warn) badge; a tint would turn it black',
}
# Light-mode twins of the above (black body, WarnLight orange 214,110,0).
LIGHT = {name + '-light': name for name in COLOURED}
WARN_LIGHT = (214, 110, 0)


def read_png(path):
    """Returns (width, height, rows) with rows a list of bytes, 4 per pixel."""
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('not a PNG')
    pos, idat, hdr = 8, b'', None
    while pos < len(data):
        n, kind = struct.unpack('>I4s', data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        pos += 12 + n
        if kind == b'IHDR':
            hdr = struct.unpack('>IIBBBBB', body)
        elif kind == b'IDAT':
            idat += body
    w, h, depth, ctype, _, _, interlace = hdr
    if depth != 8 or ctype not in (2, 6) or interlace:
        raise ValueError('only 8-bit RGB/RGBA, not interlaced')
    bpp = 4 if ctype == 6 else 3
    raw = zlib.decompress(idat)
    stride = w * bpp
    rows, prev = [], bytearray(stride)
    for y in range(h):
        f = raw[y * (stride + 1)]
        cur = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = cur[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            if f == 1:
                cur[i] = (cur[i] + a) & 255
            elif f == 2:
                cur[i] = (cur[i] + b) & 255
            elif f == 3:
                cur[i] = (cur[i] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                cur[i] = (cur[i] + pr) & 255
        prev = cur
        if bpp == 3:
            px = bytearray()
            for i in range(0, stride, 3):
                px += cur[i:i + 3] + b'\xff'
            rows.append(bytes(px))
        else:
            rows.append(bytes(cur))
    return w, h, rows


def write_png(path, w, h, rows):
    def chunk(kind, body):
        return struct.pack('>I', len(body)) + kind + body + struct.pack('>I', zlib.crc32(kind + body))
    raw = b''.join(b'\x00' + r for r in rows)
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
                     + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


def classify(path):
    """Returns (class, visible pixels, non-white pixels, non-black pixels)."""
    _, _, rows = read_png(path)
    vis = notwhite = notblack = 0
    for r in rows:
        for i in range(0, len(r), 4):
            if r[i + 3] == 0:
                continue
            vis += 1
            if min(r[i:i + 3]) < WHITE_MIN:
                notwhite += 1
            if max(r[i:i + 3]) > 0:
                notblack += 1
    return ('tintable' if notwhite == 0 else 'coloured'), vis, notwhite, notblack


def scan():
    """Yields (name, class, visible, non-white, problem or None)."""
    for path in sorted(ICONS.glob('*.png')):
        name = path.stem
        try:
            cls, vis, nw, nb = classify(path)
        except Exception as e:
            yield name, '?', 0, 0, f'cannot read ({e})'
            continue
        err = None
        if name in LIGHT:
            cls = 'light'
            if not (ICONS / (LIGHT[name] + '.png')).exists():
                err = f'{LIGHT[name]}.png (the original of this light twin) is missing'
        elif name in COLOURED:
            if cls == 'tintable':
                err = 'listed as coloured but is pure white; remove it from COLOURED'
            elif not (ICONS / (name + '-light.png')).exists():
                err = f'needs {name}-light.png (run tools/render-icons.js, or check_icons.py --write-light)'
        elif cls == 'coloured':
            err = (f'{nw} non-white pixel(s); icons must be white with alpha so ImageTint=#Ink# can '
                   f'follow light mode (re-render, or add to COLOURED in tools/check_icons.py with a reason)')
        yield name, cls, vis, nw, err


def problems():
    """Messages for tools/lint.py (rule L7)."""
    out = [f'@Resources/Icons/{n}.png: L7 {e}' for n, _, _, _, e in scan() if e]
    for name in COLOURED:
        if not (ICONS / (name + '.png')).exists():
            out.append(f'tools/check_icons.py: L7 COLOURED lists {name} but @Resources/Icons/{name}.png does not exist')
    return out


def light_twin(rows):
    """Derives the light-mode twin of a dark icon with an orange badge:
    white becomes black (alpha kept), orange becomes WARN_LIGHT, and the dark
    disc (26,29,34) that hides the globe behind the badge becomes transparent
    (its blend with the orange ring keeps the ring's share as alpha). A
    fallback for when Chromium is not at hand: tools/render-icons.js and .py
    render the same twin from the SVG, and win when they run."""
    d_r, o_r, o_b = 26, 255, 60
    out = []
    for r in rows:
        o = bytearray()
        for i in range(0, len(r), 4):
            R, G, B, A = r[i:i + 4]
            if A == 0:
                o += b'\0\0\0\0'
            elif min(R, G, B) >= WHITE_MIN:
                o += bytes((0, 0, 0, A))
            elif G >= 150:
                # Orange, possibly blended with white: B tells how much white.
                u = min(1.0, max(0.0, (B - o_b) / (255 - o_b)))
                o += bytes(round(c * (1 - u)) for c in WARN_LIGHT) + bytes((A,))
            else:
                # Orange blended with the dark disc: R tells the orange share.
                t = min(1.0, max(0.0, (R - d_r) / (o_r - d_r)))
                o += bytes(WARN_LIGHT) + bytes((round(A * t),))
        out.append(bytes(o))
    return out


def main():
    bad = 0
    print(f'{"icon":28} {"class":9} {"visible":>7} {"non-white":>9}')
    for name, cls, vis, nw, err in scan():
        print(f'{name:28} {cls:9} {vis:7} {nw:9}' + (f'   PROBLEM: {err}' if err else ''))
        bad += bool(err)
    print(f'{bad} problem(s)')
    return 1 if bad else 0


if __name__ == '__main__':
    if '--write-light' in sys.argv:
        for name in COLOURED:
            w, h, rows = read_png(ICONS / (name + '.png'))
            write_png(ICONS / (name + '-light.png'), w, h, light_twin(rows))
            print(f'wrote {name}-light.png')
    sys.exit(main())
