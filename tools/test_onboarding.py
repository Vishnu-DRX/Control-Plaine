"""Offline tests for the needs detection and the install helper list.
Run: python tools/test_onboarding.py   (needs: pip install lupa)

Runs the real @Resources/Scripts/Needs.lua over the real
@Resources/Setup/NeedsList.lua with a FAKE environment (a set of existing
files, a dict of variables and a dict of Registry measure values), so the
detection logic is checked without Rainmeter or Windows. Also checks the
Setup/Helpers.txt allow-list and that the Lua and lint readers agree on it.

What this cannot check (needs the PC): that the real file paths exist, that
the Registry measure returns a value, and running a helper.
"""
import pathlib
import sys

from lupa import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
failed = 0


def check(cond, message):
    global failed
    if not cond:
        print('FAIL', message)
        failed += 1


lua = LuaRuntime(unpack_returned_tuples=True)
loader = lua.eval('function(src) return load(src)() end')
Needs = loader((ROOT / '@Resources' / 'Scripts' / 'Needs.lua').read_text('ascii'))
LIST = loader((ROOT / '@Resources' / 'Setup' / 'NeedsList.lua').read_text('ascii'))

ENV = {
    'APPDATA': 'C:\\AppData\\Roaming',
    'LOCALAPPDATA': 'C:\\AppData\\Local',
    'ProgramFiles': 'C:\\Program Files',
    'ProgramData': 'C:\\ProgramData',
    'SystemRoot': 'C:\\Windows',
    'PATH': 'C:\\Windows\\System32;"C:\\Tools\\bin";C:\\Windows',
}
AT = 'C:\\Skins\\Control-Plaine\\@Resources\\'
DEFAULTS = {}
for p in [ROOT / '@Resources' / 'Defaults.inc', *ROOT.glob('*/Defaults.inc')]:
    for line in p.read_text('ascii').splitlines():
        if '=' in line and not line.startswith((';', '[', '@')):
            k, v = line.split('=', 1)
            DEFAULTS[k] = v


def env(files=(), variables=None, registry=None):
    """A fake Rainmeter environment. files: paths that exist (case-insensitive)."""
    have = {f.lower() for f in files}
    values = dict(DEFAULTS)
    values.update(variables or {})
    reg = registry or {}
    table = lua.table_from({
        'getenv': lambda name: ENV.get(name),
        'exists': lambda path: path.lower() in have,
        'var': lambda key: values.get(key, ''),
        'replace': lambda text: text.replace('#@#', AT),
        'reg': lambda measure: reg.get(measure, ''),
    })
    return table


def evaluate(skin, **kw):
    return Needs.evaluate(skin, LIST[skin], env(**kw))


def feature(res, name):
    return res.features[name]


# ---------- the list itself ----------

skins = ['DayDate', 'Power', 'Uptime', 'Volume', 'Media', 'RecycleBin', 'Playnite', 'WiFi',
         'FanControl', 'SignalRGB', 'DeepCool', 'Controllers', 'SettingsButton', 'General']
for s in skins:
    check(LIST[s] is not None, f'NeedsList has an entry for {s}')

# ---------- nothing installed ----------

check(evaluate('DayDate').state == 'OK', 'DayDate: the calendar default is built in')
check(evaluate('SettingsButton').state == 'OK', 'SettingsButton needs nothing')
r = evaluate('Playnite')
check(r.state == 'BLOCKED' and len(r.blockers) == 1, 'Playnite is BLOCKED without its exe')
r = evaluate('WiFi')
check(r.state == 'DEGRADED' and feature(r, 'SpeedTest') == 0, 'WiFi is DEGRADED without the Speedtest CLI')
check(feature(r, 'NetName') == 1, 'WiFi: location services are assumed present (cannot be checked)')
r = evaluate('Volume')
check(r.state == 'OK', 'Volume: the audio plugin ships with Rainmeter, a URI mixer target is fine')

# ---------- paths ----------

PLAYNITE = 'C:\\AppData\\Local\\Playnite\\Playnite.DesktopApp.exe'
r = evaluate('Playnite', files=[PLAYNITE], variables={'PlaynitePath': '%LOCALAPPDATA%\\Playnite\\Playnite.DesktopApp.exe'})
check(r.state == 'OK', 'Playnite: %LOCALAPPDATA% path that exists is FOUND')
r = evaluate('Playnite', files=['D:\\Games\\P.exe'], variables={'PlaynitePath': 'D:\\Games\\P.exe'})
check(r.state == 'OK', 'Playnite: a typed path that exists is FOUND')

# speedtest: configured path, WinGet Links, WinGet Packages, PATH, Program Files
LINKS = 'C:\\AppData\\Local\\Microsoft\\WinGet\\Links\\speedtest.exe'
PKG = ('C:\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Ookla.Speedtest.CLI_Microsoft.Winget.Source_'
       '8wekyb3d8bbwe\\speedtest.exe')
for label, files, variables in [
    ('the configured path', ['E:\\st\\speedtest.exe'], {'WiFiSpeedtestPath': 'E:\\st\\speedtest.exe'}),
    ('the WinGet Links entry', [LINKS], {}),
    ('the WinGet Packages folder', [PKG], {}),
    ('a PATH folder', ['C:\\Tools\\bin\\speedtest.exe'], {'WiFiSpeedtestPath': ''}),
    ('Program Files', ['C:\\Program Files\\Ookla\\Speedtest CLI\\speedtest.exe'], {'WiFiSpeedtestPath': ''}),
]:
    r = evaluate('WiFi', files=files, variables=variables)
    check(r.state == 'OK' and feature(r, 'SpeedTest') == 1, f'WiFi speed test found through {label}')

# ---------- Fan Control: mandatory app, optional tasks / sensors / max profile ----------

FAN = 'C:\\Program Files (x86)\\FanControl\\FanControl.exe'
TASKS = 'C:\\Windows\\System32\\Tasks\\ControlPlaine\\'
r = evaluate('FanControl')
check(r.state == 'BLOCKED', 'FanControl is BLOCKED without FanControl.exe')
r = evaluate('FanControl', files=[FAN])
check(r.state == 'DEGRADED', 'FanControl with the app only is DEGRADED')
check(feature(r, 'Tasks') == 0 and feature(r, 'Sensors') == 0 and feature(r, 'Max') == 0,
      'FanControl: tasks, sensors and the MAX profile are off until found')
r = evaluate('FanControl', files=[FAN, TASKS + 'FanOpen', TASKS + 'FanSensors',
                                  'C:\\Program Files (x86)\\FanControl\\Configurations\\Max.json'])
check(r.state == 'OK', 'FanControl with everything is OK')
r = evaluate('FanControl', files=[FAN, 'C:\\Program Files (x86)\\FanControl\\Configurations\\Max.json'],
             variables={'FanControlUseTasks': '0'})
check(r.state == 'OK', 'FanControl: tasks and sensors only count while FanControlUseTasks=1')
r = evaluate('FanControl', files=[FAN, 'C:\\Program Files (x86)\\FanControl\\Configurations\\Other.json'],
             variables={'FanControlUseTasks': '0', 'FanControlMax': 'Other.json'})
check(r.state == 'OK', 'FanControl: the MAX profile name follows FanControlMax')

# ---------- SignalRGB: launcher by registry (auto) or path ----------

r = evaluate('SignalRGB')
check(r.state == 'BLOCKED', 'SignalRGB is BLOCKED when auto finds no registration')
r = evaluate('SignalRGB', registry={'mRegSignalRGB': '"C:\\x\\SignalRgbLauncher.exe" "%1"'})
check(r.state == 'OK', 'SignalRGB: auto is FOUND through the signalrgb protocol key')
r = evaluate('SignalRGB', registry={'mRegSignalRGB': '"C:\\x\\SignalRgbLauncher.exe"'},
             variables={'SignalRGBEffect': ''})
check(r.state == 'DEGRADED' and feature(r, 'Brightness') == 0, 'SignalRGB: no effect hides the brightness control')
r = evaluate('SignalRGB', files=['E:\\srgb.exe'], variables={'SignalRGBPath': 'E:\\srgb.exe'})
check(r.state == 'OK', 'SignalRGB: a typed launcher path is FOUND')
r = evaluate('SignalRGB', variables={'SignalRGBPath': 'signalrgb://launch'})
check(r.state == 'OK', 'SignalRGB: a link counts')

# ---------- Media: the plugin that MediaPlugin names ----------

DLL = 'C:\\AppData\\Roaming\\Rainmeter\\Plugins\\MediaPlayer.dll'
check(evaluate('Media').state == 'BLOCKED', 'Media is BLOCKED without MediaPlayer.dll')
check(evaluate('Media', files=[DLL]).state == 'OK', 'Media with MediaPlayer.dll is OK')
r = evaluate('Media', files=[DLL], variables={'MediaPlugin': 'WebNowPlaying'})
check(r.state == 'BLOCKED', 'Media: WebNowPlaying needs its own plugin, not MediaPlayer.dll')
r = evaluate('Media', files=['C:\\AppData\\Roaming\\Rainmeter\\Plugins\\WebNowPlaying.dll'],
             variables={'MediaPlugin': 'WebNowPlaying'})
check(r.state == 'OK', 'Media with WebNowPlaying.dll and MediaPlugin=WebNowPlaying is OK')

# ---------- click targets ----------

SYS = 'C:\\Windows\\System32\\'
check(evaluate('Uptime').state == 'DEGRADED', 'Uptime: taskmgr.exe missing hides the click')
r = evaluate('Uptime', files=[SYS + 'taskmgr.exe'])
check(r.state == 'OK', 'Uptime: taskmgr.exe is found on PATH')
check(evaluate('Power').state == 'DEGRADED', 'Power: no schtasks.exe hides SCHEDULE')
check(evaluate('Power', files=[SYS + 'schtasks.exe']).state == 'OK', 'Power with schtasks.exe is OK')
r = evaluate('Uptime', files=[SYS + 'taskmgr.exe'], variables={'UptimeClick': 'nosuchtool.exe'})
check(r.state == 'DEGRADED' and feature(r, 'Click') == 0, 'Uptime: an unknown click target hides the click')
r = evaluate('Uptime', variables={'UptimeClick': 'ms-settings:about'})
check(r.state == 'OK', 'Uptime: a link as click target is fine')
check(evaluate('Controllers').state == 'BLOCKED', 'Controllers: BLOCKED without its PowerShell helper')
r = evaluate('Controllers', files=[AT + 'Scripts\\Controllers.ps1'])
check(r.state == 'DEGRADED' and feature(r, 'Wheel') == 0 and feature(r, 'Dsx') == 1,
      'Controllers: Pit House path missing hides the wheel click; the DSX link is accepted')
check(evaluate('Controllers', files=[AT + 'Scripts\\Controllers.ps1',
                                    'C:\\Program Files (x86)\\MOZA Pit House\\bin\\MOZA Pit House.exe']).state == 'OK',
      'Controllers: helper script and Pit House found is OK')

# ---------- General / IsFullScreen ----------

r = evaluate('General')
check(r.state == 'DEGRADED' and feature(r, 'FullScreen') == 0, 'General: IsFullScreen.dll missing is DEGRADED')
r = evaluate('General', files=['C:\\AppData\\Roaming\\Rainmeter\\Plugins\\IsFullScreen.dll'])
check(r.state == 'OK', 'General: IsFullScreen.dll found is OK')

# ---------- apply() ----------

sets = {}
r = evaluate('WiFi')
Needs.apply(r, lambda name, value: sets.__setitem__(name, value))
check(sets.get('WiFiHasSpeedTest') == '0' and sets.get('WiFiNeedState') == 'DEGRADED'
      and sets.get('WiFiNeedBlocked') == '0', f'apply() sets the Has and state variables: {sets}')
sets.clear()
Needs.apply(evaluate('Playnite'), lambda name, value: sets.__setitem__(name, value))
check(sets.get('PlayniteNeedState') == 'BLOCKED' and sets.get('PlayniteNeedBlocked') == '1',
      'apply() marks a BLOCKED skin')

# ---------- detection reads nothing but the fake environment ----------

touched = []
spy = lua.table_from({
    'getenv': lambda name: ENV.get(name),
    'exists': lambda path: touched.append(path) or False,
    'var': lambda key: DEFAULTS.get(key, ''),
    'replace': lambda text: text.replace('#@#', AT),
    'reg': lambda measure: '',
})
for s in skins:
    Needs.evaluate(s, LIST[s], spy)
check(len(touched) > 10 and all(p == p.strip() for p in touched), 'detection only calls exists() with paths')
check(not any('%' in p for p in touched), 'every path is expanded before it is read')

# ---------- Helpers.txt ----------

text = (ROOT / '@Resources' / 'Setup' / 'Helpers.txt').read_text('ascii')
H = Needs.parseHelpers(text)
ids = [H.list[i].id for i in range(1, len(H.list) + 1)]
check(set(ids) == {'speedtest', 'mediaplayer', 'isfullscreen', 'fan-tasks'}, f'helper ids: {ids}')
speed = H.byId['speedtest']
program, args, shown = Needs.helperCommand(speed, 'C:\\Skins\\Control-Plaine')
check(program == 'winget.exe' and 'Ookla.Speedtest.CLI' in args and shown == program + ' ' + args,
      'speedtest command is winget with the exact package id')
program, args, shown = Needs.helperCommand(H.byId['mediaplayer'], 'C:\\Skins\\Control-Plaine')
check('C:\\Skins\\Control-Plaine\\tools\\helpers\\MediaPlayer.ps1' in args and '{ROOT}' not in args,
      'ROOT is substituted once, with a trailing backslash')
check(H.byId['fan-tasks'].elevated == '1' and H.byId['speedtest'].elevated == '0', 'elevation flags')
check(Needs.verifyHelper(speed, env(files=[LINKS])) and not Needs.verifyHelper(speed, env()),
      'verifyHelper follows the verify entries')
check(Needs.verifyHelper(speed, env(files=['C:\\Tools\\bin\\speedtest.exe'])), 'verify path: searches PATH')
check(Needs.tail('a\n\nb\nc\nd\r\ne', 3) == 'c\nd\ne', 'tail keeps the last non-empty lines')
for hid in ids:
    h = H.byId[hid]
    check(h.program and h.label and h.reason and h.source, f'{hid}: program, label, reason and source are set')
    check(len(h.verify) >= 1, f'{hid}: has a verify entry')
# every helper named by a need exists, and every helper is named by a need
used = set()
for s in skins:
    for i in range(1, len(LIST[s]) + 1):
        h = LIST[s][i].helper
        if h:
            used.add(h)
check(used == set(ids), f'needs and helpers match: {used} vs {set(ids)}')

# install.ps1 reads the same file and only runs installer=1 entries
install = (ROOT / 'tools' / 'install.ps1').read_text('ascii')
check('Setup\\Helpers.txt' in install and "installer -ne '1'" in install,
      'install.ps1 reads Helpers.txt and only runs installer=1 entries')

# ---------- review round 5 ----------

# A network path is never probed (a dead server would freeze Rainmeter).
probed = []
unc = lua.table_from({
    'getenv': lambda name: ENV.get(name),
    'exists': lambda path: probed.append(path) or False,
    'var': lambda key: {'PlaynitePath': '\\\\nas\\share\\Playnite.exe'}.get(key, DEFAULTS.get(key, '')),
    'replace': lambda text: text.replace('#@#', AT),
    'reg': lambda measure: '',
})
check(Needs.evaluate('Playnite', LIST['Playnite'], unc).state == 'OK' and not any(p.startswith('\\\\') for p in probed),
      'a UNC program path counts as present and is not opened')

# Fan Control: the readable copy in ProgramData stands in for unreadable task files.
copy = 'C:\\ProgramData\\ControlPlaine\\FanControl\\FanControlSensors.ps1'
r = evaluate('FanControl', files=['C:\\Program Files (x86)\\FanControl\\FanControl.exe', copy])
check(feature(r, 'Tasks') == 1 and feature(r, 'Sensors') == 1, 'FanControl tasks seen through the ProgramData copy')

# Helpers.txt keys with an underscore are parsed.
check(H.byId['fan-tasks'].optional_for == 'FanControl' and H.byId['mediaplayer'].required_for == 'Media',
      'required_for and optional_for are parsed')

# The elevated command quotes the folder for a path with spaces and an apostrophe.
_, fargs, _ = Needs.helperCommand(H.byId['fan-tasks'], "C:\\Rain meter\\O'Neil Jr\\Skins\\Control-Plaine")
check("-ArgumentList \\\"" in fargs and "`\\\"C:\\Rain meter\\O'Neil Jr\\Skins\\Control-Plaine\\tools\\fan-tasks.ps1`\\\"" in fargs
      and "'-" not in fargs, 'fan-tasks path is double-quoted, no single-quoted string')

print('FAILED' if failed else 'ok', failed)
sys.exit(1 if failed else 0)
