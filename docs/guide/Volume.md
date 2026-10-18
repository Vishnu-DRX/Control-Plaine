# Volume

Output volume as a ring, the percentage and the output device.

## At rest and on hover

- **At rest:** A ring at the current level with the speaker in it. With `VolumeAlign=left` (the default) the ring is first and the text follows; `right` mirrors it (text first, ring last).
- **On hover:** The percentage (MUTED when muted), a hairline and the device name appear, and the ring turns accent. With `VolumeDetails=always` they stay visible. Scrolling anywhere on the skin changes the volume.

## Actions

- Scroll: change volume by `VolumeStep` (up also unmutes when `VolumeScrollUnmutes` is on).
- Click the ring: jump to that level. Click the percentage: mute. Click the device name: switch to the next output. Click the speaker: open `VolumeMixer`.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `VolumeTooltips` (the TOOLTIPS row on this skin's page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `Volume/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `VolumeAlign` | `left` | `left`: ring first, text after it. `right`: the mirror image inside the same box. `AlignAll` in Settings overrides it. |
| `VolumeDetails` | `hover` | `hover`: percentage, hairline and device name show on hover. `always`: they stay visible. `DetailsAll` overrides it. |
| `VolumeTheme` | `auto` | COLOURS row: `auto` follows SKINS FOR on General, `dark` = white skin (for dark wallpapers), `light` = black skin (for light wallpapers). |
| `VolumeStep` | `2` | Percent per scroll notch. |
| `VolumeScrollUnmutes` | `1` | Turning the volume up while muted unmutes. |
| `VolumeRingStroke` | `5` | Ring thickness in px. |
| `VolumeMixer` | `ms-settings:apps-volume` | What the speaker opens (or `sndvol.exe` for the classic mixer). |

## Requirements

Rainmeter's bundled Win7AudioPlugin; nothing to install.

## Known limits

The device name is the name in Windows Sound settings: rename the device there. With no playback device the plugin reports an error string.

## When something is missing

If the Windows audio plugin is missing, the skin cannot read the volume and hides itself until it is found. If the mixer target (`VolumeMixer`) cannot be opened, only the speaker click is turned off: no tooltip, no click, and the ring, %, mute and device switch keep working. Both come back within about a minute once fixed, no refresh needed.
