"""Offline check of the tooltip switch. Run: python tools/test_tooltips.py

ToolTipHidden sits in a skin's [Rainmeter] section, which Rainmeter reads while
the skin loads, before any script runs. So the global TooltipsAll cannot be
resolved by Scripts\\Core.lua (there is nothing for Core.lua to run against at
that point); it is resolved by variable lookup alone, in @Resources\\Core.inc
(TipHidden1 / TipHidden0). See specs/tooltips.md.

This test therefore models Rainmeter's variable replacement (nested
#Name[#Index]# lookups, replaced either as each variable is defined or when it
is read) and feeds it the real files in the order a skin includes them:
@Resources\\Theme.inc, Defaults.inc, <Skin>\\Defaults.inc, the user's settings
(User.inc), Core.inc. Then it reads every skin's real ToolTipHidden line for
every TooltipsAll x <Skin>Tooltips combination:

    TooltipsAll=skin  hidden = not <Skin>Tooltips
    TooltipsAll=on    never hidden
    TooltipsAll=off   always hidden

Needs no Rainmeter and no extra packages. What it cannot show (tooltips
actually appearing, the Settings rows) is [PC] in specs/tooltips.md.
"""
import itertools
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKINS = ['DayDate', 'Power', 'Uptime', 'Volume', 'Media', 'RecycleBin', 'Playnite',
         'WiFi', 'FanControl', 'SignalRGB', 'DeepCool', 'Controllers', 'SettingsButton']
failed = 0


def check(cond, message):
    global failed
    if not cond:
        print('FAIL', message)
        failed += 1


def variables_of(path):
    """Ordered (key, value) pairs from the [Variables] section of a file."""
    out, section = [], None
    for line in path.read_text('ascii').splitlines():
        line = line.strip()
        if not line or line.startswith(';'):
            continue
        m = re.match(r'^\[(.+)\]$', line)
        if m:
            section = m.group(1).lower()
        elif section == 'variables' and '=' in line:
            k, v = line.split('=', 1)
            out.append((k.strip(), v.strip()))
    return out


def replace(text, store):
    """Rainmeter-style replacement: [#Name] inside a name first, then #Name#."""
    for _ in range(20):
        new = re.sub(r'\[#(\w+)\]', lambda m: store.get(m.group(1).lower(), m.group(0)), text)
        new = re.sub(r'#(\w+)#', lambda m: store.get(m.group(1).lower(), m.group(0)), new)
        if new == text:
            break
        text = new
    return text


def load(skin, user, mode):
    """Variables as the skin sees them. mode 'define' replaces each value as
    it is defined (the strict reading), 'read' keeps the text and replaces it
    when it is used (the lenient one). Both must give the same answer."""
    files = [ROOT / '@Resources' / 'Theme.inc', ROOT / '@Resources' / 'Defaults.inc',
             ROOT / skin / 'Defaults.inc']
    pairs = [kv for f in files for kv in variables_of(f)]
    pairs += list(user.items())
    pairs += variables_of(ROOT / '@Resources' / 'Core.inc')
    store = {}
    for k, v in pairs:
        store[k.lower()] = replace(v, store) if mode == 'define' else v
    return store


def tooltip_hidden(skin, store, mode):
    text = (ROOT / skin / f'{skin}.ini').read_text('ascii')
    m = re.search(r'^ToolTipHidden=(.+)$', text, re.M)
    check(m is not None, f'{skin}: no ToolTipHidden line')
    if not m:
        return None
    if mode == 'read':
        # Lenient mode: nothing was replaced at definition, so the store
        # entries are replaced one by one on the way.
        store = {k: v for k, v in store.items()}
        for _ in range(20):
            store = {k: replace(v, store) for k, v in store.items()}
    return replace(m.group(1), store)


def test_all():
    for skin in SKINS:
        defaults = (ROOT / skin / 'Defaults.inc').read_text('ascii')
        check(re.search(rf'^{skin}Tooltips=1\s*$', defaults, re.M) is not None,
              f'{skin}/Defaults.inc: {skin}Tooltips=1 missing')
        for mode, tall, own in itertools.product(('define', 'read'), ('skin', 'on', 'off'), ('1', '0')):
            tag = f'{skin} TooltipsAll={tall} {skin}Tooltips={own} ({mode})'
            user = {'TooltipsAll': tall, f'{skin}Tooltips': own}
            got = tooltip_hidden(skin, load(skin, user, mode), mode)
            want = {'skin': '0' if own == '1' else '1', 'on': '0', 'off': '1'}[tall]
            check(got == want, f'{tag}: ToolTipHidden is {got!r}, want {want!r}')
        # Nothing set by the user: the defaults show every tooltip.
        for mode in ('define', 'read'):
            got = tooltip_hidden(skin, load(skin, {}, mode), mode)
            check(got == '0', f'{skin}: with defaults ToolTipHidden is {got!r}, want 0 ({mode})')


test_all()
print(f'{failed} problem(s)')
sys.exit(1 if failed else 0)
