# Settings Button

A gear that opens the Settings window.

## At rest and on hover

- **At rest:** A dim gear.
- **On hover:** The gear brightens and SETTINGS appears beside it (always, when `SettingsButtonDetails` is `always`). The gear turns the accent colour while the pointer is on it.
- **Side:** `SettingsButtonAlign` left puts the gear first; right mirrors it (label first, gear last). The box is the same size either way.

## Actions

- Click: opens the Settings window on the General page.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

First run: if setup has not been finished (`SetupDone` is not `1` in `@Resources\State.inc`), the skin opens the Settings window once when it loads, as a fallback in case the installer did not. It does this once per load of the skin, never repeatedly, and never once setup is finished.

It never hides itself, and it stays clickable when positions are locked, so it is always a way back into Settings.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `SettingsButtonTooltips` (the TOOLTIPS row on this skin's page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment) are on [Settings](settings.md).

> Defaults below were read from `SettingsButton/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `SettingsButtonAlign` | `left` | `left` or `right`: which screen edge it sits on. `AlignAll` can override it. |
| `SettingsButtonDetails` | `hover` | `hover` or `always`: when SETTINGS shows. `DetailsAll` can override it. |
| `SettingsButtonTheme` | `auto` | Colours: `auto` follows the global Theme (SKINS FOR on General), `dark` is white, `light` is black. The COLOURS row on this skin's page sets it. |

## Requirements

None.

## Known limits

- The shipped layout loads it under the last skin of the column; if you switched it off, turn it back on under General > SKINS.
