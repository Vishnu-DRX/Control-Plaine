"""Checks every Control-Plaine skin follows the suite's rules.

Run: python tools/lint.py

v2 skins (they include Core.inc) must follow specs/foundation-settings.md:
include order, group, right-click settings entry, no !Show/!Hide of their own.
A skin that sets SkinSide (it arranges itself left or right) is also held to
specs/alignment.md: the <Skin>Align and <Skin>Details keys with their
defaults, the Settings page rows, and no hand-rolled mirroring.
A skin that sets SkinTheme (it follows the light/dark mode) is held to
specs/theme.md: the <Skin>Theme key with its default, and no hard-coded white
or black ink (every colour comes from Ink, InkContrast, Accent, Warn, Dark).
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
V2_ORDER = ['#@#Theme.inc', '#@#Defaults.inc', '#@#User.inc', '#@#Core.inc', '#@#Styles.inc']
SETTINGS_ORDER = V2_ORDER + ['#@#Settings\\Controls.inc', '#@#Settings\\Chrome.inc']
SKIN_FOLDERS = ['DayDate', 'Power', 'Uptime', 'Volume', 'Media', 'RecycleBin', 'Playnite',
                'WiFi', 'FanControl', 'SignalRGB', 'DeepCool', 'Controllers',
                'SettingsButton']
# Settings.lua functions whose first argument is a setting key.
KEY_CALLS = r"(?<![A-Za-z])(?:Fill|Knob|Toggle|Set|Step|Show|ChoiceAlpha|ChoiceLine|EditPath)\('(\w+)'"
problems = []


def includes(text):
    return [m.strip() for m in re.findall(r'^@include\d*=(.+)$', text, re.M)]


def in_order(found, wanted):
    pos = []
    for inc in wanted:
        if inc not in found:
            return False
        pos.append(found.index(inc))
    return pos == sorted(pos)


# Every setting key defined in a Defaults file (or the theme).
defined = set()
for f in [ROOT / '@Resources' / 'Defaults.inc', ROOT / '@Resources' / 'Theme.inc',
          *ROOT.glob('*/Defaults.inc')]:
    if f.exists():
        defined |= set(re.findall(r'^(\w+)=', f.read_text('ascii', 'replace'), re.M))



def check_aligned(rel, text):
    """Rules A5, A6, A9 for a skin that sets SkinSide."""
    skin = rel.parts[0]
    align, details = f'{skin}Align', f'{skin}Details'
    if not re.search(rf'^SkinSide=#{align}#\s*$', text, re.M):
        problems.append(f'{rel}: SkinSide must be #{align}#')
    if not re.search(rf'^SkinDetails=#{details}#\s*$', text, re.M):
        problems.append(f'{rel}: SkinDetails must be #{details}#')
    defaults = (ROOT / skin / 'Defaults.inc').read_text('ascii', 'replace')
    if not re.search(rf'^{align}=left\s*$', defaults, re.M):
        problems.append(f'{skin}/Defaults.inc: needs {align}=left (every skin defaults to left)')
    if not re.search(rf'^{details}=hover\s*$', defaults, re.M):
        problems.append(f'{skin}/Defaults.inc: needs {details}=hover')
    page = ROOT / 'Settings' / f'{skin}.ini'
    if page.exists():
        ptext = page.read_text('ascii', 'replace')
        if not (re.search(rf'^AlignKey={align}\s*$', ptext, re.M)
                and re.search(rf'^DetailsKey={details}\s*$', ptext, re.M)
                and '#@#Settings\\Align.inc' in includes(ptext)):
            problems.append(f'Settings/{skin}.ini: needs AlignKey={align}, DetailsKey={details} '
                            f'and @include of #@#Settings\\Align.inc')
    for m in re.finditer(r'^StringAlign=(.+)$', text, re.M):
        if not m.group(1).strip().startswith(('#TA#', '#TAT#')):
            problems.append(f'{rel}: StringAlign must be #TA# or #TAT# (found {m.group(1).strip()}); '
                            f'use the Core helpers, not a hand-rolled mirror')
    for m in re.finditer(r'^(Anchor|Mirror|Lead|Trail|TA|TAT|Mir|Side)\w*=', text, re.M):
        problems.append(f'{rel}: {m.group(0)[:-1]} redefines a Core alignment helper; use Side Mir TA TAT Lead Trail')


def check_themed(rel, text):
    """Rules L6 and L8 for a skin that sets SkinTheme."""
    skin = rel.parts[0]
    theme = f'{skin}Theme'
    if not re.search(rf'^SkinTheme=#{theme}#\s*$', text, re.M):
        problems.append(f'{rel}: SkinTheme must be #{theme}#')
    defaults = (ROOT / skin / 'Defaults.inc').read_text('ascii', 'replace')
    if not re.search(rf'^{theme}=auto\s*$', defaults, re.M):
        problems.append(f'{skin}/Defaults.inc: needs {theme}=auto')
    # White or black with a visible alpha (or none) is ink; 0,0,0,0 and 0,0,0,1 are
    # the invisible and the hit-test backing colours.
    for n, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith(';'):
            continue
        for m in re.finditer(r'(?<![\d.])(255,255,255|0,0,0)(?:,(\d+))?(?![\d,.])', line):
            if m.group(1) == '0,0,0' and m.group(2) is not None and int(m.group(2)) <= 1:
                continue
            problems.append(f'{rel}:{n}: hard-coded {m.group(1)}; use #Ink#, #InkContrast# or #Dark#: {line.strip()}')


for path in sorted(ROOT.rglob('*')):
    if path.suffix.lower() not in ('.ini', '.inc', '.lua') or '.git' in path.parts:
        continue
    rel = path.relative_to(ROOT)
    if rel.parts[0] == 'Layouts' or rel.name in ('User.inc', 'State.inc'):
        continue
    raw = path.read_bytes()
    try:
        text = raw.decode('ascii')
    except UnicodeDecodeError:
        problems.append(f'{rel}: non-ASCII characters (keep files ASCII so Rainmeter reads them the same everywhere)')
        continue
    if re.search(r'[A-Za-z]:\\Users\\', text, re.I):
        problems.append(f'{rel}: hardcoded user path, move it to a Defaults.inc or User.inc')
    if path.suffix.lower() in ('.ini', '.inc'):
        for line in text.splitlines():
            if re.match(r'^[A-Za-z]\w*=.*\s;\s', line) and 'Text=' not in line and 'ToolTip' not in line:
                problems.append(f'{rel}: inline ; comment (Rainmeter has none, put it on its own line): {line.strip()}')
    for name in re.findall(r'#@#Icons\\([\w-]+\.png)', text):
        if not (ROOT / '@Resources' / 'Icons' / name).exists():
            problems.append(f'{rel}: icon {name} does not exist')
    if path.suffix.lower() != '.ini':
        continue
    if '[Metadata]' not in text:
        problems.append(f'{rel}: missing [Metadata]')
    found = includes(text)
    if rel.parts[0] == 'Settings':
        if not in_order(found, SETTINGS_ORDER):
            problems.append(f'{rel}: Settings page must include {", ".join(SETTINGS_ORDER)} in that order')
        for key in re.findall(r'^(?:Align|Details|Tip)Key=(\w+)\s*$', text, re.M):
            if key not in defined:
                problems.append(f'{rel}: setting {key} has no default in a Defaults.inc')
        for key in re.findall(KEY_CALLS, text):
            if key not in defined:
                problems.append(f'{rel}: setting {key} has no default in a Defaults.inc')
    elif '#@#Core.inc' in found:
        if not in_order(found, V2_ORDER):
            problems.append(f'{rel}: must include {", ".join(V2_ORDER)} in that order')
        own = f'#ROOTCONFIGPATH#{rel.parts[0]}\\Defaults.inc'
        if own not in found:
            problems.append(f'{rel}: missing @include of {own}')
        if not re.search(r'^Group=.*\bControlPlaine\b', text, re.M):
            problems.append(f'{rel}: [Rainmeter] needs Group=ControlPlaine')
        if 'ContextTitle=Control-Plaine settings' not in text or '#ROOTCONFIG#\\Settings' not in text:
            problems.append(f'{rel}: needs the Control-Plaine settings right-click entry')
        if re.search(r'\[!(Show|Hide)\]', text):
            problems.append(f'{rel}: use SelfHidden + mVisible instead of !Show/!Hide')
        if re.search(r'^SkinSide=', text, re.M):
            check_aligned(rel, text)
        if re.search(r'^SkinTheme=', text, re.M):
            check_themed(rel, text)
    else:
        problems.append(f'{rel}: a skin must include Core.inc (the v1 Fade.inc skins are gone)')

for name in SKIN_FOLDERS:
    if not (ROOT / name / 'Defaults.inc').exists():
        problems.append(f'{name}: missing Defaults.inc')
    if not (ROOT / 'Settings' / f'{name}.ini').exists():
        problems.append(f'Settings: missing page {name}.ini')

# B10: every setting key in a Defaults.inc has a Settings row (a Fill, Knob,
# Toggle, Set, Step, Show, ChoiceAlpha, ChoiceLine or EditPath call, or an
# AlignKey / DetailsKey). Keys after a '---- Runtime, not settings ----' comment
# in a Defaults.inc are state, not settings, and are exempt.
# WARNING ONLY for now: per-skin PRs are still adding their rows. Flip
# B10_FAILS to True once they have merged.
B10_FAILS = False
warnings = []
rowkeys = set()
for page in (ROOT / 'Settings').glob('*.ini'):
    ptext = page.read_text('ascii', 'replace')
    rowkeys |= set(re.findall(KEY_CALLS, ptext))
    rowkeys |= set(re.findall(r'^(?:Align|Details|Tip)Key=(\w+)\s*$', ptext, re.M))
rowkeys = {k.lower() for k in rowkeys}
for f in sorted(ROOT.glob('*/Defaults.inc')):
    runtime = False
    for line in f.read_text('ascii', 'replace').splitlines():
        if re.match(r'^;\s*-+\s*Runtime, not settings\s*-+', line):
            runtime = True
            continue
        m = re.match(r'^(\w+)=', line)
        if m and not runtime and m.group(1).lower() not in rowkeys:
            warnings.append(f'{f.relative_to(ROOT)}: B10 setting {m.group(1)} has no Settings row '
                            f'(add one, or move it under "---- Runtime, not settings ----")')
for w in warnings:
    if B10_FAILS:
        problems.append(w)
    else:
        print('warning: ' + w)

# T3, T4: tooltips. A skin with any ToolTipText (in its ini or its script) hides
# them all through the shared lookup, which includes TooltipsAll (Core.inc), and
# has a <Skin>Tooltips default and a TOOLTIPS row on its Settings page. See
# specs/tooltips.md.
core_inc = (ROOT / '@Resources' / 'Core.inc').read_text('ascii', 'replace')
for tip in ('TipHidden1', 'TipHidden0'):
    if not re.search(rf'^{tip}=.*\[#TooltipsAll\]', core_inc, re.M):
        problems.append(f'@Resources/Core.inc: T3 {tip} must be looked up through [#TooltipsAll]')
if not re.search(r'^TooltipsAll=skin\s*$', (ROOT / '@Resources' / 'Defaults.inc').read_text('ascii', 'replace'), re.M):
    problems.append('@Resources/Defaults.inc: T4 needs TooltipsAll=skin')
adv = (ROOT / 'Settings' / 'Advanced.ini')
adv_text = adv.read_text('ascii', 'replace') if adv.exists() else ''
for value in ('skin', 'on', 'off'):
    if f"Set('TooltipsAll','{value}'" not in adv_text:
        problems.append(f"Settings/Advanced.ini: T4 needs a TOOLTIPS ON ALL SKINS choice Set('TooltipsAll','{value}','all')")
for name in SKIN_FOLDERS:
    ini = ROOT / name / f'{name}.ini'
    if not ini.exists():
        continue
    itext = ini.read_text('ascii', 'replace')
    script = ROOT / '@Resources' / 'Scripts' / f'{name}.lua'
    stext = script.read_text('ascii', 'replace') if script.exists() else ''
    if 'ToolTipText' not in itext and 'ToolTipText' not in stext:
        continue
    head = itext.split('\n[', 2)
    rainmeter = head[1] if len(head) > 1 and head[1].startswith('Rainmeter]') else ''
    if not re.search(rf'^ToolTipHidden=#TipHidden\[#{name}Tooltips\]#\s*$', rainmeter, re.M):
        problems.append(f'{name}/{name}.ini: T3 [Rainmeter] needs ToolTipHidden=#TipHidden[#{name}Tooltips]# '
                        f'(a skin with tooltips must hide them through the shared lookup)')
    if not re.search(rf'^{name}Tooltips=1\s*$', (ROOT / name / 'Defaults.inc').read_text('ascii', 'replace'), re.M):
        problems.append(f'{name}/Defaults.inc: T4 needs {name}Tooltips=1')
    page = ROOT / 'Settings' / f'{name}.ini'
    ptext = page.read_text('ascii', 'replace') if page.exists() else ''
    if not (re.search(rf'^TipKey={name}Tooltips\s*$', ptext, re.M)
            and re.search(r'^TipY=\d+\s*$', ptext, re.M)
            and '#@#Settings\\Tooltips.inc' in includes(ptext)):
        problems.append(f'Settings/{name}.ini: T4 needs TipKey={name}Tooltips, TipY and @include of #@#Settings\\Tooltips.inc')

# L7: every icon is white with alpha (so ImageTint=#Ink# follows light mode) or
# is on the allow-list in tools/check_icons.py with a reason and a -light twin.
sys.path.insert(0, str(ROOT / 'tools'))
import check_icons
problems += check_icons.problems()

for p in problems:
    print(p)
print(f'{len(problems)} problem(s)')
sys.exit(1 if problems else 0)
