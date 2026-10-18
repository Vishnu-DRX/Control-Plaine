# R4 review: tools, installer, CI, site (origin/main)

Ran: `python tools/lint.py` = 0 problems. All 10 `tools/test_*.py` = 0 failures (after `pip install lupa`; test_core and test_media crash with ModuleNotFoundError without it, test_ringskins silently skips its RingClick test).

## Findings

| id | sev | file:line | one line |
| --- | --- | --- | --- |
| R4-T1 | critical (per checklist; single-user PC in practice) | tools/fan-tasks.ps1:87-90 | Elevated (RunLevel Highest) FanSensors task runs a script from the user-writable repo/Skins folder |
| R4-T2 | medium | tools/install.ps1:62-83 | Downloaded MediaPlayer.dll (loaded by Rainmeter) is not hash-verified |
| R4-T3 | medium | tools/install.ps1:98-110 | Layout `Control-Plaine` is overwritten with -Force on every run; backup only once per day |
| R4-T4 | medium | tools/install.ps1:14-22 | If `Skins\Control-Plaine` exists and is not this repo, installer says "leaving as is" and carries on against the wrong copy |
| R4-T5 | low | tools/install.ps1:52 | `Get-Content -Encoding Byte` does not exist in PowerShell 7: aborts the script under pwsh |
| R4-T6 | low | specs/daydate-bin-playnite.md:163 | Personal Windows profile path (`C:\Users\<name>\...`) committed; lint only scans .ini/.inc/.lua |
| R4-T7 | low | tools/lint.py:164 | Inline-`;` rule misses `K=1 ;x` and `K=1; x`; blanket exemption for any line containing `Text=` or `ToolTip` |
| R4-T8 | low | tools/lint.py:187 | `!Show/!Hide` rule matches only the exact `[!Show]`/`[!Hide]`: misses `[!hide]`, `[!Hide "cfg"]`, and Lua `SKIN:Bang('!Hide')` |
| R4-T9 | low | .gitignore, tools/__pycache__ | Two .pyc files are tracked and show as modified after running lint/tests; `__pycache__` not ignored |
| R4-T10 | low | .github/workflows/lint.yml | No `permissions:` block; actions pinned to tags not SHAs; `pip install lupa` unpinned |
| R4-T11 | low | tools/install.ps1:86-92 | Installer silently installs third-party software (winget Ookla Speedtest) on every run where it is absent; exit code ignored |
| R4-T12 | low | tools/test_ringskins.py:149 | Missing lupa prints "skipping" and exits 0: a vacuous green locally (CI installs lupa so CI is fine) |
| R4-T13 | low | tools/fan-tasks.ps1:74,85 | `-c $Max` / `-c $Normal` unquoted in task arguments; profile names with spaces break; elevated writer uses predictable `%TEMP%\ControlPlaine-fans.txt` |

## Scenario and fix

**R4-T1.** `fan-tasks.ps1` registers `FanSensors` as `pwsh.exe -File <repo>\@Resources\Scripts\FanControlSensors.ps1` with `-RunLevel Highest`. The repo is `Documents\Rainmeter\Skins\Control-Plaine` (junction to a user folder). Any unelevated process running as the user edits that .ps1, then the skin (or anything) runs `schtasks /run /tn \ControlPlaine\FanSensors` and the payload runs elevated with no UAC prompt. This violates the checklist rule "elevated helpers run a fixed script from a location a normal user cannot write". Same for the git-pull workflow: a pulled change goes straight to admin. Fix: have fan-tasks.ps1 copy the sensor script to a protected location (`%ProgramData%\ControlPlaine\` with ACL Users=ReadAndExecute only, or `%ProgramFiles%`) and register the task against the copy; re-run after updates (document it). Also pass `-ExecutionPolicy` nothing extra. The other three tasks run FanControl.exe from Program Files, which is fine.

**R4-T2.** `Invoke-RestMethod` fetches the release by tag, picks an asset by name regex and copies any `MediaPlayer.dll` found into `%APPDATA%\Rainmeter\Plugins`. A re-tagged or replaced release asset (or a compromised account) yields code execution in Rainmeter. The tag is pinned but contents are not. Fix: pin SHA-256 of the chosen asset and of the extracted DLL in the script and compare with `Get-FileHash` before copying; fail closed.

**R4-T3.** Run install.ps1 after customising the layout `Control-Plaine` (saved from Rainmeter): `Copy-Item ... -Force` replaces it. The backup `Before Control-Plaine <date>` is only made if absent for today, so a second run the same day, after the user rearranged, backs up nothing; then `!LoadLayout` replaces the live desktop. Also `Copy-Item Rainmeter.ini` throws if the file is missing after the backup dir was already created, so the next run skips the backup. Fix: back up the existing `Control-Plaine` layout (timestamp with time) before overwriting, or skip the copy when it exists unless `-ResetLayout`; create the backup dir only after the copy succeeds.

**R4-T4.** Input: `Skins\Control-Plaine` is an old copy or an older clone. Output "already exists, leaving it as is", then User.inc/State.inc are created in the new repo, but Rainmeter loads skins from the old folder (which has no User.inc), and the layout loads those. Fix: if the target exists, check it is a junction/symlink resolving to `$repo`; otherwise stop with an error.

**R4-T5.** With `pwsh install.ps1` and an existing MediaPlayer.dll, `Get-Content -Encoding Byte` throws (parameter removed in PS 6+); `$ErrorActionPreference='Stop'` and it is outside try, so layout install never happens. CLAUDE.md documents `powershell`, so low. Fix: `[IO.File]::ReadAllBytes` (or `Get-Content -AsByteStream` guarded by version) and read the first two bytes.

**R4-T6.** Line 163 contains the user's Windows profile folder name. Fix: replace with `%LOCALAPPDATA%\Playnite\Playnite.DesktopApp.exe`. Add to lint: scan `.md`, `.py`, `.ps1`, `.js`, `.json`, `.html` for `[A-Za-z]:\\Users\\` (allow a few doc examples such as `C:\Users\name\...` in conventions.md via explicit allow-list). `Author=Vishnu A` in skin Metadata is deliberate and not a leak; git author is the GitHub noreply address.

**R4-T7.** Checked with the regex: `A=1 ;note` -> not flagged, `B=1; note` -> not flagged, `C=1 ; note` flagged, `D=#x# ; Text=y` not flagged. Rainmeter treats these as part of the value. Fix: flag `;` preceded by whitespace OR followed by whitespace after a non-formula value, and limit the exemption to the actual `Text=`/`ToolTipText=` keys (match the key at line start, not a substring).

**R4-T8.** Verified: `re.search(r'\[!(Show|Hide)\]', 'X=[!hide]')` and `'[!Hide "x"]'` both False. No instance exists today (grep clean; only Core.inc's own `[!Show]/[!Hide]`, which is the shared implementation). Fix: `(?i)!(show|hide)(meter|group|fade)?\b` over .ini/.inc/.lua, with an exemption for Core.inc.

**R4-T9.** `git ls-files` lists tools/__pycache__/check_icons.cpython-313.pyc and new-skin.cpython-313.pyc; running lint/tests dirties the tree. Fix: `git rm --cached`, add `__pycache__/` and `*.pyc` to .gitignore.

**R4-T10.** lint.yml has no `permissions: contents: read` (token scope falls back to the repo default, possibly read/write); `actions/checkout@v4` etc. float on tags. Fix: add the permissions block, pin to commit SHAs, pin lupa version. pages.yml is good: manual only, `contents: read`, guarded by `vars.PAGES_ENABLED`.

**R4-T11.** `winget install ... --accept-source-agreements --accept-package-agreements` runs for a CLI the user may not want, on each run until it is on PATH, and failure is not reported. Fix: ask (or `-WithSpeedtest` switch), check `$LASTEXITCODE`.

**R4-T12.** Local run of test_ringskins without lupa returns 0 having skipped. Fix: print a clear SKIPPED summary line, or exit non-zero when `CI` is set.

**R4-T13.** Names are config file names, normally without spaces, so low. The elevated sensor reader writes `%TEMP%\ControlPlaine-fans.txt` (the user's own TEMP, predictable name): a user-level process can pre-place a hard link/junction so the elevated writer overwrites a file the user cannot write. Fix: write to a ProgramData folder with a restrictive ACL and read it from there, or quote the arguments.

## Checked and clean

- .gitignore ignores `@Resources/User.inc`, `@Resources/State.inc`, `*.bak`; `git check-ignore` confirms; none tracked.
- Repo grep for tokens/keys (`ghp_`, `github_pat`, `api_key`, `secret`), e-mails and `/home/` paths: none. Git author on all 50 commits is the GitHub noreply address. `Author=Vishnu A` metadata is intended.
- Layouts/Control-Plaine/Rainmeter.ini has no personal paths.
- site/: static HTML/CSS/JS, no external requests, no analytics, no forms; only links are the public GitHub repo and lucide.dev. Pages deploy is `workflow_dispatch` only plus `PAGES_ENABLED` guard, `contents: read` + pages/id-token write (needed). Nothing publishes on push.
- install.ps1: User.inc/State.inc only created when absent (idempotent, ASCII, own-line comment); junction not recreated; IsFullScreen copy only when missing; no `Remove-Item` outside its own TEMP names; layout backup is non-destructive. Paths built with Join-Path from known folders, no hardcoded user path. No admin needed.
- new-skin.py: validates name (PascalCase regex), refuses to overwrite, rejects `;`/`#`/non-ASCII, checks icon exists, renders all templates before writing any (no half-written output; test confirms). Templates have no RunCommand/Program lines.
- check_icons.py / lint.py: stdlib only, ROOT from `__file__`, run from any cwd; lint 0 problems; B10, T3/T4, layout, include-order rules behave as documented on the current tree.
- Tests: 9 of 10 assert real outcomes (counts of check/append in each file) and exit non-zero on failure; test_newskin copies the repo to a temp dir and verifies the real tree is untouched; test_controllers has 0 `check(` calls but appends to `fails` and exits 1 on any.
- render-icons.js/.py: dev-time, local files only, no network.

## PC-only verification

- install.ps1 end to end (Windows PowerShell 5.1): junction creation, IsFullScreen/MediaPlayer copy and `-Encoding Byte` path, rmskin Expand-Archive with footer, asset-selection sort, winget, layout backup/load, rerun idempotence, behaviour when Skins\Control-Plaine pre-exists.
- fan-tasks.ps1 as admin: task registration, `schtasks /run` without UAC, pwsh Store alias path, ACL of the script location after the R4-T1 fix.
- Rainmeter loading MediaPlayer.dll (error 193 case), and whether Rainmeter.ini copy while running is current.
- lint.yml on GitHub (permissions default) and a manual pages.yml dry run (repo variable absent should skip the job).
