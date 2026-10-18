# Controllers

Connected game controllers and their batteries.

*Draft.* Behaviour was read from `Controllers/Controllers.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** One row per connected controller: icon, and a battery only when it is under `ControllersBatteryShow`. Hidden while nothing is connected.
- **On hover:** Every battery shows; the hovered row brightens, shows its name and dims the others. Low batteries are orange, charging ones accent with a bolt.

## Actions

- Click a row: opens that controller's app (`ControllersDualSenseApp`, `ControllersWheelApp`, or `ControllersOther`).
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `ControllersTooltips` (1 = show its tooltips, 0 = hide them all; default 1). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `Controllers/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `ControllersBatteryShow` | `50` | At rest, a battery shows only under this (%). |
| `ControllersDualSenseApp` | `steam://rungameid/1812620` | What a DualSense click opens (DSX on Steam by default; an exe path works too). |
| `ControllersWheelApp` | `C:\Program Files (x86)\MOZA Pit House\bin\MOZA Pit House.exe` | What a wheel click opens. |
| `ControllersOther` | `ms-settings:bluetooth` | What other controllers open. |
| `ControllersBatteryLow` | `15` | Under this (%) the battery is orange. |
| `ControllersPoll` | `3` | Seconds between controller scans. |
| `ControllersBatteryPoll` | `60` | Seconds between battery reads (Xbox Bluetooth, DualSense without DSX). |
| `ControllersDsxPort` | `6969` | Port of the DSX mod server (DSX settings: incoming UDP). |

## Requirements

Tested with an Xbox Wireless Controller over Bluetooth, a DualSense with DSX (Steam, v3) and a Moza wheel base with Moza Pit House. A hidden PowerShell helper (`@Resources\Scripts\Controllers.ps1`) finds controllers and writes to `%TEMP%`.

## Known limits

Rainmeter stops the helper when the skin is closed or refreshed.
