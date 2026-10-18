# Uptime

How long Windows has been running; orange when a restart is due.

*Draft.* Behaviour was read from `Uptime/Uptime.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** Invisible until hovered (unless `UptimeAlways` is on).
- **On hover:** UPTIME over the running time. Past `UptimeWarnDays` it shows itself in orange: RESTART RECOMMENDED.

## Actions

- Click: opens Task Manager.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `UptimeTooltips` (1 = show its tooltips, 0 = hide them all; default 1). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `Uptime/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `UptimeWarnDays` | `5` | Days before the orange reminder. |
| `UptimeAlways` | `0` | 1 = visible at rest, not only on hover. |

## Requirements

Nothing to install.

## Known limits

The count matches Task Manager and includes time asleep. With Fast Startup on, Shut down does not reset it (only Restart does).
