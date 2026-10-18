# Spec: Wi-Fi skin

Source of truth: `docs/DESIGN-V1.md` section "Wi-Fi" and the V1 canvas. Conventions: `specs/foundation-settings.md` (template, tokens, styles, settings keys). This file says how the Wi-Fi skin is built on top of that. Status: built (branch claude/project-thread-2b42b3). Sections below describe the build; PC checks in section 9.

## 1. Verdict

Everything in the design can be done with bundled Rainmeter measures plus one Lua script. No extra plugin.

| Feature | Route | Confidence |
|---|---|---|
| Network name | `Measure=WiFiStatus`, `WiFiInfoType=SSID` | High, but see Location privacy (section 8) |
| Signal arcs | `WiFiStatus`, `WiFiInfoType=Quality` (0-100) | High |
| No internet | `Measure=SysInfo`, `SysInfoType=INTERNET_CONNECTIVITY` (1 / -1, Windows NCSI, same as the taskbar) | High |
| Ethernet | `SysInfo` `ADAPTER_TYPE` (6 Ethernet, 71 Wireless) + `ADAPTER_STATE`, `SysInfoData=Best` (prefers wired) | High |
| Not connected / Wi-Fi off | `ADAPTER_STATE` not 1 and nothing wired | High |
| Airplane mode | `Measure=Registry` on `HKLM\SYSTEM\CurrentControlSet\Control\RadioManagement\SystemRadioState` | Medium, verify on PC |
| Speed test | `RunCommand` runs Ookla `speedtest.exe` with output redirected to a file; Lua polls the file for live speed and the result | Medium, verify live progress on PC |
| Click opens settings | `["ms-settings:network-wifi"]` | High |

Nothing is blocked. Two risks have fallbacks: live speed during the test (falls back to `TESTING` with no number) and a blank SSID on Windows 11 24H2 with Location off (falls back to `WI-FI`).

## 2. Files (all SKIN THREAD)

```
WiFi\WiFi.ini
WiFi\Defaults.inc
Settings\WiFi.ini                       fills the foundation stub
@Resources\Scripts\WiFi.lua
docs\icons\wifi-1.svg, wifi-2.svg       new: 1 and 2 arcs lit, others at 22% opacity
@Resources\Icons\wifi-1.png, wifi-2.png rendered by tools/render-icons.py
```

Icons used, all `@Resources\Icons\<name>.png` (foundation renders the existing SVGs; this thread only adds the two new arc levels with the same renderer):

| State | Icon |
|---|---|
| Wi-Fi, 3 / 2 / 1 arcs | `wifi.png` / `wifi-2.png` / `wifi-1.png` |
| Wi-Fi, no internet | `wifi-no-internet-badge.png` (orange badge baked in, so no tint) |
| Not connected, or wired with no internet | `globe-disconnected.png` (badge baked in) |
| Ethernet | `ethernet.png` |
| Airplane mode | `airplane.png` |

## 3. Skin template

`WiFi.ini` is the section 2 template from the foundation spec, copied exactly with `<Skin>` = `WiFi`, `Update=1000`. Header comment:

```
; Control-Plaine | WiFi
; What it shows: Wi-Fi icon (lit arcs = signal) and network name; taskbar-style states for
;   no internet, not connected, Ethernet and airplane mode. Hover for a manual speed test.
; Designed for: Windows 10/11 networking, Ookla Speedtest CLI (speedtest.exe) for the test.
; Adjust: WiFiClick, WiFiSpeedtestPath, WiFiNameRest (Settings > WI-FI).
```

Skin-local variables (not settings, between `@include5` and `@include6`):

```ini
; which wireless interface WiFiStatus reads (0 = first)
WiFiInterface=0
NameW=170
; ms the speed test result stays up
ResultHold=15000
; 1 while a test runs or its result is showing
Testing=0
NameAlpha=(#WiFiNameRest#*2.55)
```

No self-hiding: the skin is always visible (only Core's full-screen hide applies).

## 4. Settings

`WiFi\Defaults.inc` (keys as agreed in foundation section 7.6):

```ini
[Variables]
; settings = Windows Wi-Fi settings; anything else is run as given (a URI or a program path)
WiFiClick=settings
; winget puts a speedtest.exe link here; Lua expands %VARS% itself before io.open
WiFiSpeedtestPath=%LOCALAPPDATA%\Microsoft\WinGet\Links\speedtest.exe
; network name brightness at rest, percent (30-90)
WiFiNameRest=50
```

`Settings\WiFi.ini` rows (foundation Controls.inc styles, Targets `WiFi`):

| Row | Control | Call |
|---|---|---|
| CLICK OPENS / What clicking the icon or name opens | Choice: `WI-FI SETTINGS` (`settings`) / `CUSTOM` (path box, InputText) | `Set('WiFiClick','settings','WiFi')`, `EditPath('WiFiClick','WiFi')` |
| SPEEDTEST / Path to Ookla speedtest.exe | Path box | `EditPath('WiFiSpeedtestPath','WiFi')` |
| NAME AT REST / How bright the network name is when you are not hovering | Value box 30-90, step 5, `%` | `Step('WiFiNameRest',5,30,90,'WiFi')` |

Install: speedtest.exe is **not installed** on the test PC (probe 2026-10-10). `tools/install.ps1` (integration owns it) should run `winget install --id Ookla.Speedtest.CLI -e --accept-source-agreements --accept-package-agreements` when `speedtest.exe` isn't found, which puts a link at the default path above. If winget is missing it skips with a message; the skin then shows `INSTALL SPEEDTEST` (section 7). `--accept-license --accept-gdpr` covers the CLI's own first-run prompt.

## 5. Layout

```
[icon]  NETWORK NAME              rest: icon + name
        SPEED TEST                hover only, accent underline
```

- `Icon`: image, `MeterStyle=sIconFade`, `X=(0-#IconPad#)*#Scale#`, `Y=(0-#IconPad#)*#Scale#`, `ImageTint=#Ink#`. Alpha AlphaDetail to AlphaHover by Reveal (the style does this).
- `Name`: string, `MeterStyle=sValue`, `FontSize=(#SizeValueS#*#Scale#)`, LeftCenter at `X=((#IconSize#+10)*#Scale#)`, `Y=(#IconSize#/2*#Scale#)`. FontColor alpha overridden to `(#NameAlpha#+(#AlphaHover#-#NameAlpha#)*#Reveal#)` so it is 50% at rest, full on hover. `ClipString=1`, `W=(#NameW#*#Scale#)` so long SSIDs end in an ellipsis. StringCase=Upper comes from the style.
- `Link`: string, `MeterStyle=sLink`, `Text=Speed test`, under the name (`Y=(4*#Scale#)R`, same X). `LinkLine`: `MeterStyle=sLinkLine` under it.
- State text in `Name`: `NO INTERNET` and `NOT CONNECTED` use `MeterStyle=sValue | sWarn`; `ETHERNET` and `AIRPLANE MODE` stay ink.
- While a test runs or the result is showing (`Testing=1`), `Link` shows the test text and stays visible at rest: alpha `(#AlphaHover#*Max(#Reveal#,#Testing#))`, underline hidden. Live speed uses `sAccent`; the result is ink; failure is `sWarn`.
- Hit areas: `Icon` and `Name` each carry the click action; a `sHit` backing behind icon + name keeps the gap between them clickable.

## 6. State logic

Measures (`UpdateDivider=2`, so state refreshes every 2 s):

```ini
[mSSID]
Measure=WiFiStatus
WiFiInfoType=SSID
WiFiIntfID=#WiFiInterface#
UpdateDivider=2

[mQuality]
Measure=WiFiStatus
WiFiInfoType=Quality
WiFiIntfID=#WiFiInterface#
UpdateDivider=2

[mType]
Measure=SysInfo
SysInfoType=ADAPTER_TYPE
SysInfoData=Best
DynamicVariables=1
UpdateDivider=2

[mState]
Measure=SysInfo
SysInfoType=ADAPTER_STATE
SysInfoData=Best
DynamicVariables=1
UpdateDivider=2

[mInternet]
Measure=SysInfo
SysInfoType=INTERNET_CONNECTIVITY
UpdateDivider=2

[mAirplane]
Measure=Registry
RegHKey=HKEY_LOCAL_MACHINE
RegKey=SYSTEM\CurrentControlSet\Control\RadioManagement\SystemRadioState
UpdateDivider=2
; empty RegValue reads the (Default) value: 1 = airplane mode on

[mWiFi]
Measure=Script
ScriptFile=#@#Scripts\WiFi.lua
UpdateDivider=2
```

`WiFi.lua` `Update()` picks one state, same priority as the taskbar:

1. Best adapter is Ethernet (`mType`=6) and connected (`mState`=1):
   - internet ok: `ethernet.png`, `ETHERNET`.
   - no internet: `globe-disconnected.png`, `NO INTERNET` (warn). The design doesn't cover this; the taskbar shows the globe, so we copy it.
2. Best adapter is Wireless (`mType`=71) and connected:
   - no internet: `wifi-no-internet-badge.png`, `NO INTERNET` (warn).
   - internet ok: arcs from quality, 3 if >= 67, 2 if >= 34, else 1. Name = SSID.
   - SSID ending in `connecting...` / `authorizing...` (WiFiStatus adds these while joining): show it as is, keep the last icon.
3. Nothing connected and airplane mode on: `airplane.png`, `AIRPLANE MODE`.
4. Otherwise: `globe-disconnected.png`, `NOT CONNECTED` (warn).

Airplane mode is checked after a live connection on purpose: with airplane on and Wi-Fi turned back on, Windows shows the Wi-Fi icon, and so does the skin.

Lua only sends `!SetOption` and `!Redraw` when the state or arc count changes.

SSID blank while connected over Wi-Fi (Location off): name shows `WI-FI`, arcs from quality, or 3 arcs if quality is also 0. Optional fallback if a user will not turn Location on: a RunCommand every 30 s running `powershell -NoProfile -Command "(Get-NetConnectionProfile -InterfaceAlias '<alias>').Name"`; the profile name is usually the SSID and doesn't need Location. Not built unless needed.

## 7. Speed test

Ookla CLI (`speedtest.exe` from speedtest.net/apps/cli, not the Python `speedtest-cli`).

```ini
[mSpeedRun]
Measure=Plugin
Plugin=RunCommand
; cmd redirect so the file fills while the test runs (RunCommand only hands over stdout at the end)
Parameter=""#WiFiSpeedtestPath#" --format=json --progress=yes --accept-license --accept-gdpr > "%TEMP%\ControlPlaine-speedtest.json" 2>&1"
State=Hide
Timeout=120000
FinishAction=[!CommandMeasure mWiFi "Finished()"]
DynamicVariables=1

[mSpeedPoll]
Measure=Plugin
Plugin=ActionTimer
ActionList1=Repeat Poll,250,480
Poll=[!CommandMeasure mWiFi "Poll()"]
```

Flow, in `WiFi.lua`:

- Click `SPEED TEST`: `Start()` checks the exe exists (`io.open`), deletes the old output file, sets `Testing=1`, shows `TESTING`, runs `[!CommandMeasure mSpeedRun "Run"]` and `[!CommandMeasure mSpeedPoll "Execute 1"]`. Clicks while testing do nothing. Never automatic.
- `Poll()`: open `os.getenv('TEMP') .. '\\ControlPlaine-speedtest.json'`, take the last complete line, match with Lua patterns:
  - `"type":"ping"` -> `TESTING`
  - `"type":"download"` or `"type":"upload"` -> `TESTING  386 MBPS` from `"bandwidth":(%d+)`
  - Mbps = bandwidth x 8 / 1e6, rounded. Ookla's `bandwidth` is bytes per second (verify).
- `Finished()`: stop `mSpeedPoll`, find the `"type":"result"` line, pull `download.bandwidth`, `upload.bandwidth`, `ping.latency`, show `412 / 38 MBPS   PING 9 MS`. After `ResultHold` ms (an ActionTimer `Wait`), set `Testing=0` and return to rest.
- Failures show in warn for `ResultHold`: exe missing -> the link itself reads `INSTALL SPEEDTEST` at hover (checked on refresh and before each run), and clicking it opens `https://www.speedtest.net/apps/cli` instead of starting a test; no result line, an error log line, timeout, or `mSpeedRun` >= 100 -> `TEST FAILED`.
- Refresh or unload during a test: `State=Hide` makes Rainmeter kill speedtest.exe. No console window flashes.
- Fallback if progress lines only appear at the end (stdout buffered when redirected): `TESTING` with an animated three dots, then the result. Same parser.

Parsing sketch (ASCII only):

```lua
local function mbps(s, key)
  local b = s:match('"' .. key .. '":{[^}]-"bandwidth":(%d+)')
  return b and math.floor(tonumber(b) * 8 / 1e6 + 0.5)
end
local ping = s:match('"ping":{[^}]-"latency":([%d%.]+)')
```

## 8. Click

- Icon and name: `LeftMouseUpAction=[!CommandMeasure mWiFi "Open()"]`; Lua runs `["ms-settings:network-wifi"]` when `WiFiClick=settings`, else `["<WiFiClick>"]`.
- `Link` has its own action, so clicking `SPEED TEST` doesn't open settings.
- Right-click: the template's "Control-Plaine settings" opens `Settings\WiFi.ini`. Add `ContextTitle2=Run speed test` / `ContextAction2=[!CommandMeasure mWiFi "Start()"]`.

## 9. Checks on the test PC

Probe results (2026-10-10, `Control-Plaine-probes.md`): Windows 11 25H2 build 26200, Rainmeter 4.5.26.

| # | Check | State |
|---|---|---|
| 1 | Location for desktop apps (needed by WiFiStatus on 24H2+) | Done: on |
| 2 | `WiFiIntfID=0` | Done: one WLAN adapter (Realtek 8852CE), 0 is right. Confirm the skin shows `Airtel_Puzzles` once built. |
| 3 | `SystemRadioState` (Default) | Half done: reads 0 with airplane off. **Tester:** turn airplane mode on once and confirm it reads 1. If not, fall back to a PowerShell radio check. |
| 4 | Ethernet vs Wi-Fi | Done: Ethernet disconnected, no Hyper-V/VPN adapters, only a disconnected Bluetooth PAN, so `Best` picks Wi-Fi. Ethernet state can't be seen live until a cable is plugged in. |
| 5 | No-internet badge timing | **Tester:** with the router WAN down, the skin shows NO INTERNET when the taskbar does. |
| 6 | speedtest.exe | Not installed. After install, run once by hand: `speedtest.exe --format=json --progress=yes --accept-license --accept-gdpr > t.jsonl` and confirm (a) download/upload lines with `bandwidth` appear during the run, (b) `bandwidth` x 8 / 1e6 matches the human-readable Mbps, (c) the `result` field names match section 7. The build thread can do this through Remote Control. |
| 7 | No console flash when a test starts | After install |
| 8 | Rainmeter specifics the build relies on | `#*Var*#` escapes in `!SetOption` (Lua keeps colour options live), `SKIN:Bang('["url"]')` opening the Ookla page when the exe is missing, and `call "..." > "..."` through RunCommand's default `cmd /U /C`. |

Verified in the cloud (2026-10-10): `WiFi.lua` run under Lua 5.1 with a mocked Rainmeter API for every state and a full speed test (progress, result, error). Ookla's JSON shape (one object per line with `--format=json --progress=yes`, `type` ping/download/upload/result/log, `bandwidth` in bytes/s, `ping.latency` in ms) confirmed from the `speedtest-net` npm wrapper's source and docs, which drive the same binary with `-f json -p`. speedtest.net itself is blocked from the cloud, so the real binary still needs check 6.

## 10. Out of scope

- Automatic or scheduled speed tests (design: manual only).
- Network list or switching networks (click opens Windows settings).
- VPN state.
