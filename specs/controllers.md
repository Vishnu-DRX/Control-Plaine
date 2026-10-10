# Spec: Controllers skin

Source of truth: `docs/DESIGN-V1.md` section "Controllers" and the V1 canvas board `Controllers.dc.html`. This file says how to build it in Rainmeter. Status: investigated, not built.

Shared conventions: follow `specs/foundation-settings.md` when it lands. Until then this spec uses what the repo already does: `Theme.inc`, `User.inc`, `Styles.inc`, `Fade.inc` included in that order; every size times `#Scale#`; ASCII-only files with CRLF; settings in `User.inc`; header comment block in the .ini; Settings opened from the right-click menu. If the foundation spec renames keys, changes the include order or the Settings hook, it wins.

## 1. Verdict

Everything in the design can be driven from Rainmeter. Rainmeter has no measure for game controllers, so one small PowerShell helper (started and killed by the skin through `RunCommand`) does detection and battery and writes a state file; a Lua script reads it and drives the meters. No third-party Rainmeter plugin is needed.

| Feature | Route | Confidence |
|---|---|---|
| Detect connected controllers (USB and Bluetooth) | Helper polls PnP every 3 s: present HID devices with gamepad/joystick usage, plus Xbox USB/adapter nodes by name | High, verify IDs on PC |
| Tell Xbox / DualSense / Moza / other apart | Vendor ID in the device ID: Microsoft `045E`, Sony `054C`, Moza `346E` | High (Moza ID verify on PC) |
| Hide skin when none connected | Lua `!Hide` / `!ShowFade` on count change | High |
| Xbox battery over Bluetooth | PnP property `{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2` (Bluetooth battery %) on the controller's `BTHLE` node | High, it is what Windows Settings shows |
| DualSense battery, DSX not running | Read one HID input report, decode the status byte | High over USB; over Bluetooth only if something (DSX, Steam) already switched it to full reports, see section 6 |
| DualSense battery, DSX running | 1st: ask DSX's UDP mod server for status. 2nd: shared HID read as above | Medium, both need checking on the PC |
| Charging bolt | DualSense: status byte high nibble. Xbox Bluetooth: not exposed | DualSense only |
| Clicks (DSX, Pit House, Windows settings) | Plain Rainmeter `["#Target#"]` bang | High |
| Per-row hover, name, battery rules | Lua + meter formulas, same fade system as the other skins | High |

Can't be done, by design falls back to showing nothing (never a wrong value):

- **Xbox wired over USB**: Windows exposes no battery (XInput reports it as wired). No battery shown.
- **Xbox through the Xbox Wireless Adapter**: only 4 coarse levels (empty/low/medium/full) via XInput, not a percentage. Not shown in v1 (option in section 6 if Vishnu uses the adapter).
- **Xbox charging state over Bluetooth**: the Bluetooth battery property has no charging flag. No bolt for Xbox.
- **DualSense over Bluetooth with neither DSX nor Steam running**: the controller sends a short report with no battery until an app switches it to full mode. The helper will not force the switch (doing so can break DirectInput games until reconnect). No battery shown in that case.
- **DualSense while DSX hides it with HidHide and DSX's UDP status is off or unavailable**: no battery shown, unless `powershell.exe` is added to HidHide's allow list (section 6).
- **Moza wheel**: no battery, as designed.

## 2. Files

```
Controllers/Controllers.ini
@Resources/Scripts/Controllers.lua
@Resources/Scripts/Controllers.ps1
@Resources/Icons/controller-xbox.png
@Resources/Icons/controller-dualsense.png
@Resources/Icons/wheel-moza.png
```

Icons: render from `docs/icons/*.svg` with headless Chromium, same pipeline as the existing icons (white on transparent, 2x of the drawn size). "Other" controllers reuse `controller-xbox.png` (the Fluent gamepad outline reads as a generic pad). The battery glyph and bolt are Shape meters, not PNGs, so they can take Warn/Accent colours and a live fill width.

Runtime state file: `%TEMP%\ControlPlaine-controllers.txt` (written by the helper, read by Lua). Nothing new goes in the repo or `.gitignore`.

## 3. Layout

From the canvas board (sizes at Scale 1; multiply everything by `#Scale#`):

```
[icon 32]  [battery 20x10] 40%   DUALSENSE      <- one row, 36 tall, rows 14 apart (pitch 50)
[icon 32]
[icon 32]  [battery] 12%
```

- Rows: up to `MaxRows=4` fixed rows (`Row1..Row4`), each built from: `RowNHit` (Shape, full-row hit rectangle, fill `0,0,0,1`), `RowNIcon` (Image, 32x32 centred in a 44 wide box), `RowNBat` (Shape battery glyph), `RowNPct` (String), `RowNName` (String). Row N top = `(N-1)*50`.
- Battery glyph (Shape), same geometry as the canvas: outline `Rectangle 0.5,0.5,17,9,2` stroke 1; nub `Rectangle 18.2,3,1.5,4,0.5` filled; level `Rectangle 2,2,(Max(Bat,8)*0.14),6,1` filled (8% floor so a near-empty bar is still visible). Charging: a filled bolt polygon cut out of the level with `Combine ... | Exclude`.
- Text: percent at `SizeXS` (9), name at `SizeS` (10), weight 600, spaced caps per the foundation spec (Rainmeter `InlineSetting=CharacterSpacing`).
- Gaps: icon box to battery 12, glyph to percent 6, battery group to name 12. Lua sets `RowNName` X explicitly, because the battery group may be hidden (Moza, unknown battery) and the name must then sit right after the icon.
- Colours: everything `#Ink#`; battery glyph and percent `#Warn#` below `ControllersBatteryLow` (15%); `#Accent#` while charging (charging wins over low).
- Order of rows is fixed by kind so they don't jump around: Xbox, DualSense, Moza, Other. Within a kind, connection order.

### Alpha and hover

- Skin-level `Reveal` (from `Fade.inc`) as in every skin.
- Lua keeps `HoverRow` (0 = none). Each `RowNHit` has `MouseOverAction=[!SetVariable HoverRow N][!UpdateMeterGroup Rows][!Redraw]` and `MouseLeaveAction` back to 0.
- Row alpha (icon, glyph, text): `HoverRow=0` -> `AlphaRest`; hovered row -> `AlphaHover`; other rows while one is hovered -> `AlphaDim` (new token, default `(#AlphaRest#*0.6)`; foundation spec may own it).
- Battery group visible when: `Bat >= 0` and (`Bat < ControllersBatteryShowBelow` or `Reveal > 0`). At rest only low ones show; on hover over the skin every known battery fades in with `Reveal`. Unknown battery (`-1`) never shows.
- Name visible only on the hovered row (alpha `AlphaHover` when `HoverRow=N`, else 0). Names are fixed per kind: `XBOX`, `DUALSENSE` (`DUALSENSE EDGE` for PID 0DF2), `MOZA`, `CONTROLLER`.
- Each `RowNHit` has `MouseActionCursor=1` and `ToolTipText` (`Open DSX`, `Open Pit House`, `Open Bluetooth settings`).

### Show / hide

- `Update=1000`. Lua re-reads the state file every update (cheap `io.open`), parses only if the text changed.
- Count goes 0 -> n: set rows, `[!ShowFade]`. n -> 0: `[!HideFade]`. Rows beyond the count get `Hidden 1`.
- `DynamicWindowSize=1` so the window shrinks to the rows shown. Anchor top-left; the list grows down.
- On first load with nothing connected, the skin hides itself in `Initialize()` after the first read, so it never flashes.

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

[Rainmeter]
OnRefreshAction=[!CommandMeasure mHelper "Run"]
```

`State=Hide` is what makes Rainmeter kill the process on refresh, unload or exit (documented RunCommand behaviour). Belt and braces inside the script: a named mutex `Local\ControlPlaineControllers` so only one copy runs, and each loop checks that the parent `Rainmeter.exe` is still alive and exits if not (covers a Rainmeter crash).

### Loop

Every `Poll` seconds (default 3):

1. **Enumerate** with one CIM query (warm process, ~100 ms):
   `Get-CimInstance Win32_PnPEntity -Filter "Present=TRUE AND (PNPClass='HIDClass' OR PNPClass='XnaComposite' OR PNPClass='XboxComposite')"`.
2. **Keep game controllers only**:
   - HID nodes whose `CompatibleID` contains `HID_DEVICE_UP:0001_U:0005` (gamepad) or `HID_DEVICE_UP:0001_U:0004` (joystick). This catches Xbox over Bluetooth, DualSense over USB/Bluetooth, the Moza base and any other pad. Mice, keyboards and headsets have other usages and drop out.
   - Plus Xbox nodes that are not HID: `XnaComposite`/`XboxComposite` class or name matching `Xbox*Controller*` (wired USB and through the wireless adapter). Exclude the adapter itself (name contains `Adapter`).
   - HID child nodes only exist while a Bluetooth device is actually connected, so paired-but-off controllers don't show.
3. **Drop virtual pads**: DSX (and DS4Windows) create virtual Xbox 360 / DS4 pads through ViGEmBus. For each new device ID, read `DEVPKEY_Device_Parent` once (cache it) and drop it if the parent chain starts with `ROOT\` or contains `VIGEM`. Without this, a phantom XBOX row appears whenever DSX runs.
4. **Classify** by vendor ID parsed with `VID[_&](?:0002|02)?([0-9A-F]{4})[&_]PID[_&]([0-9A-F]{4})` (covers USB `VID_054C&PID_0CE6`, Bluetooth classic `VID&0002054C_PID&0CE6`, BLE `VID&02045E_PID&0B13`): `045E` xbox, `054C` with PID `0CE6`/`0DF2` dualsense, `346E` moza, anything else other. Moza pedals or handbrake plugged in on their own share `346E`: one row per Moza is enough, so collapse all `346E` devices into one row.
5. **Dedupe** to one entry per physical device: key on the Bluetooth MAC when the ID has one (the 12 hex digits after `_PID&xxxx_REV&xxxx_` or in `BTHLE\DEV_<mac>`), else the USB instance path's parent. Multiple HID collections from one pad collapse to one row.
6. **Battery**, only every `BatteryPoll` seconds (default 60) and immediately when a device first appears:
   - Xbox Bluetooth: find `BTHLE\DEV_<mac>` with the same MAC, read `Get-PnpDeviceProperty -InstanceId <id> -KeyName '{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2'`; use `.Data` if the type isn't `Empty`. No charging info.
   - Xbox USB / adapter: `-1`.
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

## 6. Settings (User.inc keys, names to match the foundation spec)

| Key | Default | Meaning |
|---|---|---|
| `ControllersBatteryShowBelow` | `50` | At rest, show battery only below this % (design "configurable 50%") |
| `ControllersBatteryLow` | `15` | Below this, battery is Warn orange |
| `ControllersDualSenseApp` | `steam://rungameid/1812620` | Click DualSense (DSX on Steam, app id 1812620). Can be an exe path instead |
| `ControllersWheelApp` | `C:\Program Files (x86)\MOZA Pit House\MOZA Pit House.exe` | Click Moza (verify path) |
| `ControllersOtherTarget` | `ms-settings:bluetooth` | Click Xbox or any other controller |
| `ControllersPoll` | `3` | Seconds between device scans |
| `ControllersBatteryPoll` | `60` | Seconds between battery reads |
| `ControllersDsxPort` | `6969` | DSX mod server port |

Settings panel CONTROLLERS tab (design: "battery threshold, DualSense app, wheel app, other controllers target"): the first is a scroll box (step 5, range 5-100), the three targets are click-to-edit paths. The polls and port live in User.inc only.

Click actions on `RowNHit`: `LeftMouseUpAction=["#ControllersDualSenseApp#"]` etc.; Lua sets which variable each row uses when it assigns kinds to rows. Right-click menu: Settings (per foundation spec).

Optional, only if Vishnu needs them after the PC checks:
- **Xbox Wireless Adapter battery**: `XInputGetBatteryInformation` (xinput1_4.dll) gives EMPTY/LOW/MEDIUM/FULL. Could show the glyph with a coarse fill and no percent. Not built unless he uses the adapter.
- **HidHide allow list**: if DSX hides the DualSense and 5a is unavailable, adding `powershell.exe` to HidHide's allow list makes 5b work. It is his call: any PowerShell would then see the pad (harmless, but it is a change to his setup).

## 7. Header comment for the .ini

What it shows (connected game controllers with battery), designed for Xbox (Bluetooth), DualSense with DSX, and a Moza wheel with Pit House; what others can change (the three click targets, thresholds); that it starts a hidden PowerShell helper which Rainmeter stops when the skin closes.

## 8. Check on Vishnu's PC before calling it done

1. With each controller connected in turn (Xbox BT, Xbox USB, DualSense USB, DualSense BT, Moza), run `Get-CimInstance Win32_PnPEntity -Filter "Present=TRUE AND (PNPClass='HIDClass' OR PNPClass='XnaComposite' OR PNPClass='XboxComposite')" | ft Name,PNPClass,DeviceID,CompatibleID`. Confirm: the gamepad/joystick compatible IDs, Moza's vendor ID really is `346E`, and that a paired-but-off Bluetooth pad disappears.
2. With DSX running: the virtual Xbox 360 pad is dropped by the parent check (no phantom XBOX row).
3. Xbox over Bluetooth: the battery property returns a number on the `BTHLE` node and matches Settings > Bluetooth & devices.
4. DualSense with DSX running: does 5a answer (and is DSX's UDP/mod server switched on in DSX settings)? Does 5b open the device, or does HidHide block it?
5. DualSense over Bluetooth with DSX closed: confirm we show nothing rather than a stale or wrong value.
6. `steam://rungameid/1812620` opens DSX (and only focuses it if already running). Pit House exe path and that a second launch doesn't open a second copy.
7. Helper CPU stays negligible (expect well under 1% average) and the process disappears when the skin is unloaded or Rainmeter exits.
8. Which Xbox connection he actually uses (Bluetooth, adapter or cable), to decide on the adapter option in section 6.

## 9. Sources

- DualSense report layout and status byte: Linux `drivers/hid/hid-playstation.c` (report IDs 0x01/64 bytes USB, 0x31/78 bytes BT; status byte decoding).
- Bluetooth battery property key: Microsoft Q&A 1156194 and `HyperNylium/Get-Bluetooth-Battery-Persentage`.
- RunCommand kill-on-unload with `State=Hide`: docs.rainmeter.net/manual/plugins/runcommand.
- DSX mod server, status response fields, HidHide optional, Steam app id 1812620: DS4Windows PR #86 and its `docs/DSX-game-mod-support.md`, Paliverse/DualSenseX README.
