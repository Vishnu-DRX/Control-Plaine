# DeepCool

A switch for the DeepCool app that drives the case screen.

*Draft.* Behaviour was read from `DeepCool/DeepCool.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** The DeepCool logo: accent while the app runs, grey when closed.
- **On hover:** CASE SCREEN (or DEEPCOOL) and a bulb.

## Actions

- Click the logo, label or bulb: closed starts the app hidden in the tray; running closes it. STARTING / STOPPING TELEMETRY and a spinner show until the process list confirms.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `DeepCoolTooltips` (1 = show its tooltips, 0 = hide them all; default 1). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `DeepCool/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `DeepCoolPath` | `C:\DeepCool\DeepCool.exe` | The program that drives the case screen. |
| `DeepCoolProcess` | `DeepCool.exe` | Process name used to tell if it is running. |
| `DeepCoolStartHidden` | `1` | Open straight to the tray, no window. |
| `DeepCoolArgs` | `(empty)` | Extra start arguments. |
| `DeepCoolLabel` | `screen` | Hover label: `screen` (CASE SCREEN) or `app` (DEEPCOOL). |
| `DeepCoolOffDelay` | `7` | Seconds STOPPING TELEMETRY stays after the app has exited (the screen takes about this long to go dark). |

## Requirements

DeepCool app (1.2.6 was tested). It has no start-minimised option, so `Scripts\HideWindow.ps1` starts it and hides its window. Closing uses `taskkill`.

## Known limits

DeepCool's helper service keeps running either way. Any tray app can be toggled by changing the path and process.
