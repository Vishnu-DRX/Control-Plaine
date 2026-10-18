"""Offline check of the FanControl meters' X formulas. Run: python tools/test_fancontrol.py

Evaluates the formulas read from FanControl/FanControl.ini for both sides at
scale 100, 125 and 150% (FanControl also applies SizeBoost) and checks: same
box and hit width on both sides; every meter inside the box; every
right-anchored value on a whole pixel; the right layout the mirror image of
the left (icon, snowflake, status anchor, spinner). Text widths are estimated
(about 6.6 px per character at Sz 1); the real ones need Rainmeter, see the
[PC] list in the PR.
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
        failed += 1
        print('FAIL: ' + message)


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
    m = re.search(rf'^\[{name}\]\r?\n(.*?)(?=^\[|\Z)', text, re.M | re.S)
    return dict(re.findall(r'^(\w+)=(.*?)\r?$', m.group(1), re.M))


def main():
    ini = (ROOT / 'FanControl' / 'FanControl.ini').read_text()
    base = load_vars(['@Resources/Theme.inc', '@Resources/Defaults.inc', 'FanControl/Defaults.inc',
                      'FanControl/FanControl.ini'])
    meters = {n: section(ini, n) for n in ('Hit', 'Icon', 'Value', 'RefValue', 'Snow', 'Status', 'Spinner')}
    rows = []
    for scale in (1.0, 1.25, 1.5):
        got = {}
        for side in ('left', 'right'):
            mir = 1 if side == 'right' else 0
            v = {**base, 'Scale': str(scale), 'Mir': str(mir), 'Lead': str(mir), 'Trail': str(1 - mir)}
            sz = scale * float(base['SizeBoost'])
            icon_w = float(base['IconBox']) * sz
            box = evaluate('#BoxW#', v, {})
            # "Fans 55%" in the value, "Fans 100%" in the reference, "Slowing down" in the status.
            val_w, ref_w, st_w = 8 * 6.6 * sz, 9 * 6.6 * sz, 12 * 6.6 * sz
            snow_w = evaluate(meters['Snow']['W'], v, {})
            spin_w = 2 * (rnd(5 * sz) + max(1, rnd(1.5 * sz)))
            val_x = evaluate(meters['Value']['X'], v, {})
            ref_x = evaluate(meters['RefValue']['X'], v, {})
            extra = {('Value', 'W'): val_w, ('Value', 'XW'): val_x + val_w,
                     ('RefValue', 'W'): ref_w, ('RefValue', 'XW'): ref_x + ref_w}
            st_x = evaluate(meters['Status']['X'], v, extra)
            extra[('Status', 'W')] = st_w
            extra[('Status', 'XW')] = st_x + st_w
            hit_w = evaluate(meters['Hit']['W'], v, extra)
            icon_x = evaluate(meters['Icon']['X'], v, extra)
            snow_x = evaluate(meters['Snow']['X'], v, extra)
            spin_x = evaluate(meters['Spinner']['X'], v, extra)
            got[side] = dict(box=box, hit=hit_w, icon=icon_x, iw=icon_w, val=val_x, snow=snow_x, sw=snow_w,
                             st=st_x, stw=st_w, spin=spin_x, spw=spin_w)
            rows.append((int(scale * 100), side, box, icon_x, val_x, snow_x, st_x, spin_x))
            tag = f'scale {scale} {side}'
            check(hit_w == box, f'Hit width is the box ({tag})')
            check(val_x == ref_x, f'Value and RefValue share an anchor ({tag})')
            check(0 <= icon_x and icon_x + icon_w <= box + 0.5, f'icon inside the box ({tag})')
            check(0 <= snow_x and snow_x + snow_w <= box, f'snowflake inside the box ({tag})')
            check(0 <= spin_x and spin_x + spin_w <= box, f'spinner inside the box ({tag}): {spin_x}')
            if side == 'left':
                check(st_x + st_w <= box, f'status inside the box ({tag})')
            else:
                check(st_x - st_w >= 0, f'status inside the box ({tag})')
                for name, x in (('icon', icon_x), ('value anchor', val_x), ('snowflake', snow_x),
                                ('status anchor', st_x), ('spinner', spin_x)):
                    check(x == int(x), f'{name} on a whole pixel ({tag}): {x}')
        L, R = got['left'], got['right']
        check(L['box'] == R['box'] and L['hit'] == R['hit'], f'same box and hit area (scale {scale})')
        check(abs(L['icon'] + R['icon'] + L['iw'] - L['box']) <= 0.5, f'icon mirrors (scale {scale})')
        check(abs(L['snow'] + R['snow'] + L['sw'] - L['box']) <= 1.0, f'snowflake mirrors (scale {scale})')
        # The status text's left edge on the left is its right edge (anchor) on the right.
        check(abs(L['st'] + R['st'] - L['box']) <= 1.0, f'status mirrors (scale {scale}): {L["st"]} {R["st"]}')
        check(abs(L['spin'] + R['spin'] + L['spw'] - L['box']) <= 1.0, f'spinner mirrors (scale {scale})')
    # Elevated helper: the FanSensors task must run a copy kept in an
    # admin-only folder, never a file under the Skins checkout ($PSScriptRoot).
    tasks = (ROOT / 'tools' / 'fan-tasks.ps1').read_text('ascii', 'replace')
    arg = re.search(r'^\s*\$arg = (.+)$', tasks, re.M)
    check(arg is not None, 'fan-tasks.ps1 builds the FanSensors argument line')
    if arg:
        check('PSScriptRoot' not in arg.group(1) and '$source' not in arg.group(1),
              'FanSensors task must not run a file from the Skins folder')
    check("$script = Join-Path $data" in tasks, 'FanSensors task runs the protected copy')
    check('IgnoreNew' in tasks, 'FanSensors task allows one instance')
    check('TEMP' not in tasks.replace('# ', ''), 'elevated reader output is not in %TEMP%')
    print('| scale | side | box W | icon X | value anchor X | snowflake X | status X | spinner X |')
    print('| --- | --- | --- | --- | --- | --- | --- | --- |')
    for r in rows:
        print('| {}% | {} | {:g} | {:g} | {:g} | {:g} | {:g} | {:g} |'.format(*r))
    print(f'{failed} failure(s)')
    sys.exit(1 if failed else 0)


main()
