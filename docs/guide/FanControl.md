# Fan Control

Average fan speed and a one-click MAX switch, through Fan Control.

*Draft.* Behaviour was read from `FanControl/FanControl.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** A fan icon.
- **On hover:** FANS and the average speed, and a snowflake.

## Actions

- Click the snowflake: every fan to 100% and back. The percentage climbs (or falls) with SPEEDING UP / SLOWING DOWN until the fans arrive. While MAX is on, the fan icon and snowflake are accent.
- Click the fan icon: open Fan Control.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `FanControlTooltips` (1 = show its tooltips, 0 = hide them all; default 1). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `FanControl/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `FanControlPath` | `C:\Program Files (x86)\FanControl\FanControl.exe` | Fan Control program; its configs are in the `Configurations` folder beside it. |
| `FanControlNormal` | `userConfig.json` | Profile used when MAX is off. |
| `FanControlMax` | `Max.json` | Profile with every fan at 100%. |
| `FanControlIgnoreStopped` | `1` | Leave stopped fans (0 RPM) out of the average. |
| `FanControlUseTasks` | `1` | Run Fan Control through scheduled tasks (no UAC prompt). 0 launches the exe directly. |

## Requirements

Fan Control by Rem0o (V277 was tested). Fan Control and its sensor feed need admin, so MAX, open and the sensor reader go through scheduled tasks made once by `tools\fan-tasks.ps1` (run it as admin; the reader needs PowerShell 7).

## Known limits

Runtime key `FanControlMaxOn` is kept in `State.inc`, not a setting.
