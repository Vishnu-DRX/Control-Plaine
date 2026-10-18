# Power

Hibernate (or sleep), shut down, restart and lock, with a schedule picker.

*Draft.* Behaviour was read from `Power/Power.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** Four dim icons.
- **On hover:** Brightens; the hovered icon shows its name and a SCHEDULE link under it. While something is scheduled its icon is accent and the countdown stays visible.

## Actions

- Click an icon to run it. Shut down and restart need a second click within 3 s (`PowerConfirm`).
- SCHEDULE opens a picker: scroll to pick 15 minutes to 24 hours in 15 minute steps, then SET (X closes it). CANCEL undoes a schedule.
- Only one schedule at a time; a new one replaces the old one. A scheduled shut down closes open apps without asking.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `PowerTooltips` (the TOOLTIPS row on this skin's page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `Power/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `PowerTheme` | `auto` | COLOURS row: `auto` follows SKINS FOR on General, `dark` = white skin, `light` = black skin. |
| `PowerFirst` | `hibernate` | What the first icon does: `hibernate` or `sleep`. |
| `PowerConfirm` | `1` | Shut down and restart need a second click. |
| `PowerPickerStart` | `60` | Minutes the schedule picker opens on. |

## Requirements

Windows 10/11, no admin rights. Hibernate must be available (`powercfg /a`). Hibernate, sleep and lock schedules use one-time Windows tasks made by `@Resources\Scripts\Power.ps1`.

## Known limits

A task missed while the PC was asleep or off does not run later. Restarting the PC clears a pending shut down or restart. The schedule itself lives in `State.inc` (runtime keys `PowerScheduled*`, not settings).

## When something is missing

SCHEDULE needs Windows' task scheduler. If it is not available, the SCHEDULE link is left out and the four icons stay as they are. A schedule that is already pending can still be cancelled. It comes back by itself within about a minute once the scheduler is found.
