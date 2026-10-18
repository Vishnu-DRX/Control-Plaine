"""Offline checks for Scripts\\Settings.lua. Run: python tools/test_settings.py

Needs lupa (pip install lupa). Settings.lua runs against a fake SKIN and a
temporary User.inc:

1. Values typed into a path box: quotes and line breaks are refused, one
   trailing backslash is dropped, # is removed.
2. Port keys accept only whole numbers 1..65535; AccentColor channels 0..255.
3. Reset and CLEAN write through a temp file, keep User.inc.bak, and a UTF-16
   User.inc with non-Latin-1 text survives CLEAN.
4. Reset drops edits still waiting for the scroll timer.

Rainmeter is not involved; see docs/pc-gates.md for what needs the PC.
"""
import pathlib
import sys
import tempfile

from lupa import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parent.parent
failures = []


def check(cond, msg):
    if not cond:
        failures.append(msg)


def load(tmp):
    lua = LuaRuntime(unpack_returned_tuples=True)
    bangs = []
    res = tmp / '@Resources'
    res.mkdir(exist_ok=True)
    variables = {'ROOTCONFIG': 'Control-Plaine', '@': str(res) + '/',
                 'ROOTCONFIGPATH': str(tmp) + '/', 'SETTINGSPATH': str(tmp) + '/'}

    class Skin:
        def GetVariable(self, name, default=None):
            return variables.get(name, default)

        def ReplaceVariables(self, text):
            return text.strip('#') and variables.get(text.strip('#'), '0')

        def ParseFormula(self, text):
            return None

        def GetMeter(self, name):
            class Meter:
                def GetW(self): return 100
                def GetH(self): return 20
                def GetX(self): return 0
                def GetY(self): return 0
            return Meter()

        def Bang(self, *args):
            bangs.append(args)
            if args[0] == '!SetVariable':
                variables[args[1]] = args[2]

    lua.globals().SKIN = Skin()
    src = (ROOT / '@Resources' / 'Scripts' / 'Settings.lua').read_text('utf-8')
    lua.execute(src)
    lua.globals().Initialize()
    return lua, bangs, variables, res


def written(bangs):
    return [(b[2], b[3]) for b in bangs if b[0] == '!WriteKeyValue']


def edit(lua, bangs, key, text):
    bangs.clear()
    lua.globals().EditPath(key, 'none', 'm')
    lua.globals().InputDone(text)
    return written(bangs)


with tempfile.TemporaryDirectory() as d:
    tmp = pathlib.Path(d)
    lua, bangs, variables, res = load(tmp)

    check(edit(lua, bangs, 'DayDateClick', 'calc.exe') == [('DayDateClick', 'calc.exe')], 'plain value is written')
    check(edit(lua, bangs, 'DayDateClick', 'C:\\x\\a.exe" -Bar "x') == [], 'quote is refused')
    check(edit(lua, bangs, 'DayDateClick', '"C:\\Program Files\\x.exe"') == [('DayDateClick', 'C:\\Program Files\\x.exe')],
          'one surrounding pair of quotes is dropped')
    check(edit(lua, bangs, 'DayDateClick', 'a\r\n[!Refresh]') == [], 'line break is refused')
    check(edit(lua, bangs, 'DayDateClick', 'C:\\Apps\\Notes\\') == [('DayDateClick', 'C:\\Apps\\Notes')],
          'trailing backslash is dropped')
    check(edit(lua, bangs, 'DayDateClick', 'a#b') == [('DayDateClick', 'ab')], '# is removed')

    check(edit(lua, bangs, 'SignalRGBPort', '16038') == [('SignalRGBPort', '16038')], 'port accepted')
    for bad in ('1@evil.example', '16038 -o x', '0', '70000', 'abc', ''):
        check(edit(lua, bangs, 'SignalRGBPort', bad) == [], f'port {bad!r} refused')
    check(edit(lua, bangs, 'ControllersDsxPort', '1 -Poll 0') == [], 'DSX port with extra arguments refused')
    check(edit(lua, bangs, 'ControllersDsxPort', '6969') == [('ControllersDsxPort', '6969')], 'DSX port accepted')

    check(edit(lua, bangs, 'AccentColor', '10,20,30') == [('AccentColor', '10,20,30')], 'rgb accepted')
    check(edit(lua, bangs, 'AccentColor', '#00FF7f') == [('AccentColor', '0,255,127')], 'hex accepted')
    check(edit(lua, bangs, 'AccentColor', '999,0,0') == [], 'channel above 255 refused')
    check(edit(lua, bangs, 'AccentColor', '0000000001,1,1') == [], 'long channel refused')

    # Reset: backup kept, pending scroll edits dropped.
    user = res / 'User.inc'
    user.write_bytes(b'[Variables]\r\nScale=1.5\r\n')
    lua.globals().Step('Scale', 0.1, 0.5, 3, 'none')
    lua.globals().Reset()
    lua.globals().Reset()
    check(user.read_bytes() == b'[Variables]\r\n', 'Reset empties User.inc')
    check((res / 'User.inc.bak').read_bytes() == b'[Variables]\r\nScale=1.5\r\n', 'Reset keeps a backup')
    check(not (res / 'User.inc.tmp').exists(), 'no temp file left')
    bangs.clear()
    lua.globals().Commit()
    check(written(bangs) == [], 'Reset cleared the pending scroll edit')

    # CLEAN on a UTF-16 file with Cyrillic text.
    # Settings.lua joins with a backslash; on Linux that is part of the file name.
    (tmp / 'Playnite\\Defaults.inc').write_text('[Variables]\nPlaynitePath=x\n')
    (res / 'Defaults.inc').write_text('[Variables]\nScale=1\n')
    (res / 'Theme.inc').write_text('[Variables]\n')
    text = '[Variables]\r\nPlaynitePath=C:\\\u0418\u0433\u0440\u044b\\P.exe\r\nOldKey=1\r\nEmoji=\U0001F600\r\n'
    user.write_bytes(b'\xff\xfe' + text.encode('utf-16-le'))
    lua, bangs, variables, res = load(tmp)
    lua.globals().CleanUnknown()
    raw = user.read_bytes()
    check(raw[:2] == b'\xff\xfe', 'CLEAN keeps the UTF-16 byte order mark')
    out = raw[2:].decode('utf-16-le')
    check('PlaynitePath=C:\\\u0418\u0433\u0440\u044b\\P.exe' in out, 'Cyrillic path survives CLEAN')
    check('OldKey' not in out, 'unknown key removed')
    check('Emoji' not in out or '\U0001F600' in out, 'astral character survives')

if failures:
    print('\n'.join('FAIL: ' + f for f in failures))
    sys.exit(1)
print('test_settings: ok')
