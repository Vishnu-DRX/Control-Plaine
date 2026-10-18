# DeepCool

A switch for the DeepCool app that drives the case screen.

*Draft.* Behaviour was read from `DeepCool/DeepCool.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** The DeepCool logo: accent while the app runs, otherwise the ink colour (white or black, per COLOURS).
- **On hover:** CASE SCREEN (or DEEPCOOL) and a bulb. With `DeepCoolDetails=always` they stay visible.
- **Left or right:** `DeepCoolAlign=right` mirrors the skin inside the same box: label and bulb first, logo last. The skin never moves or resizes.

## Actions

- Click the logo, label or bulb: closed starts the app hidden in the tray; running closes it. STARTING / STOPPING TELEMETRY and a spinner show until the process list confirms.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `DeepCoolTooltips` (the TOOLTIPS row, one line on this page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `DeepCool/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `DeepCoolAlign` | `left` | `left`: logo first, text after it. `right`: the mirror image (text first, logo last). The global AlignAll can override it. |
| `DeepCoolDetails` | `hover` | `hover`: label and bulb show while hovered. `always`: they stay visible. The global DetailsAll can override it. |
| `DeepCoolTheme` | `auto` | COLOURS row: `auto` follows SKINS FOR on General, `dark` = white skin, `light` = black skin. |
| `DeepCoolPath` | `C:\DeepCool\DeepCool.exe` | The program that drives the case screen. |
| `DeepCoolProcess` | `DeepCool.exe` | Process name used to tell if it is running. |
| `DeepCoolStartHidden` | `1` | Open straight to the tray, no window. |
| `DeepCoolArgs` | `(empty)` | Extra start arguments. |
| `DeepCoolLabel` | `screen` | Hover label: `screen` (CASE SCREEN) or `app` (DEEPCOOL). |
| `DeepCoolOffDelay` | `7` | Seconds STOPPING TELEMETRY stays after the app has exited (the screen takes about this long to go dark). Under ADVANCED at the bottom of the page. |

## Requirements

DeepCool app (1.2.6 was tested). It has no start-minimised option, so `Scripts\HideWindow.ps1` starts it and hides its window. Closing uses `taskkill`.

## When something is missing

- **DeepCool app not found at `DeepCoolPath`:** the skin hides itself until the path is fixed (Settings shows what to set).
- **No process name** (`DeepCoolProcess` empty): the bulb is hidden. Starting and stopping from the logo is unchanged.

Settings marks each with an amber **!**; fixing it brings the function back without a restart (see [first-time setup](first-time-setup.md)).

## Known limits

DeepCool's helper service keeps running either way. Any tray app can be toggled by changing the path and process.
