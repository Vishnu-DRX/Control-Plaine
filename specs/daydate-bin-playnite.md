# Spec: Day-Date, Recycle Bin and Playnite skins

Investigation output for the V1 build. Look and behaviour: `docs/DESIGN-V1.md` and the V1 canvas boards `DayDate`, `RecycleBin`, `Playnite`. Conventions: `specs/foundation-settings.md` (template, tokens, styles, keys, Settings pages); this spec follows it and only says what is specific to these three skins. Where they disagree, the foundation spec wins.

## Verdict

All three are achievable with stock Rainmeter: Time measures, the bundled RecycleManager plugin, the shared Core.inc fade, and one small Lua script for the Recycle Bin. No third-party plugin, nothing blocked.

Three things the build must handle:

1. **Playnite's controller PNG is not in the repo.** Foundation 6 says `gamepad.png` is "Playnite's original art". It is not: it is a 96x96 Lucide render from v1.0.0. The original is `Skins\Playnite launcher\white-controller-icon.png` (764x511, mirrored at `/mnt/project-files/Rainmeter/Skins/Playnite launcher/`). This thread **adds** it as `@Resources/Icons/playnite-controller.png` (skin threads may add icons). Integration can delete `gamepad.png`.
2. **Recycle Bin needs an empty-bin icon.** The canvas draws the empty state as the trash without its two inner lines. This thread adds `docs/icons/trash-empty.svg` (trash.svg minus `M10 11v6M14 11v6`) and renders it with `tools/render-icons.py` to `@Resources/Icons/trash-empty.png`. Full state uses foundation's `trash.png`.
3. **"FILES" is really items.** RecycleManager counts top-level items, so a deleted folder counts as 1. The label stays `FILES` as designed; the header comment says so.

## Common to all three

- Exact skin template from foundation 2, `Version=2.0.0`, `ContextAction` opening `DayDate.ini` / `RecycleBin.ini` / `Playnite.ini`.
- Each skin gets `<Skin>\Defaults.inc` with its keys (below) and fills its stub `Settings\<Skin>.ini` page using Controls.inc styles and `Settings.lua` calls. Settings Targets = the skin's own folder name.
- Text uses the shared styles (`sDisplay`, `sTitle`, `sDetail`, `sReveal`, `sLink`, `sLinkLine`, `sHit`). Shadow comes from the styles (`StringEffect=Shadow`); no per-skin shadow.
- Right-aligned text uses CharacterSpacing trailing `0` (foundation 3), so all right edges line up without X shifts.
- A `sHit` backing meter first in each skin covers the whole box so gaps count as hover. Revealed meters always stay laid out at alpha 0, so the skin size never changes on hover.
- No `!Show`/`!Hide`; none of these skins self-hide.

## Day-Date

### Files
- `DayDate/DayDate.ini` (rewrite), `DayDate/Defaults.inc`, `Settings/DayDate.ini` (page). No script.

### Layout (canvas board DayDate)
```
                 SATURDAY        sDisplay   (52 px, 400, 0.30em)  AlphaValue -> Hover
        10  OCTOBER  2026        sTitle     (13 px design; token is 12.5 px)
      8:21 PM     WEEK 41        sReveal    (Detail type), alpha 0 -> Hover
```
Gaps at scale 1: 10 px day to date, 14 px date to detail.

Note: the canvas date line is 13 px with 0.45em tracking; the `sTitle` token is 12.5 px / 5 px tracking. Use the token (difference is not visible); do not add a local override.

### Measures
- `mDay` `Format=%A`, `mDate` `Format=%#d  %B  %Y` (two spaces each). Uppercase from the styles.
- `mTime12` `Format=%#I:%M %p`, `mTime24` `Format=%H:%M`, `mWeek` `Format=%V`.
- The detail meter uses `MeasureName=mTime#DayDateClock#`, so `DayDateClock` 12 or 24 picks the measure with no script.

### Week on/off
Two detail meters on the same spot:
- `[DetailWeek]` `MeasureName=mTime#DayDateClock#`, `MeasureName2=mWeek`, `Text=%1     WEEK %2`, `Hidden=(1-#DayDateWeek#)`.
- `[DetailTime]` same time measure, `Text=%1`, `Hidden=#DayDateWeek#`.

### Fixed edge and alignment
`MONDAY` vs `WEDNESDAY` differ by about 150 px, so the right edge must not follow the text or the skin jumps at midnight.
- `[RefDay]` `MeterStyle=sDisplay`, `Text=#DayRef#` (skin-local `DayRef=WEDNESDAY`), `Hidden=1`. Hidden meters still report `[RefDay:W]`.
- Skin-local `AnchorRight=1`, `AnchorLeft=0`.
- Every text meter: `StringAlign=#DayDateAlign#`, `X=([#Anchor[#DayDateAlign]]*[RefDay:W])`, `DynamicVariables=1` (nested-variable syntax, Rainmeter 4.1+). Key values are `right` / `left`.
- Tracking follows foundation: trailing 0 when right-aligned, trailing = tracking when left. If Styles.inc does not already switch this, override locally with `InlineSetting=CharacterSpacing | t | ([#Trail[#DayDateAlign]]*t)`, skin-local `Trailright=0`, `Trailleft=1`.
- `sHit` backing: `W=[RefDay:W]`, `H` to the bottom of the detail line.

### Defaults.inc
```ini
[Variables]
; 12 or 24
DayDateClock=12
; 1 shows WEEK nn on hover
DayDateWeek=1
; right or left
DayDateAlign=right
```

### Settings page
CLOCK choice `12 H` / `24 H`; WEEK NUMBER toggle; ALIGN choice `LEFT` / `RIGHT`.

### Change from v1.0.0
Anurati to Segoe UI; design sizes and tracking; constant `Right=805` replaced by the reference-width edge; `TimeFormat` replaced by `DayDateClock`; week and align settings; foundation template and styles.

## Recycle Bin

### Files
- `RecycleBin/RecycleBin.ini` (rewrite), `RecycleBin/Defaults.inc`, `Settings/RecycleBin.ini` (page).
- `@Resources/Scripts/RecycleBin.lua` (new).
- `docs/icons/trash-empty.svg` + rendered `@Resources/Icons/trash-empty.png` (Verdict 2).

### Layout (canvas board RecycleBin)
```
     RECYCLE BIN   [trash]    sTitle   AlphaValue -> Hover
35 FILES   3.2 GB             sDetail  AlphaDetail -> Hover
      OPEN   EMPTY            sLink + sLinkLine (accent underline), hover only
```
- Text column right-aligned at `X=[RefText:W]`. `[RefText]` is a hidden `sDetail` meter with `Text=0000 FILES   000.0 GB`; the column is `Max([RefText:W],[Title:W])` wide so the icon never moves as numbers change.
- Icon: 36 px visual on the canvas, so `W=H=(48*#Scale#)` (PNG box = visual / 0.75), placed `14*#Scale#` right of the column minus the baked pad (`6*#Scale#`), vertically centred on the title + detail lines only (not the links). `ImageTint=#Ink#`, `ImageAlpha` AlphaDetail -> Hover.
- Links right-aligned under the detail line, 16 px apart, 4 px below. Each has an `sLinkLine` underline.

### Data
- `mCount` `Measure=Plugin`, `Plugin=RecycleManager`, `RecycleType=Count`, `Drives=ALL`, `UpdateDivider=3`.
- `mSize` same with `RecycleType=Size` (bytes).
- `mScript` `Measure=Script`, `ScriptFile=#@#Scripts\RecycleBin.lua`, `UpdateDivider=3`. No IfConditions (they only fire on change).

`RecycleBin.lua`:
- `Update()` every run. `n == 0`: detail `EMPTY`, icon `trash-empty.png`, hide EMPTY link + its underline (`!HideMeter`), keep OPEN. `n > 0`: `N FILES` (`1 FILE`), plus `   ` and the size when `RecycleBinShowSize=1`; icon `trash.png`; show EMPTY. Size is 1024-based, units `B KB MB GB TB`, one decimal under 100 (`3.2 GB`), none from 100 (`412 MB`). Sets meters only when the string or state changed, then `!UpdateMeterGroup` and `!Redraw`.
- `Empty()`: `!CommandMeasure mCount "EmptyBin"` when `RecycleBinConfirm=1` (Windows confirm dialog), `"EmptyBinSilent"` when 0; then updates mCount, mSize and mScript so the line flips to EMPTY at once.

### Actions
- OPEN and the icon: `[!CommandMeasure mCount "OpenBin"]` (icon click kept from v1.0.0).
- EMPTY: `[!CommandMeasure mScript "Empty()"]`.

### Defaults.inc
```ini
[Variables]
; 1 adds the total size after the count
RecycleBinShowSize=1
; 1 = Windows asks before emptying
RecycleBinConfirm=1
```

### Settings page
SHOW SIZE toggle; ASK BEFORE EMPTYING toggle.

### Change from v1.0.0
Title and count/size always visible, links on hover, new icons, Lua instead of IfConditions, accent underlines, foundation template.

## Playnite

### Files
- `Playnite/Playnite.ini` (rewrite), `Playnite/Defaults.inc`, `Settings/Playnite.ini` (page).
- `@Resources/Icons/playnite-controller.png` (Verdict 1, copied unchanged).

### Layout (canvas board Playnite)
```
[controller]  PLAYNITE        icon 49x34 px; label sLink type without underline, hover only
```
- Icon: `W=(49*#Scale#)`, `H=(34*#Scale#)`, `PreserveAspectRatio=1`, `ImageAlpha` AlphaDetail -> Hover. Source is 764 px wide, sharp up to 300%. No baked shadow (original art); accepted.
- Label `X=(14*#Scale#)R`, `StringAlign=LeftCenter` on the icon's middle, `sReveal` alpha (85% canvas, use the token).
- `sHit` covers icon + label.

### Action
- Icon and label: `LeftMouseUpAction=["#PlaynitePath#" [#SplashArg[#PlayniteSkipSplash]]]` with skin-local `SplashArg1=--hidesplashscreen`, `SplashArg0=` and `DynamicVariables=1` on the meter.

### Defaults.inc
```ini
[Variables]
PlaynitePath=%LOCALAPPDATA%\Playnite\Playnite.DesktopApp.exe
; 1 starts Playnite without its splash screen
PlayniteSkipSplash=1
```
Default `PlayniteSkipSplash=1` (foundation table says 0) to keep what Vishnu's current skin does. Vishnu's `User.inc` already holds his full `PlaynitePath`.

### Settings page
PLAYNITE PATH path box; SKIP SPLASH SCREEN toggle.

### Change from v1.0.0
Original controller art instead of the Lucide gamepad, `PLAYNITE` label, skip-splash setting, foundation template.

## Header comments
- Day-Date: what it shows; the three settings; `DayRef` is the widest day name used for the fixed edge (change it for another language).
- Recycle Bin: counts top-level items on all drives (RecycleManager); the two settings.
- Playnite: designed for Playnite (playnite.link); point `PlaynitePath` at any other exe to launch something else.

## Limits
1. Day names in other languages can be wider than `WEDNESDAY`; change `DayRef`.
2. Recycle Bin count is items, not files.
3. Playnite icon has no shadow (original PNG).

## PC probe results (2026-10-11, `/mnt/project-files/Control-Plaine-probes.md`)
- Rainmeter 4.5.26, Segoe UI Variable installed: nested variables, FontWeight and the foundation styles are all available.
- Playnite exe confirmed at `C:\Users\Vishnu A\AppData\Local\Playnite\Playnite.DesktopApp.exe` (the `%LOCALAPPDATA%` default resolves to it; Vishnu's User.inc already holds it).
- Original icon confirmed: `Skins\Playnite launcher\white-controller-icon.png`, 764x511.
- Still open (visual): checks 1 to 7 below.

## Check on Vishnu's PC before calling these done
1. `%V` shows `41` on 10 Oct 2026 (v1.0.0 already uses it).
2. Day-Date right edge stays put across a day change and in left alignment; nested `[#Anchor[#DayDateAlign]]` resolves (Rainmeter 4.5).
3. RecycleManager `Drives=ALL` updates within about 3 s after deleting on C: and T:, and does not stall Rainmeter with a USB or network drive attached.
4. `EmptyBin` shows the Windows confirm, `EmptyBinSilent` does not, and the line flips to `EMPTY` right after.
5. `%LOCALAPPDATA%` in `PlaynitePath` expands when run from an action (fresh install default). Vishnu's own full path works either way.
6. Playnite starts without the splash, and clicking again while it runs focuses the open window.
7. All three look right at Scale 2.5.

## As built (v2.0.0)

- Tracking: DirectWrite adds CharacterSpacing leading **and** trailing to every letter, so leading = trailing = tracking would double the gap. These skins put the tracking on one side only: before each letter for right-aligned text (`| t | 0`), after each letter for left-aligned text (`| 0 | t`). Day-Date switches with `[#Lead[#DayDateAlign]]` / `[#Trail[#DayDateAlign]]`.
- Week on/off uses two detail meters with `Hidden=(1-#DayDateWeek#)` / `Hidden=#DayDateWeek#`.
- The reference meters (`RefDay`, `RefText`) are transparent, not `Hidden=1`, so their width is always measured.
- `PlayniteSkipSplash` defaults to 1 (Vishnu's old skin always skipped the splash).
- Icons added: `trash-empty.png` (from `docs/icons/trash-empty.svg`, rendered by `tools/render-icons.js`), `playnite-controller.png` (original art, unchanged).
- Feedback 2026-10-11 (Vishnu): the bin shows only the size (no file count), in Warn orange above `RecycleBinWarnGB` (default 10); EMPTY sits on the size line, left of the size, on hover. `RecycleBinShowSize` and its Settings row are gone (the size is now the whole line).
