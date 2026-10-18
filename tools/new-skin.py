"""Scaffolds a new Control-Plaine skin.

Run: python tools/new-skin.py <Name> [--title "Fan Control"] [--icon settings]
                              [--summary "One line."] [--root DIR]

Writes, from tools/templates/:
  <Name>/<Name>.ini          the skin (icon + label, aligned, themed, tooltips)
  <Name>/Defaults.inc        its Align, Details, Theme and Tooltips defaults
  Settings/<Name>.ini        its Settings page (ALIGN, DETAILS, TOOLTIPS rows)
  docs/guide/<Name>.md       its user-guide page (a draft with TODO markers)

It never edits an existing file and refuses to run if any target exists. The
shared registration (SKIN_FOLDERS, the Settings tab, TABS, the General toggle,
skins.json, README, site, CHANGELOG, the icon) is not automated because those
are shared files with one owner at a time; the script prints each step. The
full procedure is docs/sop/add-a-skin.md.

The generated skin draws an existing icon (--icon, default "settings") so lint
passes straight away; replace it with the skin's own icon (docs/sop/add-an-icon.md).
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
TEMPLATES = HERE / 'templates'


def default_title(name):
    """SettingsButton -> Settings Button."""
    return re.sub(r'(?<=[a-z0-9])(?=[A-Z])', ' ', name)


def render(template, values):
    text = (TEMPLATES / template).read_text('ascii')
    for key, value in values.items():
        text = text.replace('{{' + key + '}}', value)
    left = re.findall(r'\{\{\w+\}\}', text)
    if left:
        raise SystemExit(f'template {template}: unfilled {sorted(set(left))}')
    return text


def targets(root, name):
    return [
        (root / name / f'{name}.ini', 'skin.ini.tpl'),
        (root / name / 'Defaults.inc', 'Defaults.inc.tpl'),
        (root / 'Settings' / f'{name}.ini', 'Settings.ini.tpl'),
        (root / 'docs' / 'guide' / f'{name}.md', 'guide.md.tpl'),
    ]


def generate(root, name, title=None, icon='settings', summary=None):
    """Writes the four files under root and returns their paths. Raises SystemExit on bad input."""
    if not re.fullmatch(r'[A-Z][A-Za-z0-9]*', name):
        raise SystemExit(f'name {name!r}: use PascalCase letters and digits, no spaces (for example DayDate)')
    title = title or default_title(name)
    summary = summary or f'TODO one sentence about {title}.'
    for text in (title, summary, icon):
        if not text.isascii() or ';' in text or '#' in text or '\n' in text:
            raise SystemExit('title, icon and summary must be ASCII, one line, with no ";" or "#"')
    if not (root / '@Resources' / 'Icons' / f'{icon}.png').exists():
        raise SystemExit(f'icon {icon}.png is not in @Resources/Icons (see docs/sop/add-an-icon.md)')
    plan = targets(root, name)
    clash = [p for p, _ in plan if p.exists()]
    if clash:
        raise SystemExit('refusing to overwrite: ' + ', '.join(str(p) for p in clash))
    values = {'Name': name, 'Title': title, 'LABEL': title.upper(), 'Icon': icon, 'Summary': summary}
    rendered = [(p, render(t, values)) for p, t in plan]
    for path, text in rendered:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='ascii', newline='\n')
    return [p for p, _ in rendered]


def remaining(name, title):
    label = title.upper()
    return f"""
Generated. Now the manual steps (details and the lint rule for each: docs/sop/add-a-skin.md).
Shared files have one owner at a time: if another PR is changing one, send the exact change to its owner.

 1. Fill the TODOs in {name}/{name}.ini (header, click action, Sz) and in docs/guide/{name}.md.
 2. Icon: add docs/icons/<icon>.svg, run `node tools/render-icons.js`, and point
    ImageName at it (docs/sop/add-an-icon.md). Until then the skin uses an existing icon.
 3. tools/lint.py: add '{name}' to SKIN_FOLDERS (turns on the per-skin checks).
 3b. @Resources/Setup/NeedsList.lua: add `{name} = {{}},` (an empty list when the skin
    needs nothing; otherwise one entry per app, plugin or path it needs, see the
    header of that file). Lint fails without an entry.
 4. @Resources/Scripts/Settings.lua: add '{name}' to TABS.
 5. @Resources/Settings/Chrome.inc: add a tab after the last one, with the next
    free row number, before [TabBar]:
      [Tab{name}]
      Meter=String
      MeterStyle=sTab
      Y=((#TabY0#+<next number>*#TabStep#)*#PS#)
      Text={label}
      LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\\Settings" "{name}.ini"]
 6. Settings/General.ini: add the skin toggle pair [Skin{name}] and
    [Skin{name}Toggle] (copy a neighbour; use SkinOn('{name}'), SkinFill, SkinKnob).
 7. docs/skins.json: add {{"folder": "{name}", "name": "{title}", "oneLiner": "...", "guide": "docs/guide/{name}.md"}}.
 8. README.md: add a row to the Skins table. docs/INDEX.md: add the guide to the skin list.
 9. site/index.html: add a card (illustration from the skin's own icons).
10. CHANGELOG.md and Layouts/: integration-owned; ask before touching (docs/dev/release.md).
11. Cover the skin in the offline tests if it has formulas worth checking
    (tools/test_*.py; add a new file, do not edit another skin's).
12. python tools/lint.py must print 0 problem(s). Say in the PR what only the PC can check.
"""


def main(argv=None):
    ap = argparse.ArgumentParser(description='Scaffold a Control-Plaine skin.')
    ap.add_argument('name', help='PascalCase skin name, also the folder and key prefix')
    ap.add_argument('--title', help='display name, default: the name split into words')
    ap.add_argument('--icon', default='settings', help='existing icon in @Resources/Icons (no .png)')
    ap.add_argument('--summary', help='one-line description')
    ap.add_argument('--root', default=str(HERE.parent), help='repo root to write into (default: this repo)')
    args = ap.parse_args(argv)
    root = pathlib.Path(args.root).resolve()
    written = generate(root, args.name, args.title, args.icon, args.summary)
    for p in written:
        print('wrote', p.relative_to(root))
    print(remaining(args.name, args.title or default_title(args.name)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
