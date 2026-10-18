# Media

The song playing in any app, with progress ring and controls.

*Draft.* Behaviour was read from `Media/Media.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** A progress ring with play/pause, and the title and artist next to it (ring first by default; `MediaAlign=right` puts the ring last). Hidden while nothing is playing (`MediaHideIdle`).
- **On hover:** Brightens; previous and next chevrons appear (Previous at the left end of the line, Next at the right end, on both sides). With `MediaDetails=always` they stay shown. A title too long for the line slides once when the song changes and again on hover (`MediaScrollTitles`): it starts at its first letter, moves left and stops with the last letter at the edge of the line, then goes back.

## Actions

- Click play/pause, previous or next.
- Click the ring: seek to that point.
- Click the title or artist: bring the playing app to the front.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `MediaTooltips` (the TOOLTIPS row on this skin's page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `Media/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `MediaAlign` | `left` | `left`: ring first, text after it. `right`: text first, ring last (how it was drawn before). The skin's box and hit area are the same on both sides. |
| `MediaDetails` | `hover` | `hover`: chevrons and the brighter state show on hover. `always`: they stay shown. |
| `MediaTheme` | `auto` | COLOURS row: `auto` follows SKINS FOR on General, `dark` = white skin (for dark wallpapers), `light` = black skin (for light wallpapers). |
| `MediaHideIdle` | `1` | The skin disappears when no app is playing. |
| `MediaSource` | `any` | Which players it follows: `any` (Windows media session) or `wnp` (WebNowPlaying Redux). |
| `MediaScrollTitles` | `1` | Long names slide (1) or are cut with an ellipsis (0). |
| `MediaPlugin` | `MediaPlayer` | Plugin that reads the player, set together with `MediaSource`. |

## Requirements

`MediaPlayer.dll` (64-bit, v1.4) in `%APPDATA%\Rainmeter\Plugins`; `tools\install.ps1` downloads it. Restart Rainmeter after installing. For `wnp`, WebNowPlaying Redux must be installed.

## Known limits

Some sources (certain websites) report no position, so the ring stays empty. When several apps play, Windows decides which is shown.
