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

- [ ] First run opens Settings once, placement works, degradation gating hides what is missing. Not started here; waiting for the onboarding PRs to merge.

## Release and public readiness (WP-I, WP-P)

- [ ] Full visual pass of every skin in light and dark.
- [ ] Fresh-PC install from the repo using only `docs/guide/install.md`.
- [ ] GitHub Pages site stays unpublished until Vishnu says go (`PAGES_ENABLED` unset).
