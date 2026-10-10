# Spec: app skins (Fan Control, SignalRGB, DeepCool)

Investigation output for the V1 build. Source of truth for behaviour and look: `docs/DESIGN-V1.md` and the V1 canvas. This file says **how** to build each skin in Rainmeter, what changes from the design, and what must be checked on Vishnu's PC.

Shared conventions (User.inc keys, state file, Settings refresh, accent, full-screen hide, ring drawing) belong to `specs/foundation-settings.md`. It did not exist when this was written; where this spec names a key or file that the foundation spec defines differently, the foundation spec wins.

## Verdict

| Skin | Achievable in Rainmeter? | Route | Blocker / risk |
|---|---|---|---|
| Fan Control | Yes | HWiNFO "Gadget" registry values read by `Measure=Registry` (no plugin); profile switch with `FanControl.exe -c <config>` | Fan Control runs elevated, so launching it from Rainmeter may raise a UAC prompt. Fix: run it through a one-time "highest privileges" scheduled task. Fan % may have to be derived from RPM. |
| SignalRGB | Yes; ring and on/off **only with SignalRGB Pro**, auto-detected, plain launcher otherwise | Local REST API on `localhost:16038` (WebParser to read, `curl.exe` to write) | The API is Pro-only. Without Pro there is no way to read or set brightness or turn lights off; the skin falls back to an icon that opens the app. |
| DeepCool | Yes | `Measure=Process` for state; RunCommand to start hidden / `taskkill` to close | No documented "start minimized" flag; whether closing the app blanks the case screen is unconfirmed. |

### What's installed (checked on DRK-TOWER, folder names only)
- **Fan Control**: `C:\Program Files (x86)\FanControl\` (installer build) with `Configurations\` and `Plugins\` folders.
- **HWiNFO64**: `C:\Program Files\HWiNFO64\`. **LibreHardwareMonitor is not installed** (no folder in Program Files or AppData), so HWiNFO is the sensor source.
- **SignalRGB**: `%LOCALAPPDATA%\VortxEngine\app-2.5.74\` (Squirrel install; the folder name changes with each update, so never hard-code it).
- **DeepCool**: an Electron app in `C:\DeepCool\` (has `locales\`, `resources\`), data in `%APPDATA%\DeepCool\`. This is DeepCool's current "DeepCreative" software. The exe name was not visible (file names are hidden without folder access).

## Shared for all three

- Files: `FanControl/FanControl.ini`, `SignalRGB/SignalRGB.ini`, `DeepCool/DeepCool.ini`, Lua in `@Resources/Scripts/<Skin>.lua` where noted.
- Each .ini opens with the header block the design asks for: what it shows, the software it was designed for (name + version tested), and a "To use with other software" list naming every variable to change.
- Every path, process name, port and command comes from `User.inc` variables (defaults in `User.example.inc`). No skin hard-codes a user path (`tools/lint.py` already enforces this).
- Icons: render `docs/icons/fan.svg`, `rgb.svg`, `case-screen.svg` to white PNG at 1x/2x/3x like the other icons; tint at runtime with `ImageTint` (Ink at rest alpha, Accent when "on").
- Hover: `Fade.inc` (`#Reveal#`), `sIconFade` / `sReveal` styles. Nothing moves.
- Commands: `Plugin=RunCommand` with `State=Hide`. Lua sets `Program`/`Parameter` with `!SetOption` then `!CommandMeasure ... "Run"` when the command varies.
- Right-click menu: `ContextTitle=Control-Plaine settings` opening the Settings skin (foundation spec).

---

## Fan Control

Designed for **Fan Control by Rem0o, V277** (https://getfancontrol.com).

### Behaviour (from design)
- Rest: fan icon only, dim. If MAX is on, the filled accent `MAX` bubble also stays visible.
- Hover: icon brightens, average fan speed `46%` (Value), outlined `MAX` bubble.
- Click MAX toggles max fans. On: bubble filled accent, dark text; hover shows `100%`.
- Click icon opens Fan Control.

### Average fan % (sensor source: HWiNFO)
Fan Control has no API or export. Its plugins only import sensors into Fan Control; none export (FanControl.Releases wiki "Plugins"). So Rainmeter reads the fans from HWiNFO, which is installed.

Route: HWiNFO **Gadget reporting** (Configure Sensors > HWiNFO Gadget > "Enable reporting to Gadget", then tick "Report value in Gadget" per sensor). HWiNFO writes each reported sensor to the registry under `HKEY_CURRENT_USER\SOFTWARE\HWiNFO64\VSB` as `LabelN` / `ValueN` / `ValueRawN` (N = 0, 1, 2 ... in the order of reported sensors). Rainmeter reads them with the built-in `Measure=Registry`; no HWiNFO plugin and no Shared Memory (a Pro feature since HWiNFO 7.0) is needed. The Rainmeter docs (docs.rainmeter.net/tips/hwinfo) say this route is agreed with HWiNFO's author for free personal use, needs HWiNFO 7.02+, and that Shared Memory should stay off. HWiNFO writes the same values under `HKEY_LOCAL_MACHINE` too; use that (`FanRegHKey`) if HKCU is empty. Values refresh at HWiNFO's poll rate (2 s default). Gadget indexes renumber when sensors are added to or removed from reporting, so the Settings tab should show each index's `LabelN` next to it.

Two modes, chosen by `FanSource`:

1. `duty` (preferred): if HWiNFO shows fan **duty / PWM %** sensors for the board's fan headers, report those and average them. That matches what Fan Control is driving.
2. `rpm` (fallback): report fan RPM sensors and compute `% = RPM / MaxRPM` per fan, then average. `MaxRPM` per fan is captured once (turn MAX on, read each fan's RPM, write it to User.inc; Settings can offer a "CALIBRATE" link that does this with Lua).

Config:
```
FanSource=rpm            ; duty | rpm
FanIndexes=0,1,2,3       ; HWiNFO Gadget indexes to average (max 8)
FanMaxRPM=1800,1800,2200,2200   ; rpm mode only, same order
```
Implementation: 8 `Measure=Registry` measures (`RegHKey=HKEY_CURRENT_USER`, `RegKey=SOFTWARE\HWiNFO64\VSB`, `RegValue=ValueRaw#Idx#`), disabled when unused; `FanControl.lua` averages the enabled ones, ignores fans at 0 RPM if `FanIgnoreStopped=1` (zero-RPM GPU fans would drag the average down), and returns the rounded %. `Update=1000`, read every 2 s.

If HWiNFO is not running (values missing/stale), hover shows `NO SENSOR` in Detail instead of a number.

### MAX toggle
Fan Control supports `-c` / `--config`: "Start using the specified config, or change the config if the software is already running" (getfancontrol.com/docs; the wiki adds that it messages the running instance). Other documented flags: `-w` force the window open, `-m` minimized, `-r` refresh sensors, `-e` exit the running instance, `-sc` service client. There is no built-in "all fans max"; a config with a 100% Flat curve on every control is the documented way. The config name is resolved relative to the working folder, so set `StartInFolder` to the Fan Control folder.

- Vishnu creates a config `Max.json` in Fan Control: copy the normal config, set every control to a flat 100% curve (or manual 100). Normal config name goes in `FanNormalConfig`.
- On: run `FanControl.exe -c #FanMaxConfig#`. Off: `-c #FanNormalConfig#`.
- **UAC problem**: Fan Control needs admin. If `FanControl.exe` requests elevation, every Rainmeter launch shows a UAC prompt, even when it only forwards `-c` to the running instance. Fix: two scheduled tasks created once, elevated, with "Run with highest privileges" (`ControlPlaine\FanMax`, `ControlPlaine\FanNormal`), each running `FanControl.exe -c <config>` with Start-in = the Fan Control folder. The skin then runs `schtasks.exe /run /tn "ControlPlaine\FanMax"` with no prompt. `tools/install.ps1` (or a `tools/fan-tasks.ps1` run as admin) creates them. `FanUseTasks=1` switches the skin between direct launch and tasks.
- State: `FanMax` (0/1) kept in the shared state file (foundation spec) so it survives refresh. It can drift if Vishnu changes config inside the Fan Control window; acceptable. Optional check (verify): Fan Control remembers the last config in a file in its folder; if it is readable without admin, Lua can re-sync `FanMax` on refresh.
- Safety: none needed; switching back is just the other config.

### Open the app
`FanControl.exe -w` ("Force the UI window to open"). Verify it surfaces the running instance rather than starting a second one. Same UAC issue: if it prompts, use a third task `ControlPlaine\FanOpen`.

### Settings (Fan Control tab)
`FanControlPath` (default `C:\Program Files (x86)\FanControl\FanControl.exe`), `FanNormalConfig` (default `Default.json`, verify name), `FanMaxConfig` (`Max.json`), `FanUseTasks`, `FanSource`, `FanRegHKey` (HKEY_CURRENT_USER), `FanIndexes`, `FanMaxRPM`, `FanIgnoreStopped`.

---

## SignalRGB

Designed for **SignalRGB 2.5.x** (WhirlwindFX), tested against the local REST API used by the `signalrgb` Python client 1.0.2.

### Behaviour (from design)
- Icon monochrome: accent while lights are on, grey when off.
- Rest: icon only.
- Hover: thin ring (stroke 2.5) around the icon showing brightness, `70%` and `BRIGHTNESS` beside it. Scroll changes brightness (default 5% per notch). Scroll to 0 = lights off, text `OFF`.
- Click icon opens SignalRGB.

### Control route
URL commands (`signalrgb://`) only apply effects and open views; **there is no brightness or on/off URL** (docs.signalrgb.com "Application URLs"; a 2023 forum request for one is unanswered).

The local REST API does both. Endpoints, read from the `signalrgb` client source (`constants.py`, `async_client.py`):

| Action | Request |
|---|---|
| Read state | `GET http://localhost:16038/api/v1/lighting` returns `{"data": {"attributes": {"name": ..., "enabled": true, "global_brightness": 70}, ...}}` |
| Set brightness | `PATCH http://localhost:16038/api/v1/lighting/global_brightness` body `{"global_brightness": 70}` |
| Lights on/off | `PATCH http://localhost:16038/api/v1/lighting/enabled` body `{"enabled": false}` |

**The REST API is SignalRGB Pro only** (signalrgb-python README: "This library uses the SignalRGB REST API, which is only available in SignalRGB Pro").

### Implementation
- Read: `Measure=WebParser`, `URL=http://localhost:#SrgbPort#/api/v1/lighting`, `UpdateRate` = 2 s, raw string passed to `SignalRGB.lua`, which pulls `enabled` and `global_brightness` with `string.match` (don't rely on key order in a WebParser RegExp). `OnConnectErrorAction` sets state `offline`.
- Write: `RunCommand` with `Program=curl.exe` (ships with Windows 10 1803+), e.g. `-s -m 2 -X PATCH -H "Content-Type: application/json" -d "{\"global_brightness\":70}" http://localhost:16038/api/v1/lighting/global_brightness`. Lua builds the parameter.
- Scroll: Lua changes the shown value immediately (ring + text redraw), then an ActionTimer debounce (`Wait 250 | Send`) sends one PATCH after the last notch, so a fast scroll sends one request, not twenty. Ignore WebParser results for 1.5 s after a send so the ring doesn't jump back.
- Scroll down to 0: send `enabled=false`, keep the last non-zero brightness in a variable; text `OFF`, ring empty, icon grey. Scroll up from OFF: brightness = one step, send brightness then `enabled=true`.
- Icon tint: accent when `enabled && brightness > 0`, grey otherwise.
- Offline (app closed or API refused): icon grey, hover shows `NOT RUNNING` instead of the ring; scroll does nothing.
- Ring: Shape meter arc like the Volume ring (foundation spec), radius sized to circle the 24 px icon, stroke 2.5, track at ring track alpha. Revealed with `#Reveal#`.

### Open the app
`signalrgb://view/dashboard` (RunCommand or `["signalrgb://view/dashboard"]`). This survives updates, unlike the versioned exe path. `SrgbOpen` lets other users replace it with an exe path.

### No-Pro fallback (auto-detected)
Do not wait on knowing whether Vishnu has Pro. The skin detects it: if the `GET /api/v1/lighting` call answers with a `global_brightness` value, it runs in API mode (ring, scroll, on/off). If the call fails or returns no such field, it runs as a plain launcher: Ink-tinted icon (not accent) that opens the app, hover label `SIGNALRGB`, no ring, no scroll. It keeps polling every 2 s, so it switches to API mode as soon as the API answers. A failure right after app start looks the same as no Pro; that is fine because the skin recovers on the next poll. `SrgbApi=0` forces launcher mode. A black effect via `signalrgb://effect/apply/...` is not a real "off" (custom-painted LEDs stay lit), so it is not offered.

### Settings (SignalRGB tab)
`SrgbApi` (auto/0, default auto), `SrgbPort` (16038), `SrgbStep` (5), `SrgbOpen` (`signalrgb://view/dashboard`).

---

## DeepCool

Designed for **DeepCool DeepCreative** (the Electron app at `C:\DeepCool\`) driving the case screen.

### Behaviour (from design)
- Icon is the toggle: accent when the app is running (screen on), grey when closed. Hover label `CASE SCREEN ON` / `CASE SCREEN OFF`.
- Click: not running, start it hidden in the tray; running, close it silently.

### Implementation
- Running state: `Measure=Process`, `ProcessName=#DeepCoolProcess#` (value 1 running, -1 not). Update every 2 s. (Older Rainmeter builds use the Process plugin; check the version on the PC.)
- Start: RunCommand `Program=#DeepCoolPath#`, `Parameter=#DeepCoolArgs#`, `State=Hide`. There is **no documented minimized/tray flag**. Plan in order:
  1. Use whatever arguments DeepCreative's own startup entry passes (`HKCU\Software\Microsoft\Windows\CurrentVersion\Run` or its Startup shortcut); Electron tray apps usually start hidden with a flag like `--hidden` / `--autostart` there. Put it in `DeepCoolArgs`.
  2. If there is none, a small `@Resources/Scripts/HideWindow.ps1` helper (run hidden) waits up to 10 s for the app's main window and hides it (`ShowWindow SW_HIDE` via `Add-Type` user32), leaving the tray icon. A brief flash of the window may remain; acceptable.
- Close: RunCommand `taskkill.exe /IM "#DeepCoolProcess#" /T /F`. A graceful close (`/F` dropped) would normally just hide an Electron tray app to the tray, so force is needed; no prompt is shown either way.
- Click feedback: tint flips immediately on click (optimistic), then the Process measure confirms on its next update.

### Does closing turn the screen off? (unconfirmed)
No DeepCool statement. Open-source drivers for other DeepCool displays report the screen falls back to black or a DeepCool logo when the host stops sending (Nortank12/deepcool-digital-linux issue #69; daedlock/deepcool-lm "Screen goes black when CLI stops"). A case screen may instead hold the last frame. **Must be tested on the PC.** If it does not blank, the label changes to `DEEPCOOL ON` / `DEEPCOOL OFF` (an honest app toggle), and a true screen-off would need a custom HID sender, which is out of scope for V1. No open-source Windows tool for DeepCool **case** screens exists.

### Settings (DeepCool tab)
`DeepCoolPath` (default `C:\DeepCool\<exe>`, verify), `DeepCoolProcess` (verify), `DeepCoolArgs`, `DeepCoolStartHidden` (1).

---

## Checks on Vishnu's PC

Fan Control
1. Does launching `FanControl.exe` from a normal (non-admin) process show a UAC prompt? Decides `FanUseTasks`.
2. Does `FanControl.exe -c Max.json` switch the running instance on V277 (and does it still work if Fan Control runs as a service)? Is the config name relative to the exe folder or `Configurations\`?
3. Name of the normal config file in `Configurations\`.
4. In HWiNFO sensors: are there fan duty/PWM % sensors for the motherboard fan headers, or only RPM? Which fans does Fan Control drive (to pick indexes)? Is HWiNFO set to start with Windows in sensors-only mode?
5. Do HWiNFO and Fan Control coexist without sensor conflicts (both poll the Super I/O)?

SignalRGB
6. Does Vishnu have SignalRGB Pro? (The skin auto-detects it; this only confirms which mode he'll see.)
7. With SignalRGB running, does `curl http://localhost:16038/api/v1/lighting` answer? Does the brightness PATCH change lights; does `enabled=false` turn every LED off?
8. Does `signalrgb://view/dashboard` bring the window up from the tray?

DeepCool
9. Exe name in `C:\DeepCool\` and its process name in Task Manager (likely one Electron main process plus helpers of the same name).
10. Arguments in its startup entry (hidden-start flag).
11. Is it running elevated? (`taskkill` from Rainmeter fails with "Access denied" if so.)
12. **Which case is it**, and when the app is closed does the case screen go black, show a logo, or freeze on the last frame?
