"""Checks every Control-Plaine skin follows the suite's rules.

Run: python tools/lint.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
REQUIRED = ['#@#Theme.inc', '#@#User.inc', '#@#Styles.inc', '#@#Fade.inc']
problems = []

for path in sorted(ROOT.rglob('*')):
    if path.suffix.lower() not in ('.ini', '.inc', '.lua') or '.git' in path.parts:
        continue
    rel = path.relative_to(ROOT)
    if rel.parts[0] == 'Layouts' or rel.name == 'User.inc':
        continue
    raw = path.read_bytes()
    try:
        text = raw.decode('ascii')
    except UnicodeDecodeError:
        problems.append(f'{rel}: non-ASCII characters (keep files ASCII so Rainmeter reads them the same everywhere)')
        continue
    if re.search(r'[A-Za-z]:\\Users\\', text, re.I):
        problems.append(f'{rel}: hardcoded user path, move it to User.inc')
    if path.suffix.lower() == '.ini':
        for inc in REQUIRED:
            if inc not in text:
                problems.append(f'{rel}: missing @include of {inc}')
        if '[Metadata]' not in text:
            problems.append(f'{rel}: missing [Metadata]')
        for name in re.findall(r'#@#Icons\\([\w-]+\.png)', text):
            if not (ROOT / '@Resources' / 'Icons' / name).exists():
                problems.append(f'{rel}: icon {name} does not exist')

for p in problems:
    print(p)
print(f'{len(problems)} problem(s)')
sys.exit(1 if problems else 0)
