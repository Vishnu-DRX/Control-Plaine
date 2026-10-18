# Review: Settings engine (R1)

Scope: @Resources/Scripts/Settings.lua, Settings/*.ini, @Resources/Settings/*.inc, Core.lua, User.inc/State.inc writers, value-to-sink paths. Onboarding work skipped.
Baseline: `python tools/lint.py` 0 problems; every `tools/test_*.py` 0 failures (two skip: `lupa` not installed). No Lua interpreter here, so Lua behaviour below is read from code, not run.
Threat model: User.inc is user-writable, so the realistic attacker is a pasted string or a typo, not a remote party. "Escalation" below means a boundary that is crossed (elevated task), not the user running their own command.

## Findings

| id | sev | file:line | one line |
|---|---|---|---|
| R1-S1 | high | @Resources/Settings/Chrome.inc:274 + Scripts/Settings.lua:205 | `InputDone([[$UserInput$]])` pastes raw text into a Lua chunk: `]]` ends the string and runs code; `"` or `]` break the bang |
| R1-S2 | high (outside scope, owner Fan Control) | tools/fan-tasks.ps1:89 | Elevated (RunLevel Highest) FanSensors task runs a script from the user-writable Skins folder with no UAC |
| R1-S3 | medium | Scripts/Settings.lua:147-148,172 | Value reaches `SKIN:Bang` args unescaped; a `"` can split the argument list of `!WriteKeyValue` / `!SetVariable` |
| R1-S4 | medium | DayDate/DayDate.ini:75 | `-Target "#DayDateClick#"`: value ending in `\` or containing `"` corrupts the PowerShell command line |
| R1-S5 | medium | Uptime/Uptime.ini:78, Playnite/Playnite.ini:89,102 | `["#UptimeClick#"]` / `["#PlaynitePath#" ...]`: value is substituted into an action string, so `"` and `]` break out and extra bangs can be appended |
| R1-S6 | medium | Scripts/Settings.lua:263-274,353,378 | User.inc rewritten in place (`io.open 'wb'` truncates), no temp-file-and-rename, no backup; Reset wipes all settings after two clicks |
| R1-S7 | medium | Scripts/Settings.lua:158-178,367-379 | Scroll edits live only in a 600 ms timer; tab switch, Close or Reset inside the window loses or resurrects them |
| R1-S8 | medium | Scripts/Settings.lua:252-274 | UTF-16 round trip strips every NUL byte, then doubles every byte on write: any non-Latin-1 character in User.inc is corrupted by CLEAN |
| R1-S9 | low | Scripts/FanControl.lua:243,245 | `'-c ' .. FanControlMax` unquoted: a profile name with a space is split (non-task mode); in task mode the Settings boxes do not change what runs |
| R1-S10 | low | Scripts/SignalRGB.lua:60 + SignalRGB.ini:78 | `SignalRGBPort` is not validated and is pasted into a URL: `1@host` sends the request to another host |
| R1-S11 | low | Scripts/Settings.lua:7-11,285-295 | `TABS` is a second copy of the skin list; a skin missing from it makes CLEAN delete that skin's valid settings. Lint does not tie TABS to SKIN_FOLDERS |
| R1-S12 | low | Scripts/Settings.lua:195-203 | AccentColor accepts channels above 255 and any digit count |
| R1-S13 | low | Scripts/Settings.lua:36-54,250,299 | `active` and `unknownCache` are read once; external changes make toggles and the CLEAN notice stale |
| R1-S14 | low | Scripts/SignalRGB.lua:222 | Non-.exe target is run as `SKIN:Bang('"'..target..'"')`; a `.exe` with arguments is treated as a bang string |

## Scenarios and fixes

### R1-S1 (high) Lua injection through the path/colour box
Chrome.inc:274 `Command1=[!CommandMeasure mSettings "InputDone([[$UserInput$]])"]`. InputText substitutes `$UserInput$` into text that Rainmeter then runs as a Lua chunk.
- Input `]]) os.execute("calc") --` becomes `InputDone([[]]) os.execute("calc") --]])`. Lua closes the string at the first `]]` and runs the rest (if `os.execute` is exposed; the scripts already use `io` and `os.getenv`).
- Even without malice: pasting `"C:\Program Files\Foo\foo.exe"` (a quoted path, very common) puts `"` inside the bang's own `"..."` argument, and a value containing `]` or `]]` (for example `...\a[1]]`) ends the `[!...]` bang or the Lua string early. Result: syntax error, the box silently does nothing, or the text is cut at the quote.
- `InputDone` strips only `#`, so nothing in Lua can repair this, since the text arrives after the code is already built.
Fix: do not paste user text into code. Preferred (PC to confirm): read it in Lua, e.g. have `Command1=[!CommandMeasure mSettings "InputDone()"]` and call `SKIN:GetMeasure('mInput'):GetStringValue()` (or the plugin's equivalent). If InputText cannot return the text, use a high-level bracket with a marker, `[==[$UserInput$]==]`, and a second guard; but `"` still breaks the outer bang argument, so tell users to type without quotes and strip a single pair of surrounding quotes in a pre-step. Add a lint rule that bans `$UserInput$` inside `[[...]]`.

### R1-S2 (high, outside this scope) elevated task runs user-writable script
tools/fan-tasks.ps1:89-91 registers `FanSensors` with `-RunLevel Highest` and `-File "...\@Resources\Scripts\FanControlSensors.ps1"`. That file lives in the Skins checkout under the user profile. Any process running as the user can append a line to it and trigger the task (`schtasks /run /tn ControlPlaine\FanSensors`, no UAC) for admin code execution. The FanMax/FanNormal/FanOpen tasks are safe (they run FanControl.exe from Program Files with fixed arguments).
Fix: at install, copy the sensor script to an admin-only location (`%ProgramData%\ControlPlaine\` with ACL for Administrators write only) and register the task against the copy; re-run fan-tasks.ps1 after updates (it already says to). Route to the Fan Control owner.

### R1-S3 (medium) bang argument splitting
Settings.lua:147 `SKIN:Bang('!WriteKeyValue','Variables',key,value,userInc)`. Rainmeter's Lua `Bang` builds one command string from the arguments (believed: each wrapped in double quotes; PC to confirm). A value containing `"` ends the quote: value `x" "C:\Users\me\Skins\foo.ini` shifts the arguments so the file argument becomes the attacker-chosen path (Rainmeter limits writable locations, which the PC must confirm). Realistic case: `Foo "bar` stored truncated or not at all, while `!SetVariable` on the next line applies a different string, so the live UI and User.inc disagree.
Fix: in `Set` (and `Step`, `Commit`) reject values containing `"`, CR or LF (return without writing, show a hint), the same place `#` is stripped. One helper `clean(text)` used by every writer.

### R1-S4 (medium) DayDate PowerShell argument
DayDate.ini:75 `-File "...Calendar.ps1" -Target "#DayDateClick#"`. powershell.exe parses the command line with Windows rules.
- `DayDateClick=C:\Apps\Notes\` (a folder, trailing backslash) gives `-Target "C:\Apps\Notes\"`; `\"` is an escaped quote, so Target swallows the rest of the line and Start-Process fails.
- A value with `"` adds extra parameters (`foo" -Bar "x`), which `param()` rejects, so the click does nothing.
- Running any program here is by design (it is a "run this" box); there is no privilege gain, only breakage.
Fix: strip one trailing `\` and reject `"` before writing (S3 helper), or pass the target base64/through an environment variable; at least document "no quotes, no trailing backslash" in docs/guide/DayDate.md.

### R1-S5 (medium) action-string substitution
Uptime.ini:78 `LeftMouseUpAction=["#UptimeClick#"]`; Playnite.ini:89 and :102 `["#PlaynitePath#" [#SplashArg[#PlayniteSkipSplash]]]`. Rainmeter replaces the variable first and then parses bangs.
- `UptimeClick=taskmgr.exe"] [!Refresh] ["` becomes `["taskmgr.exe"] [!Refresh] [""]`, so a value can add bangs (re-evaluation as a bang, as the checklist asks). Same privilege as the box already grants, so not an escalation, but a pasted path containing `"` or `]` (`D:\Games [x64]\app.exe`, balanced brackets are fine, `a]b` is not) breaks the click silently.
Fix: same sanitiser as S3 (reject `"`, `[`, `]` in click/path keys); the Settings.lua `Show` path should flag a value that was rejected. The three sinks are in other skins' files (owners), but the filter belongs in the Settings engine.

### R1-S6 (medium) non-atomic writes and Reset with no backup
`writeFile` (Settings.lua:263) opens User.inc with `'wb'`, which truncates it before writing. A crash, a full disk, or Rainmeter being killed between truncate and close leaves an empty or half file, and the user's settings are gone. `Reset` (367-379) replaces the whole file with `[Variables]` after a second click with no copy kept. Rainmeter's own `!WriteKeyValue` calls (WritePrivateProfileString) are separate writers of the same file: both run on Rainmeter's main thread so they do not interleave within one session, but a second Rainmeter instance or an editor (the Settings footer links to User.inc, Chrome.inc:227) saving at the same time loses one side.
Fix: write to `User.inc.tmp`, then `os.remove` + `os.rename` (Windows rename does not overwrite); before Reset and CLEAN copy to `User.inc.bak` (one generation), and say so in the Reset description.

### R1-S7 (medium) pending scroll edits
`Step` (158) sets the variable and arms a 600 ms timer (Chrome.inc:258); `Commit` writes. Clicking a tab (Chrome.inc:66-164 `!ActivateConfig ... Settings`), Close (`!DeactivateConfig`, :240) or Refresh within 600 ms unloads the script: the new value was shown but is never written, and the next load shows the old one. Reverse case: scroll a value, click RESET within 600 ms; `Reset` does not clear `pending`/`pendingTargets`, so `Commit` re-creates the key in the freshly emptied User.inc.
Fix: in `Reset` set `pending, pendingTargets = {}, {}` and `!CommandMeasure mCommit "Stop 1"`; for tab/close, call `Commit()` from `OnCloseAction`/before `!ActivateConfig` (a `Flush()` bang in each tab action) or write immediately and only debounce the skin refresh.

### R1-S8 (medium) UTF-16 handling loses characters
`readFile` removes all NUL bytes, `writeFile(wide)` adds a NUL after every byte. That is only correct for characters below U+0100 whose high byte is 0 and whose low byte is not 0.
Input: a User.inc written by Rainmeter as UTF-16 containing `PlaynitePath=C:\<Cyrillic folder>\Playnite.exe` (U+0418 = bytes 18 04). After CLEAN the file holds U+0018, U+0004 and similar garbage, and the path is broken; a character with low byte 0 (for example U+0100) loses a byte entirely. CLEAN is the only path that preserves content (Reset overwrites), so only users with non-ASCII paths are hit, but they lose the data silently.
Fix: decode UTF-16LE properly (pairs, surrogates) into UTF-8 and encode back; or in wide mode edit at the byte level (drop only lines whose zero-stripped text matches, copy other lines' raw bytes untouched). Add a lupa test with a Cyrillic path.

### R1-S9 (low) Fan Control names
FanControl.lua:243,245 (non-task mode) `Parameter = '-c ' .. name`: `FanControlMax=Max Fans.json` runs `-c Max Fans.json`. Quote it (`-c "name"`), after rejecting `"` (S3). In task mode (default) Settings/FanControl.ini edits of path, Normal and Max do not change the task arguments (fixed by fan-tasks.ps1 at install), yet FanControl.lua:230 still compares CACHE with the edited Normal name. The row text (FanControl.ini:104) only mentions the script for the Max profile. Add a "re-run tools\fan-tasks.ps1 after changing" note on these rows and in docs/guide/FanControl.md.

### R1-S10 (low) port not validated
`SignalRGBPort` edited through the same box. `1@evil.example` makes `http://localhost:1@evil.example/api/v1/lighting`, and lighting state is sent to that host (checklist: only localhost endpoints). Fix: accept only digits 1-65535 for this key (generalise `InputDone` to a per-key validator table, like `toRGB` for AccentColor).

### R1-S11 (low) TABS drift
CLEAN deletes every User.inc key not found in root Defaults, Theme, or a Defaults file of a skin in `TABS`. All 14 current skin folders are listed today (verified), but a new skin added to SKIN_FOLDERS and not to TABS has all its saved settings listed as "unknown" and deleted on the first CLEAN. Fix: lint rule that `TABS` (parsed from Settings.lua) matches `SKIN_FOLDERS` plus General, Advanced, SettingsButton; or build the list from `docs/skins.json`.

### R1-S12, S13, S14 (low)
- S12: `AccentColor` input `999,0,0` or `0000000000,1,1` is stored; Core.lua:117 only validates the Windows value, `Darken` clamps but dark mode does not. Clamp to 0-255 in `toRGB`.
- S13: `active` is read once at Initialize; closing a skin from its own menu while Settings is open leaves its toggle on, and the first click does nothing. `unknownCache` is never cleared after a manual edit of User.inc until refresh. Re-read in `SkinOn` or on `OnFocus`; cheap.
- S14: SignalRGB.lua:222 `SKIN:Bang('"'..target..'"')` only handles a bare path/URI; `C:\x\SignalRGB.exe --minimized` does not end in `.exe` and is not run.

## Checked and clean
- Include order and variable flow (Theme, Defaults, skin Defaults, User, Core, Styles) in Settings pages; every `Set`/`Step`/`EditPath` key in Settings/*.ini exists in a Defaults file (lint passes).
- `#` stripped before write (Settings.lua:214) and `Core.lua get()` re-resolves variables only for known keys; no `%` or `;` handling issue: Rainmeter .inc files treat `;` as a comment only at line start, `%` is not special in Rainmeter, and `WiFi.lua expand()` only expands `%NAME%`.
- `Step`/`Commit`: numeric values are formed in Lua (`tostring` of a rounded number), not from user text; min/max clamps correct; targets come from fixed strings in the .ini.
- `toRGB` hex and RGB branches reject everything else; `InputDone` ignores a call with no active edit key.
- State.inc: written only by Power.lua, FanControl.lua, SignalRGB.lua with fixed keys and Lua-generated values (action string from a fixed set); no user text reaches it. State.inc and User.inc are different files, so the Settings engine and skins do not write the same file.
- Settings.lua never runs a process; it only calls Rainmeter bangs. `SKIN:Bang('!Refresh', root..'\\'..t)` uses `active` keys from a fixed list.
- `reset`/`clean` never touch State.inc. CLEAN keeps comments and unrelated lines byte-for-byte in the ANSI case.
- Efficiency: `mSettings` UpdateDivider=-1, `unknownKeys()` caches (16 file reads once per load), Core.lua only issues `!SetVariable` on change (UpdateDivider=5). Settings pages `Update=1000` with inline Lua per meter is acceptable for a window that is open briefly.
- Elevated FanMax/FanNormal/FanOpen tasks: fixed arguments, FanControl.exe in an admin-only folder.

## PC-only verification
- Whether `SKIN:Bang` quotes each argument (R1-S3) and whether a `"` in the value shifts the arguments of `!WriteKeyValue`; which file locations `!WriteKeyValue` refuses.
- R1-S1: type `]]) os.execute("calc") --`, `"C:\x\a.exe"`, `a]b` into a path box and into the AccentColor box; confirm what runs and what is stored. Whether `os.execute` exists in Rainmeter's Lua, and whether InputText exposes the text to Lua (preferred fix).
- Whether Rainmeter writes User.inc as UTF-16 on a fresh install, and the R1-S8 round trip with a Cyrillic path.
- R1-S7: scroll, then switch tab/close within 600 ms; scroll then RESET.
- R1-S4/S5: click behaviour for `C:\Apps\`, `a]b`, `a"b` with DayDateClick, UptimeClick, PlaynitePath.
- R1-S2: the FanSensors task runs elevated and the script path ACL on the PC.
- Timing: whether `SKIN:Bang('!WriteKeyValue')` is synchronous with the following `!RefreshGroup` (skins must read the new value).
