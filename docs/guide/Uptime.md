# Uptime

How long Windows has been running; orange when a restart is due.

## At rest and on hover

- **At rest:** Invisible until hovered (unless `UptimeDetails` is `always`).
- **On hover:** UPTIME over the running time. Past `UptimeWarnDays` it shows itself in orange: RESTART RECOMMENDED.
- **Side:** `UptimeAlign` left grows the text rightwards from the edge; right grows it leftwards. The box is the same size either way.

## Actions

- Click: opens `UptimeClick` (default Task Manager).
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `UptimeTooltips` (the TOOLTIPS row on this skin's page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `Uptime/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `UptimeTheme` | `auto` | COLOURS row: `auto` follows SKINS FOR on General, `dark` = white skin, `light` = black skin. |
| `UptimeWarnDays` | `5` | Days before the orange reminder. |
| `UptimeClick` | `taskmgr.exe` | What a click opens: a program, file or link. |
| `UptimeAlign` | `left` | `left` or `right`: which screen edge it sits on. `AlignAll` can override it. |
| `UptimeDetails` | `hover` | `hover` or `always`: when the text shows. `DetailsAll` can override it. Replaces the old `UptimeAlways`. The orange reminder shows itself either way. |

## Requirements

Nothing to install.

## Known limits

The count matches Task Manager and includes time asleep. With Fast Startup on, Shut down does not reset it (only Restart does).

## When something is missing

The click that opens Task Manager needs a target. If `UptimeClick` points at something that cannot be opened, the click is turned off: no tooltip, no click, and the text looks the same. Fix the target in Settings and it comes back within about a minute, no refresh needed.
