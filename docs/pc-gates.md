# PC gates

Things the cloud cannot check because they need Rainmeter or a Windows PC. Each line names what to do and which review finding or work package it closes. Tick it off here when done, with the date. Procedure: [sop/pc-test-protocol.md](sop/pc-test-protocol.md). Reviews: [reviews/](reviews/).

## Settings engine (R1)

- [ ] Type `]]) os.execute("calc") --`, `"C:\x\a.exe"` and `a]b` into a path box and into AccentColor; confirm what runs and what is stored (R1-S1). Check whether `$UserInput$` can be read back from Lua instead of pasted into code.
- [ ] Confirm how `SKIN:Bang` quotes its arguments and what happens to a value containing `"` (R1-S3).
- [ ] Scroll a value, then switch tab, Close or RESET within 600 ms; confirm nothing is lost or resurrected (R1-S7).
- [ ] Write a Cyrillic `PlaynitePath`, run CLEAN, confirm the path survives (R1-S8). Confirm whether a fresh Rainmeter writes `User.inc` as UTF-16.
- [ ] Click behaviour for `C:\Apps\`, `a]b`, `a"b` in DayDateClick, UptimeClick, PlaynitePath (R1-S4, R1-S5).

## Launchers and process control (R2)

- [ ] `ControllersDsxPort` set to `1 -Poll 0` and to `abc`: no CPU spin, no 30 s respawn loop (R2-L1).
- [ ] Hang a Power PowerShell call (stop the Task Scheduler service) and confirm the queue recovers (R2-L2).
- [ ] Click the Media title with Spotify closed to the tray (R2-L3).
- [ ] Does RunCommand call FinishAction when it ends after the Power watchdog gave up, and does hibernate then resume trip the watchdog (R2-N1, N2)?
- [ ] `DeepCoolArgs=--minimized` binds as a value (R2-L6). Wheel row double click starts one copy (R2-L8).
- [ ] Idle CPU of the Controllers helper and of Power with the skin visible (R2-L9, R2-L10).

## Data, network and the elevated fan task (R3)

- [ ] Run `tools\fan-tasks.ps1` as admin; confirm the FanSensors task points at the protected copy, that a normal user cannot edit it, and that fan speeds still appear (R3-D1).
- [ ] Portable Fan Control in Downloads: the script refuses (R3-D2). Program Files install passes, including the parent-folder check (R3-N3).
- [ ] Store-only pwsh: the script declines and says to install the MSI; with the MSI the task points at Program Files (R3-N2). A leftover user-planted file in `%ProgramData%\ControlPlaine\FanControl` is cleared (R3-N1).
- [ ] After updating an existing install, re-run `tools\fan-tasks.ps1`; confirm the old task is replaced (R3-N4).
- [ ] With Fan Control closed, one elevated pwsh at most is running after two minutes (R3-D4).
- [ ] Standard user plus separate admin account: tasks run as the right user (R3-D10).
- [ ] SignalRGB: bad port and bad MoveParams values do not reach curl or cmd (R3-D7, R3-D8). Wi-Fi speed test first-run licence wording (R3-D9).

## Tools and installer (R4)

- [ ] `tools\install.ps1` on Windows PowerShell 5.1 and on pwsh 7: fresh install, second run the same day, existing non-repo `Skins\Control-Plaine` (R4-T3, R4-T4, R4-T5).
- [ ] Compute the SHA-256 of the MediaPlayer release asset and pin it in the helper script (R4-T2; GitHub downloads were not reachable from the cloud session).
- [ ] `Helpers.txt` entries with a quoted `{ROOT}` when the repo path has an apostrophe, e.g. `C:\O'Neil\...` (onboarding re-check).
- [ ] GitHub Actions: `lint` still passes with the `permissions:` block and pinned actions (R4-T10).

## Onboarding (WP-O)

- [ ] First run on a fresh profile (no `SetupDone`): `install.ps1` opens Settings once and it shows the onboarding, not two windows; FINISH and SKIP SETUP both write `SetupDone=1` and Settings does not reopen the onboarding afterwards (R5-N16).
- [ ] Existing profile that only pulled the update and refreshed: what the first Settings open does (R5-N10). With `install.ps1` an existing profile is marked done, and State.inc stays readable if Rainmeter saved it as UTF-16 (R5-N7).
- [ ] SKINS step: skins whose mandatory need is missing start off with the reason; the ones that are fine stay on. SignalRGB with the default `auto` path is NOT blocked when SignalRGB is installed, and hides about 5 s after load when it is not (R5-N1, R5-N2).
- [ ] Flags flip live within a minute with no refresh: install Speedtest CLI and the Wi-Fi speed test icon appears; rename the `FanControlMax` profile file and the snowflake hides; a wrong Playnite path hides the skin and a fixed path brings it back.
- [ ] Fan Control: with the tasks installed, MAX works without UAC and the live fan value shows (the task checks must not read as missing for a normal user, R5-N5); without them MAX asks for UAC and the sensor value is hidden.
- [ ] Controllers overlay: with `ControllersDualSenseApp`, `ControllersWheelApp` and `ControllersOther` each cleared or pointed at a missing file, hovering the row still reveals the detail, the cursor stays an arrow, there is no tooltip and a click starts nothing; with valid values the click opens the app (R5-N14).
- [ ] RUN IT FOR ME and COPY COMMAND for the MediaPlayer plugin, Speedtest, IsFullScreen and the fan tasks, with a profile folder that has a space and with one that has an apostrophe: the clipboard text equals the command shown and the helper gets the full argument list, not its first word (R5-N3, R5-N11). The UAC prompt appears for the fan tasks only.
- [ ] RUN IT FOR ME with the PC offline or the UAC prompt dismissed: the row ends in NOT FOUND AFTER THE RUN with a tail of the output, and the button works again; nothing hangs for the 10 minute timeout.
- [ ] Placement: one screen, two screens (click the screen word to cycle), a portrait screen and a screen left of the primary (negative X): skins stack on the chosen edge inside the work area, nothing overlaps the taskbar, many skins on a short screen start a second column that is still on screen (R5-N15). The `!Move` positions survive a Rainmeter restart.
- [ ] Fan Control tasks helper: the UAC prompt names Windows PowerShell, not the script; confirm the SOURCE line shows `tools\fan-tasks.ps1` before you accept (R5-N12, accepted risk). Cancelling the prompt leaves the row NOT FOUND.
- [ ] Settings first open after only pulling the repo (no installer) shows the setup; SKIP SETUP marks it done and changes nothing (R5-N10, documented).
- [ ] Settings window behind Onboarding on first run: no flicker of two windows (R5-N16, left as is).
- [ ] Per-skin gates on screen: Power hides SCHEDULE without Task Scheduler, RecycleBin hides EMPTY, Wi-Fi shows plain Wi-Fi when the network name flag is 0, SignalRGB hides the brightness control and the double arrow when their effects are empty and stops polling with `SignalRGBApi=0`, DayDate, Uptime and Volume clicks do nothing when their target is missing, Playnite, FanControl, DeepCool, Volume, RecycleBin and Media hide when BLOCKED and return when fixed.
- [ ] A program path on an offline network share (`\\server\share\app.exe`) does not freeze Rainmeter (R5-N6). Idle CPU of the 13 skins stays flat over ten minutes with the Settings window closed.
- [ ] Amber marks in Settings: shown only for loaded skins, the tooltip names the missing items, a click opens the setup for that skin only (fix mode), DONE closes it, and the mark clears by itself within a minute after the fix.

## Release and public readiness (WP-I, WP-P)

- [ ] Full visual pass of every skin in light and dark.
- [ ] Fresh-PC install from the repo using only `docs/guide/install.md`.
- [ ] GitHub Pages site stays unpublished until Vishnu says go (`PAGES_ENABLED` unset).
