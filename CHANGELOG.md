# Changelog

## 2.0.1

A small follow-up to 2.0.0.

- **Setup placement follows the edge.** Choosing the right edge in the PLACEMENT step now also sets ALIGN ALL SKINS to right, so the column ends flush; choosing left only overrides a right setting.
- **MediaPlayer plugin download is checked.** The helper compares the downloaded package with a pinned SHA-256 and installs nothing if it differs.

## 2.0.0

Control-Plaine 2.0.0 is the suite rebuilt on one shared design system and one Settings window.

### Skins

Day-Date, Power, Uptime, Volume, Media, Recycle Bin, Playnite, Wi-Fi, Fan Control, SignalRGB, DeepCool, Controllers and the new Settings Button (a gear that opens Settings). The guides in `docs/guide/` describe each one.

### New settings

- **Left or right.** Every skin except Power (its four icons are symmetric) can sit on the left or the right edge of the screen and keeps the same footprint either way. Set it per skin (ALIGN row) or for all of them (ALIGN ALL SKINS on Advanced). New installs start on the left.
- **Details.** Show the detail text on hover or always (DETAILS row per skin, DETAILS ON ALL SKINS on Advanced). `UptimeDetails` replaces the old `UptimeAlways`.
- **Tooltips.** One TOOLTIPS row per skin, and TOOLTIPS ON ALL SKINS (skin, on, off) on Advanced.
- **Light and dark.** SKINS FOR on General (dark wallpapers, light wallpapers, or follow Windows), a COLOURS row per skin, LIGHT MODE BOOST and ACCENT DARKENING for light wallpapers. Brightness at rest and on hover are settings (RestBrightness, HoverBrightness).
- **Advanced page.** FONT, SIZE BOOST, HOVER LINGER, ACCENT ON HOVER, RESET SETTINGS and CLEAN UNKNOWN SETTINGS (both keep `User.inc.bak`). Every page footer has REFRESH ALL, OPEN SKINS FOLDER and OPEN USER.INC.
- **Click targets.** What a click opens is a setting for Day-Date (`DayDateClick`) and Uptime (`UptimeClick`), and Playnite's program path is `PlaynitePath`.
- **Settings button.** A gear skin that is always a way back into Settings; it opens Settings once on a first run.

### First run and missing apps

- **Guided setup.** A new install opens Settings on a short setup: pick the skins, see what each needs, choose the look, then place the skins. RUN SETUP AGAIN on General restarts it.
- **Install helpers.** For a missing item with a known command (Speedtest CLI, the MediaPlayer and IsFullScreen plugins, the Fan Control scheduled tasks) setup shows the exact command and runs it only when you click. The command list is one file the installer shares.
- **Graceful degradation.** A skin whose optional app is missing hides that one function and keeps working; a skin whose required app is missing says what it needs instead of showing a broken face. An amber ! in Settings marks both.
- **Placement.** The PLACEMENT step stacks the skins in a column on the left or right edge of the screen you choose, in a fixed order with fixed gaps, wrapping to a second column on short screens. The shipped layout (`tools\layout\Control-Plaine.layout`) is a first column at the left of the main screen.

### Other changes

- Shared look: sharper rings and lines, whole-pixel icons, the accent on the hovered icon, SizeBoost for the app skins.
- Wi-Fi: one-line speed test (manual), network names shown in full. Fan Control: FANS and the snowflake MAX switch. SignalRGB: brightness without Pro. Controllers: battery next to the name and DualSense click brings DSX up. Power: a schedule for lock too, with a tick and X in the picker.
- Skins stay visible when an app is full screen unless HIDE IN FULL SCREEN is on.
- Security: the Fan Control sensor reader runs from `%ProgramData%\ControlPlaine\FanControl`, an admin-only folder. **Run `tools\fan-tasks.ps1` as admin once after updating** (it needs PowerShell 7 from Program Files). Until you do, fan speeds may be empty.
- Settings text boxes refuse quotes and line breaks, ports must be numbers, and Reset and CLEAN keep `User.inc.bak`.
- The installer is hardened and shares its helper list with the setup.

## 1.0.0

- First release: Day-Date, Power, Recycle Bin, Volume and Playnite on one shared theme and style.
