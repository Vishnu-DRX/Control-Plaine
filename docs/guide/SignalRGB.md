# SignalRGB

Case lights brightness and a move effect, through SignalRGB.

*Draft.* Behaviour was read from `SignalRGB/SignalRGB.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** The SignalRGB logo (accent while the lights are on).
- **On hover:** The label and brightness (default "Case lights 40%") and a double arrow.

## Actions

- Scroll anywhere on the skin: brightness by `SignalRGBStep`, down to OFF.
- Click the arrow: start `SignalRGBMoveEffect`. Click the logo: open SignalRGB.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `SignalRGBTooltips` (the TOOLTIPS row on this skin's page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `SignalRGB/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `SignalRGBPath` | `auto` | What the logo opens: `auto` (the launcher, found through its `signalrgb://` registration), a program path or a link. |
| `SignalRGBStep` | `5` | Brightness change per scroll notch (%). |
| `SignalRGBApi` | `auto` | `auto` uses the local API when it answers (Pro), else just opens the app. 0 = never use the API. |
| `SignalRGBPort` | `16038` | Port of SignalRGB's local API. |
| `SignalRGBEffect` | `Solid Color` | Free mode: the effect brightness is applied to (needs a `color` property). Empty = launcher only. |
| `SignalRGBColor` | `00AE57` | Free mode: full-brightness colour, six hex digits, no #. Set it to the colour you use in SignalRGB. |
| `SignalRGBLabel` | `Case lights` | Text before the percentage. |
| `SignalRGBMoveEffect` | `Side to Side` | Effect the double arrow starts (empty hides the arrow). |
| `SignalRGBMoveParams` | `direction=All%20Directions&color1=...` | Link parameters for it (`#` is `%23`, a space is `%20`). See the file for the full default. |

## Requirements

SignalRGB 2.5. Pro uses the local API and shows the real state; the free tier applies an effect through the `signalrgb://effect/apply` link.

## Known limits

The free tier cannot be read back: the number is what the skin last sent. SignalRGB's window is hidden again right away; its tray icon stays.
