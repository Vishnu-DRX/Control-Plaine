# Control-Plaine

A quiet Rainmeter suite for Windows. Quiet at rest, detail on hover, one shared design system.

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

Every skin has a **Control-Plaine settings** entry in its right-click menu, which opens one Settings window with a tab per skin. See [Settings](docs/guide/settings.md).

## Requirements

- Windows 10 or 11 and [Rainmeter](https://www.rainmeter.net) 4.5 or newer.
- Segoe UI Variable (Windows 11). On Windows 10 set `FontFace=Segoe UI` in `@Resources\User.inc`.
- Some skins need an app or plugin (Media, Wi-Fi speed test, Fan Control, SignalRGB, DeepCool, Playnite, Controllers). Each guide page lists its own.

## Install

From the repo folder in PowerShell:

```
powershell -ExecutionPolicy Bypass -File tools\install.ps1
```

Details, the manual route and what the installer changes are in [docs/guide/install.md](docs/guide/install.md). Problems: [docs/guide/troubleshooting.md](docs/guide/troubleshooting.md).

## Documentation

- Using the skins: [docs/guide/](docs/guide/)
- Working on the repo (or adding a skin): [docs/INDEX.md](docs/INDEX.md), [CLAUDE.md](CLAUDE.md)
- Design and per-skin specs: [docs/DESIGN-V1.md](docs/DESIGN-V1.md), [specs/](specs/)

## Checks

`python tools/lint.py` checks the suite's rules. It runs on every push and pull request.

## Licence and credits

Skins are licensed CC BY-NC-SA 4.0 (the `License` line in each skin's `[Metadata]`). Icons are based on [Lucide](https://lucide.dev) (ISC licence). Third-party plugins and tools (MediaPlayer, Ookla Speedtest CLI, Fan Control, SignalRGB and so on) belong to their authors and are downloaded or installed separately, never committed here.
