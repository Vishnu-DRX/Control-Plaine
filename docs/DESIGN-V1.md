# Control-Plaine design V1

Phase 1 design, signed off by Vishnu on 10 October 2026. This is the build spec for the next rebuild of the suite. The visual source of truth is the mockup canvas: https://claude.ai/artifact/EYVaqvHoYVwzN69cj1RWwz (each board shows every state of one skin; "Control-Plaine V1" board is the index).

Final icons are in `docs/icons/` as 24x24 SVGs (white strokes). Render them to PNG at 1x/2x/3x for Rainmeter, or draw them with Shape meters.

## 1. Design language

| Token | Value |
|---|---|
| Font | Segoe UI (Segoe UI Variable Display where present). No other fonts. |
| Case | All text in capitals with wide tracking. |
| Display (Day-Date day name) | Regular 400, 52px at scale 1, tracking 0.30em |
| Value (volume %, track title, uptime) | Light 300, 18 to 22px, tracking 0.06 to 0.12em |
| Title (RECYCLE BIN, date line) | Medium 500, 12 to 13px, tracking 0.35 to 0.45em |
| Detail (device name, counts, labels) | Medium/Semibold 500 to 600, 9 to 10px, tracking 0.20 to 0.30em |
| Text shadow | 0 1px 3px rgba(0,0,0,0.45) on all skin text and icons |
| Brightness at rest | values 80%, details/icons 60%, tracks 18%; hover lifts to 95 to 100% |
| Accent | Windows accent colour, read from `HKCU\Software\Microsoft\Windows\DWM\AccentColor` (ABGR DWORD, convert to RGB). Vishnu's is cyan; mockups use #00E5FF. Settings can override. |
| Warn | #FFAA3C (low battery, restart recommended, max fans on is accent not warn) |
| Ring | radius 22, stroke 5, round caps, track rgba(255,255,255,0.18), fill = accent, starts at 12 o'clock |
| Links/actions | 9 to 10px semibold capitals with a 1px accent underline |
| Toggle bubble | pill, 1px outline grey when off, filled accent with dark text when on |
| Hover | fade 150 to 200 ms (ActionTimer), only brightens and reveals actions. Nothing moves. |
| Scale | one global `Scale` variable (Settings, default 100%) multiplies every size. Must look right at 250%. |
| Full screen | hide all skins while a full-screen app is in front (Settings toggle, default on). |

Rules: monitored values are always visible (volume %, output device, bin count/size, network name, low battery). Skins do not need to share a layout, only this language. App skins (Fan Control, SignalRGB, DeepCool) are icon-led and must not look like Volume/Media.

## 2. Skins

13 skins. "Rest" = not hovered. Every skin's right-click menu has "Control-Plaine settings".

### Day-Date
- Rest: day name (Display) right-aligned over `10  OCTOBER  2026` (Title, double spaces).
- Hover: adds `8:21 PM     WEEK 41` (Detail) underneath.
- Settings: 12/24 h, week number on/off, align left/right.

### Power
- Rest: four icons in a row at 60%: hibernate, shut down, restart, lock (`power-*.svg`, old Phenix style). No uptime here.
- Hover an icon: it brightens, its name shows above (HIBERNATE / SHUT DOWN / RESTART / LOCK) and a SCHEDULE link shows below (not for lock).
- Shut down and restart need a second click: first click turns the icon orange with CLICK AGAIN above; times out after about 3 s.
- SCHEDULE opens a picker: `SHUT DOWN IN` / value box `3 H 15 M` / SET link. Scroll changes the value in 15-minute steps, minimum 15 M, maximum 24 H. No range text is shown.
- While scheduled: icon in accent, `SHUT DOWN IN` + countdown (`58 M`) in accent, CANCEL link. The countdown stays visible at rest.
- Commands: shut down `shutdown /s /t N`, restart `shutdown /r /t N`, cancel `shutdown /a`. Hibernate now `shutdown /h`; scheduled hibernate via a one-time task: `schtasks /create /tn ControlPlaineHibernate /sc once /st HH:MM /sd DATE /tr "shutdown /h" /f`, cancel with `schtasks /delete /tn ControlPlaineHibernate /f` (no admin needed, verify). Lock `rundll32 user32.dll,LockWorkStation`.
- Persist the scheduled time in a variable so the countdown survives a Rainmeter refresh.
- Settings: first button hibernate/sleep, ask to confirm, picker start value (default 1 H).

### Uptime (separate skin)
- Rest: invisible, but keeps a hover area.
- Hover: `UPTIME` (Detail) over `14 H 32 M` (Value).
- Past the threshold (default 5 days) it shows itself at rest in orange: `RESTART RECOMMENDED` over `6 DAYS 3 H`.
- Must update every minute (the old skin went stale because IfTrueAction only fires on change). Note: with Fast Startup, Shut down does not reset uptime; mention this in the skin comments.
- Settings: threshold, always visible.

### Volume
- Rest: `43%` (Value) over a hairline over output device name (`SOUND BAR - LG`, Detail), ring on the right showing the level, speaker icon inside the ring.
- Hover: everything brightens; scrolling anywhere on the skin changes volume (default 2% per notch); device name gets an underline.
- Click on the ring sets the level to that angle (Lua: atan2 from the ring centre, 0 at 12 o'clock, clockwise).
- Click the % text toggles mute. Muted: text `MUTED`, ring grey, speaker icon crossed (`speaker-muted.svg`).
- Click the speaker icon opens the Windows volume mixer (`ms-settings:apps-volume`, fallback `sndvol.exe`). A custom mixer skin may come later.
- Click the device name cycles output devices.
- Plugin: Win7AudioPlugin (value -1 when muted, string = device name).
- Settings: scroll step, scroll up unmutes, ring thickness.

### Media
- Same shape as Volume: track title where the % is, artist where the device is, ring = playback progress (no scroll), play/pause icon inside the ring, small prev/next chevrons at the two ends of the hairline.
- Paused: dimmer, play icon, ring grey.
- Nothing playing: skin hidden completely.
- Long titles: ellipsis by default (setting to scroll instead).
- Source: Windows media session (any app). Plugin to choose at build time; WebNowPlaying Redux is the first candidate. Test with Spotify and a browser.

### Recycle Bin
- Rest: `RECYCLE BIN` (Title) over `35 FILES   3.2 GB` (Detail), trash icon on the right. Always visible.
- Hover: OPEN and EMPTY links appear below.
- Empty: second line reads `EMPTY`.
- Plugin: RecycleManager (Count, Size, OpenBin, EmptyBin). Settings: show size, ask before emptying.

### Playnite
- The white controller PNG from the old Playnite skin (asset already in the repo), 60% at rest, full on hover with `PLAYNITE` label. Click launches Playnite (optionally skip splash). Path is a setting.

### Wi-Fi
- Not like Volume/Media. Wi-Fi icon with the network name to its right.
- Signal strength is shown by how many arcs are lit (lit = 100%, unlit = 22% opacity): 3 arcs strong, 2 medium, 1 weak.
- Network name is dim (about 50%) at rest and only full brightness on hover.
- Hover: SPEED TEST link under the name. Click it: `TESTING  386 MBPS` (accent, live), then the result `412 / 38 MBPS   PING 9 MS`, then back to rest. Manual only, never automatic.
- Click the icon or name opens `ms-settings:network-wifi`.
- States that copy the taskbar: connected but no internet (Wi-Fi icon + orange "no" badge, `NO INTERNET` in orange); not connected or Wi-Fi off (globe + orange "no" badge, `NOT CONNECTED`); on Ethernet (monitor icon, `ETHERNET`); airplane mode (plane icon, `AIRPLANE MODE`).
- Data: WiFiStatus plugin (SSID, quality); internet via SysInfo or a ping/NCSI check; Ethernet via adapter status; airplane mode from `HKLM\SYSTEM\CurrentControlSet\Control\RadioManagement\SystemRadioState` (verify). Speed test: Ookla `speedtest.exe --format=json --accept-license --accept-gdpr` via RunCommand, parse with Lua.
- Settings: click target, speedtest.exe path, name brightness at rest.

### Fan Control (app skin, generic)
- Designed for Fan Control by Rem0o (Vishnu runs V277). Header comment must say so and list what to change for other software.
- Rest: fan icon only, dim.
- Hover: icon brightens, average fan speed `46%` (Value) and a grey outlined `MAX` bubble.
- Click MAX toggles max fans. On: bubble filled with accent and it stays visible at rest. Hover while on shows `100%`.
- Click the icon opens the Fan Control app.
- Max toggle: switch Fan Control to a "Max" config (all fans 100%) and back to the normal config, e.g. `FanControl.exe -c Max.json` (verify it works while Fan Control is already running).
- Average %: Fan Control has no API, so read fan control % (or RPM) from LibreHardwareMonitor or HWiNFO. Ask Vishnu which he has installed.
- Settings: app path, normal profile, max profile, sensor source.

### SignalRGB (app skin, generic)
- Designed for SignalRGB.
- Icon is monochrome: accent while lights are on, grey when off.
- Rest: icon only.
- Hover: a thin ring (stroke 2.5) appears around the icon showing brightness, with `70%` and `BRIGHTNESS` beside it. Scroll changes brightness (default 5% per notch). Scroll to 0 = lights off, text `OFF`.
- Click the icon opens SignalRGB.
- Control via SignalRGB's URL commands (`signalrgb://...`) or its local API; verify which supports brightness and on/off.
- Settings: app path, scroll step.

### DeepCool (app skin, generic)
- Designed for the DeepCool app that drives the case screen.
- The icon is the toggle: accent when the app is running (screen on), grey when closed. Hover label `CASE SCREEN ON` / `CASE SCREEN OFF`.
- Click: if the app is not running, start it minimized to tray with no window; if running, close it silently.
- Running state from a Process measure on the process name.
- Verify: a tray/minimized start flag exists; how to close without a prompt (graceful close, else taskkill); whether closing the app actually turns the screen off.
- Settings: app path, process name, start hidden.

### Controllers
- Hidden unless a game controller or wheel is connected (USB or Bluetooth). Only game controllers are listed, nothing else.
- Vertical list, one row per device: icon, then battery. Icons: `controller-xbox.svg` (Fluent, MIT), `controller-dualsense.svg`, `wheel-moza.svg` (D-shaped, flat bottom). Vishnu may want AI-generated icon art later; keep the same simple outline style.
- Battery: at rest only shown when below 50% (setting). On hover every device's battery shows. Low (under 15%) in orange, charging in accent with a bolt. Wheel has no battery.
- Hover a row: it brightens, others dim, and its name shows (`XBOX`, `DUALSENSE`, `MOZA`).
- Click: DualSense opens DSX; Moza opens Moza Pit House; any other controller opens its Windows device settings (`ms-settings:bluetooth`).
- Detection: PnP devices by vendor ID (Xbox 045E, Sony 054C, Moza 346E; verify), e.g. a small PowerShell or Lua helper run on a timer.
- Battery: Xbox over Bluetooth exposes battery to Windows (Bluetooth battery property). DualSense does not; it needs a HID read of the input report, which may be blocked while DSX holds the controller. Verify, and show nothing rather than a wrong value.
- Settings: battery threshold, DualSense app, wheel app, other controllers target.

### Settings
- One panel opened from any skin's right-click menu. Left column: CONTROL / PLAINE wordmark, then tabs GENERAL, DAY-DATE, POWER, UPTIME, VOLUME, RECYCLE BIN, PLAYNITE, MEDIA, WI-FI, FAN CONTROL, SIGNALRGB, DEEPCOOL, CONTROLLERS. Active tab has a 2px accent bar. Footer: VERSION and OPEN ON GITHUB.
- GENERAL: on/off toggle for every skin, scale, accent (Windows or custom), brightness at rest, hide in full screen, lock positions.
- Per-skin tabs: the settings listed under each skin above. Values with a box are changed by scrolling; paths by clicking (InputText).
- All settings write to `@Resources\User.inc` (git-ignored) and refresh the affected skins.

## 3. Build notes

- Shared styles in `@Resources\Styles.inc`, tokens in `@Resources\Theme.inc`; every skin @includes both and uses `#Scale#` for every size.
- App skins read all program paths, process names and commands from variables so anyone can repoint them.
- Start every skin's .ini with a comment block: what it shows, what it was designed for, and what other users can adjust.
- Things to verify on the PC before calling a skin done: listed under each skin as "verify".
- Commits: author Vishnu-DRX, Claude as co-author.
