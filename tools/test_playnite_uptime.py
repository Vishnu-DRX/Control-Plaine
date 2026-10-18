"""Offline layout check for Playnite and Uptime. Run: python tools/test_playnite_uptime.py

Evaluates the X/W formulas in Playnite.ini and Uptime.ini for both sides at
scale 100, 125 and 150%: same box and hit width on both sides, everything
inside the box, right-anchored values on whole pixels, the right layout the
mirror image of the left. Text widths are estimates (Rainmeter is not run).
"""
import math
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


# Same helpers as tools/test_core.py (which runs on import, so they are copied).
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
        new = re.sub(r'#(\w+)#', lambda m: variables.get(m.group(1), extra.get(m.group(1), m.group(0))), expr)
        if new == expr:
            break
        expr = new
    expr = re.sub(r'\[(\w+):(\w+)\]', lambda m: str(extra[(m.group(1), m.group(2))]), expr)
    expr = expr.replace('Round(', 'rnd(')
    return eval(expr, {'rnd': rnd, '__builtins__': {}})


def section(text, name):
    m = re.search(rf'^\[{name}\]\n(.*?)(?=^\[|\Z)', text, re.M | re.S)
    return dict(re.findall(r'^(\w+)=(.*)$', m.group(1), re.M))

failures = 0


def check(cond, msg):
    global failures
    if not cond:
        failures += 1
        print('FAIL', msg)


def variables_for(base, scale, side):
    mir = 1 if side == 'right' else 0
    v = {**base, 'Scale': str(scale), 'Mir': str(mir), 'Lead': str(mir), 'Trail': str(1 - mir)}
    v['Sz'] = f'({scale}*{base.get("SizeBoost", "1")})'
    return v


def playnite():
    ini = (ROOT / 'Playnite' / 'Playnite.ini').read_text()
    files = ['@Resources/Theme.inc', '@Resources/Defaults.inc', 'Playnite/Defaults.inc', 'Playnite/Playnite.ini']
    base = load_vars(files)
    m = {n: section(ini, n) for n in ('RefLabel', 'Hit', 'Icon', 'Label')}
    for scale in (1.0, 1.25, 1.5):
        got = {}
        for side in ('left', 'right'):
            v = variables_for(base, scale, side)
            # "PLAYNITE": 8 capitals, about 6.6 px each plus tracking, at Sz 1.
            ref_w = 8 * (6.6 + float(base['TrackDetail'])) * scale * float(base['SizeBoost'])
            extra = {('RefLabel', 'W'): ref_w}
            hit = evaluate(m['Hit']['W'], v, extra)
            extra[('Hit', 'W')] = hit
            icon_x = evaluate(m['Icon']['X'], v, extra)
            label_x = evaluate(m['Label']['X'], v, extra)
            ref_x = evaluate(m['RefLabel']['X'], v, extra)
            art = float(base['ArtW']) * scale
            tag = f'Playnite {scale} {side}'
            check(0 <= icon_x and icon_x + art <= hit + 0.5, f'icon inside box ({tag})')
            if side == 'left':
                check(label_x + ref_w <= hit + 0.5, f'label inside box ({tag})')
            else:
                check(label_x - ref_w >= -1 and label_x <= icon_x, f'label left of icon, inside box ({tag})')
                check(icon_x == int(icon_x) and label_x == int(label_x), f'whole pixels ({tag})')
                check(ref_x - ref_w >= 0 and ref_x <= hit + 0.5, f'reference inside box ({tag})')
            got[side] = (hit, icon_x, art)
        check(got['left'][0] == got['right'][0], f'Playnite same box on both sides ({scale})')
        check(abs(got['left'][1] + got['right'][1] + got['left'][2] - got['left'][0]) <= 0.5,
              f'Playnite icon mirrors ({scale})')


def uptime():
    ini = (ROOT / 'Uptime' / 'Uptime.ini').read_text()
    files = ['@Resources/Theme.inc', '@Resources/Defaults.inc', 'Uptime/Defaults.inc', 'Uptime/Uptime.ini']
    base = load_vars(files)
    m = {n: section(ini, n) for n in ('Hit', 'UpLabel', 'UpValue')}
    for scale in (1.0, 1.25, 1.5):
        boxes = []
        for side in ('left', 'right'):
            v = variables_for(base, scale, side)
            box = evaluate('#BoxW#', v, {})
            hit = evaluate(m['Hit']['W'], v, {})
            lx = evaluate(m['UpLabel']['X'], v, {})
            vx = evaluate(m['UpValue']['X'], v, {})
            tag = f'Uptime {scale} {side}'
            check(hit == box, f'hit is the box ({tag})')
            check(lx == vx, f'label and value share an anchor ({tag})')
            check(lx == (box if side == 'right' else 0), f'anchor on the box edge ({tag})')
            check(box == int(box), f'whole-pixel box ({tag})')
            # RESTART RECOMMENDED: 19 capitals at about 6.6 px plus tracking at Sz 1.
            text_w = 19 * (6.6 + float(base['TrackDetail'])) * scale
            check(text_w <= box, f'longest label fits ({tag}): {text_w} > {box}')
            # Longest value, 99 DAYS 23 H: 12 chars at SizeValue.
            val_w = 12 * (0.62 * float(base['SizeValue']) / 0.75 + float(base['TrackValue'])) * scale
            check(val_w <= box, f'longest value fits ({tag}): {val_w} > {box}')
            boxes.append(box)
        check(boxes[0] == boxes[1], f'Uptime same box on both sides ({scale})')


playnite()
uptime()
print(f'{failures} failure(s)')
sys.exit(1 if failures else 0)
