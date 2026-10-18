"""Offline checks for the shared layout code. Run: python tools/test_core.py

Needs lupa (pip install lupa), which embeds Lua.

1. Scripts\\Core.lua, run against a fake SKIN, resolves Side Mir TA TAT Lead
   Trail RevealMin Reveal HoverTint for every AlignAll/SkinSide/DetailsAll/
   SkinDetails/HoverAccent combination, and falls back safely on bad values.
   It also resolves Mode, Ink, InkContrast, Warn, Accent and the effective
   brightness for every Theme/SkinTheme/ThemeLock/Windows-theme combination.
2. The SignalRGB meters' X formulas, read from SignalRGB.ini, are evaluated
   for both sides at scale 100, 125 and 150% and checked: same box, whole
   pixels where they are right-anchored, the right layout the mirror image of
   the left, nothing outside the box.

Rainmeter itself is not involved: behaviour that needs it is listed in
specs/alignment.md as [PC].
"""
import itertools
import math
import pathlib
import re
import sys

from lupa import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent


# ---------- 1. Core.lua ----------

class FakeMeasure:
    def __init__(self, value):
        self.value = value

    def GetValue(self):
        return self.value

    def GetStringValue(self):
        return str(self.value)


class FakeSkin:
    """Just enough of Rainmeter's SKIN for Core.lua."""

    def __init__(self, variables, measures=None):
        self.vars = dict(variables)
        self.measures = measures or {}

    def GetMeasure(self, name):
        return self.measures[name]

    def GetVariable(self, name, default=None):
        return self.vars.get(name, default)

    def ReplaceVariables(self, text):
        return re.sub(r'#(\w+|@)#', lambda m: self.ReplaceVariables(self.vars.get(m.group(1), m.group(0))), text)

    def Bang(self, bang, *args):
        # Rainmeter keeps variables as text.
        if bang == '!SetVariable':
            self.vars[args[0]] = str(args[1])


def run_core(variables, measures=None):
    lua = LuaRuntime(unpack_returned_tuples=True)
    skin = FakeSkin(variables, measures)
    lua.globals().SKIN = skin
    lua.execute((ROOT / '@Resources' / 'Scripts' / 'Core.lua').read_text())
    lua.globals().Initialize()
    return lua, skin


def check(cond, message):
    if not cond:
        print('FAIL', message)
        check.failed += 1


check.failed = 0


def test_core():
    base = {'AccentColor': '0,158,155', 'Ink': '255,255,255'}
    for all_, skin, dall, sdet, hover in itertools.product(
            ['skin', 'left', 'right', 'garbage', ''], ['left', 'right', 'Right ', 'oops'],
            ['skin', 'hover', 'always', 'x'], ['hover', 'always', 'oops'], ['1', '0', '']):
        _, s = run_core({**base, 'AlignAll': all_, 'SkinSide': skin, 'DetailsAll': dall,
                         'SkinDetails': sdet, 'HoverAccent': hover})
        want_side = all_ if all_ in ('left', 'right') else ('right' if skin.strip().lower() == 'right' else 'left')
        want_always = dall == 'always' or (dall not in ('hover', 'always') and sdet == 'always')
        tag = f'AlignAll={all_!r} SkinSide={skin!r} DetailsAll={dall!r} SkinDetails={sdet!r} HoverAccent={hover!r}'
        v = s.vars
        check(v['Side'] == want_side, f'Side {v["Side"]} for {tag}')
        check(v['Mir'] == ('1' if want_side == 'right' else '0'), f'Mir for {tag}')
        check(int(v['Lead']) + int(v['Trail']) == 1 and v['Lead'] == v['Mir'], f'Lead/Trail for {tag}')
        check(v['TA'] == ('RightCenter' if want_side == 'right' else 'LeftCenter'), f'TA for {tag}')
        check(v['TAT'] == ('Right' if want_side == 'right' else 'Left'), f'TAT for {tag}')
        check(v['RevealMin'] == ('1' if want_always else '0') and v['Reveal'] == v['RevealMin'], f'RevealMin for {tag}')
        check(v['HoverTint'] == ('255,255,255' if hover == '0' else '0,158,155'), f'HoverTint for {tag}')
    # Missing variables: left, hover, accent.
    _, s = run_core({})
    check(s.vars['Side'] == 'left' and s.vars['RevealMin'] == '0' and s.vars['HoverTint'] == '0,229,255',
          'defaults when nothing is set')
    # The accent follows Windows while running: HoverTint tracks it on Update.
    lua, s = run_core({**base})
    s.vars['AccentColor'] = '10,20,30'
    lua.globals().Update()
    check(s.vars['HoverTint'] == '10,20,30', 'HoverTint follows Accent on Update')
    # Update must not undo a hover fade in progress.
    s.vars['Reveal'] = '0.5'
    lua.globals().Update()
    check(s.vars['Reveal'] == '0.5', 'Update leaves Reveal alone')


THEME_BASE = {'Ink': '255,255,255', 'InkContrast': '0,0,0', 'Warn': '255,170,60', 'InkLight': '0,0,0',
              'InkContrastLight': '255,255,255', 'WarnLight': '214,110,0', 'AccentColor': '0,200,100',
              'AccentFollowWindows': '1', 'AccentLight': '1', 'AccentLightK': '0.7',
              'RestBrightness': '60', 'HoverBrightness': '98', 'LightBoost': '10'}


def theme(variables, win=0, accent='0,0,0'):
    # win is the Windows light-theme value, accent the mAccent text.
    measures = {'mWinTheme': FakeMeasure(win), 'mAccent': FakeMeasure(accent)}
    return run_core({**THEME_BASE, **variables}, measures)


def test_theme():
    # Mode: lock beats everything, a skin beats the global, auto follows Windows.
    for lock, skin, glob, win in itertools.product(['0', '1'], ['auto', 'dark', 'light', 'x'],
                                                   ['auto', 'dark', 'light', 'x'], [0, 1]):
        _, s = theme({'ThemeLock': lock, 'SkinTheme': skin, 'Theme': glob}, win=win)
        if lock == '1':
            want = 'dark'
        elif skin in ('dark', 'light'):
            want = skin
        elif glob in ('dark', 'light'):
            want = glob
        elif glob == 'auto':
            want = 'light' if win else 'dark'
        else:
            want = 'dark'
        tag = f'lock={lock} skin={skin} Theme={glob} win={win}'
        v = s.vars
        check(v['Mode'] == want, f'Mode {v["Mode"]} != {want} for {tag}')
        check(v['Ink'] == ('0,0,0' if want == 'light' else '255,255,255'), f'Ink for {tag}')
        check(v['InkContrast'] == ('255,255,255' if want == 'light' else '0,0,0'), f'InkContrast for {tag}')
        check(v['Warn'] == ('214,110,0' if want == 'light' else '255,170,60'), f'Warn for {tag}')
        check(v['Accent'] == ('0,140,70' if want == 'light' else '0,200,100'), f'Accent for {tag}: {v["Accent"]}')
    # The Settings window names its page in Tab and is always dark.
    _, s = theme({'Tab': 'SignalRGB', 'Theme': 'light'})
    check(s.vars['Mode'] == 'dark' and s.vars['Ink'] == '255,255,255', 'a Tab page is locked dark')
    # Defaults change nothing: dark, today's brightness, today's hover alpha.
    _, s = theme({'Theme': 'dark'})
    check(s.vars['RestEff'] == '60' and s.vars['HoverEff'] == '98', 'dark brightness is untouched')
    check(round(float(s.vars['HoverEff']) * 2.55) == 250, 'AlphaHover stays 250')
    # Light adds the boost to rest, hover is never below rest, both cap at 100.
    _, s = theme({'Theme': 'light'})
    check(s.vars['RestEff'] == '70' and s.vars['HoverEff'] == '98', 'light boost on rest')
    _, s = theme({'Theme': 'light', 'LightBoost': '0'})
    check(s.vars['RestEff'] == '60', 'LightBoost=0 restores the unboosted level')
    _, s = theme({'Theme': 'light', 'RestBrightness': '90', 'LightBoost': '30', 'HoverBrightness': '80'})
    check(s.vars['RestEff'] == '100' and s.vars['HoverEff'] == '100', 'rest and hover cap at 100, hover >= rest')
    _, s = theme({'Theme': 'light', 'AccentLight': '0'})
    check(s.vars['Accent'] == '0,200,100', 'AccentLight=0 keeps the accent')
    # Garbage numbers fall back instead of erroring.
    _, s = theme({'Theme': 'light', 'RestBrightness': 'abc', 'LightBoost': 'x', 'AccentLightK': 'y'})
    check(s.vars['RestEff'] == '60' and s.vars['Accent'] == '0,200,100', 'bad numbers fall back')
    # Accent: Windows' value wins while following, 0,0,0 means not read.
    _, s = theme({}, accent='1,2,3')
    check(s.vars['Accent'] == '1,2,3', 'Windows accent')
    _, s = theme({}, accent='0,0,0')
    check(s.vars['Accent'] == '0,200,100', 'unreadable Windows accent keeps AccentColor')
    _, s = theme({'AccentFollowWindows': '0'}, accent='1,2,3')
    check(s.vars['Accent'] == '0,200,100', 'AccentFollowWindows=0 uses AccentColor')
    # HoverTint is the (darkened) accent, or the ink when HoverAccent=0.
    _, s = theme({'Theme': 'light'})
    check(s.vars['HoverTint'] == '0,140,70', 'HoverTint is the darkened accent in light mode')
    _, s = theme({'Theme': 'light', 'HoverAccent': '0'})
    check(s.vars['HoverTint'] == '0,0,0', 'HoverTint is the ink with HoverAccent=0')
    # A Windows switch shows within an Update, with no refresh.
    lua, s = theme({'Theme': 'auto'}, win=0)
    check(s.vars['Mode'] == 'dark', 'auto starts dark')
    s.measures['mWinTheme'].value = 1
    lua.globals().Update()
    check(s.vars['Mode'] == 'light' and s.vars['Ink'] == '0,0,0' and s.vars['RestEff'] == '70',
          'Windows switch to light is picked up')
    s.measures['mWinTheme'].value = 0
    lua.globals().Update()
    check(s.vars['Mode'] == 'dark' and s.vars['Ink'] == '255,255,255' and s.vars['RestEff'] == '60',
          'and back')
    # L11: the registry measure missing altogether falls back to dark.
    lua, s = run_core({**THEME_BASE, 'Theme': 'auto'}, {})
    check(s.vars['Mode'] == 'dark', 'auto with no registry measure is dark')


# ---------- 2. SignalRGB layout formulas ----------

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


def test_signalrgb():
    ini = (ROOT / 'SignalRGB' / 'SignalRGB.ini').read_text()
    files = ['@Resources/Theme.inc', '@Resources/Defaults.inc', 'SignalRGB/Defaults.inc', 'SignalRGB/SignalRGB.ini']
    base = load_vars(files)
    meters = {n: section(ini, n) for n in ('Hit', 'Icon', 'Value', 'RefValue', 'Move')}
    rows = []
    for scale in (1.0, 1.25, 1.5):
        got = {}
        for side in ('left', 'right'):
            mir = 1 if side == 'right' else 0
            variables = {**base, 'Scale': str(scale), 'Mir': str(mir), 'Lead': str(mir), 'Trail': str(1 - mir)}
            sz = scale * float(base['SizeBoost'])
            icon_w = float(base['IconBox']) * sz
            box = evaluate('#BoxW#', variables, {})
            # Width of "CASE LIGHTS 100%" in px: about 6.6 px per character at Sz 1.
            ref_w = 16 * 6.6 * sz
            # XW is right of the text when it is left-aligned; the right layout does not use it.
            extra = {('RefValue', 'W'): ref_w,
                     ('RefValue', 'XW'): evaluate(meters['RefValue']['X'], variables, {}) + ref_w}
            hit_w = evaluate(meters['Hit']['W'], variables, extra)
            icon_x = evaluate(meters['Icon']['X'], variables, extra)
            text_x = evaluate(meters['Value']['X'], variables, extra)
            ref_x = evaluate(meters['RefValue']['X'], variables, extra)
            move_x = evaluate(meters['Move']['X'], variables, extra)
            move_w = evaluate(meters['Move']['W'], variables, extra)
            got[side] = (box, hit_w, icon_x, icon_w, text_x, ref_w, move_x, move_w)
            rows.append((int(scale * 100), side, box, hit_w, icon_x, text_x, move_x))
            tag = f'scale {scale} {side}'
            check(hit_w == box, f'Hit width is the box ({tag})')
            check(text_x == ref_x, f'Value and RefValue share an anchor ({tag})')
            check(0 <= icon_x and icon_x + icon_w <= box + 0.5, f'icon inside the box ({tag})')
            check(0 <= move_x and move_x + move_w <= box, f'arrow inside the box ({tag})')
            if side == 'right':
                for name, v in (('icon', icon_x), ('text anchor', text_x), ('arrow', move_x)):
                    check(v == int(v), f'{name} on a whole pixel ({tag}): {v}')
        (bl, hl, il, iw, tl, rw, ml, mw), (br, hr, ir, _, tr, _, mr, _) = got['left'], got['right']
        check(bl == br and hl == hr, f'same box and hit area on both sides (scale {scale})')
        # Mirror image, to the pixel rounding.
        check(abs((il + ir + iw) - bl) <= 0.5, f'icon mirrors (scale {scale}): {il} {ir}')
        check(abs((tl + tr) - bl) <= 0.5, f'text anchor mirrors (scale {scale}): {tl} {tr}')
        check(abs((ml + mr + mw) - bl) <= 1.0, f'arrow mirrors (scale {scale}): {ml} {mr}')
    return rows


def test_needs_wiring():
    """Core.lua evaluates the skin's own needs and sets the flags on itself."""
    import tempfile
    tmp = pathlib.Path(tempfile.mkdtemp())
    # The scripts use Windows separators, so the files get those literal names.
    (tmp / 'Scripts\\Needs.lua').write_text((ROOT / '@Resources' / 'Scripts' / 'Needs.lua').read_text())
    opt, man = tmp / 'optional.txt', tmp / 'mandatory.txt'
    (tmp / 'Setup\\NeedsList.lua').write_text(
        "return { Demo = {\n"
        " { id='o', label='O', level='optional', feature='Click', check={file=[[" + str(opt) + "]]}, why='x' },\n"
        " { id='m', label='M', level='mandatory', check={file=[[" + str(man) + "]]}, why='y' } } }\n")
    base = {'CURRENTCONFIG': 'Control-Plaine\\Demo', '@': str(tmp) + '/'}
    run = lambda v=base: run_core(dict(v))

    lua, skin = run()
    check(skin.vars.get('DemoHasClick') == '0', 'optional missing: Has=0')
    check(skin.vars.get('DemoNeedBlocked') == '1' and skin.vars.get('DemoNeedState') == 'BLOCKED',
          'mandatory missing: NeedBlocked=1')
    man.write_text('x')
    lua, skin = run()
    check(skin.vars.get('DemoNeedBlocked') == '0' and skin.vars.get('DemoNeedState') == 'DEGRADED',
          'mandatory present, optional missing: DEGRADED, not blocked')
    opt.write_text('x')
    lua, skin = run()
    check(skin.vars.get('DemoHasClick') == '1' and skin.vars.get('DemoNeedState') == 'OK',
          'optional present: Has=1, OK')

    # Flips live: item removed, then the minute poll sees it and bangs a redraw.
    bangs = []
    orig = skin.Bang
    skin.Bang = lambda _s, b, *a: (bangs.append(b), orig(b, *a))[1]
    opt.unlink()
    lua.execute('local t = os.time() + 61; os.time = function() return t end')
    lua.globals().Update()
    check(skin.vars.get('DemoHasClick') == '0' and '!Redraw' in bangs, 'poll: flag flips and redraws')
    bangs.clear()
    lua.globals().Update()
    check(skin.vars.get('DemoHasClick') == '0' and '!Redraw' not in bangs, 'no change: no redraw')

    # No entry for this skin, no lists, unreadable lists: no error, no flags.
    for cfg in ('Control-Plaine\\Other', ''):
        lua, skin = run(dict(base, CURRENTCONFIG=cfg))
        check(not any(k.startswith('Demo') for k in skin.vars), 'no entry: nothing set (' + cfg + ')')
        lua.globals().Update()
    lua, skin = run(dict(base, **{'@': str(tmp / 'missing') + '/'}))
    lua.globals().Update()
    check('DemoHasClick' not in skin.vars and skin.vars.get('Side') == 'left', 'lists fail to load: no error')
    (tmp / 'Setup\\NeedsList.lua').write_text('this is not lua')
    lua, skin = run()
    check('DemoNeedBlocked' not in skin.vars and skin.vars.get('Side') == 'left', 'broken list: no error')


def main():
    test_core()
    test_theme()
    test_needs_wiring()
    rows = test_signalrgb()
    print('| scale | side | box W | hit W | icon X | text anchor X | arrow X |')
    print('| --- | --- | --- | --- | --- | --- | --- |')
    for scale, side, box, hit, icon, text, move in rows:
        print(f'| {scale}% | {side} | {box:g} | {hit:g} | {icon:g} | {text:g} | {move:g} |')
    print(f'{check.failed} failure(s)')
    sys.exit(1 if check.failed else 0)


main()
