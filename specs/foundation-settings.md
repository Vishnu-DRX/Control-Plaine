# Foundation and Settings: implementation spec

Status: built 2026-10-10 (foundation PR). Where the build differs, the code comments win. Source of truth for look and behaviour: `docs/DESIGN-V1.md` and the V1 canvas (Settings board). This file settles **how** it is built in Rainmeter and the conventions every skin thread must follow.

Checked on Vishnu's PC (folder access, 2026-10-10):
- Rainmeter **4.5.26** (`Rainmeter.data` LastCheck). 4.5 gives us Shape meters, `FontWeight`, `InlineSetting=CharacterSpacing`, `Container`, Lua, built-in Game Mode.
- `Skins\@Vault\Plugins` already has **IsFullScreen 3.0.0.0**, FrostedGlass 1.1.1.0, HotKey 1.0.0.12, XInput 1.0.0.0, Drag&Drop 3.1.0.3 (64-bit builds present). Rainmeter 4.5 loads Vault plugins.
- No `Plugins` folder in `%APPDATA%\Rainmeter`, so only bundled + Vault plugins are available. Bundled ones we rely on: ActionTimer, InputText, RunCommand, RecycleManager, Win7AudioPlugin, WiFiStatus, SysInfo, Registry/Calc/Time/Uptime/Script measures.
- `Rainmeter.ini` is **UTF-16 LE**; Control-Plaine is not yet active in it (old skins still loaded).

---

## 1. Ownership and file layout

```
Control-Plaine\                      (config root; always referred to as #ROOTCONFIG#, never the literal name)
  @Resources\
    Theme.inc        FOUNDATION  design tokens (not user settings)
    Defaults.inc     FOUNDATION  defaults for GENERAL settings only
    User.inc         git-ignored overrides written by Settings (may be empty)
    State.inc        git-ignored runtime state (e.g. Power's scheduled time); skins write their own keys
    Core.inc         FOUNDATION  shared measures: accent, full-screen hide, fade
    Styles.inc       FOUNDATION  shared meter styles
    Fade.inc         v1 only (Core.inc has the same fade); removed at integration
    Settings\Chrome.inc    FOUNDATION  panel, wordmark, tab column, footer, close
    Settings\Controls.inc  FOUNDATION  row/toggle/choice/value/path styles
    Scripts\Settings.lua   FOUNDATION  read/write/apply logic for the Settings skin
    Scripts\<Skin>.lua     SKIN THREAD
    Icons\<name>.png       FOUNDATION renders all docs/icons; skin threads may ADD new files (e.g. app icons)
  <Skin>\<Skin>.ini        SKIN THREAD
  <Skin>\Defaults.inc      SKIN THREAD  defaults for that skin's settings
  Settings\General.ini     FOUNDATION
  Settings\<Skin>.ini      SKIN THREAD fills it (FOUNDATION commits a stub per skin)
  Layouts\, README.md, CHANGELOG.md, tools\install.ps1   INTEGRATION (coordinator, after skins land)
```

Skin folder names (also Settings page names, `Settings\<name>.ini`): `DayDate`, `Power`, `Uptime`, `Volume`, `Media`, `RecycleBin`, `Playnite`, `WiFi`, `FanControl`, `SignalRGB`, `DeepCool`, `Controllers`, `Settings`.

**Sequencing:** the foundation PR must merge before skin threads open their PRs (they rebase on it). Skin threads must not edit FOUNDATION files; if they need a new shared style or token, they ask the foundation thread (via the coordinator) or keep it local to their skin.

Files are ASCII with CRLF (existing `.gitattributes`). No `#` inside stored values. Rainmeter has no inline comments: a `;` comment must be on its own line.

## 2. Skin template (every skin, copy exactly)

```ini
; Control-Plaine | <Skin>
; What it shows: ...
; Designed for: ... (app skins: name the target software and version)
; Adjust: list the Settings keys / variables another user would change
[Rainmeter]
Update=1000
AccurateText=1
DynamicWindowSize=1
Group=ControlPlaine
ContextTitle=Control-Plaine settings
ContextAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "<Skin>.ini"]
MouseOverAction=[!CommandMeasure mFade "Stop 2"][!CommandMeasure mFade "Execute 1"]
MouseLeaveAction=[!CommandMeasure mFade "Stop 1"][!CommandMeasure mFade "Execute 2"]

[Metadata]
Name=Control-Plaine | <Skin>
Author=Vishnu A
Version=2.0.0
License=CC BY-NC-SA 4.0

[Variables]
@include=#@#Theme.inc
@include2=#@#Defaults.inc
@include3=#ROOTCONFIGPATH#<Skin>\Defaults.inc
@include4=#@#User.inc
@include5=#@#State.inc
; skin-local, non-setting variables here
@include6=#@#Core.inc
@include7=#@#Styles.inc
```

Order matters: later files override earlier ones, so `User.inc` beats both defaults files. `Core.inc` and `Styles.inc` hold sections, so they come last. Every user-facing setting key must exist in a Defaults file so a fresh install (empty `User.inc`) works and new keys arrive with `git pull`.

Rules for skins:
- Never call `!Show`/`!Hide` on yourself. To hide the skin (Media idle, Controllers none, Uptime-style), set `SelfHidden` and update `mVisible`: `[!SetVariable SelfHidden 1][!UpdateMeasure mVisible]`. Core combines it with full-screen hiding.
- Every size is `(n*#Scale#)`. Every colour is a token. No hardcoded paths (lint enforces).
- Invisible hover/click areas use `SolidColor=0,0,0,1` (alpha 0 is not hit-testable).
- Every option using a variable that can change at runtime needs `DynamicVariables=1` (all shared styles set it).

## 3. Theme.inc (tokens)

Font sizes are **points** (Rainmeter `FontSize` is pt; px x 0.75). Tracking is px at scale 1 (CharacterSpacing is in DIPs). Apply it on one side only (both sides doubles the gap): `| 0 | t` for left/centred text, `| t | 0` for right-aligned text so right edges line up.

```ini
[Variables]
Version=2.0.0
RepoURL=https://github.com/Vishnu-DRX/Control-Plaine

; Colour (R,G,B)
Ink=255,255,255
Warn=255,170,60
Dark=18,20,24
; Accent is set at runtime by Core.inc; this is the start value.
Accent=#AccentColor#
Shadow=0,0,0,115

; Alpha (0-255). Rest levels follow the RestBrightness setting (default 60).
; details, icons at rest (60%)
AlphaDetail=(#RestBrightness#*2.55)
; values at rest (80%)
AlphaValue=(Min(255,(#RestBrightness#+20)*2.55))
; ring tracks, hairlines (18%)
AlphaTrack=46
; hover (98%)
AlphaHover=250
; disabled/unselected (45%)
AlphaOff=115

; Type
; Win10 or missing font: Settings sets FontFace=Segoe UI, see section 6
FontFace=Segoe UI Variable Display
; 52px Day-Date day name
SizeDisplay=39
WeightDisplay=400
TrackDisplay=15.6
; 20px (use SizeValueS 13.5 = 18px, SizeValueL 16.5 = 22px)
SizeValue=15
SizeValueS=13.5
SizeValueL=16.5
WeightValue=300
TrackValue=1.8
; 12.5px
SizeTitle=9.5
WeightTitle=600
TrackTitle=5
; 9.5px
SizeDetail=7.25
WeightDetail=600
TrackDetail=2.4

; Shapes
RingRadius=22
RingStroke=5
; visual icon size
IconSize=24
; transparent margin baked into every icon PNG (holds the shadow)
IconPad=4
; PNG box = IconSize + 2*IconPad
IconBox=32
; px between link text and its underline
LinkGap=2

; Motion: FadeSteps x FadeStep ms = 180 ms
FadeStep=15
FadeSteps=12
HideDelay=500
```

`Defaults.inc` (GENERAL settings, all skins read these):

```ini
[Variables]
; 0.5 - 3.0, Settings shows it as %
Scale=1
; 1 = Windows accent, 0 = AccentColor
AccentFollowWindows=1
AccentColor=0,229,255
; 30 - 90 (%)
RestBrightness=60
HideFullScreen=1
LockPositions=0
SelfHidden=0
Reveal=0
```

## 4. Core.inc (shared measures)

### 4.1 Accent from Windows
Feasible with built-in measures, no Lua. `AccentColor` is a REG_DWORD in ABGR (0xAABBGGRR). Rainmeter reads DWORD unsigned, and formulas have no bit ops, so use division and modulo.

```ini
[mAccentReg]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\Microsoft\Windows\DWM
RegValue=AccentColor
UpdateDivider=5
Disabled=(1-#AccentFollowWindows#)
[mAccentR]
Measure=Calc
Formula=Trunc(mAccentReg) % 256
UpdateDivider=5
Disabled=(1-#AccentFollowWindows#)
[mAccentG]
Measure=Calc
Formula=Trunc(mAccentReg/256) % 256
...
[mAccentB]
Measure=Calc
Formula=Trunc(mAccentReg/65536) % 256
...
[mAccent]
Measure=String
String=[mAccentR],[mAccentG],[mAccentB]
DynamicVariables=1
UpdateDivider=5
Disabled=(1-#AccentFollowWindows#)
IfMatch=^0,0,0$
IfNotMatchAction=[!SetVariable Accent "[mAccent]"]
IfMatchMode=1
```
Accent changes in Windows show within 5 s without a refresh. If the value is missing (0,0,0) the start value `AccentColor` stays. With `AccentFollowWindows=0` the measures are disabled and `Accent=#AccentColor#` is used.

### 4.2 Hide in full screen (and self-hide)
IsFullScreen plugin (already in @Vault) returns 1 while the foreground window is full screen.

```ini
[mFullScreen]
Measure=Plugin
Plugin=IsFullScreen
Disabled=(1-#HideFullScreen#)
[mVisible]
Measure=Calc
Formula=((#HideFullScreen#=1) && (mFullScreen=1)) || (#SelfHidden#=1) ? 0 : 1
DynamicVariables=1
IfCondition=mVisible=1
IfTrueAction=[!Show]
IfFalseAction=[!Hide]
```
Alternatives considered: Rainmeter 4.5 Game Mode can unload all skins on full screen, but it hits every suite and unloads rather than hides, so not used. When packaging an .rmskin later, IsFullScreen must be bundled.

### 4.3 Hover fade
Current `Fade.inc` moves into Core.inc unchanged in mechanics (ActionTimer drives `#Reveal#` 0 to 1 and back after `HideDelay`, updating meter group `Reveal`). Meters that brighten on hover use `Group=Reveal` and alpha `(#AlphaX#+(#AlphaHover#-#AlphaX#)*#Reveal#)`. Per-element hover (one icon in a row, a link) may snap instantly via MouseOverAction; "nothing moves" still applies.

### 4.4 Lock positions
No measure: Settings runs `[!DraggableGroup 0 ControlPlaine]` / `1`, Rainmeter persists `Draggable=` per config itself. `LockPositions` is saved only so the toggle shows its state.

## 5. Styles.inc

All styles set `AntiAlias=1`, `DynamicVariables=1`, and text styles `StringCase=Upper`, `StringEffect=Shadow`, `FontEffectColor=#Shadow#`, `FontFace=#FontFace#`.

| Style | Use | Key options |
|---|---|---|
| `sDisplay` | Day-Date day name | SizeDisplay, WeightDisplay, TrackDisplay, alpha AlphaValue to Hover by Reveal |
| `sValue` | %, title, uptime | SizeValue, WeightValue, TrackValue, AlphaValue to Hover |
| `sTitle` | RECYCLE BIN, date line | SizeTitle, WeightTitle, TrackTitle, AlphaValue to Hover |
| `sDetail` | device name, counts | SizeDetail, WeightDetail, TrackDetail, AlphaDetail to Hover |
| `sReveal` | text only shown on hover | as sDetail, alpha `AlphaHover*Reveal` |
| `sLink` | OPEN, EMPTY, SCHEDULE, SET, CANCEL | sDetail type, AlphaHover*Reveal, hand cursor |
| `sLinkLine` | 1px accent underline | Image meter, `W=[<Link>:W]`, `H=(1*#Scale#)`, `Y=(#LinkGap#*#Scale#)R`, `SolidColor=#Accent#,(255*#Reveal#)` |
| `sIcon` / `sIconFade` | icons | `W=H=(#IconBox#*#Scale#)`, place at `X=(x-#IconPad#)*#Scale#`, ImageTint #Ink# or #Accent#/#Warn# |
| `sRingTrack` / `sRing` | rings | see below |
| `sHit` | hover/click backing | `SolidColor=0,0,0,1` |
| `sWarn`, `sAccent` | colour modifiers | `FontColor=#Warn#,...` / `#Accent#` (combine: `MeterStyle=sValue | sWarn`) |

Ring (Volume, Media, SignalRGB): one Shape meter, centre `c=(#RingRadius#+#RingStroke#/2+1)*#Scale#`, angle `a=2*PI*value` from 12 o'clock clockwise:
```ini
Shape=Ellipse c,c,(#RingRadius#*#Scale#) | Fill Color 0,0,0,0 | StrokeWidth (#RingStroke#*#Scale#) | Stroke Color #Ink#,#AlphaTrack#
Shape2=Arc c,(c-R),(c+R*Sin(a)),(c-R*Cos(a)),0,0,(a>PI?1:0) | Fill Color 0,0,0,0 | StrokeWidth (#RingStroke#*#Scale#) | Stroke Color #Accent#,255 | StrokeStartCap Round | StrokeEndCap Round
```
As built, Theme.inc provides `#RingTrack#` and `#RingFill#` modifier strings, coloured by `RingColor` (default `#Accent#`) with width `RingWidth` (default `RingStroke`); a skin overrides either in its own [Variables] or with `!SetVariable`. At value >= 0.999 draw Shape2 as a full Ellipse (an arc with equal ends draws nothing); at 0 hide it.

## 6. Typography, scale, icons: how close Rainmeter gets

| Design | Rainmeter | Gap |
|---|---|---|
| Segoe UI Variable Display | `FontFace` via DirectWrite named instance | Win10 lacks it; Rainmeter falls back to Arial silently. Keep `FontFace` overridable: Settings writes `FontFace=Segoe UI` if PC check fails. |
| Weights 300/400/600 | `FontWeight=` | **Medium 500 does not exist** in Segoe UI; we use Semibold 600 for Title/Detail. |
| Tracking in em | `InlineSetting=CharacterSpacing | t | t` | Values precomputed in px per size. |
| Text shadow 0 1px 3px | `StringEffect=Shadow`, `FontEffectColor=0,0,0,115` | **No blur** in Rainmeter, hard 1px shadow. Close enough at these sizes. |
| Icon shadow | Baked into PNG | Fine (tint multiplies RGB; the black shadow stays black). |
| Ring/line shadow | none | **Not possible** on Shape meters without a duplicate shape; skipped. |
| Hover fade 150-200 ms | ActionTimer 12 x 15 ms | OK. |
| Scale 50-300% | `#Scale#` in every size | OK; icons are 128 px masters so they stay sharp up to 400%. |

Icons: `tools/render-icons.py` (dev-time, headless Chromium, already used for v1) renders every `docs/icons/*.svg` to `@Resources\Icons\<same-name>.png` at **128x128** (32 units x 4): icon drawn 96 px centred, white strokes, `drop-shadow(0 4px 12px rgba(0,0,0,.45))` (1px/3px at 4x). Old PNGs (`power.png`, `bin-full.png`, ...) stay until their skins are rebuilt; integration deletes unused ones. `gamepad.png` (Playnite's original art) is kept as is.

## 7. Settings skin

### 7.1 Structure
One config, `Control-Plaine\Settings`, with **one variant per tab**: `General.ini`, `DayDate.ini`, `Power.ini`, ... `Controllers.ini`. Switching tab = `!ActivateConfig "#ROOTCONFIG#\Settings" "<Tab>.ini"`; Rainmeter keeps the window position across variants. Benefits: each skin's right-click opens its own tab directly, and each skin thread owns one small page file with no shared-file conflicts.

Each page:
```ini
[Rainmeter]
Group=ControlPlaineSettings
OnRefreshAction=[!ZPos 1]
ContextTitle=Close settings
ContextAction=[!DeactivateConfig]
[Variables]
@include=#@#Theme.inc
@include2=#@#Defaults.inc
; omitted on General
@include3=#ROOTCONFIGPATH#<Skin>\Defaults.inc
@include4=#@#User.inc
Tab=<Skin>
@include5=#@#Core.inc
@include6=#@#Styles.inc
@include7=#@#Settings\Chrome.inc
@include8=#@#Settings\Controls.inc
; rows...
```
Settings is in its own group so `!RefreshGroup ControlPlaine` does not reload it mid-edit.

### 7.2 Chrome (from the canvas Settings board)
- Panel 912 x 620 at scale 1, scaled by `PanelScale=(Min(#Scale#,#SCREENAREAHEIGHT#*0.85/620))` so 250-300% never overflows the screen.
- Shape rectangle, radius 12, fill `#Dark#,219` (0.86), 1px stroke `#Ink#,20`. Optional FrostedGlass blur behind it: off by default, verify rounded corners on Win11 first.
- Left column: `CONTROL` / `PLAINE` wordmark (18px, 400, 0.30em, drag handle), then 13 tabs (10px semibold, 0.25em, 3px padding; inactive 50% alpha; active 100% with a 2px accent bar on the left). Tab list order: GENERAL, DAY-DATE, POWER, UPTIME, VOLUME, RECYCLE BIN, PLAYNITE, MEDIA, WI-FI, FAN CONTROL, SIGNALRGB, DEEPCOOL, CONTROLLERS.
- Footer: `VERSION #Version#`, `OPEN ON GITHUB` (link style, opens `#RepoURL#`).
- Close: a small x top-right (`!DeactivateConfig`). No Esc key (would need HotKey plugin; not worth it).
- First open: the layout carries `[Control-Plaine\Settings] Active=0 WindowX=50% WindowY=50% AnchorX=50% AnchorY=50%` so it opens centred on the primary monitor; afterwards it remembers where it was dragged.

### 7.3 Controls (Controls.inc styles + Settings.lua calls)
Row = label (11px semibold 0.25em) over description (12px, 55% alpha, sentence case so no StringCase) on the left, control right-aligned. Row height 52 at scale 1.

| Control | Look (canvas) | Input | Lua call |
|---|---|---|---|
| Toggle | pill 30x16 r8; off fill `#Ink#,46` knob left; on fill accent knob right; knob 12px white | click | `Toggle('Key','Targets')` |
| Choice | words 10px semibold 0.2em; selected 100% with 1px accent underline; others 45% | click a word | `Set('Key','value','Targets')` |
| Value box | 16px light in a 1px `#Ink#,77` box r6 | scroll up/down | `Step('Key',delta,min,max,'Targets')` |
| Path box | 12px in a box r6, ellipsis when long | click opens InputText over the box | `EditPath('Key','Targets')` |
| Skin toggle (General) | toggle beside each skin name | click | `SkinOn('Volume')` |

`Targets` = which configs to refresh after a write: a skin folder name, a comma list, `all` (`!RefreshGroup ControlPlaine`) or `none`.

### 7.4 Settings.lua behaviour
- `Set/Toggle`: `!WriteKeyValue Variables Key Value "#@#User.inc"`, `!SetVariable` locally, redraw the row, refresh Targets. Settings pages show values from the same variables, so the page is always truthful after a refresh.
- `Step` (scroll): change the variable and the shown value immediately, then restart a debounce ActionTimer (`Wait 600 | Commit`); `Commit()` writes all pending keys once and refreshes Targets once. Avoids a refresh per scroll notch.
- `EditPath`: `!SetOption mInput DefaultValue "<current>"`, then `ExecuteBatch 1`; InputText command `[!CommandMeasure mSettings "Set('Key', [[$UserInput$]], 'Targets')"]` (Lua long string, so quotes or backslashes in paths are safe).
- `SkinOn(name)`: `!ActivateConfig "#ROOTCONFIG#\<name>" "<name>.ini"` or `!DeactivateConfig "#ROOTCONFIG#\<name>"`. Current on/off state: Lua reads `#SETTINGSPATH#Rainmeter.ini` (UTF-16 LE: strip NUL bytes, find `[Control-Plaine\<name>]` then `Active=`; Active is the variant index, 0 = off).
- Lock positions: `!DraggableGroup` as in 4.4, plus write `LockPositions`.
- Scale or RestBrightness or accent change: Targets `all`, then refresh Settings itself.
- Values never contain `#`; colours are stored `R,G,B`. Custom accent is entered through InputText as `R,G,B` or hex `00E5FF` (Lua converts hex).

### 7.5 GENERAL tab (foundation builds)
SKINS toggles (12), SCALE value box 50-300% step 10, ACCENT choice WINDOWS/CUSTOM (custom shows a swatch, click to edit), BRIGHTNESS AT REST value box 30-90% step 5, HIDE IN FULL SCREEN toggle, LOCK POSITIONS toggle.

### 7.6 Per-skin tabs (skin threads build; foundation commits stubs)
Rows are defined in DESIGN-V1.md and the canvas. Keys are prefixed with the skin folder name, booleans are 0/1, enums are lowercase words, durations in minutes, percentages as integers. Agreed names so the threads match:

| Tab | Keys (default) |
|---|---|
| DayDate | `DayDateClock` 12, `DayDateWeek` 1, `DayDateAlign` right |
| Power | `PowerFirst` hibernate, `PowerConfirm` 1, `PowerPickerStart` 60 |
| Uptime | `UptimeWarnDays` 5, `UptimeAlways` 0 |
| Volume | `VolumeStep` 2, `VolumeScrollUnmutes` 1, `VolumeRingStroke` 5 |
| RecycleBin | `RecycleBinShowSize` 1, `RecycleBinConfirm` 1 |
| Playnite | `PlaynitePath`, `PlayniteSkipSplash` 0 |
| Media | `MediaHideIdle` 1, `MediaSource` any, `MediaScrollTitles` 0 |
| WiFi | `WiFiClick` settings, `WiFiSpeedtestPath`, `WiFiNameRest` 50 |
| FanControl | `FanControlPath`, `FanControlNormal` userConfig.json, `FanControlMax` Max.json, `FanControlSensor` lhm |
| SignalRGB | `SignalRGBPath`, `SignalRGBStep` 5 |
| DeepCool | `DeepCoolPath`, `DeepCoolProcess` DeepCool.exe, `DeepCoolStartHidden` 1 |
| Controllers | `ControllersBatteryShow` 50, `ControllersDualSenseApp`, `ControllersWheelApp`, `ControllersOther` ms-settings:bluetooth |

A skin thread may add keys (same prefix, in its own `Defaults.inc` and page). Runtime state such as Power's scheduled time goes in `State.inc` (`PowerScheduledAt`), not `User.inc`.

Migration: the v1 `User.inc` has `PlaynitePath`, `TimeFormat`, `VolumeStep`, `UptimeWarnDays`. `TimeFormat` is replaced by `DayDateClock`; others keep their names. `User.example.inc` is removed; `install.ps1` creates empty `User.inc` and `State.inc`.

## 8. Lint additions (tools/lint.py)

Every skin `.ini` (not Settings pages): has `Group=ControlPlaine`, the ContextTitle/ContextAction pair, includes Theme, Defaults, User, Core, Styles in that order; no raw `R,G,B` colour literals in meters other than `0,0,0,1`; no `!Show`/`!Hide` outside Core.inc. Every `#Key#` used in a Settings page exists in a Defaults file. ASCII only (existing).

## 9. Can't do / deviations from the design

1. Text shadow has no blur (Rainmeter hard shadow).
2. Rings and underlines have no shadow.
3. Medium 500 weight rendered as Semibold 600.
4. Settings changes apply by refreshing the affected skins (a brief redraw), not live. Scroll edits apply 0.6 s after the last notch.
5. Accent follows Windows within 5 s, not instantly.
6. "Hide in full screen" hides on all monitors whenever the foreground app is full screen, including when it is on another monitor (IsFullScreen is foreground-based).
7. Settings has no Esc-to-close.

Nothing in the foundation or the Settings skin is blocked.

## 10. Check on Vishnu's PC before calling the foundation done

1. Done (PC probe): Rainmeter 4.5.26, ActionTimer/InputText/RunCommand bundled. Segoe UI Variable installed. Accent `0xFF9B9E00` gives 0,158,155 (`#009E9B`).
2. PC probe: IsFullScreen is only in @Vault, not in `%APPDATA%\Rainmeter\Plugins`; `install.ps1` copies the 64-bit DLL there. Then check it loads (no log error), returns 1 in a full-screen game and borderless-full-screen video, 0 on the desktop.
3. `HKCU\Software\Microsoft\Windows\DWM\AccentColor` exists and the computed R,G,B matches his cyan.
4. Windows 11 with **Segoe UI Variable** installed (else set `FontFace=Segoe UI`), and FontWeight 300/600 render distinctly.
5. Display scaling per monitor (which monitor the skins sit on, at what %), to pick the default `Scale`.
6. Colour options accept formulas in the alpha slot (`#Ink#,(60*2.55)`). If not, Core computes alphas into variables at refresh.
7. `!WriteKeyValue` into `#@#User.inc` works through the Skins junction to `T:\Development Space\Control-Plaine` and creates the file if missing; `@include` of a missing file is harmless.
8. `!ActivateConfig` between Settings variants keeps position; activating the already-open variant does not toggle it off.
9. Where "Control-Plaine settings" appears in the right-click menu (top level vs "Custom skin actions").
10. Lua can open and parse the UTF-16 `Rainmeter.ini` for skin on/off state.
