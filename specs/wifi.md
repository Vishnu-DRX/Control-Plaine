# Spec: Wi-Fi skin

Source of truth: `docs/DESIGN-V1.md` section "Wi-Fi" and the V1 canvas. This file says how to build it in Rainmeter. Status: investigated, not built.

Shared conventions: follow `specs/foundation-settings.md` when it lands. Until then this spec uses what the repo already does: `Theme.inc`, `User.inc`, `Styles.inc`, `Fade.inc` included in that order; every size times `#Scale#`; ASCII-only files with CRLF; settings live in `User.inc`; header comment block in the .ini. If the foundation spec renames variables or changes the include order, it wins.

## 1. Verdict

Everything in the design can be done in Rainmeter with built-in measures plus one Lua script. No third-party plugin is needed.

| Feature | Route | Confidence |
|---|---|---|
| Network name | `Measure=WiFiStatus`, `WiFiInfoType=SSID` | High, but see Location privacy (section 7) |
| Signal arcs | `WiFiStatus`, `WiFiInfoType=Quality` (0-100) | High |
| No internet | `Measure=SysInfo`, `SysInfoType=INTERNET_CONNECTIVITY` (1 / -1, uses Windows NCSI like the taskbar) | High |
| Ethernet | `SysInfo` `ADAPTER_TYPE` (6 Ethernet, 71 Wireless) + `ADAPTER_STATE` with `SysInfoData=Best` (prefers wired) | High |
| Not connected / Wi-Fi off | `ADAPTER_STATE` not 1 and no Ethernet | High |
| Airplane mode | `Measure=Registry` on `HKLM\SYSTEM\CurrentControlSet\Control\RadioManagement\SystemRadioState` | Medium, verify on PC |
| Speed test | `RunCommand` runs Ookla `speedtest.exe`, output redirected to a file; Lua polls the file for live progress and the result | Medium, verify live progress on PC |
| Click opens settings | `["ms-settings:network-wifi"]` | High |

Nothing in the design is blocked. Two risks have fallbacks: live speed during the test (falls back to `TESTING` with no number) and the SSID being blank on Windows 11 24H2 when Location is off (falls back to the profile name or `WI-FI`).

## 2. Files

```
WiFi/WiFi.ini
@Resources/Scripts/WiFi.lua
@Resources/Icons/wifi-1.png  wifi-2.png  wifi-3.png
@Resources/Icons/wifi-no-internet.png
@Resources/Icons/globe-disconnected.png
@Resources/Icons/ethernet.png
@Resources/Icons/airplane.png
```

Icons: render from `docs/icons/*.svg` with headless Chromium, same pipeline as the existing icons (white, transparent, 2x of `#IconSize#`). `wifi-1/2/3.png` are `wifi.svg` with 1, 2 or 3 arcs at full alpha and the rest at 22% (the dot is always lit). `wifi-no-internet.png` is `wifi-no-internet-badge.svg` (orange badge baked in). Pre-rendering the three arc levels keeps one image meter and matches the other skins; a Shape meter with per-arc alpha is the alternative if crisper scaling is wanted later.

The speed test output goes to `%TEMP%` (section 5), so nothing new goes in the repo or `.gitignore`.

## 3. Layout

```
[icon]  Network name              rest: icon + name (name at WifiNameAlpha)
        SPEED TEST                hover only (sReveal, SizeXS, accent on its own hover)
```

- `Icon`: image meter, `sIconFade`, X=0, Y=0, 24x24 at Scale 1.
- `Name`: string, `sText`, LeftCenter at `(IconSize+IconGap)*Scale`, vertically centred on the icon. FontColor alpha = `WifiNameAlpha + (AlphaHover - WifiNameAlpha) * Reveal`, so it is ~50% at rest and full on hover. `ClipString=1`, `W=#WifiNameW#` (default 170) so long SSIDs end in an ellipsis.
- `Link`: string, `sReveal`, under the name. Text `SPEED TEST`. Hidden (alpha 0) at rest via Reveal. Hover on the link itself turns it accent.
- In state text (NO INTERNET, NOT CONNECTED, ETHERNET, AIRPLANE MODE) the `Name` meter shows that text. Orange (`#Warn#`) for NO INTERNET and NOT CONNECTED, normal ink for ETHERNET and AIRPLANE MODE.
- While a test runs or a result is showing, the `Link` line shows the test text and stays visible at rest (same pattern as Volume keeping `%` visible while muted: alpha = `AlphaHover * Max(Reveal, Testing)`).
- Spaced caps: follow whatever the foundation spec sets for letter spacing; the strings above are the content.

## 4. State logic

Measures (all `UpdateDivider=2` on a `Update=1000` skin, so state refreshes every 2 s):

```ini
[mSSID]
Measure=WiFiStatus
WiFiInfoType=SSID
WiFiIntfID=#WifiInterface#

[mQuality]
Measure=WiFiStatus
WiFiInfoType=Quality
WiFiIntfID=#WifiInterface#

[mType]
Measure=SysInfo
SysInfoType=ADAPTER_TYPE
SysInfoData=Best
DynamicVariables=1

[mState]
Measure=SysInfo
SysInfoType=ADAPTER_STATE
SysInfoData=Best
DynamicVariables=1

[mInternet]
Measure=SysInfo
SysInfoType=INTERNET_CONNECTIVITY

[mAirplane]
Measure=Registry
RegHKey=HKEY_LOCAL_MACHINE
RegKey=SYSTEM\CurrentControlSet\Control\RadioManagement\SystemRadioState
; empty RegValue reads the (Default) value: 1 = airplane mode on
```

`WiFi.lua` `Update()` picks one state, in this order (same priority as the taskbar):

1. Best adapter is Ethernet (`mType`=6) and connected (`mState`=1):
   - internet ok: `ethernet.png`, `ETHERNET`.
   - no internet: `globe-disconnected.png`, `NO INTERNET` (orange). The taskbar shows the globe for wired-without-internet; the design doesn't cover this case, so this copies the taskbar.
2. Best adapter is Wireless (`mType`=71) and connected:
   - no internet: `wifi-no-internet.png`, `NO INTERNET` (orange).
   - internet ok: `wifi-N.png` with N = 3 if quality >= 67, 2 if >= 34, else 1. Name = SSID.
   - SSID text contains `connecting...` or `authorizing...`: show the SSID dim, no change in icon (WiFiStatus appends these while joining).
3. Nothing connected and airplane mode on: `airplane.png`, `AIRPLANE MODE`.
4. Otherwise: `globe-disconnected.png`, `NOT CONNECTED` (orange).

Airplane mode is checked after a live connection on purpose: with airplane on and Wi-Fi switched back on, Windows shows the Wi-Fi icon, and so does this skin.

Lua only calls `!SetOption` and redraws when the state or bar count actually changes, to avoid redrawing every tick.

SSID blank while connected over Wi-Fi (Location off, see section 7): show `WI-FI` as the name and full arcs if quality is also 0. Optional fallback if Vishnu wants the real name without enabling Location: a RunCommand running `powershell -NoProfile -Command "(Get-NetConnectionProfile -InterfaceAlias '<alias>').Name"` every 30 s; the profile name is usually the SSID and doesn't need Location. Not built unless needed.

## 5. Speed test

Ookla CLI (`speedtest.exe`, the official one from speedtest.net/apps/cli, not the Python `speedtest-cli`).

Run measure:

```ini
[mSpeedRun]
Measure=Plugin
Plugin=RunCommand
; cmd redirect so the file fills while the test runs (RunCommand only hands over stdout at the end)
Parameter=""#SpeedtestPath#" --format=jsonl --progress=yes --accept-license --accept-gdpr > "%TEMP%\ControlPlaine-speedtest.jsonl" 2>&1"
State=Hide
Timeout=120000
FinishAction=[!CommandMeasure mWiFi "Finished()"]
DynamicVariables=1
```

Flow, all in `WiFi.lua`:

- Click `SPEED TEST`: `Start()` deletes the old file, sets `Testing=1`, shows `TESTING`, starts `[!CommandMeasure mSpeedRun "Run"]`, and sets the skin's update to fast polling (an ActionTimer repeating `[!UpdateMeasure mWiFi]` every 250 ms while testing, so the rest of the skin stays at 1 s). Clicks while a test is running do nothing. Never started automatically.
- Poll: read the file with `io.open(os.getenv('TEMP') .. '\\ControlPlaine-speedtest.jsonl')`, take the last complete line, match with Lua patterns (no JSON library needed):
  - `"type":"ping"` -> `TESTING`
  - `"type":"download"` -> `TESTING  386 MBPS` using `"bandwidth":(%d+)`
  - `"type":"upload"` -> same, upload bandwidth. Design shows one live number; download then upload both use the same line.
  - Mbps = bandwidth * 8 / 1e6, rounded to an integer. Ookla's `bandwidth` is bytes per second (verify, section 7).
  - Live text in `#Accent#`.
- `Finished()`: find the `"type":"result"` line; pull `download.bandwidth`, `upload.bandwidth`, `ping.latency`. Show `412 / 38 MBPS   PING 9 MS` in ink. Hold for `#SpeedResultHold#` ms (default 15000) or until the next mouse-leave after that, then clear `Testing` and go back to rest.
- Failure (no result line, `"type":"log"` with `"level":"error"`, timeout, file missing, or `mSpeedRun` number >= 100): show `TEST FAILED` in orange for the hold time. If `#SpeedtestPath#` doesn't exist, show `SPEEDTEST NOT FOUND` and do nothing else.
- Refresh or unload during a test: `State=Hide` makes Rainmeter kill speedtest.exe automatically.
- No window flashes: `State=Hide` hides the cmd window and speedtest runs inside it.

Fallback if live progress doesn't appear (stdout buffered when redirected): show `TESTING` with a three-dot ActionTimer animation, then the result. Same parser, no other change.

Lua parsing sketch:

```lua
local function mbps(s, key)  -- key = 'download' or 'upload'
  local b = s:match('"' .. key .. '":{[^}]-"bandwidth":(%d+)')
  return b and math.floor(tonumber(b) * 8 / 1e6 + 0.5)
end
local ping = s:match('"ping":{[^}]-"latency":([%d%.]+)')
```

## 6. Click and settings

- Icon and name: `LeftMouseUpAction=["#WifiClick#"]`. The `Link` meter has its own action so clicking `SPEED TEST` doesn't also open settings.
- Right-click menu: open Settings (per foundation spec) plus `Run speed test`.

`User.example.inc` additions (Settings tab WI-FI shows these):

```ini
; Wi-Fi: what clicking the icon or name opens.
WifiClick=ms-settings:network-wifi
; Wi-Fi: Ookla speedtest.exe (speedtest.net/apps/cli).
SpeedtestPath=%LOCALAPPDATA%\Programs\Ookla\speedtest.exe
; Wi-Fi: network name brightness at rest (0-255, 128 is about 50%).
WifiNameAlpha=128
```

Internal, not in Settings: `WifiInterface=0`, `WifiNameW=170`, `SpeedResultHold=15000`.

Install note: the CLI is a zip, not an installer. Suggest Vishnu unzip it to `%LOCALAPPDATA%\Programs\Ookla\` (no admin), or `winget install Ookla.Speedtest.CLI`, then set the path to wherever it landed. `--accept-license --accept-gdpr` covers the first-run prompt.

## 7. Check on Vishnu's PC before calling it done

1. **Location privacy (Windows 11 24H2+):** WiFiStatus returns nothing unless Settings > Privacy & security > Location > "Let desktop apps access your location" is on. Check his Windows build and that toggle. If he doesn't want it on, the name falls back to `WI-FI` (or the PowerShell profile-name fallback in section 4).
2. **WiFiIntfID:** confirm `0` returns his SSID; if blank with Location on, try 1, 2.
3. **Airplane registry value:** read `HKLM\SYSTEM\CurrentControlSet\Control\RadioManagement\SystemRadioState` (Default) with airplane mode off and on; expect 0 / 1. If it doesn't flip, fall back to "Wi-Fi adapter present but `ADAPTER_STATUS` is -1/-2 and Bluetooth off" or a small PowerShell radio check, and note it.
4. **Ethernet:** if the PC has a wired port, plug in and confirm `ADAPTER_TYPE`=6 wins over Wi-Fi with `SysInfoData=Best`. Also check that virtual adapters (Hyper-V, VPN, VirtualBox) don't get picked as "Best"; if they do, set `SysInfoData` to the real adapter aliases instead.
5. **No internet:** with Wi-Fi connected but the router's WAN unplugged (or a DNS block), confirm `INTERNET_CONNECTIVITY` goes to -1 at the same time the taskbar shows the badge.
6. **speedtest.exe:** installed and its path. Run once by hand: `speedtest.exe --format=jsonl --progress=yes --accept-license --accept-gdpr > test.jsonl` and confirm (a) progress lines with `"type":"download"` and `"bandwidth"` appear while it runs, not only at the end, (b) `bandwidth` is bytes/s (result x8/1e6 should match the human-readable output), (c) the `result` line field names match section 5.
7. **No console flash** when the test starts from the skin.

## 8. Out of scope

- Automatic or scheduled speed tests (design says manual only).
- Network list / switching networks from the skin (click opens Windows settings instead).
- VPN state.
