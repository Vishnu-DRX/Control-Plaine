# Day-Date

The day name over the date. Click to open the calendar.

*Draft.* Behaviour was read from `DayDate/DayDate.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** The day name (large) over the date line.
- **On hover:** Brightens. Tooltip: Open calendar.

## Actions

- Click: opens `DayDateClick` (default: the Windows calendar flyout, Win+N).
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `DayDateTooltips` (1 = show its tooltips, 0 = hide them all; default 1). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `DayDate/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `DayDateClick` | `calendar` | What a click opens: `calendar`, or any program, file or URI. |
| `DayDateAlign` | `right` | Which side the text lines up to: `left` or `right`. |

## Requirements

Nothing to install.

## Known limits

Another language: set `DayRef` in the skin to its widest day name, so the fixed edge fits.
