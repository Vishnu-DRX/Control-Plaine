# Settings Button

A gear that opens the Settings window.

*Draft.* Behaviour was read from `SettingsButton/SettingsButton.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** A dim gear.
- **On hover:** The gear brightens and SETTINGS appears beside it (always, when `SettingsButtonDetails` is `always`). The gear turns the accent colour while the pointer is on it.
- **Side:** `SettingsButtonAlign` left puts the gear first; right mirrors it (label first, gear last). The box is the same size either way.

## Actions

- Click: opens the Settings window on the General page.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

It never hides itself, and it stays clickable when positions are locked, so it is always a way back into Settings.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `SettingsButtonTooltips` (the TOOLTIPS row on this skin's page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment) are on [Settings](settings.md).

> Defaults below were read from `SettingsButton/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `SettingsButtonAlign` | `left` | `left` or `right`: which screen edge it sits on. `AlignAll` can override it. |
| `SettingsButtonDetails` | `hover` | `hover` or `always`: when SETTINGS shows. `DetailsAll` can override it. |

## Requirements

None.

## Known limits

- It is not placed by the default layout yet; turn it on under General > Skins.
