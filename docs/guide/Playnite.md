# Playnite

A controller icon that opens Playnite.

## At rest and on hover

- **At rest:** The controller icon.
- **On hover:** Brightens and shows PLAYNITE (always, when `PlayniteDetails` is `always`).
- **Side:** `PlayniteAlign` left puts the art first; right mirrors it (label first, art last). The box is the same size either way.

## Actions

- Click: starts `PlaynitePath` (skipping the splash screen when `PlayniteSkipSplash` is on).
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `PlayniteTooltips` (the TOOLTIPS row on this skin's page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `Playnite/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `PlaynitePath` | `%LOCALAPPDATA%\Playnite\Playnite.DesktopApp.exe` | The program to start. Any other `.exe` launches that instead. |
| `PlayniteTheme` | `auto` | COLOURS row: `auto` follows SKINS FOR on General, `dark` = white skin, `light` = black skin. |
| `PlayniteSkipSplash` | `1` | Start without Playnite's splash screen. |
| `PlayniteAlign` | `left` | `left` or `right`: which screen edge it sits on. `AlignAll` can override it. |
| `PlayniteDetails` | `hover` | `hover` or `always`: when PLAYNITE shows. `DetailsAll` can override it. |

## Requirements

Playnite (playnite.link), desktop mode.

## When something is missing

Playnite checks `PlaynitePath` at load and about once a minute (a file check; nothing is started). If the program is not found, the skin hides itself instead of sitting on the desktop doing nothing; Settings shows an amber **!** on its tab. Fix the path or install Playnite and the icon returns within a minute.

## Known limits

None known.
