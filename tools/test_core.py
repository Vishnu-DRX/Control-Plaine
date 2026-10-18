"""Offline checks for the shared layout code. Run: python tools/test_core.py

Needs lupa (pip install lupa), which embeds Lua.

1. Scripts\\Core.lua, run against a fake SKIN, resolves Side Mir TA TAT Lead
   Trail RevealMin Reveal HoverTint for every AlignAll/SkinSide/DetailsAll/
   SkinDetails/HoverAccent combination, and falls back safely on bad values.
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

class FakeSkin:
    """Just enough of Rainmeter's SKIN for Core.lua."""

    def __init__(self, variables):
        self.vars = dict(variables)

    def GetVariable(self, name, default=None):
        return self.vars.get(name, default)

    def ReplaceVariables(self, text):
        return re.sub(r'#(\w+)#', lambda m: self.ReplaceVariables(self.vars.get(m.group(1), m.group(0))), text)

    def Bang(self, bang, *args):
        # Rainmeter keeps variables as text.
        if bang == '!SetVariable':
            self.vars[args[0]] = str(args[1])


def run_core(variables):
    lua = LuaRuntime(unpack_returned_tuples=True)
    skin = FakeSkin(variables)
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
    base = {'Accent': '0,158,155', 'Ink': '255,255,255'}
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
    s.vars['Accent'] = '10,20,30'
    lua.globals().Update()
    check(s.vars['HoverTint'] == '10,20,30', 'HoverTint follows Accent on Update')
    # Update must not undo a hover fade in progress.
    s.vars['Reveal'] = '0.5'
    lua.globals().Update()
    check(s.vars['Reveal'] == '0.5', 'Update leaves Reveal alone')


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


def main():
    test_core()
    rows = test_signalrgb()
    print('| scale | side | box W | hit W | icon X | text anchor X | arrow X |')
    print('| --- | --- | --- | --- | --- | --- | --- |')
    for scale, side, box, hit, icon, text, move in rows:
        print(f'| {scale}% | {side} | {box:g} | {hit:g} | {icon:g} | {text:g} | {move:g} |')
    print(f'{check.failed} failure(s)')
    sys.exit(1 if check.failed else 0)


main()
