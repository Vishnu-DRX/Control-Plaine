# Documentation index

A map of the repo's docs. "Read this when" says why to open each one. Docs here can lag the code: when one disagrees with the repo, trust the repo and fix the doc.

## Start here

| Doc | Read this when |
| --- | --- |
| [../CLAUDE.md](../CLAUDE.md) | You are a Claude session about to work on the repo. |
| [../README.md](../README.md) | You want the overview, requirements and install in one page. |

## Using the skins (docs/guide)

| Doc | Read this when |
| --- | --- |
| [guide/install.md](guide/install.md) | Installing or updating. |
| [guide/first-time-setup.md](guide/first-time-setup.md) | A new install: what the guided setup asks, the install helpers and the amber marks. |
| [guide/settings.md](guide/settings.md) | You need the general options or want to edit `User.inc`. |
| [guide/troubleshooting.md](guide/troubleshooting.md) | A skin is missing, blank or not responding. |
| [guide/DayDate.md](guide/DayDate.md), [Power](guide/Power.md), [Uptime](guide/Uptime.md), [Volume](guide/Volume.md), [Media](guide/Media.md), [RecycleBin](guide/RecycleBin.md), [Playnite](guide/Playnite.md), [WiFi](guide/WiFi.md), [FanControl](guide/FanControl.md), [SignalRGB](guide/SignalRGB.md), [DeepCool](guide/DeepCool.md), [Controllers](guide/Controllers.md), [SettingsButton](guide/SettingsButton.md) | You need what one skin does, its options and its requirements. |
| [skins.json](skins.json) | You need the skin list and one-liners as data (README and site source). |

## Working on the repo (docs/dev)

| Doc | Read this when |
| --- | --- |
| [dev/architecture.md](dev/architecture.md) | You need the folder layout, include order, shared files or the settings flow. |
| [dev/conventions.md](dev/conventions.md) | You are writing or reviewing code: naming, ASCII, comments, icons, sharpness. |
| [dev/testing.md](dev/testing.md) | You are about to verify a change, on the cloud or on the PC. |
| [dev/release.md](dev/release.md) | You are preparing a version (integration only). |
| [pc-gates.md](pc-gates.md) | You want what still needs Rainmeter or the PC to verify. |
| [reviews/](reviews/) | You want the independent code review reports (safety, efficiency, maintainability) and finding ids. |
| [sop/README.md](sop/README.md) | You are doing a repeatable job: add a skin (`tools/new-skin.py`), a setting or an icon, change a shared file, fix a bug, review, or test on the PC. |

## Design and specs

| Doc | Read this when |
| --- | --- |
| [DESIGN-V1.md](DESIGN-V1.md) | You need the original design intent and per-skin behaviour. |
| [../specs/foundation-settings.md](../specs/foundation-settings.md) | You are touching shared files, the skin template or the Settings window. |
| [../specs/tooltips.md](../specs/tooltips.md) | You are changing tooltips, `TooltipsAll`, or a skin's `ToolTipHidden` line. |
| [../specs/power-uptime.md](../specs/power-uptime.md), [volume-media](../specs/volume-media.md), [wifi](../specs/wifi.md), [app-skins](../specs/app-skins.md) (Fan Control, SignalRGB, DeepCool), [controllers](../specs/controllers.md), [daydate-bin-playnite](../specs/daydate-bin-playnite.md) | You are changing that skin and want the reasoning and what was checked on a real PC. |
| [icons/](icons/) | You are adding or changing an icon (SVG sources). |

## Not in this repo

The programme plans (alignment, appearance, onboarding, docs and site) live in the project's shared folder, not in git. A session that needs them should ask for the current plan rather than assume one.
