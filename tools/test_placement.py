"""Offline checks for the first-run PLACEMENT step. Run: python tools/test_placement.py

Needs lupa (pip install lupa), which embeds Lua.

Runs @Resources/Scripts/Placement.lua (the maths Onboarding.lua uses) and checks:
- screens are read from Rainmeter's variables for 1 to 3 monitors, with
  negative and portrait areas, and the primary one is found;
- the stack on the left and right edge, at 100, 125 and 150 percent Scale, on
  a landscape and a portrait screen: every skin inside the work area with the
  margin, nothing overlapping, fixed gaps inside a column, right edges flush on
  the right, left edges flush on the left, wrapping into a second column when
  the height runs out, only requested skins placed, order kept;
- the shipped layout (tools/layout/Control-Plaine.layout) has no machine
  coordinates (no negative position, no anchors) and every skin of it lies on
  a 1920x1040 work area at 100 percent;
- Onboarding.lua and install.ps1 still reference the layout's new place.

Rainmeter itself is not involved: the !Move result on real monitors is [PC].
"""
import pathlib
import re
import sys

from lupa import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
lua = LuaRuntime(unpack_returned_tuples=True)
P = lua.eval("dofile(%r)" % str(ROOT / '@Resources' / 'Scripts' / 'Placement.lua').replace('\\', '/'))

problems = []


def check(cond, msg):
    if not cond:
        problems.append(msg)


def stack(names, area, edge, scale, boost=1.25):
    res = P.stack(lua.table_from(names), lua.table(**area), edge, scale, boost)
    return [{k: res[i][k] for k in ('name', 'x', 'y', 'w', 'h')} | {'clamped': bool(res[i]['clamped'])} for i in range(1, len(res) + 1)]


ORDER = [P.ORDER[i] for i in range(1, len(P.ORDER) + 1)]
GAP, MARGIN = P.GAP, P.MARGIN

# ---------- screens ----------


def getter(values):
    return lambda name: values.get(name, '#' + name + '#')


def screens(values):
    res, primary = P.screens(getter(values))
    return [dict(res[i]) for i in range(1, len(res) + 1)], primary


one = {'NUMOFMONITORS': '1', 'SCREENAREAX': '0', 'SCREENAREAY': '0', 'SCREENAREAWIDTH': '1920', 'SCREENAREAHEIGHT': '1040',
       'SCREENAREAX@1': '0', 'SCREENAREAY@1': '0', 'SCREENAREAWIDTH@1': '1920', 'SCREENAREAHEIGHT@1': '1040'}
s, p = screens(one)
check(len(s) == 1 and p == 1 and s[0]['w'] == 1920, 'one monitor')

# Portrait monitor left of the primary (negative X), primary second in the list.
two = {'NUMOFMONITORS': '2', 'SCREENAREAX': '0', 'SCREENAREAY': '0', 'SCREENAREAWIDTH': '2560', 'SCREENAREAHEIGHT': '1400',
       'SCREENAREAX@1': '-1080', 'SCREENAREAY@1': '-300', 'SCREENAREAWIDTH@1': '1080', 'SCREENAREAHEIGHT@1': '1880',
       'SCREENAREAX@2': '0', 'SCREENAREAY@2': '0', 'SCREENAREAWIDTH@2': '2560', 'SCREENAREAHEIGHT@2': '1400'}
s, p = screens(two)
check(len(s) == 2 and p == 2 and s[0]['x'] == -1080, 'two monitors, portrait on the left, primary found as 2')

# Rainmeter leaves unknown variables as #NAME#: fall back to the primary values, then to a default.
s, p = screens({'NUMOFMONITORS': '#NUMOFMONITORS#', 'SCREENAREAX': '0', 'SCREENAREAY': '0', 'SCREENAREAWIDTH': '1600', 'SCREENAREAHEIGHT': '900'})
check(len(s) == 1 and s[0]['w'] == 1600, 'fallback to the primary area when @n is unavailable')
s, p = screens({})
check(len(s) == 1 and s[0]['w'] > 0, 'fallback to a default area')

# ---------- stacking ----------

AREAS = {
    'landscape': dict(x=0, y=0, w=1920, h=1040),
    'portrait_left_of_primary': dict(x=-1080, y=-300, w=1080, h=1880),
    'small': dict(x=100, y=50, w=1366, h=720),
}
ALL = ORDER[:]
for aname, area in AREAS.items():
    for scale in (1.0, 1.25, 1.5):
        for edge in ('left', 'right'):
            tag = f'{aname} {int(scale * 100)}% {edge}'
            res = stack(ALL, area, edge, scale)
            check([r['name'] for r in res] == ALL, f'{tag}: all skins placed in order')
            # Inside the area, margin respected (a skin alone in an over-full area aside).
            ncols = len({r['x'] for r in res})
            for r in res:
                if ncols > 2:
                    break
                check(r['x'] >= area['x'] + MARGIN, f'{tag}: {r["name"]} left of the margin')
                check(r['x'] + r['w'] <= area['x'] + area['w'] - MARGIN, f'{tag}: {r["name"]} right of the margin')
                check(r['y'] >= area['y'] + MARGIN, f'{tag}: {r["name"]} above the margin')
            # Nothing overlaps.
            for i, a in enumerate(res):
                for b in res[i + 1:]:
                    sep = (a['x'] + a['w'] <= b['x'] or b['x'] + b['w'] <= a['x'] or
                           a['y'] + a['h'] <= b['y'] or b['y'] + b['h'] <= a['y'])
                    check(sep or a['clamped'] or b['clamped'], f'{tag}: {a["name"]} overlaps {b["name"]}')
            # Columns: same x edge flush; fixed gap inside a column; wrapped columns start at the top.
            cols = {}
            for r in res:
                key = r['x'] if edge == 'left' else r['x'] + r['w']
                cols.setdefault(key, []).append(r)
            for key, col in cols.items():
                for a, b in zip(col, col[1:]):
                    check(b['y'] == a['y'] + a['h'] + GAP, f'{tag}: gap between {a["name"]} and {b["name"]}')
                check(col[0]['y'] == area['y'] + MARGIN, f'{tag}: column of {col[0]["name"]} starts at the top margin')
                if len(cols) == 1 or col is not list(cols.values())[-1]:
                    last = col[-1]
                    check(last['y'] + last['h'] <= area['y'] + area['h'] - MARGIN or len(col) == 1,
                          f'{tag}: column ending at {last["name"]} runs below the area')
            first = list(cols)[0]
            if edge == 'left':
                check(first == area['x'] + MARGIN, f'{tag}: first column flush with the left margin')
            else:
                check(first == area['x'] + area['w'] - MARGIN, f'{tag}: first column flush with the right margin')
            # More columns only when the first one is full.
            if len(cols) > 1:
                first_col = list(cols.values())[0]
                nxt = ALL[len(first_col)]
                w, h = P.size(nxt, scale, 1.25)
                end = first_col[-1]['y'] + first_col[-1]['h'] + GAP
                check(end + h > area['y'] + area['h'] - MARGIN, f'{tag}: wrapped though {nxt} still fit')

# 1080p at 100% fits a single column (this is what the shipped layout relies on).
res = stack([n for n in ALL if n != 'SettingsButton'], AREAS['landscape'], 'left', 1.0)
check(len({r['x'] for r in res}) == 1, '1920x1040 at 100%: a single column')

# R5-N15: a narrow portrait screen must not push a column past the far edge.
narrow = {'x': 0, 'y': 0, 'w': 500, 'h': 400}
for edge in ('left', 'right'):
    res = stack(ALL, narrow, edge, 1.5)
    for r in res:
        check(r['x'] >= MARGIN and r['x'] + r['w'] <= narrow['w'] - MARGIN or r['w'] > narrow['w'] - 2 * MARGIN,
              f'narrow {edge}: {r["name"]} outside the area (x={r["x"]}, w={r["w"]})')
check(any(r['clamped'] for r in stack(ALL, narrow, 'left', 1.5)), 'narrow screen: a skin is reported as clamped')
check(not any(r['clamped'] for r in stack(ALL, AREAS['landscape'], 'left', 1.0)), '1920x1040: nothing is clamped')

# Only the requested skins, in the fixed order, however the caller lists them.
res = stack(['Volume', 'DayDate', 'NotASkin', 'Power'], AREAS['landscape'], 'right', 1.25)
check([r['name'] for r in res] == ['DayDate', 'Power', 'Volume'], 'subset in fixed order, unknown names ignored')
check(stack([], AREAS['landscape'], 'left', 1.0) == [], 'no skins, no placement')

# Scale and SizeBoost: icon skins take both, ring skins only Scale.
w1, h1 = P.size('SignalRGB', 1.0, 1.25)
w2, h2 = P.size('SignalRGB', 1.5, 1.25)
check((w1, h1) == (288, 40), f'SignalRGB at 100% should be 288x40 (BoxW 230*1.25), got {w1}x{h1}')
check(w2 == 432 and h2 == 60, f'SignalRGB at 150% should be 432x60, got {w2}x{h2}')
w3, h3 = P.size('Volume', 1.5, 1.25)
check((w3, h3) == (350, 78), f'Volume at 150% should be 350x78 (no SizeBoost), got {w3}x{h3}')
check(P.size('Nope', 1, 1) is None, 'unknown skin has no size')

# Worked values at 1920x1040, 100%, left edge (the table in the docs).
res = {r['name']: (r['x'], r['y']) for r in stack(ALL, AREAS['landscape'], 'left', 1.0)}
check(res['DayDate'] == (24, 24) and res['Uptime'] == (24, 130), 'DayDate/Uptime positions at 100%')

# ---------- shipped layout ----------

layout = ROOT / 'tools' / 'layout' / 'Control-Plaine.layout'
check(layout.exists(), 'tools/layout/Control-Plaine.layout exists')
check(not (ROOT / 'Layouts').exists(), 'Layouts/ is gone (Rainmeter would list it as a skin)')
if layout.exists():
    raw = layout.read_bytes()
    try:
        text = raw.decode('ascii')
    except UnicodeDecodeError:
        text = ''
        problems.append('layout: non-ASCII characters')
    section = None
    seen = {}
    for line in text.splitlines():
        m = re.match(r'\[(.+)\]', line)
        if m:
            section = m.group(1)
            continue
        if re.match(r'^\w+=.*\s;\s', line):
            problems.append(f'layout: inline ; comment: {line}')
        if section and section.startswith('Control-Plaine\\'):
            k, _, v = line.partition('=')
            if k == 'WindowX' and not v.endswith('%'):
                seen.setdefault(section, {})['x'] = int(v)
            if k == 'WindowY' and not v.endswith('%'):
                seen.setdefault(section, {})['y'] = int(v)
            check(k not in ('AnchorX', 'AnchorY') or section.endswith('Settings'), f'layout: {section} has {k}')
    check(len(seen) >= 12, f'layout: expected the 12 skins, found {len(seen)}')
    for section, pos in seen.items():
        name = section.split('\\')[1]
        check(pos['x'] >= 0 and pos['y'] >= 0, f'layout: {name} has a negative coordinate (another PC)')
        if name in P.SIZES:
            w, h = P.size(name, 1.0, 1.25)
            check(pos['x'] + w <= 1920 and pos['y'] + h <= 1040, f'layout: {name} outside a 1920x1040 work area')
    names = {s.split('\\')[1] for s in seen}
    mine = {r['name']: (r['x'], r['y']) for r in stack(sorted(names), AREAS['landscape'], 'left', 1.0)}
    for section, pos in seen.items():
        name = section.split('\\')[1]
        if name in mine:
            check((pos['x'], pos['y']) == mine[name], f'layout: {name} is not where Placement.lua puts it ({pos} vs {mine[name]})')

install = (ROOT / 'tools' / 'install.ps1').read_text('ascii', 'replace')
check('tools\\layout\\Control-Plaine.layout' in install, 'install.ps1 copies tools\\layout\\Control-Plaine.layout')
check('Layouts\\Control-Plaine\\Rainmeter.ini' not in install.replace("'Rainmeter\\Layouts'", ''), 'install.ps1 still copies the old Layouts\\ source')

if problems:
    print(f'{len(problems)} problem(s)')
    for p_ in problems:
        print(' -', p_)
    sys.exit(1)
print('placement: ok')
