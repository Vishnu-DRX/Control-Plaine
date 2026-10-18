"""Offline check of the Controllers click gating. Run: python tools/test_controllers_gating.py

Evaluates the Hidden formula of each RowNClick meter in Controllers/Controllers.ini
for every combination of row kind (1 DualSense, 2 wheel, 3 other), the three
ControllersHas flags, and Count: the click overlay is visible only when the row
is shown and the flag of its kind is 1. Row<N>Hit (hover) must keep no click.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
text = (ROOT / 'Controllers' / 'Controllers.ini').read_text('ascii')

fails = []
DEBUG = False


def section(name):
    m = re.search(rf'^\[{name}\]\n((?:(?!\[).*\n?)*)', text, re.M)
    return m.group(1) if m else ''


def hidden(n, kind, dsx, wheel, other, count):
    body = section(f'Row{n}Click')
    expr = re.search(r'^Hidden=(.*)$', body, re.M).group(1)
    expr = expr.replace('#Count#', str(count)).replace(f'#Row{n}Kind#', str(kind))
    expr = expr.replace('#ControllersHasDsx#', str(dsx)).replace('#ControllersHasWheel#', str(wheel))
    expr = expr.replace('#ControllersHasOther#', str(other))
    # Rainmeter: = is equality, ? : ternary, || or.
    expr = re.sub(r'(?<![<>!=])=(?!=)', '==', expr)
    expr = expr.replace('||', ' or ')
    # (c ? a : b) -> ((a) if (c) else (b)), the innermost group first
    def tern(s):
        while ' ? ' in s:
            stack = []
            for i, ch in enumerate(s):
                if ch == '(':
                    stack.append(i)
                elif ch == ')':
                    j = stack.pop()
                    group = s[j + 1:i]
                    if ' ? ' in group:
                        c, rest = group.split(' ? ', 1)
                        x, y = rest.split(' : ', 1)
                        s = s[:j] + f'(({x}) if ({c}) else ({y}))' + s[i + 1:]
                        break
        return s
    expr = tern(expr)
    if DEBUG: print(expr)
    return int(bool(eval(expr)))


for n in range(1, 5):
    if 'MouseActionCursor=0' not in section(f'Row{n}Hit') or 'LeftMouseUpAction' in section(f'Row{n}Hit') \
            or 'ToolTipText' in section(f'Row{n}Hit'):
        fails.append(f'Row{n}Hit must have no click, cursor or tooltip')
    click = section(f'Row{n}Click')
    styles = (ROOT / '@Resources' / 'Styles.inc').read_text('ascii')
    shit = re.search(r'^\[sHit\]\n((?:(?!\[).*\n?)*)', styles, re.M).group(1)
    if 'DynamicVariables=1' not in shit and 'DynamicVariables=1' not in click:
        fails.append(f'Row{n}Click needs DynamicVariables=1 (or sHit must give it)')
    for kind in (1, 2, 3):
        for flags in range(8):
            dsx, wheel, other = flags & 1, (flags >> 1) & 1, (flags >> 2) & 1
            flag = {1: dsx, 2: wheel, 3: other}[kind]
            for count in range(0, 5):
                got = hidden(n, kind, dsx, wheel, other, count)
                want = 0 if (count >= n and flag == 1) else 1
                if got != want:
                    fails.append(f'Row{n}Click kind {kind} flags {dsx}{wheel}{other} count {count}: hidden {got}, want {want}')

if fails:
    print('\n'.join(fails[:20]))
    sys.exit(1)
print('Controllers click gating: ok')
