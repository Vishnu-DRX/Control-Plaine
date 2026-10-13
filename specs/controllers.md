# Spec: Controllers skin

Source of truth: `docs/DESIGN-V1.md` section "Controllers" and the V1 canvas board `Controllers.dc.html`. This file says how to build it in Rainmeter. Status: built (see section 10 for what the build settled).

Shared conventions: `specs/foundation-settings.md` (skin template in its section 2, tokens and styles in 3 and 5, Settings pages in 7). This spec uses its names; where anything here disagrees with it, the foundation spec wins.

## 1. Verdict

Everything in the design can be driven from Rainmeter. Rainmeter has no measure for game controllers, so one small PowerShell helper (started and killed by the skin through `RunCommand`) does detection and battery and writes a state file; a Lua script reads it and drives the meters. No third-party Rainmeter plugin is needed.

| Feature | Route | Confidence |
|---|---|---|
| Detect connected controllers (USB and Bluetooth) | Helper polls PnP every 3 s: present HID devices with gamepad/joystick usage, plus Xbox USB nodes and Moza by VID; Bluetooth pads must also pass the IsConnected check | High (IDs checked on PC 2026-10-11) |
| Tell Xbox / DualSense / Moza / other apart | Vendor ID in the device ID: Microsoft `045E`, Sony `054C` (PID `0CE6`/`0DF2` only), Moza `346E` | High, confirmed on PC |
| Hide skin when none connected | Lua sets `SelfHidden` and updates `mVisible` (Core.inc) on count change | High |
| Xbox battery over Bluetooth | PnP property `{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2` (Bluetooth battery %) on the controller's `BTHLE` node, read only while connected (it keeps a stale value when off) | High, property seen on PC |
| DualSense battery, DSX not running | Read one HID input report, decode the status byte | High over USB; over Bluetooth only if something (DSX, Steam) already switched it to full reports, see section 6 |
| DualSense battery, DSX running | DSX's UDP mod server (on, 127.0.0.1:6969 on Vishnu's PC). The HID read is blocked then: DSX controls HidHide and hides the pad | Medium, live status reply not yet tried |
| Charging bolt | DualSense: status byte high nibble. Xbox Bluetooth: not exposed | DualSense only |
| Clicks (DSX, Pit House, Windows settings) | Plain Rainmeter `["#Target#"]` bang | High |
| Per-row hover, name, battery rules | Lua + meter formulas, same fade system as the other skins | High |

Can't be done, by design falls back to showing nothing (never a wrong value):

- **Xbox wired over USB**: Windows exposes no battery (XInput reports it as wired). No battery shown.
- **Xbox through the Xbox Wireless Adapter**: only 4 coarse levels via XInput. Not built: Vishnu's pad is Bluetooth LE and no adapter has ever been connected (probe 2026-10-11).
- **Xbox charging state over Bluetooth**: the Bluetooth battery property has no charging flag. No bolt for Xbox.
- **DualSense over Bluetooth with neither DSX nor Steam running**: the controller sends a short report with no battery until an app switches it to full mode. The helper will not force the switch (doing so can break DirectInput games until reconnect). No battery shown in that case.
- **DualSense while DSX hides it with HidHide and DSX's UDP status is off or unavailable**: no battery shown, unless `powershell.exe` is added to HidHide's allow list (section 6).
- **Moza wheel**: no battery, as designed.

## 2. Files

Skin thread owns:

```
Controllers/Controllers.ini          foundation skin template, section 2
Controllers/Defaults.inc             defaults for every Controllers* key (section 6)
Settings/Controllers.ini             fills the foundation's stub page
@Resources/Scripts/Controllers.lua
@Resources/Scripts/Controllers.ps1
```

Icons `controller-xbox.png`, `controller-dualsense.png`, `wheel-moza.png` are rendered by the foundation (`tools/render-icons.py`, 128 px masters with `IconPad` and shadow baked in). "Other" controllers reuse `controller-xbox.png` (the Fluent gamepad outline reads as a generic pad). The battery glyph and bolt are Shape meters, not PNGs, so they take token colours and a live fill width.

Runtime state file: `%TEMP%\ControlPlaine-controllers.txt` (written by the helper, read by Lua). Nothing new goes in the repo or `.gitignore`.

## 3. Layout

From the canvas board (sizes at Scale 1; multiply everything by `#Scale#`):

```
[icon 32]  [battery 20x10] 40%   DUALSENSE      <- one row, 36 tall, rows 14 apart (pitch 50)
[icon 32]
[icon 32]  [battery] 12%
```

- Rows: up to `MaxRows=4` fixed rows (`Row1..Row4`), each built from: `RowNHit` (`MeterStyle=sHit`, full-row rectangle), `RowNIcon` (Image, `sIcon`), `RowNBat` (Shape battery glyph), `RowNPct` (String), `RowNName` (String). Row N top = `(N-1)*50`.
- Icon: same grid as the other skins. Each row is IconBox (32 px) high, 40 px pitch; the icon sits at X=0, Y=row top, and the hit area is 230 x 32 at 0,0 of the row. The controller icons are one 32 x 32 canvas (a 28 px glyph, 2 px strokes, 3 px margin, vertically centred; `tools/render-icons.py` FIT list), so `W=(#CtlW#*#Scale#)`, `H=(#IconBox#*#Scale#)`. Battery glyph at X=CtlW+4, percent at CtlW+30, name after the percent (or at CtlW+4 with no battery), all centred on row top + 16.
- Battery glyph (Shape), same geometry as the canvas: outline `Rectangle 0.5,0.5,17,9,2` stroke 1; nub `Rectangle 18.2,3,1.5,4,0.5` filled; level `Rectangle 2,2,(Max(Bat,8)*0.14),6,1` filled (8% floor so a near-empty bar is still visible). Charging: a filled bolt polygon cut out of the level with `Combine ... | Exclude`.
- Text: percent and name both `MeterStyle=sDetail` (9.5 px semibold, tracked, upper case, shadow); the canvas's 9/10 px both round to it. Tracking on the trailing side only (`CharacterSpacing | 0 | t`): DirectWrite applies it per letter, so both sides doubles the gap.
- Gaps: icon box to battery 12, glyph to percent 6, battery group to name 12. Lua sets `RowNName` X explicitly, because the battery group may be hidden (Moza, unknown battery) and the name must then sit right after the icon.
- Colours: everything `#Ink#`; battery glyph and percent `#Warn#` (`sWarn`) below `ControllersBatteryLow` (15%); `#Accent#` (`sAccent`) while charging (charging wins over low). The glyph's colour is set by Lua with `!SetOption` on the Shape's `Stroke Color`/`Fill Color`, never a raw RGB literal.
- Order of rows is fixed by kind so they don't jump around: Xbox, DualSense, Moza, Other. Within a kind, connection order.

### Alpha and hover

- Skin-level `Reveal` (hover fade in `Core.inc`) as in every skin.
- Lua keeps `HoverRow` (0 = none). Each `RowNHit` has `MouseOverAction=[!SetVariable HoverRow N][!UpdateMeterGroup Rows][!Redraw]` and `MouseLeaveAction` back to 0.
- Row alpha: `HoverRow=0` -> icon `AlphaDetail`, battery text `AlphaValue`; hovered row -> `AlphaHover`; other rows while one is hovered -> `AlphaDim` (Core.inc, 60% of the rest level).
- Battery group visible when: `Bat >= 0` and (`Bat < ControllersBatteryShow` or `Reveal > 0`). At rest only low ones show; on hover over the skin every known battery fades in with `Reveal`. Unknown battery (`-1`) never shows.
- Name visible only on the hovered row (alpha `AlphaHover` when `HoverRow=N`, else 0). Names are fixed per kind: `XBOX`, `DUALSENSE` (`DUALSENSE EDGE` for PID 0DF2), `MOZA`, `CONTROLLER`.
- Each `RowNHit` has `MouseActionCursor=1` and `ToolTipText` (`Open DSX`, `Open Pit House`, `Open Bluetooth settings`).

### Show / hide

- `Update=1000`. Lua re-reads the state file every update (cheap `io.open`), parses only if the text changed.
- Count goes 0 -> n: set rows, then `[!SetVariable SelfHidden 0][!UpdateMeasure mVisible]`. n -> 0: `[!SetVariable SelfHidden 1][!UpdateMeasure mVisible]`. Never `!Show`/`!Hide` directly (foundation rule; Core combines this with full-screen hiding). Rows beyond the count get `Hidden 1`.
- `DynamicWindowSize=1` (in the template) so the window shrinks to the rows shown. Anchor top-left; the list grows down.
- Controllers.ini sets `SelfHidden=1` in its skin-local variables (after the Defaults include), so on load it stays hidden until the first read finds a controller, and never flashes.

## 4. The helper (`Controllers.ps1`)

One long-running PowerShell process per skin, started by the skin and killed by Rainmeter when the skin refreshes or unloads.

```ini
[mHelper]
Measure=Plugin
Plugin=RunCommand
Program=powershell.exe
Parameter=-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "#@#Scripts\Controllers.ps1" -Out "%TEMP%\ControlPlaine-controllers.txt" -Poll #ControllersPoll# -BatteryPoll #ControllersBatteryPoll# -DsxPort #ControllersDsxPort#
State=Hide
OutputType=ANSI
DynamicVariables=1

; added to the template's [Rainmeter] section
OnRefreshAction=[!CommandMeasure mHelper "Run"]
```

`State=Hide` is what makes Rainmeter kill the process on refresh, unload or exit (documented RunCommand behaviour). Belt and braces inside the script: a named mutex `Local\ControlPlaineControllers` so only one copy runs, and each loop checks that the parent `Rainmeter.exe` is still alive and exits if not (covers a Rainmeter crash).

### Loop

Every `Poll` seconds (default 3):

1. **Enumerate** with one CIM query (warm process, ~100 ms):
   `Get-CimInstance Win32_PnPEntity -Filter "Present=TRUE AND (PNPClass='HIDClass' OR PNPClass='XnaComposite' OR PNPClass='XboxComposite')"`.
2. **Keep game controllers only**:
   - HID nodes whose `CompatibleID` contains `HID_DEVICE_UP:0001_U:0005` (gamepad) or `HID_DEVICE_UP:0001_U:0004` (joystick). This catches Xbox over Bluetooth, DualSense over USB/Bluetooth and any other pad. Mice, keyboards and headsets have other usages and drop out.
   - Plus Xbox nodes that are not HID: `XnaComposite`/`XboxComposite` class or name matching `Xbox*Controller*` (wired USB). Exclude any name containing `Adapter`.
   - Plus Moza by vendor: any present `HID\VID_346E...` or `USB\VID_346E...` node (seen on PC: PIDs `0005` and `0015`, HID "MOZA Windows Driver" on `MI_02`), whether or not it has a gamepad usage. Ignore `SWD\` software nodes ("MOZA WheelBase Virtual Device") and the COM port; they are not proof the base is plugged in.
   - **Bluetooth connected check (required).** On Vishnu's PC, paired pads that are switched off keep `Present=TRUE`, Status OK and even their HID child node. So for every Bluetooth match, take its MAC, find `BTHLE\DEV_<mac>` (Xbox, BLE) or `BTHENUM\DEV_<mac>` (DualSense, classic), read `DEVPKEY_Device_IsConnected` = `{83DA6326-97A6-4088-9453-A1923F573B29} 15` and keep the device only if it is `True`. USB devices are only present while plugged in, so they skip this.
3. **Drop virtual pads**: DSX (and DS4Windows) create virtual Xbox 360 / DS4 pads through ViGEmBus. For each new device ID, read `DEVPKEY_Device_Parent` once (cache it) and drop it if the parent chain starts with `ROOT\` or contains `VIGEM`. Without this, a phantom XBOX row appears whenever DSX runs.
4. **Classify** by vendor ID parsed with `VID[_&](?:0002|02)?([0-9A-F]{4})[&_]PID[_&]([0-9A-F]{4})` (covers USB `VID_054C&PID_0CE6`, Bluetooth classic `VID&0002054C_PID&0CE6`, BLE `VID&02045E_PID&0B13`): `045E` xbox, `054C` with PID `0CE6`/`0DF2` dualsense, `346E` moza, anything else other. Moza pedals or handbrake plugged in on their own share `346E`: one row per Moza is enough, so collapse all `346E` devices into one row.
5. **Dedupe** to one entry per physical device: key on the Bluetooth MAC when the ID has one (the 12 hex digits after `_PID&xxxx_REV&xxxx_` or in `BTHLE\DEV_<mac>`), else the USB instance path's parent. Multiple HID collections from one pad collapse to one row.
6. **Battery**, only every `BatteryPoll` seconds (default 60) and immediately when a device first appears:
   - Xbox Bluetooth: on the same `BTHLE\DEV_<mac>` node, read `Get-PnpDeviceProperty -InstanceId <id> -KeyName '{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2'` (a Byte); use `.Data` if the type isn't `Empty`. Only ever read it after the IsConnected check passed: when the pad is off it still returns the last value (77 at probe time). No charging info.
   - Xbox USB: `-1`.
   - DualSense: section 5.
   - Moza, other: `-1`.
7. **Write** the file only when content changed: write `<file>.tmp`, then `Move-Item -Force` over the real file so Lua never reads half a file.

### State file format

ASCII, one device per line, `|`-separated, plus a version line:

```
v1
xbox|XBOX|80|0
dualsense|DUALSENSE|40|1
moza|MOZA|-1|0
```

Fields: kind, display name, battery 0-100 or -1 unknown, charging 0/1. Lua splits with `gmatch('[^|]+')`; no JSON needed.

## 5. DualSense battery

Two sources, tried in this order each battery poll. The first that gives a value wins; if neither does, `-1` (show nothing).

On Vishnu's PC (probe 2026-10-11): DSX v3 Beta from Steam (`G:\SteamLibrary\steamapps\common\DSX`, also starts at logon) has `use_incoming_udp: true` on `127.0.0.1:6969`, and `SaveFile_LetDSXControlHidHide: true` with the DualSense's Bluetooth HID paths on its hide list. So while DSX runs, 5a is the only route and 5b fails to open the pad. With DSX closed, 5b is the route (if DSX lifts the hide on exit; to be checked).

### 5a. DSX UDP status (only when `DSX.exe` is running)

DSX runs a mod server on `127.0.0.1:6969` (setting `ControllersDsxPort`). A status request returns JSON that includes a `Devices` list with `BatteryLevel` and `ConnectionType` per controller (confirmed from DS4Windows' DSX-compatible server and its docs; Paliverse's own schema could not be fetched from here). Helper sends one status packet, waits 300 ms for the reply, regex-matches `"BatteryLevel"\s*:\s*(\d+)` for the DualSense entry. If no reply, move on to 5b. This is read-only; it changes nothing in DSX.

Implementation thread: fetch Paliverse's mod example (`github.com/Paliverse/DSX`, folder `Mod System (DSX v3)`) to get the exact packet (`instructions` / `type` / `parameters` names and the `GetDSXStatus` enum value). If DSX turns out not to answer status requests, drop 5a; 5b still works when HidHide is not hiding the pad.

Note: the old DSX README says battery over USB "will show 100%". If 5a returns exactly 100 on USB, prefer 5b's value.

### 5b. Direct HID read (works with or without DSX, if the pad is visible)

Small C# block compiled once at helper start with `Add-Type` (P/Invoke to `hid.dll`, `setupapi.dll`, `kernel32.dll`):

1. Enumerate HID interfaces (`HidD_GetHidGuid`, `SetupDiGetClassDevs`, `SetupDiEnumDeviceInterfaces`), keep paths containing `vid_054c` and `pid_0ce6` or `pid_0df2`.
2. `CreateFile(path, GENERIC_READ, FILE_SHARE_READ|FILE_SHARE_WRITE, OPEN_EXISTING, FILE_FLAG_OVERLAPPED)`. Shared open: Windows hands every open handle its own copy of each input report, so this does not take reports away from DSX or a game.
3. `HidP_GetCaps` -> `InputReportByteLength`: 64 means USB, 78 means Bluetooth.
4. Read one report with a 500 ms timeout (`FileStream.BeginRead` + wait). Decode:
   - USB, report ID `0x01`: status byte at `data[53]`.
   - Bluetooth, report ID `0x31`: status byte at `data[54]`.
   - Bluetooth, report ID `0x01` (short report): no battery, return -1. Do not send feature report `0x05` to force full mode.
5. Status byte (from the Linux `hid-playstation` driver): low nibble `n` = capacity, percent `min(n*10+5, 100)`; high nibble `0` discharging, `1` charging, `2` full (100%, charging 1), `0xA`/`0xB`/`0xF` error -> -1.
6. Close the handle. If `CreateFile` fails (HidHide hiding it, or exclusive open), return -1.

Resolution is 10% steps, which is what PlayStation shows too.

## 6. Settings

Keys and defaults live in `Controllers/Defaults.inc`; Settings writes overrides to `User.inc`. The first four are the foundation's agreed names (its section 7.6); the rest are additions with the same prefix.

| Key | Default | Meaning |
|---|---|---|
| `ControllersBatteryShow` | `50` | At rest, show battery only below this % (design "configurable 50%") |
| `ControllersDualSenseApp` | `steam://rungameid/1812620` | Click DualSense (DSX on Steam, app id 1812620). Can be an exe path instead |
| `ControllersWheelApp` | `C:\Program Files (x86)\MOZA Pit House\bin\MOZA Pit House.exe` | Click Moza (path confirmed on PC) |
| `ControllersOther` | `ms-settings:bluetooth` | Click Xbox or any other controller |
| `ControllersBatteryLow` | `15` | Below this, battery is Warn orange |
| `ControllersPoll` | `3` | Seconds between device scans |
| `ControllersBatteryPoll` | `60` | Seconds between battery reads |
| `ControllersDsxPort` | `6969` | DSX mod server port |

Settings page `Settings/Controllers.ini` (foundation page template, section 7.1; controls from 7.3), rows from the design ("battery threshold, DualSense app, wheel app, other controllers target"):

| Row | Control | Call |
|---|---|---|
| BATTERY AT REST | value box, shows `50%` | `Step('ControllersBatteryShow',5,5,100,'Controllers')` |
| DUALSENSE APP | path box | `EditPath('ControllersDualSenseApp','Controllers')` |
| WHEEL APP | path box | `EditPath('ControllersWheelApp','Controllers')` |
| OTHER CONTROLLERS | path box | `EditPath('ControllersOther','Controllers')` |

`ControllersBatteryLow`, the polls and the port are Defaults-only (no row), changeable by editing `User.inc`.

Click actions on `RowNHit`: `LeftMouseUpAction=["#ControllersDualSenseApp#"]` etc.; Lua sets which variable each row uses when it assigns kinds to rows. Right-click menu comes from the template's `ContextAction`, which opens `Settings\Controllers.ini`.

Optional, only if Vishnu needs them after the PC checks:
- **HidHide allow list**: if DSX hides the DualSense and 5a is unavailable, adding `powershell.exe` to HidHide's allow list makes 5b work. It is his call: any PowerShell would then see the pad (harmless, but it is a change to his setup).

## 7. Header comment for the .ini

What it shows (connected game controllers with battery), designed for Xbox (Bluetooth), DualSense with DSX, and a Moza wheel with Pit House; what others can change (the three click targets, thresholds); that it starts a hidden PowerShell helper which Rainmeter stops when the skin closes.

## 8. Check on Vishnu's PC before calling it done

Answered by the probe (2026-10-11): Moza VID `346E` (PIDs `0005`, `0015`); Xbox is Bluetooth LE, no adapter; DSX UDP server on at 127.0.0.1:6969; DSX Steam app id 1812620; Pit House path; paired-but-off pads stay present (hence the IsConnected check); the Sony camera `054C:0A92` is excluded by the PID filter.

Still to check, with the pads on:

1. Each controller shows one row when connected and none when switched off (Xbox BT, DualSense USB and BT, Moza).
2. With DSX running: no phantom XBOX row from the ViGEm virtual Xbox 360 pad (`045E:028E`).
3. Xbox battery matches Settings > Bluetooth & devices while connected.
4. DSX answers the status request on 6969 with the DualSense battery (5a).
5. DSX closed: does DSX lift the HidHide hide so 5b can open the pad? Over Bluetooth with DSX and Steam closed we expect nothing shown (short reports), not a stale value.
6. `steam://rungameid/1812620` only focuses DSX when it is already running (it auto-starts at logon); Pit House doesn't open a second copy.
7. Helper CPU stays negligible and the process goes away when the skin is unloaded or Rainmeter exits.

## 9. Sources

- DualSense report layout and status byte: Linux `drivers/hid/hid-playstation.c` (report IDs 0x01/64 bytes USB, 0x31/78 bytes BT; status byte decoding).
- Bluetooth battery property key: Microsoft Q&A 1156194 and `HyperNylium/Get-Bluetooth-Battery-Persentage`.
- RunCommand kill-on-unload with `State=Hide`: docs.rainmeter.net/manual/plugins/runcommand.
- DSX mod server, status response fields, HidHide optional, Steam app id 1812620: DS4Windows PR #86 and its `docs/DSX-game-mod-support.md`, Paliverse/DualSenseX README.

## 10. What the build settled

- DSX status packet confirmed on Vishnu's PC: `{"instructions":[{"type":0,"parameters":[]}]}` to 127.0.0.1:6969, reply JSON with `isControllerConnected` and `Devices` (`DeviceType` 0 = DualSense, `ConnectionType` 0 = USB, `BatteryLevel`). The top-level `BatteryLevel` is ignored. A USB pad below 100% from DSX is shown as charging.
- If DSX lists more DualSense pads than PnP shows (HidHide can hide them), the helper adds rows from DSX's list.
- The helper rewrites the state file every scan with a time stamp. Lua deletes the file on load, treats a file older than 4 polls (min 15 s) as "nothing connected" and restarts the helper at most every 30 s.
- Rows are shown and hidden with `!ShowMeterGroup` / `!HideMeterGroup Row<N>`; each row's transparent hit area sits on top and takes hover and click.
- Settings page rows: BATTERY AT REST (scroll, 5-100 step 5), DUALSENSE APP, WHEEL APP, OTHER CONTROLLERS (click to edit).
