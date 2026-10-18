# PC test pass

One pass for Vishnu on the live PC, after the last code PR has merged and the Skins folder has been updated (fast-forward only) and refreshed. It covers left and right, light and dark, tooltips, and the first-run setup. Tick a line and date it. Anything that fails goes to the parent thread with the skin name and what you saw. The longer list of review findings is in [pc-gates.md](pc-gates.md); procedure and rules are in [sop/pc-test-protocol.md](sop/pc-test-protocol.md).

Skins: Day-Date, Power, Uptime, Volume, Media, Recycle Bin, Playnite, Wi-Fi, Fan Control, SignalRGB, DeepCool, Controllers, Settings Button.

## G1 Alignment, details, light and dark (SignalRGB first)

- [ ] SignalRGB: ALIGN left then right in Settings. Same footprint, icon and text mirror, nothing clipped.
- [ ] SignalRGB: DETAILS hover then always.
- [ ] SignalRGB: SKINS FOR dark, light and auto. Light mode has readable ink and a darker accent; rings and lines sharp at 100, 125 and 150 percent size.

## G2 One pass across every skin: left and right

For each skin, with ALIGN left and then right (or ALIGN ALL SKINS on Advanced), and DETAILS hover and always:

- [ ] Day-Date (click opens the calendar). Volume (click sets the level, scroll). Media (controls, long titles). Recycle Bin (EMPTY).
- [ ] Uptime (the orange reminder shows either way). Playnite (opens the app). Settings Button (opens Settings, stays clickable with LOCK POSITIONS on).
- [ ] Wi-Fi (speed test). Fan Control (average, MAX switch). SignalRGB (brightness, move effect). DeepCool (switch still works). Controllers (rows, batteries, DualSense and wheel clicks).
- [ ] Power: all four icons, schedule picker, shut down needs the second click. It has no ALIGN row.
- [ ] Defaults on a fresh `User.inc`: every skin left and hover. Seven skins look as before; Volume, Media, Recycle Bin and Day-Date have the intended left arrangement.
- [ ] ALIGN ALL SKINS and DETAILS ON ALL SKINS force every skin, and "skin" gives control back.
- [ ] Settings has no row that does nothing, and no option you use that has no row.
- [ ] Layout: load `tools\layout\Control-Plaine.layout` on a throwaway profile; every skin shows, in a column at the left, none overlapping.

## G3 Tooltips and light/dark on every skin

- [ ] Tooltips on: each skin shows its tooltips and no others (none on the Wi-Fi speed test icon, none on the snowflake or move icons).
- [ ] TOOLTIPS ON ALL SKINS off, on, skin: skins reload and follow it. A skin's own TOOLTIPS row works when it is "skin".
- [ ] Light wallpaper, SKINS FOR light: every skin readable, icons dark, accent darkened. Dark wallpaper, SKINS FOR dark: as before. Auto follows the Windows setting.
- [ ] A skin's own COLOURS row overrides General. LIGHT MODE BOOST and ACCENT DARKENING change what they say.
- [ ] The Settings window keeps its dark look in both.

## G3b Setup on a throwaway profile, and missing items

- [ ] Fresh profile: `tools\install.ps1` opens Settings and the guided setup starts by itself; SKIP SETUP changes nothing and does not ask again.
- [ ] SKINS step: a skin whose required app is missing starts off with its reason. SETUP step: FOUND and NOT FOUND are right.
- [ ] Install helpers show the exact command; RUN IT FOR ME runs only after the click (say go before anything installs); COPY COMMAND runs nothing.
- [ ] PLACEMENT: choose each screen and LEFT and RIGHT; skins land inside the work area, 24 px from the edge, no overlap; a short screen wraps to a second column.
- [ ] Remove an optional item (Speedtest CLI, a plugin): that one function disappears, the skin stays. Remove a required one: the skin hides and says what it needs. Amber ! marks appear and clear within a minute of fixing.
- [ ] The first run opens Settings once only (Settings Button fallback).
- [ ] RUN SETUP AGAIN on General restarts it and keeps current settings.

## G4 No regression

- [ ] DeepCool still drives the case screen.
- [ ] Fan Control: run `tools\fan-tasks.ps1` as admin once; fan speeds still appear.
- [ ] Power scheduling: set, cancel, replace. Media: any player. Volume click-to-set. Wi-Fi speed test runs and shows a result.
- [ ] RESET SETTINGS and CLEAN UNKNOWN SETTINGS keep `User.inc.bak`; skins reload.
- [ ] The Rainmeter log after REFRESH ALL has no error that names a Control-Plaine file.

## G5 Final: clean install

- [ ] Clean clone, follow only [guide/install.md](guide/install.md): every skin loads, setup runs, no file from this PC is needed.
- [ ] You say "good" per skin. Only then are the version tag, the site and the repo visibility decided (each waits for your go).
