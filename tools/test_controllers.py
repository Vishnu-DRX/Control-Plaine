"""Offline check of the Controllers X formulas. Run: python tools/test_controllers.py

Reads the formulas of Row1 from Controllers/Controllers.ini, evaluates them for
both sides at scale 100, 125 and 150% (SizeBoost 1.25) with an estimated name
width, and checks: right-anchored values are whole pixels, the right layout
mirrors the left within a pixel, the icon stays inside the box and the battery
never overlaps the name. The real text width needs Rainmeter, so it is
estimated.
"""
import math
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
text = (ROOT / 'Controllers' / 'Controllers.ini').read_text('ascii')


def option(section, key):
    m = re.search(rf'^\[{section}\]\n(?:(?!\[).*\n)*?{key}=(.*)$', text, re.M)
    return m.group(1).strip()


def rnd(x):
    return math.floor(x + 0.5)


def ev(expr, env):
    expr = re.sub(r'\[(\w+):(\w+)\]', lambda m: repr(env[m.group(1) + ':' + m.group(2)]), expr)
    expr = re.sub(r'#(\w+)#', lambda m: repr(env[m.group(1)]), expr)
    expr = expr.replace('Round', 'rnd').replace('Trunc', 'trunc')
    return eval(expr, {'rnd': rnd, 'trunc': math.trunc, 'Max': max, 'Min': min})


fails = []
for scale in (1.0, 1.25, 1.5):
    sz = scale * 1.25
    res = {}
    for mir in (0, 1):
        env = {'Mir': mir, 'Sz': sz, 'CtlW': 31.2, 'IconBox': 32}
        env['BoxW'] = rnd(230 * sz)
        env['BatS'] = max(1, rnd(1 * sz))
        env['BatW'] = rnd(17 * sz)
        env['NameA'] = ev(re.search(r'^NameA=(.*)$', text, re.M).group(1), env)
        env['BatTot'] = ev(re.search(r'^BatTot=(.*)$', text, re.M).group(1), env)
        box = env['BoxW']
        for nlen in (0, 9, 14):
            nw = nlen * 7.5 * sz
            env['Row1Name:W'] = nw
            if mir:
                nx = env['NameA'] - nw
                env['Row1Name:XW'] = env['NameA']
            else:
                nx = (31.2 + 4) * sz
                env['Row1Name:XW'] = nx + nw
            icon = ev(option('Row1Icon', 'X'), env)
            namex = ev(option('Row1Name', 'X'), env)
            bat = ev(option('Row1Bat', 'X'), env)
            pct = ev(option('Row1Pct', 'X'), env)
            tag = f'scale {scale} mir {mir} name {nlen}'
            if mir:
                for n, v in (('icon', icon), ('name', namex), ('bat', bat), ('pct', pct)):
                    if abs(v - round(v)) > 1e-9:
                        fails.append(f'{tag}: {n} X {v} not whole')
                if icon + 31.2 * sz > box + 0.5:
                    fails.append(f'{tag}: icon outside box')
                if bat + env['BatTot'] > nx - 10 * sz + 1:
                    fails.append(f'{tag}: battery overlaps name')
                if pct > nx - 36 * sz + 1:
                    fails.append(f'{tag}: pct anchor overlaps battery')
            else:
                if icon != 0 or abs(namex - nx) > 1e-9:
                    fails.append(f'{tag}: left icon/name wrong')
                if abs(bat - rnd(nx + nw + 10 * sz)) > 1e-9 or abs(pct - (nx + nw + 36 * sz)) > 1e-9:
                    fails.append(f'{tag}: left battery/pct wrong')
            res[(mir, nlen)] = (icon, bat, env)
    for nlen in (0, 9, 14):
        l, r = res[(0, nlen)], res[(1, nlen)]
        box, bw = l[2]['BoxW'], l[2]['BatTot']
        if abs((box - l[1] - bw) - r[1]) > 1.5:
            fails.append(f'scale {scale} name {nlen}: battery not mirrored: {l[1]} {r[1]}')
        if abs((box - l[0] - 31.2 * sz) - r[0]) > 1:
            fails.append(f'scale {scale} name {nlen}: icon not mirrored')
    print(f'scale {scale}: box {rnd(230 * sz)}')

for f in fails:
    print('FAIL', f)
print(f'{len(fails)} failure(s)')
sys.exit(1 if fails else 0)
