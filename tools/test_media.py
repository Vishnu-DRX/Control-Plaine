"""Offline checks for the Media skin. Run: python tools/test_media.py

Needs lupa (pip install lupa), which embeds Lua.

1. The Media meters' X/W formulas, read from Media/Media.ini, are evaluated
   for both sides at scale 100, 125 and 150%: same box and hit width on both
   sides, ring and text column inside the box and not overlapping, the ring at
   the outer edge, chevrons in the same order (Prev left of Next) and the same
   place in the column on both sides, clip boxes inside the text column. The
   variables are baked the way Rainmeter does it (a [Variables] value keeps
   what #Mir# was when it was defined: Core.inc's placeholder), so a variable
   that depends on the side would leave the ring on the left: that is checked.
   Also: title, artist and hairline are invisible at Reveal=0 (details on
   hover) and shown at Reveal=1 (always), as on Volume. The chevrons follow
   Hov instead, so they show on hover only, whatever MediaDetails says.
2. Scripts\\Media.lua, run against a fake SKIN, scrolls a long title for both
   sides: it starts with the first letter at the box's left edge, moves
   leftwards only, stops with the last letter flush with the right edge,
   returns to rest, and stops the scroll timer. A short title does not slide.

Rainmeter itself is not involved: see the PR for what only the PC can show.
"""
import math
import pathlib
import re
import sys

from lupa import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
failed = 0


def check(cond, message):
    global failed
    if not cond:
        failed += 1
        print('FAIL', message)


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


PLACEHOLDERS = {'Mir': '0', 'Lead': '0', 'Trail': '1', 'Side': 'left', 'TA': 'LeftCenter',
                'TAT': 'Left', 'RevealMin': '0'}


def bake(paths, scale):
    """[Variables] as Rainmeter reads them: each value has its #Name# parts
    replaced when it is defined, so it keeps the value they had then. Core.inc's
    side placeholders are in place before the skin's own variables."""
    out = {'Scale': str(scale), 'Sz': str(scale), **PLACEHOLDERS}
    for p in paths:
        in_vars = False
        for line in (ROOT / p).read_text().splitlines():
            if line.startswith('['):
                in_vars = line.strip() == '[Variables]'
            elif in_vars and re.match(r'^\w+=', line) and not line.startswith('@include'):
                k, v = line.split('=', 1)
                if k == 'Scale':
                    continue
                for _ in range(20):
                    new = re.sub(r'#(\w+)#', lambda m: out.get(m.group(1), m.group(0)), v)
                    if new == v:
                        break
                    v = new
                out[k] = v
    return out


def evaluate(expr, variables):
    for _ in range(20):
        new = re.sub(r'#(\w+)#', lambda m: variables.get(m.group(1), m.group(0)), expr)
        if new == expr:
            break
        expr = new
    expr = expr.replace('Round(', 'rnd(')
    return eval(expr, {'rnd': rnd, '__builtins__': {}})


def section(text, name):
    m = re.search(rf'^\[{name}\]\n(.*?)(?=^\[|\Z)', text, re.M | re.S)
    return dict(re.findall(r'^(\w+)=(.*)$', m.group(1), re.M))


def test_layout():
    ini = (ROOT / 'Media' / 'Media.ini').read_text()
    files = ['@Resources/Theme.inc', '@Resources/Defaults.inc', 'Media/Defaults.inc', 'Media/Media.ini']
    names = ('Back', 'TitleBox', 'ArtistBox', 'Hairline', 'PrevHit', 'Prev', 'NextHit', 'Next',
             'TitleHit', 'ArtistHit', 'Ring', 'RingHit', 'PlayPause')
    meters = {n: section(ini, n) for n in names}
    rows = []
    for scale in (1.0, 1.25, 1.5):
        got = {}
        for side in ('left', 'right'):
            mir = 1 if side == 'right' else 0
            v = {**bake(files, scale), 'Mir': str(mir), 'Lead': str(mir), 'Trail': str(1 - mir)}
            tag = f'scale {scale} {side}'
            box = evaluate('#BoxW#', v)
            x = {n: evaluate(meters[n]['X'], v) for n in names if n != 'Back'}
            w = {n: evaluate(meters[n]['W'], v) for n in names if 'W' in meters[n]}
            col = evaluate(meters['PrevHit']['X'], v)
            colw = evaluate('#ColP#', v)
            ring = evaluate(meters['RingHit']['X'], v)
            ringw = evaluate('#RingP#', v)
            check(w['Back'] == box, f'Back is the box ({tag})')
            check(all(a == int(a) for a in (box, col, colw, ring, ringw)), f'whole pixels ({tag})')
            check(col >= 0 and col + colw <= box and ring >= 0 and ring + ringw <= box, f'inside the box ({tag})')
            check(col + colw <= ring or ring + ringw <= col, f'ring and column do not overlap ({tag})')
            check(ring == (0 if side == 'left' else box - ringw), f'ring at the outer edge ({tag}): {ring}')
            check(col == (ringw + evaluate('#GapP#', v) if side == 'left' else 0), f'column on the far side ({tag}): {col}')
            for n in ('TitleBox', 'ArtistBox', 'Hairline', 'TitleHit', 'ArtistHit'):
                check(col <= x[n] and x[n] + w[n] <= col + colw, f'{n} inside the column ({tag})')
            tb = x['TitleBox'] - col
            check(tb == colw - (tb + w['TitleBox']), f'text box centred in column ({tag})')
            check(x['RingHit'] == ring and x['PlayPause'] == ring and x['Ring'] == ring, f'ring parts share X ({tag})')
            check(x['Prev'] < x['Next'] and x['PrevHit'] < x['NextHit'], f'chevron order Prev, Next ({tag})')
            check(x['Prev'] >= col and x['Next'] <= col + colw, f'chevrons inside the column ({tag})')
            got[side] = (box, w['Back'], x['Prev'] - col, x['Next'] - col, col, ring, tb, w['TitleBox'])
            rows.append((int(scale * 100), side, box, col, ring, tb, w['TitleBox']))
        check(got['left'][:2] == got['right'][:2], f'same box and hit area on both sides (scale {scale})')
        check(got['left'][2:4] == got['right'][2:4], f'chevrons keep their place in the column (scale {scale})')
        check(got['left'][6:] == got['right'][6:], f'same text box in the column (scale {scale})')
    return rows


def test_reveal():
    """Title, artist and hairline: nothing at Reveal=0, the hover level at 1."""
    ini = (ROOT / 'Media' / 'Media.ini').read_text()
    files = ['@Resources/Theme.inc', '@Resources/Defaults.inc', 'Media/Defaults.inc', 'Media/Media.ini']
    for name, opt in (('Title', 'FontColor'), ('Artist', 'FontColor'), ('Hairline', 'SolidColor')):
        expr = section(ini, name)[opt]
        alpha = expr.split(',', 1)[1]
        check('#Reveal#' in alpha, f'{name} follows Reveal')
        if name == 'Hairline':
            check('Reveal' in section(ini, name).get('Group', ''), 'Hairline is in group Reveal')
        for dim in (1, 0.7):
            v = {**bake(files, 1), 'AlphaHover': '250', 'AlphaTrack': '60', 'Dim': str(dim)}
            vals = {}
            for reveal in (0, 1):
                v['Reveal'] = str(reveal)
                vals[reveal] = evaluate(alpha, v)
            check(vals[0] == 0, f'{name} is invisible at rest with details on hover (Dim {dim})')
            check(vals[1] > 0, f'{name} is shown at Reveal=1 (Dim {dim})')
    for name in ('Prev', 'Next'):
        shape = section(ini, name)['Shape']
        check('#Hov#' in shape and '#Reveal#' not in shape, f'{name} chevron follows Hov (hover only), not Reveal')
        check('Hover' in section(ini, name).get('Group', ''), f'{name} is in group Hover')
    for name in ('TitleBox', 'ArtistBox'):
        # A container with a near-transparent colour (alpha 1) left the text unseen.
        col = section(ini, name)['SolidColor']
        check('#Reveal#' in col and col.split(',', 1)[1].strip() != '1', f'{name} container is opaque while the text shows')
    # Bug guard: no [Variables] entry may use the side helpers (baked at load).
    in_vars = False
    for line in ini.splitlines():
        if line.startswith('['):
            in_vars = line.strip() == '[Variables]'
        elif in_vars and re.match(r'^\w+=', line):
            check(not re.search(r'#(Mir|Lead|Trail|TA|TAT|Side|RevealMin|HoverTint)#', line),
                  f'a [Variables] value uses a side helper: {line}')


# ---------- Media.lua scroll direction ----------

class Meter:
    def __init__(self, w=0):
        self.opts = {}
        self.w = w

    def GetW(self):
        return self.w


def run_scroll(mir, text_w=400, box_w=190, reveal_min=1):
    lua = LuaRuntime(unpack_returned_tuples=True)
    meters = {'Title': Meter(), 'TitleBox': Meter(box_w), 'Artist': Meter(), 'ArtistBox': Meter(box_w)}
    full = {'Title': text_w, 'Artist': max(0, text_w - 100)}
    log = []
    variables = {'Mir': str(mir), 'Scale': '1', 'MediaScrollTitles': '1', 'RevealMin': str(reveal_min)}

    class Measure:
        def GetValue(self):
            return 1

    class Skin:
        def ParseFormula(self, s):
            return float(eval(s))

        def ReplaceVariables(self, s):
            return re.sub(r'#(\w+)#', lambda m: variables.get(m.group(1), m.group(0)), s)

        def GetMeter(self, name):
            return meters.get(name)

        def GetMeasure(self, name):
            return Measure()

        def Bang(self, bang, *args):
            if bang == '!SetOption':
                m = meters[args[0]]
                m.opts[args[1]] = args[2]
                if args[0] in full and args[1] in ('ClipString', 'W'):
                    m.w = box_w if str(m.opts.get('ClipString')) == '1' else full[args[0]]
            log.append((bang,) + tuple(args))

    g = lua.globals()
    g.SKIN = Skin()
    lua.execute((ROOT / '@Resources' / 'Scripts' / 'Media.lua').read_text())
    g.Initialize()
    return g, meters, log, full


def edges(m, mir, full_w):
    """(left, right) of the unclipped text in box coordinates."""
    x = float(m.opts['X'])
    return (x - full_w, x) if mir else (x, x + full_w)


def at_rest(m):
    return str(m.opts.get('ClipString')) == '1' and m.opts.get('X') == '(#Mir#*#TextWp#)'


def test_scroll():
    for mir in (0, 1):
        tag = f'side {mir}'
        g, meters, log, full = run_scroll(mir)
        g.TrackChanged()
        m = meters['Title']
        left, right = edges(m, mir, full['Title'])
        check(abs(left) < 1.01, f'first letter at the left edge when the slide starts ({tag}): {left}')
        check(('!CommandMeasure', 'mScroll', 'Execute 1') in log, f'timer started ({tag})')
        prev, last_right, ticks = left, right, 0
        while not at_rest(m) and ticks < 5000:
            g.Tick()
            ticks += 1
            if not at_rest(m):
                left, right = edges(m, mir, full['Title'])
                check(left <= prev + 1e-9, f'moves leftwards only ({tag})')
                prev, last_right = left, right
        check(at_rest(m), f'returns to rest ({tag})')
        check(abs(last_right - 190) < 1.01, f'last letter flush with the right edge at the end ({tag}): {last_right}')
        check(m.opts['StringAlign'] == '#TAT#', f'rest alignment comes from Core ({tag})')
        check(('!CommandMeasure', 'mScroll', 'Stop 1') in log, f'timer stopped ({tag})')
        # A title that fits does not slide.
        g, meters, log, full = run_scroll(mir, text_w=100)
        g.TrackChanged()
        check(at_rest(meters['Title']) and ('!CommandMeasure', 'mScroll', 'Execute 1') not in log,
              f'short title stays at rest ({tag})')
        # Details on hover: the text is invisible at rest, so a track change
        # does not slide; hovering does.
        g, meters, log, full = run_scroll(mir, reveal_min=0)
        g.TrackChanged()
        check(at_rest(meters['Title']) and ('!CommandMeasure', 'mScroll', 'Execute 1') not in log,
              f'no slide on a track change while the text is hidden ({tag})')
        g.Hover(1)
        check(not at_rest(meters['Title']), f'hover slides it ({tag})')
        # Hover keeps it going; leaving rests.
        g, meters, log, full = run_scroll(mir)
        g.Hover(1)
        check(not at_rest(meters['Title']), f'hover starts a slide ({tag})')
        g.Hover(0)
        check(at_rest(meters['Title']), f'leaving rests ({tag})')
        check(('!CommandMeasure', 'mScroll', 'Stop 1') in log, f'timer stopped on leave ({tag})')


def main():
    rows = test_layout()
    test_reveal()
    test_scroll()
    print('| scale | side | box W | column X | ring X | title box X in column | title box W |')
    print('| --- | --- | --- | --- | --- | --- | --- |')
    for scale, side, box, col, ring, tb, tw in rows:
        print(f'| {scale}% | {side} | {box:g} | {col:g} | {ring:g} | {tb:g} | {tw:g} |')
    print(f'{failed} failure(s)')
    sys.exit(1 if failed else 0)


main()
