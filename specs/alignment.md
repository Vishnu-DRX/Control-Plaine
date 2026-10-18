# Alignment and details: how skins arrange themselves

Status: built in WP0 (alignment foundation) with SignalRGB as the reference skin. The plan is `plans/alignment-settings-icon-plan.md` in the project folder; where the build differs, the code comments win. Rainmeter behaviour that only the PC can prove is marked **[PC]**.

## 1. What a skin gets

Every skin that opts in has two settings and two global overrides:

| Key | Values | Default | Meaning |
| --- | --- | --- | --- |
| `<Skin>Align` | `left`, `right` | `left` | `left`: icon first, text after it. `right`: the mirror image inside the same box, text first, icon last. |
| `<Skin>Details` | `hover`, `always` | `hover` | `hover`: the hover-only text and meters show while the mouse is over the skin. `always`: they stay visible. |
| `AlignAll` | `skin`, `left`, `right` | `skin` | `skin`: each skin uses its own `<Skin>Align`. `left` or `right` forces every aligned skin. |
| `DetailsAll` | `skin`, `hover`, `always` | `skin` | Same idea for details. |

Only the arrangement inside the skin's box changes. The window never moves, resizes or re-anchors, and the hit area is identical on both sides. A skin that is dragged to the other screen edge is the user's choice; no code repositions it.

## 2. Opting a skin in

1. **Defaults.** In `<Skin>/Defaults.inc`: `<Skin>Align=left` and `<Skin>Details=hover`.
2. **Skin variables.** In the skin's `[Variables]`, after `State.inc` and before `Core.inc`:
   ```
   SkinSide=#<Skin>Align#
   SkinDetails=#<Skin>Details#
   ```
   After `Core.inc` and `Sz=...`, define the fixed box: `BoxW=(Round(<current Hit width>*#Sz#))`.
3. **Settings page.** Before the page's own rows, set the keys and include the shared rows (ALIGN sits at Y=52 and DETAILS at Y=116, each 64 high, so the page's own rows start at Y=180; a page that runs out of room uses a pitch of 52 or one-line rows, and `tools/lint.py` fails rows that overlap or leave the panel):
   ```
   AlignKey=<Skin>Align
   DetailsKey=<Skin>Details
   @include9=#@#Settings\Align.inc
   ```
4. **Meters.** Use only the helpers in section 3, never a private mirror map. Lint (`tools/lint.py`) fails a skin that sets `SkinSide` and has a missing key or default, a missing Settings include, a literal `StringAlign`, or its own `Anchor`, `Lead`, `Trail`, `Mir` or `Side` variables.

## 3. Helpers

`Scripts\Core.lua` (the `mCore` measure in `Core.inc`) reads `SkinSide`, `AlignAll`, `SkinDetails`, `DetailsAll` and `HoverAccent` once when the skin loads and sets these variables, so every skin uses the same resolution:

| Variable | left | right | Use |
| --- | --- | --- | --- |
| `Side` | `left` | `right` | the resolved side |
| `Mir` | `0` | `1` | arithmetic: `X=(#Mir#*rightX+(1-#Mir#)*leftX)` |
| `TA` | `LeftCenter` | `RightCenter` | `StringAlign=#TA#` (vertically centred text) |
| `TAT` | `Left` | `Right` | `StringAlign=#TAT#` (top-aligned text) |
| `Lead` / `Trail` | `0` / `1` | `1` / `0` | `InlineSetting=CharacterSpacing | (#Lead#*t) | (#Trail#*t)`: tracking on one side only, so right-aligned text puts it before the letter |
| `RevealMin` | `0` | `1` when details are `always` | the level `#Reveal#` rests at; `mFade`'s fade-out stops here |
| `HoverTint` | | | colour of a hovered icon: `#Accent#`, or `#Ink#` when `HoverAccent=0`. Kept current as the Windows accent changes. |

Meters that use them need `DynamicVariables=1` (every `Styles.inc` style has it). A bad value in `User.inc` falls back to `left` / `hover` / accent; it never errors.

`Core.inc` carries placeholders (`Side=left`, `Mir=0`, ...) so a skin that does not opt in, and the first read before the script runs, are valid.

## 4. Layout recipe

Every aligned skin keeps one fixed box `BoxW`, in whole pixels, and places everything from the box edges. Left and right use the same box and the same Hit meter.

**Icon-first rows** (SignalRGB, DeepCool, FanControl, WiFi, Controllers, Playnite, SettingsButton). With `IW = IconBox*Sz`:
- Icon: `X=(#Mir#*Round(#BoxW#-#IconBox#*#Sz#))`
- Text: `X=(#Mir#*Round(#BoxW#-(#IconBox#+4)*#Sz#)+(1-#Mir#)*(#IconBox#+4)*#Sz#)`, `StringAlign=#TA#`
- Trailing extras on the inner side of the text (arrow, bulb, snowflake, gauge, spinner): left `X=[Ref:XW]+gap`; right `X=Round(textAnchor-[Ref:W]-gap-ownW)`, where `Ref` is the invisible widest-text meter that reserves the space. Using `W` and the anchor, not `[Ref:X]`, so nothing depends on how Rainmeter reports the X of right-aligned text.
- The left branch is written without `Round`, exactly as before, so a skin that was drawn left looks the same. Only right-anchored values are rounded: a fractional text X is what makes text soft.

**Text-only** (Uptime): same box, `StringAlign` and tracking swap.
**Ring skins** (Volume, Media, RecycleBin): left puts the ring at X=0 and the text after it; every X becomes `Mir ? mirrored : old`, where the mirror of `x` of width `w` is `BoxW-x-w`.

The SignalRGB skin (`SignalRGB/SignalRGB.ini`, `Settings/SignalRGB.ini`) is the worked example.

## 5. SignalRGB, checked by hand

`python tools/test_core.py` evaluates the formulas in `SignalRGB.ini` for both sides at 100, 125 and 150% Scale (SignalRGB also applies `SizeBoost` 1.25) and asserts: same box and hit width on both sides; icon, text anchor and arrow inside the box; every right-anchored value on a whole pixel; the right layout the mirror image of the left to within a pixel of rounding. The arrow width is taken from an estimated text width, since the real one needs Rainmeter.

| scale | side | box W | hit W | icon X | text anchor X | arrow X |
| --- | --- | --- | --- | --- | --- | --- |
| 100% | left | 288 | 288 | 0 | 45 | 187 |
| 100% | right | 288 | 288 | 248 | 243 | 71 |
| 125% | left | 359 | 359 | 0 | 56.25 | 233.75 |
| 125% | right | 359 | 359 | 309 | 303 | 88 |
| 150% | left | 431 | 431 | 0 | 67.5 | 280.5 |
| 150% | right | 431 | 431 | 371 | 364 | 106 |

(Box, hit, icon, text anchor and arrow X in pixels. The text anchor is the left edge of the text on the left and the right edge on the right.)

The same script runs `Core.lua` against a fake `SKIN` for every combination of the four settings plus `HoverAccent`, including garbage values.

## 6. What only the PC can show [PC]

1. The meters resolve `#Mir#`, `#TA#`, `#Lead#` and `#Trail#` after `Core.lua` sets them (script `Initialize` runs before the meters first read their options).
2. A flip changes only the arrangement: same hit area, no window resize, same vertical position.
3. Text and icons are as sharp on the right as on the left, at Scale 1.0 and 1.25.
4. `AlignAll=left` / `right` / `skin` and `DetailsAll=hover` / `always` / `skin` behave as in section 1, and a per-skin change made afterwards still works.
5. `Details=always`: no flicker on hover in and out. In this build `always` shows the hover-only text at hover brightness, since `Reveal` rests at 1; if a dimmer resting level is wanted, `RevealMin` can become fractional.
6. The arrow's `[RefValue:W]` equals the visible width of the text with its tracking.
