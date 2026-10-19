# Control-Plaine

A quiet Rainmeter suite for Windows: thirteen skins and one Settings window that share a single design system. Quiet at rest, detail on hover, key information always visible, the Windows accent colour, and a layout that works on the left or the right edge of the screen.

## Skins

| Skin | What it does | Guide |
| --- | --- | --- |
| Day-Date | The day name over the date. Click to open the calendar. | [guide](docs/guide/DayDate.md) |
| Power | Hibernate (or sleep), shut down, restart and lock, with a schedule picker. | [guide](docs/guide/Power.md) |
| Uptime | How long Windows has been running; orange when a restart is due. | [guide](docs/guide/Uptime.md) |
| Volume | Output volume as a ring, the percentage and the output device. | [guide](docs/guide/Volume.md) |
| Media | The song playing in any app, with progress ring and controls. | [guide](docs/guide/Media.md) |
| Recycle Bin | Recycle Bin size, with an Empty link. | [guide](docs/guide/RecycleBin.md) |
| Playnite | A controller icon that opens Playnite. | [guide](docs/guide/Playnite.md) |
| Wi-Fi | Wi-Fi signal and network name, with a manual speed test. | [guide](docs/guide/WiFi.md) |
| Fan Control | Average fan speed and a one-click MAX switch, through Fan Control. | [guide](docs/guide/FanControl.md) |
| SignalRGB | Case lights brightness and a move effect, through SignalRGB. | [guide](docs/guide/SignalRGB.md) |
| DeepCool | A switch for the DeepCool app that drives the case screen. | [guide](docs/guide/DeepCool.md) |
| Controllers | Connected game controllers and their batteries. | [guide](docs/guide/Controllers.md) |
| Settings Button | A gear that opens the Settings window. | [guide](docs/guide/SettingsButton.md) |

Each guide says what the skin shows at rest and on hover, what clicking and scrolling do, every option with its default, and what it needs. You only need the apps for the skins you use.

## Requirements

- Windows 10 or 11 and [Rainmeter](https://www.rainmeter.net) 4.5 or newer.
- Segoe UI Variable (Windows 11). On Windows 10 choose FONT > SEGOE UI on the Advanced page of Settings.
- Some skins need an app or a plugin (Media, the Wi-Fi speed test, Fan Control, SignalRGB, DeepCool, Playnite, Controllers). The installer and the first-time setup handle the plugins; each guide lists what its skin needs. A skin whose app is missing says so instead of sitting broken on the desktop.

## Install

From the repo folder in PowerShell:

```
powershell -ExecutionPolicy Bypass -File tools\install.ps1
```

The installer links the folder into your Rainmeter Skins folder, creates your settings files, installs the plugins the skins use, saves your current desktop as a backup layout, loads the Control-Plaine layout and opens Settings. After a plugin is installed, exit and restart Rainmeter once. The manual route and updating are in [docs/guide/install.md](docs/guide/install.md).

## First-time setup

On a new install, Settings opens a short guided setup: which skins you want, what each needs (with the exact install command, run only when you click), the look (size, light or dark, left or right, details, tooltips, accent) and where the skins sit on your screen. You can skip it or run it again from General (RUN SETUP AGAIN). See [docs/guide/first-time-setup.md](docs/guide/first-time-setup.md).

## What you can set

Right-click any Control-Plaine skin and choose **Control-Plaine settings**. One window opens with a tab per skin plus General and Advanced. Changes apply at once and are stored in `@Resources\User.inc`, which git does not touch.

- **Left or right.** Every skin except Power can sit on the left or the right edge and keeps the same footprint either way. Set it per skin or for all of them (ALIGN ALL SKINS).
- **Light and dark.** SKINS FOR picks colours for dark wallpapers, light wallpapers, or follows Windows. A skin can override it with its COLOURS row.
- **Details.** Show detail text only on hover, or always.
- **Tooltips.** One switch per skin, or all on or all off.
- **Size, accent and brightness.** Scale, the Windows or a custom accent, and the brightness at rest and on hover.
- **Full screen and lock.** Hide every skin while a full-screen app is in front; lock positions against accidental drags.

All options and their defaults are in [docs/guide/settings.md](docs/guide/settings.md) and on each skin's page.

## Troubleshooting

A skin missing, blank or not responding, a plugin that will not load, a blank Wi-Fi name: see [docs/guide/troubleshooting.md](docs/guide/troubleshooting.md).

## Documentation

- Using the skins: [docs/guide/](docs/guide/)
- Working on the repo or adding a skin: [docs/INDEX.md](docs/INDEX.md), [CLAUDE.md](CLAUDE.md)
- Design and per-skin specs: [docs/DESIGN-V1.md](docs/DESIGN-V1.md), [specs/](specs/)
- Version history: [CHANGELOG.md](CHANGELOG.md)

`python tools/lint.py` checks the suite's rules and runs on every push and pull request.

## Licence and credits

Control-Plaine is licensed under the MIT licence (see [LICENSE](LICENSE); the `License` line in each skin's `[Metadata]`). Many icons are based on [Lucide](https://lucide.dev) (ISC licence); all third-party notices are in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). Third-party plugins and tools (MediaPlayer, Ookla Speedtest CLI, Fan Control, SignalRGB and so on) belong to their authors and are downloaded or installed separately, never committed here.
