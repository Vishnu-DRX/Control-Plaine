#!/usr/bin/env python3
"""Offline check of the Volume and RecycleBin layout formulas (left and right).

Reads the X/W formulas from Volume/Volume.ini and RecycleBin/RecycleBin.ini,
evaluates them at 100/125/150% Scale for both sides and asserts: one box and
one hit width on both sides, everything inside the box, values on whole
pixels, the right layout the mirror image of the left. Also runs Volume.lua's
RingClick (the ring moves with the side, the angle maths must not). Text
widths are estimates; the real ones need Rainmeter.

Usage: python3 tools/test_ringskins.py   (needs: pip install lupa)
"""
import math
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
failed = 0


def check(cond, msg):
    global failed
    if not cond:
        failed += 1
        print('FAIL:', msg)


def rnd(x):
    return math.floor(x + 0.5) if x >= 0 else -math.floor(-x + 0.5)


def load_vars(paths):
    out = {}
    for p in paths:
        in_vars = False
        for line in (ROOT / p).read_text().splitlines():
            if line.startswith('['):
                in_vars = line.strip() == '[Variables]'
            elif in_vars and re.match(r'^\w+=', line) and not line.startswith('@include'):
                k, v = line.split('=', 1)
                out[k] = v
    return out


def evaluate(expr, variables, extra):
    for _ in range(20):
        new = re.sub(r'#(\w+)#', lambda m: variables.get(m.group(1), m.group(0)), expr)
        if new == expr:
            break
        expr = new
    expr = re.sub(r'\[(\w+):(\w+)\]', lambda m: str(extra[(m.group(1), m.group(2))]), expr)
    expr = expr.replace('Round(', 'rnd(')
    return eval(expr, {'rnd': rnd, '__builtins__': {}})


def section(text, name):
    m = re.search(rf'^\[{name}\]\n(.*?)(?=^\[|\Z)', text, re.M | re.S)
    return dict(re.findall(r'^(\w+)=(.*)$', m.group(1), re.M))


def setup(skin, scale, side):
    mir = 1 if side == 'right' else 0
    files = ['@Resources/Theme.inc', '@Resources/Defaults.inc', f'{skin}/Defaults.inc', f'{skin}/{skin}.ini']
    v = load_vars(files)
    v.update({'Scale': str(scale), 'Sz': str(scale), 'Mir': str(mir), 'Lead': str(mir), 'Trail': str(1 - mir)})
    return v


def test_volume():
    ini = (ROOT / 'Volume' / 'Volume.ini').read_text()
    m = {n: section(ini, n) for n in ('Back', 'Pct', 'Label', 'Hairline', 'Device', 'Ring', 'Speaker')}
    for scale in (1.0, 1.25, 1.5):
        got = {}
        for side in ('left', 'right'):
            v = setup('Volume', scale, side)
            box = evaluate('#BoxW#', v, {})
            c = evaluate('#C#', v, {})
            pct_w = 5 * 14 * scale
            pct_x = evaluate(m['Pct']['X'], v, {})
            label_x = evaluate(m['Label']['X'], v, {('Pct', 'W'): pct_w})
            hair_x = evaluate(m['Hairline']['X'], v, {})
            hair_w = evaluate(m['Hairline']['W'], v, {})
            dev_x = evaluate(m['Device']['X'], v, {})
            dev_w = evaluate(m['Device']['ClipStringW'], v, {})
            ring_x = evaluate(m['Ring']['X'], v, {})
            spk_x = evaluate(m['Speaker']['X'], v, {})
            icon_w = float(v['IconBox']) * scale
            tag = f'volume {scale} {side}'
            got[side] = (box, ring_x, pct_x, hair_x, hair_w, spk_x)
            check(evaluate(m['Back']['W'], v, {}) == box, f'Back width is the box ({tag})')
            check(0 <= ring_x and ring_x + 2 * c <= box + 0.5, f'ring inside the box ({tag}) {ring_x}')
            check(abs(spk_x + icon_w / 2 - (ring_x + c)) <= 1, f'speaker centred on the ring ({tag})')
            check(0 <= hair_x and hair_x + hair_w <= box, f'hairline inside ({tag})')
            if side == 'left':
                check(ring_x == 0, f'ring first on the left ({tag})')
                check(pct_x >= 2 * c and label_x >= pct_x + pct_w and dev_x + dev_w <= box + 0.5,
                      f'text after the ring ({tag})')
            else:
                check(pct_x <= ring_x and dev_x <= ring_x, f'text before the ring ({tag})')
                check(label_x <= pct_x - pct_w and label_x >= 0, f'label left of the % ({tag})')
            for name, val in (('pct', pct_x), ('label', label_x), ('hairline', hair_x), ('device', dev_x),
                              ('ring', ring_x), ('speaker', spk_x)):
                check(val == int(val), f'{name} on a whole pixel ({tag}): {val}')
        l, r = got['left'], got['right']
        check(l[0] == r[0], f'same box on both sides (scale {scale})')
        check(abs(l[2] + r[2] - l[0]) <= 1, f'text anchor mirrors (scale {scale}): {l[2]} {r[2]}')
        check(abs(l[3] + r[3] + l[4] - l[0]) <= 1, f'hairline mirrors (scale {scale})')


def test_bin():
    ini = (ROOT / 'RecycleBin' / 'RecycleBin.ini').read_text()
    m = {n: section(ini, n) for n in ('Hit', 'Title', 'Detail', 'LinkEmpty', 'Icon')}
    for scale in (1.0, 1.25, 1.5):
        got = {}
        for side in ('left', 'right'):
            v = setup('RecycleBin', scale, side)
            box = evaluate('#BoxW#', v, {})
            icon_w = float(v['IconW']) * scale
            text_x = evaluate(m['Title']['X'], v, {})
            detail_x = evaluate(m['Detail']['X'], v, {})
            icon_x = evaluate(m['Icon']['X'], v, {})
            det_w = 6 * 8 * scale
            link_x = evaluate(m['LinkEmpty']['X'], v, {('Detail', 'W'): det_w})
            link_w = 5 * 8 * scale
            tag = f'bin {scale} {side}'
            got[side] = (box, icon_x, text_x)
            check(evaluate(m['Hit']['W'], v, {}) == box, f'Hit width is the box ({tag})')
            check(text_x == detail_x, f'Title and Detail share an anchor ({tag})')
            check(0 <= icon_x and icon_x + icon_w <= box + 0.5, f'icon inside the box ({tag})')
            if side == 'left':
                check(icon_x == 0, f'icon first on the left ({tag})')
                check(text_x > icon_x + icon_w * 7 / 8 and link_x >= text_x + det_w and link_x + link_w <= box,
                      f'text then EMPTY after the icon ({tag}): {text_x} {link_x}')
            else:
                check(text_x < icon_x + icon_w / 8 and link_x <= text_x - det_w and link_x - link_w >= 0,
                      f'EMPTY then text before the icon ({tag}): {text_x} {link_x}')
            for name, val in (('text', text_x), ('icon', icon_x), ('link', link_x)):
                check(val == int(val), f'{name} on a whole pixel ({tag}): {val}')
        l, r = got['left'], got['right']
        check(l[0] == r[0], f'same box on both sides (scale {scale})')
        check(abs(l[1] + r[1] + 56 * scale - l[0]) <= 1, f'icon mirrors (scale {scale})')
        check(abs(l[2] + r[2] - l[0]) <= 1, f'text anchor mirrors (scale {scale}): {l[2]} {r[2]}')


def test_ringclick():
    try:
        import lupa
    except ImportError:
        # CI always has lupa; a silent skip must not look like a pass there.
        print('SKIPPED: lupa missing, RingClick test not run (pip install lupa)')
        if os.environ.get('CI'):
            check(False, 'lupa missing in CI')
        return
    for scale in (1.0, 1.5):
        lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        sent = []
        vars_ = {'Scale': str(scale), 'RingRadius': '22', 'RingWidth': '5'}

        class Skin:
            def GetMeasure(self, n):
                return None

            def ReplaceVariables(self, s):
                return vars_[s.strip('#')]

            def ParseFormula(self, s):
                return str(eval(s))

            def Bang(self, *a):
                sent.append(a)

        lua.globals().SKIN = Skin()
        # Rainmeter's Lua 5.1 has math.atan2; newer Lua does not.
        lua.execute('math.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end')
        lua.execute((ROOT / '@Resources/Scripts/Volume.lua').read_text())
        c = (22 + 2.5 + 1) * scale
        r = 22 * scale
        # 9 o'clock (just below = full), 12 o'clock (25), 3 o'clock (50), 6 o'clock (75).
        for (x, y), want in (((c - r, c), 1), ((c, c - r), 25), ((c + r, c), 50), ((c, c + r), 75)):
            sent.clear()
            lua.globals().RingClick(x, y)
            cmds = [a[2] for a in sent if a[0] == '!CommandMeasure']
            check(cmds == [f'SetVolume {want}'], f'RingClick({x:.1f},{y:.1f}) -> {want}, got {cmds}')
        sent.clear()
        lua.globals().RingClick(c, c)
        check(not [a for a in sent if a[0] == '!CommandMeasure'], 'click in the ring centre does nothing')


def test_text_top_aligned():
    # Their text Y is the top of the line (Y=0, Y=2*Scale, ...), so it must use
    # the top-aligned #TAT#. #TA# centres vertically on Y: the top half of the
    # line falls outside the skin and is clipped, on either side.
    for ini in ('Volume/Volume.ini', 'RecycleBin/RecycleBin.ini'):
        text = (ROOT / ini).read_text()
        check('StringAlign=#TA#' not in text.replace('\r', '').replace('#TAT#', ''), f'{ini}: text uses #TA# (vertically centred)')
        check('StringAlign=#TAT#' in text, f'{ini}: text uses #TAT#')


test_volume()
test_bin()
test_ringclick()
test_text_top_aligned()
print(f'{failed} failure(s)')
sys.exit(1 if failed else 0)
