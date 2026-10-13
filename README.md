# Control-Plaine

A minimal Rainmeter suite. Quiet at rest, detail on hover, one shared design system.

## Skins

| Skin | At rest | On hover |
| --- | --- | --- |
| Day-Date | Day name, date | Time and ISO week number |
| Power | Four dim icons: lock, sleep, restart, shut down | Icon name; uptime line. Restart and shut down need a second click within 3 s. Uptime stays visible as a reminder after 5 days. |
| Recycle Bin | Bin icon (lines show when it has something in it) | Item count, size, Empty bin. Click the icon to open the bin. |
| Volume | Thin ring at the current level, "off" when muted | Scroll to change (up also unmutes), click ring to mute, output device name; click it to switch device |
| Playnite | Controller icon | "Playnite" label. Click to open. |

## Install

Quick way, from the repo folder in PowerShell:

```
powershell -ExecutionPolicy Bypass -File tools\install.ps1
```

It links the repo into your Skins folder, creates `User.inc` and `State.inc`, downloads the MediaPlayer plugin for the Media skin, saves your current desktop as a backup layout, and loads the Control-Plaine layout.

By hand:

1. Put this folder at `Documents\Rainmeter\Skins\Control-Plaine` (clone or copy).
2. Create empty `@Resources\User.inc` and `@Resources\State.inc` (the installer does this). Change settings from any skin's right-click menu > Control-Plaine settings.
3. In Rainmeter: Manage > Layouts, load **Control-Plaine** (copy `Layouts\Control-Plaine` into `%APPDATA%\Rainmeter\Layouts` first), or load each skin from Manage > Skins.

Day-Date uses the Anurati font for the day name; install it in Windows if it is not already.

## Design system

All skins include three shared files in `@Resources`:

- `Theme.inc`: colours, alpha levels, fonts, sizes, scale, fade timing. Change one value and refresh all.
- `Styles.inc`: meter styles. `sText` always visible, `sReveal` fades in on hover, `sIcon` / `sIconFade` for icons.
- `Fade.inc`: the 150 ms hover fade with a 500 ms hide delay, used by every skin.

Rules:

1. At rest things are dim (`AlphaRest`) and have no labels or backgrounds.
2. Hover brightens to `AlphaHover` and reveals one or two lines of detail. No movement or scaling.
3. Detail hides 500 ms after the mouse leaves.
4. `Warn` colour only for things that need attention (confirm a shut down, restart reminder). `Accent` only for active state.
5. Every clickable thing has a hand cursor and, where it is not obvious, a tooltip.
6. Personal paths go in `User.inc`, never in a skin.

Icons are line icons based on [Lucide](https://lucide.dev) (ISC licence), rendered white by `tools/render-icons.py` at the exact pixel size each skin shows them (strokes on whole pixels, one size and weight for the app skins) and tinted in Rainmeter.

## Checks

`python tools/lint.py` checks that every skin includes the shared files, has no hardcoded user paths, stays ASCII, and only uses icons that exist. It runs on every push and pull request.
