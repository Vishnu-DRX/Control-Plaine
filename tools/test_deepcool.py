#!/usr/bin/env python3
"""Offline check of the DeepCool layout formulas (left and right, 100/125/150% scale).

Evaluates the X/W formulas in DeepCool/DeepCool.ini. Text widths are estimates
(about 6.6 px per character at Sz 1); the real ones need Rainmeter.
Run: python tools/test_deepcool.py
"""
import math
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
    expr = expr.replace('Round(', 'rnd(').replace('Max(', 'max(')
    return eval(expr, {'rnd': rnd, 'max': max, '__builtins__': {}})


def section(text, name):
    m = re.search(rf'^\[{name}\]\n(.*?)(?=^\[|\Z)', text, re.M | re.S)
    return dict(re.findall(r'^(\w+)=(.*)$', m.group(1), re.M))


def main():
    ini = (ROOT / 'DeepCool' / 'DeepCool.ini').read_text().replace('\r\n', '\n')
    base = load_vars(['@Resources/Theme.inc', '@Resources/Defaults.inc',
                      'DeepCool/Defaults.inc', 'DeepCool/DeepCool.ini'])
    meters = {n: section(ini, n) for n in ('Hit', 'Icon', 'State', 'Bulb', 'Spinner')}
    for scale in (1.0, 1.25, 1.5):
        for text in ('Case screen', 'Stopping telemetry'):
            got = {}
            for side in ('left', 'right'):
                mir = 1 if side == 'right' else 0
                v = {**base, 'Scale': str(scale), 'Mir': str(mir)}
                sz = scale * float(base['SizeBoost'])
                box = evaluate('#BoxW#', v, {})
                icon_w = float(base['IconBox']) * sz
                tw = len(text) * 6.6 * sz
                text_x = evaluate(meters['State']['X'], v, {})
                # Left text grows right from its anchor, right text grows left.
                xw = text_x + tw if side == 'left' else text_x
                extra = {('State', 'W'): tw, ('State', 'XW'): xw}
                hit = evaluate(meters['Hit']['W'], v, extra)
                icon_x = evaluate(meters['Icon']['X'], v, extra)
                bulb_x = evaluate(meters['Bulb']['X'], v, extra)
                spin_x = evaluate(meters['Spinner']['X'], v, extra)
                bulb_w = 24 * sz
                spin_w = 2 * (rnd(5 * sz) + max(1, rnd(1.5 * sz)))
                tag = f'scale {scale} {side} "{text}"'
                check(hit == box, f'Hit is the box ({tag})')
                check(0 <= icon_x and icon_x + icon_w <= box + 0.5, f'icon inside ({tag})')
                lo, hi = (text_x, text_x + tw) if side == 'left' else (text_x - tw, text_x)
                check(lo >= 0 and hi <= box, f'text inside ({tag})')
                check(0 <= bulb_x and bulb_x + bulb_w <= box, f'bulb inside ({tag}): {bulb_x}')
                check(0 <= spin_x and spin_x + spin_w <= box, f'spinner inside ({tag}): {spin_x}')
                if side == 'left':
                    check(bulb_x >= hi and spin_x >= hi, f'extras clear of text ({tag})')
                else:
                    check(bulb_x + bulb_w <= lo and spin_x + spin_w <= lo, f'extras clear of text ({tag})')
                    for name, val in (('icon', icon_x), ('text', text_x), ('spinner', spin_x)):
                        check(val == int(val), f'{name} on a whole pixel ({tag}): {val}')
                got[side] = (box, icon_x, icon_w, text_x, bulb_x, bulb_w)
            (bl, il, iw, tl, ml, mw), (br, ir, _, tr, mr, _) = got['left'], got['right']
            check(bl == br, f'same box on both sides (scale {scale})')
            check(abs(il + ir + iw - bl) <= 0.5, f'icon mirrors (scale {scale})')
            check(abs(tl + tr - bl) <= 0.5, f'text anchor mirrors (scale {scale})')
            check(abs(ml + mr + mw - bl) <= 1.0, f'bulb mirrors (scale {scale}): {ml} {mr}')
    print(f'{failed} failure(s)')
    sys.exit(1 if failed else 0)


main()
