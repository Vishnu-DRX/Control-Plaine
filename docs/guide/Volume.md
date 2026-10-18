# Volume

Output volume as a ring, the percentage and the output device.

*Draft.* Behaviour was read from `Volume/Volume.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** A ring at the current level, the percentage (MUTED when muted) and the device name.
- **On hover:** Brightens. Scrolling anywhere on the skin changes the volume.

## Actions

- Scroll: change volume by `VolumeStep` (up also unmutes when `VolumeScrollUnmutes` is on).
- Click the ring: jump to that level. Click the percentage: mute. Click the device name: switch to the next output. Click the speaker: open `VolumeMixer`.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `VolumeTooltips` (1 = show its tooltips, 0 = hide them all; default 1). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `Volume/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `VolumeStep` | `2` | Percent per scroll notch. |
| `VolumeScrollUnmutes` | `1` | Turning the volume up while muted unmutes. |
| `VolumeRingStroke` | `5` | Ring thickness in px. |
| `VolumeMixer` | `ms-settings:apps-volume` | What the speaker opens (or `sndvol.exe` for the classic mixer). |

## Requirements

Rainmeter's bundled Win7AudioPlugin; nothing to install.

## Known limits

The device name is the name in Windows Sound settings: rename the device there. With no playback device the plugin reports an error string.
