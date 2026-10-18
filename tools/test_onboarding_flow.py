"""Smoke test of the first-run flow: Settings.lua and Onboarding.lua run for real
against a fake SKIN object and a temporary copy of the skin files.
Run: python tools/test_onboarding_flow.py   (needs: pip install lupa)

Checks, without Rainmeter: Settings.lua sends a profile with no SetupDone to
Onboarding.ini and a configured one to its page; the amber marks follow the
detection; Onboarding.lua walks WELCOME -> SKINS -> SETUP -> LOOK -> DONE,
shows the right items, runs a helper only from Helpers.txt after Run(), turns
a skin off after SKIP on a required item, and FINISH / SKIP SETUP write
SetupDone=1. Bang arguments are recorded, not executed.

Not covered (needs the PC): drawing, the meters, RunCommand, UAC, real paths.
"""
import pathlib
import re
import shutil
import sys
import tempfile

from lupa import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
failed = 0


def check(cond, message):
    global failed
    if not cond:
        print('FAIL', message)
        failed += 1


PRELUDE = r"""
local real_open, real_dofile = io.open, dofile
io.open = function(p, m) return real_open((p:gsub('\\', '/')), m) end
dofile = function(p) return real_dofile((p:gsub('\\', '/'))) end
"""


class Fake:
    """One script's world: variables, recorded bangs, the other scripts' functions."""

    def __init__(self, tmp, script, variables, peers, files=()):
        self.tmp, self.vars, self.peers, self.bangs = tmp, dict(variables), peers, []
        self.clip = None
        self.rt = LuaRuntime(unpack_returned_tuples=True)
        self.rt.execute(PRELUDE)
        g = self.rt.globals()
        g.py = self.rt.table_from({
            'getvar': self.getvar, 'replace': self.replace, 'bang': self.bang,
        })
        self.rt.execute("""
            SKIN = {}
            function SKIN:GetVariable(k, d) return py.getvar(k, d) end
            function SKIN:ReplaceVariables(s) return py.replace(s) end
            function SKIN:Bang(...) return py.bang(...) end
            function SKIN:GetMeter(n) if n:match('^Mark') or n:match('^Tab') then return {} end end
            function SKIN:GetMeasure(n)
                if n == 'mOS' then return { GetStringValue = function() return 'Windows test' end } end
                if n == 'mRun' then return { GetStringValue = function() return py.runout() end } end
            end
        """)
        g.py.runout = lambda: 'fake output line 1\nfake error'
        self.rt.execute((ROOT / '@Resources' / 'Scripts' / script).read_text('ascii'))
        self.g = self.rt.globals()

    def getvar(self, key, default=None):
        value = self.vars.get(key)
        return value if value is not None else (default if default is not None else '')

    def replace(self, text):
        def inline(m):
            peer = self.peers.get(m.group(1))
            return str(getattr(peer.g, m.group(2))()) if peer else m.group(0)
        text = re.sub(r'\[&(\w+):(\w+)\(\)\]', inline, text)
        return re.sub(r'#(\w+)#', lambda m: self.vars.get(m.group(1), m.group(0)), text)

    def bang(self, *args):
        self.bangs.append(tuple(str(a) for a in args))
        if args[0] == '!SetVariable':
            self.vars[args[1]] = str(args[2])
        if args[0] == '!WriteKeyValue':
            write_state(args[4], args[2], args[3])
        if args[0] == '!SetClip':
            self.clip = args[1]
        if args[0] == '!CommandMeasure' and args[1] == 'mSettings' and 'mSettings' in self.peers:
            fn = re.match(r"(\w+)\('(\w+)'\)", args[2])
            if fn:
                getattr(self.peers['mSettings'].g, fn.group(1))(fn.group(2))

    def sent(self, name, *rest):
        return any(b[0] == name and all(r in b[1:] for r in rest) for b in self.bangs)


def write_state(path, key, value):
    path = pathlib.Path(path.replace('\\', '/'))
    text = path.read_text() if path.exists() else '[Variables]\n'
    if re.search(rf'^{key}=', text, re.M):
        text = re.sub(rf'^{key}=.*$', f'{key}={value}', text, flags=re.M)
    else:
        text += f'{key}={value}\n'
    path.write_text(text)


def world(tmp, state=None, user='', registry=None):
    """Copy the files the scripts read into tmp and return the shared variables."""
    base = pathlib.Path(tmp) / 'Control-Plaine'
    shutil.copytree(ROOT / '@Resources', base / '@Resources', ignore=shutil.ignore_patterns('Icons'))
    for d in ROOT.glob('*/Defaults.inc'):
        (base / d.parent.name).mkdir(exist_ok=True)
        shutil.copy(d, base / d.parent.name / 'Defaults.inc')
    (base / '@Resources' / 'Scripts').mkdir(exist_ok=True)
    (base / '@Resources' / 'State.inc').write_text('[Variables]\n' + (state or ''))
    (base / '@Resources' / 'User.inc').write_text('[Variables]\n' + user)
    (base / 'Settings').mkdir(exist_ok=True)
    return {
        '@': str(base / '@Resources') + '/',
        'ROOTCONFIG': 'Control-Plaine',
        'ROOTCONFIGPATH': str(base) + '/',
        'SETTINGSPATH': str(base) + '/',
        'Accent': '0,229,255', 'Ink': '255,255,255', 'Warn': '255,170,60',
        'SCREENAREAWIDTH': '1920', 'SCREENAREAHEIGHT': '1080',
    }, base


def state_text(base):
    return (base / '@Resources' / 'State.inc').read_text()


# ---------- Settings.lua: the trigger ----------

with tempfile.TemporaryDirectory() as tmp:
    base_vars, base = world(tmp)
    s = Fake(tmp, 'Settings.lua', dict(base_vars, Tab='General'), {})
    s.g.Initialize()
    check(s.sent('!ActivateConfig', 'Control-Plaine\\Settings', 'Onboarding.ini'),
          'no SetupDone: Settings opens Onboarding.ini instead of the page')

with tempfile.TemporaryDirectory() as tmp:
    base_vars, base = world(tmp, state='SetupDone=1\n')
    s = Fake(tmp, 'Settings.lua', dict(base_vars, Tab='General'), {})
    s.g.Initialize()
    check(not s.sent('!ActivateConfig'), 'SetupDone=1: Settings shows the requested page')
    check(s.g.MarkHidden('General') == 0, 'General: the IsFullScreen mark shows while the plugin is missing')
    check(s.g.Banner() == '', 'General has no banner')

with tempfile.TemporaryDirectory() as tmp:
    base_vars, base = world(tmp, state='SetupDone=0\n')
    s = Fake(tmp, 'Settings.lua', dict(base_vars, Tab='Onboarding'), {})
    s.g.Initialize()
    check(not s.sent('!ActivateConfig'), 'the Onboarding page never redirects to itself')
    check(s.sent('!HideMeter', 'TabPower') and s.sent('!HideMeter', 'MarkPower') and s.sent('!HideMeter', 'TabBar'),
          'onboarding hides the tab column and the marks')

# ---------- Settings.lua: marks and RUN SETUP AGAIN ----------

with tempfile.TemporaryDirectory() as tmp:
    base_vars, base = world(tmp, state='SetupDone=1\n')
    rainmeter_ini = pathlib.Path(base_vars['SETTINGSPATH'] + 'Rainmeter.ini')
    ini = ['[Control-Plaine\\Playnite]', 'Active=1', '[Control-Plaine\\WiFi]', 'Active=1',
           '[Control-Plaine\\Power]', 'Active=0']
    rainmeter_ini.write_text('\n'.join(ini))
    s = Fake(tmp, 'Settings.lua', dict(base_vars, Tab='Playnite'), {})
    s.g.Initialize()
    check(s.g.MarkHidden('Playnite') == 0 and 'SETUP NEEDED' in s.g.MarkTip('Playnite'),
          'a loaded skin with a missing mandatory need gets an amber mark')
    check(s.g.Banner() == 'SETUP NEEDED: PLAYNITE', f'banner text: {s.g.Banner()!r}')
    check(s.g.MarkHidden('WiFi') == 0 and 'SOME FEATURES OFF' in s.g.MarkTip('WiFi'),
          'WiFi without the Speedtest CLI is DEGRADED')
    check(s.g.MarkHidden('Power') == 1, 'a skin that is not loaded shows no mark')
    s.g.RunSetup()
    check('SetupDone=0' in state_text(base) and s.sent('!ActivateConfig', 'Control-Plaine\\Settings', 'Onboarding.ini'),
          'RUN SETUP AGAIN clears SetupDone and opens the onboarding')
    s.g.Fix('Playnite')
    check('OnbOnly=Playnite' in state_text(base) and 'OnbStep=setup' in state_text(base),
          'clicking a mark opens setup for that skin only')

# ---------- Onboarding.lua: the walk ----------

with tempfile.TemporaryDirectory() as tmp:
    base_vars, base = world(tmp, state='SetupDone=0\n')
    rainmeter_ini = pathlib.Path(base_vars['SETTINGSPATH'] + 'Rainmeter.ini')
    rainmeter_ini.write_text('\n'.join(
        f'[Control-Plaine\\{n}]\nActive=1' for n in
        ['Playnite', 'WiFi', 'DayDate', 'Media', 'FanControl']))
    onb_vars = dict(base_vars, Tab='Onboarding', OnbStep='welcome', OnbOnly='', OnbPre='0',
                    OnbSkip='', OnbSel='', OnbPage='0', TabY0='128', TabStep='28')
    for f in ROOT.glob('*/Defaults.inc'):
        for line in f.read_text('ascii').splitlines():
            m = re.match(r'^(\w+)=(.*)$', line)
            if m:
                onb_vars.setdefault(m.group(1), m.group(2))
    settings = Fake(tmp, 'Settings.lua', dict(base_vars, Tab='Onboarding'), {})
    settings.g.Initialize()
    onb = Fake(tmp, 'Onboarding.lua', onb_vars, {'mSettings': settings})
    onb.g.Initialize()
    onb.g.Update()
    check(onb.g.Title() == 'WELCOME' and onb.g.Progress() == 'STEP 1 OF 5',
          f'starts at WELCOME, 5 steps while placement is a stub: {onb.g.Title()} {onb.g.Progress()}')
    check('FOUND' in onb.g.Facts() and 'DISPLAYS' in onb.g.Facts(), 'WELCOME lists what was detected')
    check(onb.sent('!ShowMeterGroup', 'OnbWelcome'), 'WELCOME group is shown')

    onb.g.Next()
    check(onb.g.Title() == 'SKINS' and 'OnbStep=skins' in state_text(base), 'NEXT goes to SKINS and saves the step')
    check(onb.sent('!CommandMeasure', 'mSettings', "SkinOn('Playnite')"),
          'a skin whose mandatory app is missing starts switched off')
    check('Needs' in onb.g.Note('Playnite') and onb.g.Note('DayDate') == 'Ready.', 'SKINS notes per skin')

    onb.g.Next()
    check(onb.g.Title() == 'SETUP', 'NEXT goes to SETUP')
    labels = [onb.g.ItemLabel(i) for i in range(1, 6)]
    check(any('SPEEDTEST' in l for l in labels), f'SETUP lists the chosen skins items: {labels}')
    check(not any('PLAYNITE' in l or 'FAN CONTROL' in l for l in labels),
          'a skin switched off in SKINS has no setup rows')
    wifi_row = next(i for i in range(1, 6) if 'SPEEDTEST' in onb.g.ItemLabel(i))
    onb.g.Select(wifi_row)
    check('winget.exe install --id Ookla.Speedtest.CLI' in onb.g.DetCmd(), 'the full command is shown before any click')
    check(onb.g.ItemStatus(wifi_row) == 'NOT FOUND', 'speed test is NOT FOUND')
    check(not onb.sent('!CommandMeasure', 'mRun'), 'nothing ran yet')
    onb.g.Copy()
    check(onb.clip and onb.clip.startswith('winget.exe install --id Ookla.Speedtest.CLI')
          and not onb.sent('!CommandMeasure', 'mRun'), 'COPY COMMAND sets the clipboard and runs nothing')
    onb.g.Run()
    check(onb.sent('!SetOption', 'mRun', 'Program', 'winget.exe') and onb.sent('!CommandMeasure', 'mRun', 'Run'),
          'RUN IT FOR ME starts exactly the helper command')
    onb.g.RunDone()
    check('NOT FOUND AFTER THE RUN' in onb.g.DetOut() and 'fake error' in onb.g.DetOut(),
          'a failed run shows the output tail and tells the user to run it themselves')
    runs = [b for b in onb.bangs if b[:3] == ('!CommandMeasure', 'mRun', 'Run')]
    check(len(runs) == 1, 'a failed run is not retried')

    onb.g.SkipItem()
    check(onb.g.ItemStatus(wifi_row) == 'SKIPPED' and 'WiFi:speedtest' in state_text(base),
          'SKIP on an optional item keeps the skin and marks the row SKIPPED')

    # The user switches Playnite back on: its mandatory app is missing.
    settings.g.SkinOn('Playnite')
    onb.g.Update()
    row = next(i for i in range(1, 6) if onb.g.ItemLabel(i).startswith('PLAYNITE'))
    onb.g.Select(row)
    onb.g.SkipItem()
    check(onb.g.AskText() == 'TURN PLAYNITE OFF?', 'SKIP on a required item asks to turn the skin off')
    onb.g.Ask(True)
    check(settings.sent('!DeactivateConfig', 'Control-Plaine\\Playnite'), 'YES turns the skin off')

    onb.g.Next()
    check(onb.g.Title() == 'LOOK', 'NEXT goes to LOOK')
    onb.g.Next()
    check(onb.g.Title() == 'DONE' and onb.g.NextLabel() == 'FINISH', 'the stub placement step is skipped')
    summary = onb.g.Summary()
    check('SKINS ON' in summary and 'SAVED IN' in summary and 'WI-FI' in summary, f'summary: {summary!r}')
    onb.g.Back()
    check(onb.g.Title() == 'LOOK', 'BACK works')
    onb.g.Next()
    onb.g.Next()
    check('SetupDone=1' in state_text(base) and onb.sent('!DeactivateConfig'), 'FINISH records SetupDone=1')
    check(not any(b[0] == '!WriteKeyValue' and b[4].endswith('User.inc') for b in onb.bangs),
          'onboarding itself writes nothing to User.inc (Settings.lua does, per choice)')

with tempfile.TemporaryDirectory() as tmp:
    base_vars, base = world(tmp, state='SetupDone=0\n')
    pathlib.Path(base_vars['SETTINGSPATH'] + 'Rainmeter.ini').write_text('')
    onb_vars = dict(base_vars, Tab='Onboarding', OnbStep='welcome', OnbOnly='', OnbPre='0', OnbSkip='',
                    OnbSel='', OnbPage='0', TabY0='128', TabStep='28')
    settings = Fake(tmp, 'Settings.lua', dict(base_vars, Tab='Onboarding'), {})
    onb = Fake(tmp, 'Onboarding.lua', onb_vars, {'mSettings': settings})
    onb.g.Initialize()
    onb.g.Update()
    onb.g.SkipSetup()
    check('SetupDone=1' in state_text(base) and onb.sent('!DeactivateConfig'),
          'SKIP SETUP records SetupDone=1 and closes')
    check(not any(b[0] == '!WriteKeyValue' and b[4].endswith('User.inc') for b in onb.bangs),
          'SKIP SETUP leaves the settings untouched')

with tempfile.TemporaryDirectory() as tmp:
    base_vars, base = world(tmp, state='SetupDone=1\nOnbOnly=WiFi\nOnbStep=setup\n')
    pathlib.Path(base_vars['SETTINGSPATH'] + 'Rainmeter.ini').write_text('[Control-Plaine\\WiFi]\nActive=1\n')
    onb_vars = dict(base_vars, Tab='Onboarding', OnbStep='setup', OnbOnly='WiFi', OnbPre='0', OnbSkip='',
                    OnbSel='', OnbPage='0', TabY0='128', TabStep='28')
    for f in ROOT.glob('*/Defaults.inc'):
        for line in f.read_text('ascii').splitlines():
            m = re.match(r'^(\w+)=(.*)$', line)
            if m:
                onb_vars.setdefault(m.group(1), m.group(2))
    settings = Fake(tmp, 'Settings.lua', dict(base_vars, Tab='Onboarding'), {})
    onb = Fake(tmp, 'Onboarding.lua', onb_vars, {'mSettings': settings})
    onb.g.Initialize()
    onb.g.Update()
    check(onb.g.Progress() == 'SET UP WI-FI' and 'SPEEDTEST' in onb.g.ItemLabel(1),
          'opened from a mark: only that skin, SETUP only')
    check(onb.g.NextLabel() == 'DONE', 'the mark flow ends with DONE')

print('FAILED' if failed else 'ok', failed)
sys.exit(1 if failed else 0)
