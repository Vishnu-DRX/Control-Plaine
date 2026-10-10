"""Checks every Control-Plaine skin follows the suite's rules.

Run: python tools/lint.py

v2 skins (they include Core.inc) must follow specs/foundation-settings.md:
include order, group, right-click settings entry, no !Show/!Hide of their own.
v1 skins (Fade.inc) are checked by the old rules until they are rebuilt.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
V1_REQUIRED = ['#@#Theme.inc', '#@#User.inc', '#@#Styles.inc', '#@#Fade.inc']
V2_ORDER = ['#@#Theme.inc', '#@#Defaults.inc', '#@#User.inc', '#@#Core.inc', '#@#Styles.inc']
SETTINGS_ORDER = V2_ORDER + ['#@#Settings\\Controls.inc', '#@#Settings\\Chrome.inc']
SKIN_FOLDERS = ['DayDate', 'Power', 'Uptime', 'Volume', 'Media', 'RecycleBin', 'Playnite',
                'WiFi', 'FanControl', 'SignalRGB', 'DeepCool', 'Controllers']
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
    else:
        for inc in V1_REQUIRED:
            if inc not in found:
                problems.append(f'{rel}: missing @include of {inc}')

for name in SKIN_FOLDERS:
    if not (ROOT / name / 'Defaults.inc').exists():
        problems.append(f'{name}: missing Defaults.inc')
    if not (ROOT / 'Settings' / f'{name}.ini').exists():
        problems.append(f'Settings: missing page {name}.ini')

for p in problems:
    print(p)
print(f'{len(problems)} problem(s)')
sys.exit(1 if problems else 0)
