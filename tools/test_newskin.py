"""Tests tools/new-skin.py without touching the repo.

Run: python tools/test_newskin.py

Copies the repo into a temp directory, generates a throwaway skin there, checks
the generated files, runs that copy's tools/lint.py (1) as generated and (2)
after the shared registration steps that the script deliberately does not do
(SKIN_FOLDERS, TABS, the Settings tab, the General toggle, skins.json, the
layout, the INDEX, the README row and the site), applied here
programmatically. Nothing is written to the real repo. Standard library only.
"""
import importlib.util
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKIN = 'ZzScaffold'
failures = []


def check(cond, msg):
    if not cond:
        failures.append(msg)
        print('FAIL:', msg)


def load_script():
    spec = importlib.util.spec_from_file_location('new_skin', ROOT / 'tools' / 'new-skin.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def lint(copy):
    p = subprocess.run([sys.executable, str(copy / 'tools' / 'lint.py')], capture_output=True, text=True)
    problems = [l for l in p.stdout.splitlines() if l and not l.startswith('warning:')
                and not re.fullmatch(r'\d+ problem\(s\)', l)]
    return p.returncode, problems


def edit(path, pattern, repl, count=1):
    text = path.read_text('ascii')
    new, n = re.subn(pattern, repl, text, count=count, flags=re.S)
    check(n == count, f'registration edit did not apply in {path.name}: {pattern}')
    path.write_text(new, 'ascii', newline='\n')


def register(copy, name):
    """The manual steps of docs/sop/add-a-skin.md that touch shared files."""
    edit(copy / 'tools' / 'lint.py', r"(SKIN_FOLDERS = \[.*?)\]", rf"\1, '{name}']")
    edit(copy / '@Resources' / 'Setup' / 'NeedsList.lua', r"(\n\tSettingsButton = \{\},)", rf"\1\n\t{name} = {{}},")
    edit(copy / '@Resources' / 'Scripts' / 'Settings.lua', r"(local TABS = \{.*?)\n\}", rf"\1\n\t'{name}',\n}}")
    chrome = copy / '@Resources' / 'Settings' / 'Chrome.inc'
    n = len(re.findall(r'^\[Tab[A-Za-z]+\]', chrome.read_text('ascii'), re.M)) - 1  # minus [TabBar]
    tab = (f'[Tab{name}]\nMeter=String\nMeterStyle=sTab\nY=((#TabY0#+{n}*#TabStep#)*#PS#)\n'
           f'Text={name.upper()}\nLeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\\Settings" "{name}.ini"]\n\n')
    edit(chrome, r'(\[TabBar\])', lambda m: tab + m.group(1))
    general = copy / 'Settings' / 'General.ini'
    toggle = (f'\n[Skin{name}]\nMeter=String\nX=(576*#PS#)\nY=(600*#PS#)\nFontFace=#FontFace#\n'
              f'FontSize=(9*#PS#)\nFontColor=#Ink#,230\nDynamicVariables=1\nText={name.upper()}\n\n'
              f'[Skin{name}Toggle]\nMeter=Shape\nMeterStyle=sToggle\nX=(842*#PS#)\nY=(601*#PS#)\n'
              f"Shape=Rectangle 0,0,(30*#PS#),(16*#PS#),(8*#PS#) | StrokeWidth 0 | Fill Color [&mSettings:SkinFill('{name}')]\n"
              f"LeftMouseUpAction=[!CommandMeasure mSettings \"SkinOn('{name}')\"]\n")
    with general.open('a', encoding='ascii', newline='\n') as f:
        f.write(toggle)
    skins = copy / 'docs' / 'skins.json'
    edit(skins, r'(\n  \])', f',\n    {{"folder": "{name}", "name": "{name}", "oneLiner": "x", "guide": "docs/guide/{name}.md"}}\\1')
    with (copy / 'tools' / 'layout' / 'Control-Plaine.layout').open('a', encoding='ascii', newline='\n') as f:
        f.write(f'\n[Control-Plaine\\{name}]\nActive=1\nWindowX=24\nWindowY=24\n')
    with (copy / 'docs' / 'INDEX.md').open('a', encoding='ascii', newline='\n') as f:
        f.write(f'\n[guide/{name}.md](guide/{name}.md)\n')
    with (copy / 'README.md').open('a', encoding='ascii', newline='\n') as f:
        f.write(f'\n| {name} | x | [guide](docs/guide/{name}.md) |\n')
    with (copy / 'site' / 'index.html').open('a', encoding='ascii', newline='\n') as f:
        f.write(f'\n<!-- {name} -->\n')


def main():
    before = sorted(str(p.relative_to(ROOT)) for p in ROOT.rglob('*') if '.git' not in p.parts and p.is_file())
    mod = load_script()
    with tempfile.TemporaryDirectory() as tmp:
        copy = pathlib.Path(tmp) / 'repo'
        shutil.copytree(ROOT, copy, ignore=shutil.ignore_patterns('.git', 'node_modules', '__pycache__'))
        code, problems = lint(copy)
        check(code == 0, f'baseline lint of the copy is not clean: {problems[:3]}')

        written = mod.generate(copy, SKIN, icon='settings', summary='A throwaway test skin.')
        rels = sorted(str(p.relative_to(copy)).replace('\\', '/') for p in written)
        check(rels == sorted([f'{SKIN}/{SKIN}.ini', f'{SKIN}/Defaults.inc', f'Settings/{SKIN}.ini',
                              f'docs/guide/{SKIN}.md']), f'unexpected files written: {rels}')
        for p in written:
            text = p.read_text('ascii')
            check('{{' not in text, f'{p.name}: unfilled placeholder')
            check(SKIN in text, f'{p.name}: skin name missing')

        # Generated files only: before the shared registration the only complaints
        # are the skin-list agreement (I1) and the INDEX (I2), so the new skin
        # cannot be forgotten.
        code, problems = lint(copy)
        check(code == 1 and all(': I1 ' in p or p.startswith('I1:') or ': I2 ' in p for p in problems) and problems,
              f'lint after generate (unregistered) should only ask for registration: {problems[:5]}')

        # With the registration steps applied, the per-skin checks (tooltips T3/T4,
        # Defaults and Settings page present) apply to the new skin as well.
        register(copy, SKIN)
        code, problems = lint(copy)
        check(code == 0, f'lint after registration: {problems[:5]}')
        lint_text = (copy / 'tools' / 'lint.py').read_text('ascii')
        check(f"'{SKIN}'" in lint_text, 'registration did not reach lint.py')

        # A second run must refuse rather than overwrite.
        try:
            mod.generate(copy, SKIN)
            check(False, 'a second run overwrote an existing skin')
        except SystemExit:
            pass
        # Bad input is rejected.
        for bad in ('lower', 'Has Space', '1Bad', 'Caf' + chr(233)):
            try:
                mod.generate(copy, bad)
                check(False, f'name {bad!r} was accepted')
            except SystemExit:
                pass
        try:
            mod.generate(copy, 'ZzOther', icon='no-such-icon')
            check(False, 'a missing icon was accepted')
        except SystemExit:
            pass
        check(not (copy / 'ZzOther').exists(), 'a rejected run left files behind')

    after = sorted(str(p.relative_to(ROOT)) for p in ROOT.rglob('*') if '.git' not in p.parts and p.is_file())
    after = [a for a in after if '__pycache__' not in a]
    before = [b for b in before if '__pycache__' not in b]
    check(before == after, 'the test changed files in the real repo')
    print(f'{len(failures)} failure(s)')
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
