"""Offline layout check for the WiFi skin. Run: python tools/test_wifi.py

Reads the X/W formulas of WiFi/WiFi.ini and evaluates them for both sides at
scale 100, 125 and 150% (SizeBoost applies), with estimated text widths since
the real ones need Rainmeter. Checks: same box and hit area on both sides;
everything inside the box; every right-anchored value on a whole pixel; the
speed test result chain (down icon, down, up icon, up, ping) running left to
right on the left and mirrored on the right with no overlaps; the speed test
button and spinner on the inner side of the name and live speed.

Behaviour that needs Rainmeter is listed in the WiFi PR as [PC].
"""
import math
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
failed = 0


def check(cond, message):
    global failed
    if not cond:
        print('FAIL', message)
        failed += 1


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


def section(text, name):
    m = re.search(rf'^\[{name}\]\n(.*?)(?=^\[|\Z)', text, re.M | re.S)
    return dict(re.findall(r'^(\w+)=(.*)$', m.group(1), re.M))


def evaluate(expr, variables, refs):
    for _ in range(20):
        new = re.sub(r'#(\w+)#', lambda m: variables.get(m.group(1), m.group(0)), expr)
        if new == expr:
            break
        expr = new
    expr = re.sub(r'\[(\w+):(\w+)\]', lambda m: str(refs[(m.group(1), m.group(2))]), expr)
    expr = expr.replace('Round(', 'rnd(').replace('Max(', 'max(')
    return eval(expr, {'rnd': rnd, 'max': max, '__builtins__': {}})


# Estimated text (about 6.6 px a character at Sz 1).
TEXTS = {'Name': 'SAVARI GIRI GIRI', 'Live': '-- Mbps', 'Down': '888', 'Up': '888 Mbps', 'Ping': 'Ping 88 ms'}
ORDER = ['Hit', 'Icon', 'Name', 'Gauge', 'Live', 'Spinner', 'DownIcon', 'Down', 'UpIcon', 'Up', 'Ping']


def layout(meters, base, scale, mir):
    sz = scale * float(base['SizeBoost'])
    v = {**base, 'Scale': str(scale), 'Mir': str(mir), 'Lead': str(mir), 'Trail': str(1 - mir)}
    tag = f'scale {scale} {"right" if mir else "left"}'
    refs, span = {}, {}
    for name in ORDER:
        m = meters[name]
        if name in TEXTS:
            w = len(TEXTS[name]) * 6.6 * sz
        elif name == 'Spinner':
            w = 2 * (rnd(5 * sz) + max(1, rnd(1.5 * sz)))
        elif name == 'Icon':
            w = float(base['IconBox']) * sz
        else:
            w = evaluate(m['W'], v, refs)
        x = evaluate(m['X'], v, refs)
        if name in TEXTS and mir:
            check(x == int(x), f'{name} anchor on a whole pixel ({tag}): {x}')
            x = x - w
        elif mir and name != 'Hit':
            check(x == int(x), f'{name} X on a whole pixel ({tag}): {x}')
        refs[(name, 'X')] = x
        refs[(name, 'W')] = w
        refs[(name, 'XW')] = x + w
        span[name] = (x, x + w)
    return evaluate('#BoxW#', v, {}), evaluate('#TextX#', v, {}), span, sz, tag


def main():
    ini = (ROOT / 'WiFi' / 'WiFi.ini').read_text()
    base = load_vars(['@Resources/Theme.inc', '@Resources/Defaults.inc', 'WiFi/Defaults.inc', 'WiFi/WiFi.ini'])
    meters = {n: section(ini, n) for n in ORDER}
    chain = ['DownIcon', 'Down', 'UpIcon', 'Up', 'Ping']
    for scale in (1.0, 1.25, 1.5):
        res = {}
        for mir in (0, 1):
            box, anchor, span, sz, tag = layout(meters, base, scale, mir)
            res[mir] = (box, span)
            iw = float(base['IconBox']) * sz
            check(span['Hit'] == (0, box), f'Hit is the box ({tag})')
            for name in ORDER[1:]:
                a, b = span[name]
                check(a >= -0.01 and b <= box + 0.01, f'{name} inside the box ({tag}): {a:.1f}..{b:.1f} of {box}')
            check(span['Icon'][0] == ((box - iw) if mir else 0), f'icon at the outer edge ({tag})')
            for a, b in zip(chain, chain[1:]):
                if mir:
                    check(span[b][1] <= span[a][0] + 0.01, f'{b} is inside {a} ({tag})')
                else:
                    check(span[b][0] >= span[a][1] - 0.01, f'{b} follows {a} ({tag})')
            check(abs(span['DownIcon'][1 if mir else 0] - anchor) <= 0.01, f'chain starts at the text anchor ({tag})')
            if mir:
                check(span['Gauge'][1] <= span['Name'][0] - 8 * sz + 1, f'gauge clear of the name ({tag})')
                check(span['Spinner'][1] <= span['Live'][0] - 8 * sz + 1, f'spinner clear of live speed ({tag})')
            else:
                check(span['Gauge'][0] >= span['Name'][1] + 8 * sz - 0.01, f'gauge clear of the name ({tag})')
                check(span['Spinner'][0] >= span['Live'][1] + 8 * sz - 0.01, f'spinner clear of live speed ({tag})')
            print(f'{tag}: box {box:g}, anchor {anchor:g}, gauge {span["Gauge"][0]:.1f}, '
                  f'ping {span["Ping"][0]:.1f}..{span["Ping"][1]:.1f}')
        (bl, sl), (br, sr) = res[0], res[1]
        check(bl == br, f'same box on both sides (scale {scale})')
        check(abs(sl['Icon'][0] + sr['Icon'][1] - bl) <= 0.5, f'icon mirrors (scale {scale})')
        check(abs(sl['DownIcon'][0] + sr['DownIcon'][1] - bl) <= 0.5, f'down icon mirrors (scale {scale})')
        check(abs(sl['Ping'][0] + sr['Ping'][1] - bl) <= 1.5, f'ping mirrors (scale {scale})')
    print(f'{failed} failure(s)')
    sys.exit(1 if failed else 0)


main()
