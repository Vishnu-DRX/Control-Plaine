# Spec: Day-Date, Recycle Bin and Playnite skins

Investigation output for the V1 build. Source of truth for behaviour and look: `docs/DESIGN-V1.md` and the V1 canvas boards `DayDate`, `RecycleBin`, `Playnite`, `Type`. This file says **how** to build each skin in Rainmeter, what differs from v1.0.0 in the repo, and what must be checked on Vishnu's PC.

Shared conventions (User.inc keys, Theme tokens, accent from the registry, full-screen hide, right-click menu, Settings refresh) belong to `specs/foundation-settings.md`. It did not exist when this was written; where this spec names a key or token that the foundation spec defines differently, the foundation spec wins. Format follows `specs/power-uptime.md`.

## Verdict

All three are achievable with stock Rainmeter: Time measures, the bundled RecycleManager plugin, ActionTimer (already in `Fade.inc`), and one small Lua script for the Recycle Bin text. No third-party plugin.

Nothing is impossible. Three things change or need a decision:

1. **The Playnite controller PNG is not in the repo.** `@Resources/Icons/gamepad.png` is a Lucide render, not the old white controller. Copy `Skins\Playnite launcher\white-controller-icon.png` (764x511, mirrored at `/mnt/project-files/Rainmeter/Skins/Playnite launcher/`) to `@Resources/Icons/playnite-controller.png` and delete `gamepad.png`.
2. **Recycle Bin needs two trash icons, not one.** The canvas draws the empty state without the two inner lines. Render `docs/icons/trash.svg` as `trash-full.png` and a copy without `M10 11v6M14 11v6` as `trash-empty.png`; drop `bin-empty.png` / `bin-full.png`.
3. **"FILES" is really items.** RecycleManager counts top-level items, so a deleted folder with 500 files counts as 1. The label stays `FILES` as designed; this is noted in the skin header.

## Shared notes for these three skins (for the foundation spec to confirm)

- **Font size is in points.** Rainmeter `FontSize` is pt, the design is px at 96 DPI: `FontSize = px * 0.75 * #Scale#`. So 52 px is `39`, 13 px is `9.75`, 9 px is `6.75`. Verify by eye against the canvas at 100%.
- **Tracking.** `InlineSetting=CharacterSpacing | 0 | T` with `T = em * px * #Scale#` (0.30em at 52 px is 15.6). It adds T after the last letter too, so right-aligned text shifts T left. Shift the meter's X right by T, exactly as the canvas does with `margin-right: -0.3em`.
- **Weights.** `FontWeight=300/400/600`. Segoe UI and Segoe UI Variable have no 500 (Medium). Map design "Medium 500" to a token (`WeightMedium`) and pick 400 or 600 on the PC by eye; default 600.
- **Text shadow.** `InlineSetting2=Shadow | 0 | (1*#Scale#) | (3*#Scale#) | 0,0,0,115` on every String meter. Icons: no runtime shadow in Rainmeter; bake a soft shadow into the PNG at render time, or skip (design says all icons, so bake it).
- **Brightness tokens.** Values 80% (204), details/icons 60% (153), hover 95 to 100% (242 to 255). Every alpha is `Rest + (Hover - Rest) * #Reveal#` driven by `Fade.inc`.
- **Nothing moves on hover.** Revealed meters are always laid out and only fade (alpha 0 at rest), so `DynamicWindowSize` never changes the skin size on hover. Keep that pattern.
- **Hit area.** A background `Meter=Image` with `SolidColor=0,0,0,1` sized to the skin, first in the file, so the whole box (not just glyph pixels) counts as hover.
- **Right-click.** `ContextTitle=Control-Plaine settings`, `ContextAction=[!ActivateConfig "Control-Plaine\Settings"]` (foundation decides the exact bang, for example opening a tab).
- **Theme.inc today still has `FontDisplay=Anurati` and `Accent=0,250,200`.** The design says Segoe UI only and the Windows accent. Foundation owns that change; these skins just use `#FontUI#` / `#FontDisplay#` / `#Accent#`.

## Day-Date

### Files
- `DayDate/DayDate.ini` (rewrite). No script.

### Layout (canvas board DayDate)
```
                 SATURDAY        Display  400  52 px  0.30em  80% rest / 100% hover
        10  OCTOBER  2026        Title    500  13 px  0.45em  80% / 95%
      8:21 PM     WEEK 41        Detail   500   9 px  0.30em  0% / 65%   (hover only)
```
Gaps: 10 px day to date, 10 + 4 px date to detail. All lines share one right edge (or left edge when aligned left).

### Measures
- `mDay`: `Measure=Time`, `Format=%A`. Uppercase via `StringCase=Upper`.
- `mDate`: `Format=%#d  %B  %Y` (two spaces each, as designed).
- `mTime`: `Format=#TimeFormat#`. Settings writes `%#I:%M %p` (12 h) or `%H:%M` (24 h).
- `mWeek`: `Format=%V` (ISO week). If `%V` renders empty or literally on the PC, fall back to a 10-line Lua ISO-week calculation; see check 2.
- Skin `Update=1000` is fine (cheap). The detail line is 9 px, so seconds are not shown.

### Fixed edge so the skin does not shift each day
`MONDAY` and `WEDNESDAY` differ by ~150 px. If the right edge followed the text, the skin would jump every midnight. Instead:
- `[RefWidth]` hidden String meter in the Display style with `Text=#DayRef#` (default `WEDNESDAY`, the widest English day). Hidden meters still report `[RefWidth:W]`.
- All three lines: `X=(#DDAnchor# * ([RefWidth:W] + T))` where `T` is that line's trailing tracking, `StringAlign=#DDAlign#`, `DynamicVariables=1`.
- `DDAlign=Right` with `DDAnchor=1`, or `DDAlign=Left` with `DDAnchor=0` (left needs no tracking shift). Settings writes both keys together.
- Background hit meter: `W=([RefWidth:W])`, height to the bottom of the detail line.

### Hover
- Existing `Fade.inc` + `sReveal` pattern. Day and date use `#Reveal#` to go from 80% to 100%/95%; detail goes 0 to 65%.
- Week hidden setting: `DDShowWeek=0` swaps the detail `Text` from `%1     WEEK %2` to `%1` (two `Text` variables, chosen by Settings writing `DDDetailText`). Rainmeter has no string `if` in options, so Settings writes the finished text rather than a flag. Alternative: two meters and `Hidden=(1-#DDShowWeek#)` with `DynamicVariables=1`; either is fine.

### Settings (User.inc keys, names to match the foundation spec)
- `TimeFormat=%#I:%M %p` (already in User.example.inc; 24 h writes `%H:%M`)
- `DDShowWeek=1`
- `DDAlign=Right`, `DDAnchor=1`
- `DayRef=WEDNESDAY` stays a skin variable (only change for another language).

### Change from v1.0.0
Font Anurati to Segoe UI 400; sizes and tracking to the design; `Right=805` constant replaced by the reference-width edge; Settings keys added; text shadow added; brightness tokens.

## Recycle Bin

### Files
- `RecycleBin/RecycleBin.ini` (rewrite).
- `@Resources/Scripts/RecycleBin.lua` (new, formats the detail line and switches state).
- `@Resources/Icons/trash-full.png`, `trash-empty.png` (see Verdict 2; 1x/2x/3x like the other icons, displayed at 36 px x Scale).

### Layout (canvas board RecycleBin)
```
     RECYCLE BIN   [trash]    Title  500  12 px  0.35em  80% / 95%
35 FILES   3.2 GB  [ icon ]   Detail 500   9 px  0.25em  60% / 80%
      OPEN   EMPTY            Link   600   9 px  0.30em  0% / 90%, 1 px accent underline (hover only)
```
- Text column right-aligned at `X=[RefText:W]`. `[RefText]` is a hidden Detail-style meter with `Text=0000 FILES   000.0 GB`, so the column (and the icon) never moves as numbers change. Use `Max([RefText:W],[Title:W])`.
- Icon at `X=(Max([RefText:W],[Title:W]) + 14*#Scale#)`, 36 px x Scale, vertically centred on the title + detail block only (not the links), so revealing links moves nothing.
- Links: OPEN and EMPTY right-aligned under the detail line, 16 px apart, 4 px below. Underline is a `Meter=Shape` `Rectangle 0,0,W,1` per link with `Fill Color #Accent#,(255*#Reveal#*0.9)`, `W=([OpenLink:W] - T)`, 2 px under the text.

### Data
- `mCount`: `Measure=Plugin`, `Plugin=RecycleManager`, `RecycleType=Count`, `Drives=ALL`, `UpdateDivider=3`.
- `mSize`: same with `RecycleType=Size` (bytes).
- `mScript`: `Measure=Script`, `ScriptFile=#@#Scripts\RecycleBin.lua`, same divider. No `IfCondition`s (they only fire on change, the bug Uptime hit).

`RecycleBin.lua` `Update()` every run:
- `n = count`, `b = size`.
- `n == 0`: detail `EMPTY`, icon `trash-empty.png`, hide EMPTY link meters (`!HideMeter`), keep OPEN.
- `n > 0`: detail `N FILES` (`1 FILE` when 1), plus `   ` and the size when `RBShowSize=1`. Size: 1024-based, units `B KB MB GB TB`, one decimal under 100 (`3.2 GB`, `48.6 MB`), none from 100 (`412 MB`). Icon `trash-full.png`, show EMPTY link.
- Sets text with `!SetOption Detail Text "..."` and redraws only when the string or state changed.

### Actions
- OPEN: `[!CommandMeasure mCount "OpenBin"]`.
- EMPTY: `[!CommandMeasure mCount "#RBEmptyCmd#"]`. Settings writes `RBEmptyCmd=EmptyBin` (Windows asks to confirm, the default) or `EmptyBinSilent`. Then `[!UpdateMeasure mCount][!UpdateMeasure mSize][!UpdateMeasure mScript]` so the line flips to EMPTY without waiting for the poll.
- Clicking the icon also opens the bin (v1.0.0 behaviour kept; costs nothing, not on the canvas).

### Settings
- `RBShowSize=1`
- `RBEmptyCmd=EmptyBin` (Settings shows it as "ask before emptying" on/off)

### Change from v1.0.0
v1.0.0 hides count/size until hover and has no title. V1 shows `RECYCLE BIN` and the count/size always, links on hover, new icons, Lua text instead of IfConditions, accent underlines.

## Playnite

### Files
- `Playnite/Playnite.ini` (rewrite).
- `@Resources/Icons/playnite-controller.png` (copied original, see Verdict 1).

### Layout (canvas board Playnite)
```
[controller]  PLAYNITE        icon 49x34 px, 60% rest / 100% hover; label Link style 600 9 px 0.30em, 0% / 85%
```
- Icon: `W=(49*#Scale#)`, `H=(34*#Scale#)`, `PreserveAspectRatio=1`. Source is 764 px wide, so it stays sharp at 250%.
- Label: `X=(14*#Scale#)R`, vertically centred on the icon (`StringAlign=LeftCenter`), alpha 0 at rest.
- Hit meter covers icon + label, so hovering the empty label area still counts.

### Action
- Icon and label: `LeftMouseUpAction=["#PlaynitePath#" #PlayniteArgs#]`.
- `PlayniteArgs=--hidesplashscreen` when skip splash is on, empty when off. (Old skin used deprecated `!Execute`; drop it.)

### Settings
- `PlaynitePath` (already in User.inc). Settings sets it with InputText.
- `PlayniteSkipSplash=1`, which Settings turns into `PlayniteArgs`.

### Change from v1.0.0
Original controller PNG instead of Lucide gamepad, label `PLAYNITE` in caps with tracking, design brightness tokens, args variable.

## Skin header comments (all three)
- Day-Date: what it shows, the three settings, that `DayRef` is the widest day name for the fixed edge (change it for another language).
- Recycle Bin: counts are top-level items across all drives (RecycleManager), the two settings, EMPTY uses Windows' own confirm unless `EmptyBinSilent`.
- Playnite: designed for Playnite (playnite.link); repoint `PlaynitePath`/`PlayniteArgs` to launch any other app.

## Limits
1. Day names in other languages can be wider than `WEDNESDAY`; the user changes `DayRef`.
2. Recycle Bin count is items, not files (see Verdict 3).
3. Icon shadow is baked into the PNG, so it does not scale its blur with `Scale` exactly. Not visible in practice.

## Check on Vishnu's PC before calling these done
1. Font sizes at `px * 0.75` match the canvas at 100% scale, and `FontWeight=600` vs `400` for the "Medium" lines (pick by eye; report to foundation).
2. `Format=%V` shows `41` on 10 Oct 2026 (Rainmeter's Time measure uses the CRT's `wcsftime`, which supports it, and v1.0.0 already uses it; confirm it renders).
3. Day-Date right edge stays put across a day change (set the clock or temporarily set `DayRef` and the day format to test) and with align left.
4. RecycleManager `Drives=ALL` updates within ~3 s of deleting a file on C: and on a second drive (T:), and does not stall Rainmeter if a removable or network drive is present.
5. `EmptyBin` shows the Windows confirm; `EmptyBinSilent` empties with no dialog; the line flips to `EMPTY` right after.
6. Playnite: the `["path" --hidesplashscreen]` action starts Playnite without the splash; clicking again while Playnite runs focuses the existing window rather than erroring.
7. Text shadow `InlineSetting=Shadow` renders (needs Rainmeter 4.0+ with D2D; confirm Rainmeter version in About).
8. All three look right at Scale 2.5 (icons from 3x PNGs, underline 1 px x Scale, no clipped tracking on the right edge).
