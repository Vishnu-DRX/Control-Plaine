# Review R3: data/network scripts and elevated fan task

Base: origin/main (6b2068b). `python tools/lint.py`: 0 problems. All tools/test_*.py pass (10/10). Scope read in full: WiFi.lua, FanControl.lua, FanControlSensors.ps1, tools/fan-tasks.ps1, SignalRGB.lua, SignalRGBApply.ps1, Media.lua, MediaOpen.ps1, Volume.lua, Uptime.lua, and the Plugin/WebParser sections of the skin .ini files.

## Findings

| id | severity | file:line | one line |
| --- | --- | --- | --- |
| R3-D1 | critical | tools/fan-tasks.ps1:79,88-89 | Highest-privilege task runs a script from the user-writable Skins folder: UAC bypass for any same-user process |
| R3-D2 | medium | tools/fan-tasks.ps1:27-29,88; FanControlSensors.ps1:59 | Elevated reader loads DLLs and tasks launch FanControl.exe from any path given, with no check that the folder is admin-only |
| R3-D3 | medium | FanControlSensors.ps1:30-37 | Elevated process writes predictable `%TEMP%\ControlPlaine-fans.txt(.tmp)`: arbitrary-file overwrite via symlink (Developer Mode) |
| R3-D4 | medium | tools/fan-tasks.ps1:63-64; FanControl.lua:119-126; FanControl.ini:97-103 | `-MultipleInstances Parallel` plus a 30 s retry spawns an elevated pwsh 7 every 30 s while Fan Control is closed or the file is stale |
| R3-D5 | low | FanControlSensors.ps1:27-28,43-53 | Reader lifetime is tied to Rainmeter.exe, not the skin: keeps polling elevated forever once the skin is unloaded |
| R3-D6 | low | FanControlSensors.ps1:27 | `Local\` mutex name can be pre-created by any same-session process, so the reader exits silently (denial of service) |
| R3-D7 | low | SignalRGB.lua:332,411; Settings/SignalRGB.ini:157 | `SignalRGBPort` is free text spliced unquoted into curl arguments and the WebParser URL |
| R3-D8 | low | SignalRGB.lua:421-422,446-460 | `SignalRGBMoveParams` is inserted unescaped into a cmd.exe command line (a `"` breaks out) |
| R3-D9 | low | WiFi.lua:217-218 | `--accept-license --accept-gdpr` accepts Ookla's terms for the user on the first click, with no notice |
| R3-D10 | low | fan-tasks.ps1:60,87; FanControl.lua:110 | Task principal and `%TEMP%` come from the elevating account; with a different admin account the file never reaches the skin |
| R3-D11 | low | fan-tasks.ps1:73,76 | `$Normal`/`$Max` go into the task argument unquoted; a config name with a space breaks the task |
| R3-D12 | low | FanControl.lua:119-126 | With `FanControlUseTasks=1` and no tasks installed, schtasks.exe is spawned every 30 s forever |

## Findings in detail

### R3-D1 (critical) Elevation path writable by a normal user
Where: `fan-tasks.ps1:79` sets `$script` to `<repo>\@Resources\Scripts\FanControlSensors.ps1`. Lines 88-89 register it with `-RunLevel Highest` as `pwsh -NoProfile -File "<script>"`. `tools/install.ps1:7-12` puts the repo in `Documents\Rainmeter\Skins\Control-Plaine` (a junction to the git checkout).
Scenario: any process running as the user at medium integrity (a malicious npm or pip postinstall, a browser exploit, a Rainmeter skin from the internet) appends `Start-Process cmd` to `FanControlSensors.ps1`, then runs `schtasks /run /tn ControlPlaine\FanSensors`. That executes with an admin token and no UAC prompt. The skin itself does this every time it runs the task (`FanControl.ini:97`). A `git pull` of an untrusted branch has the same effect. The task exists precisely to avoid UAC, so this undoes the UAC boundary for that user.
Fix (any one):
- Have `fan-tasks.ps1` copy `FanControlSensors.ps1` to an admin-only location (`%ProgramFiles%\Control-Plaine\` or `%ProgramData%` with the ACL reset to Administrators and SYSTEM write-only) and register that copy. Re-run the script to update it, and print a note about this in the script header.
- Pin integrity: store the SHA-256 in the task action and verify it in a tiny admin-owned launcher.
- Minimum: make `fan-tasks.ps1` refuse, or require `-Force`, if the script's folder is writable by non-admins (check the ACL for `BUILTIN\Users`, `Authenticated Users` or the current user with Write or Modify).
Also add a lint or test rule that fan-tasks.ps1 never registers an elevated action whose path is under `$PSScriptRoot`'s parent. Document the model in docs/guide and docs/dev.

### R3-D2 (medium) Fan Control folder is trusted blindly
`-FanControlPath` is any admin-supplied path. Portable Fan Control (a zip in Downloads) is common. Then (a) the three tasks run an exe a normal user can replace, and (b) `FanControlSensors.ps1:59` `Assembly.LoadFrom`s four DLLs from that folder into an elevated process, so a planted `Google.Protobuf.dll` gives elevated code execution. The default Program Files path is safe.
Fix: in fan-tasks.ps1, check that the Fan Control folder and exe are not writable by non-admins (`Get-Acl`), and throw otherwise. Do the same in the reader for `$FanControlDir` (refuse if the folder is not under Program Files or is user-writable).

### R3-D3 (medium) Predictable temp file written by an elevated process
`FanControlSensors.ps1:32` `WriteAllLines("$Out.tmp")` and `:35` `Move($tmp,$Out,$true)` run elevated against `%TEMP%\ControlPlaine-fans.txt(.tmp)`, which the user and any same-user process control. With Developer Mode (unprivileged symlinks), a process pre-creates `ControlPlaine-fans.txt.tmp` as a symlink to a protected file. The elevated task then overwrites it with `ts|...` lines (or `error|<message>`). A system file is corrupted (DoS), though the content is not freely chosen. Same-user processes can also forge fan data (cosmetic).
Fix: write to a directory only the elevated process and the user can read but not replace, e.g. create `%LOCALAPPDATA%\ControlPlaine` with a restrictive ACL. Open with `FileMode.Create` and `FileShare.Read` on the real file. Reject reparse points (check `FileAttributes.ReparsePoint` before writing). Or drop the temp file: let the skin read the data via a named pipe or `curl` to localhost.

### R3-D4 (medium) Elevated pwsh respawned every 30 s
`fan-tasks.ps1:63-64` sets `-MultipleInstances Parallel` for every task, including FanSensors. The `FanControl.ini:97-100` comment ("a no-op while one is already running") is wrong for this setting. A new pwsh 7 starts and exits only at the mutex check (`FanControlSensors.ps1:27-28`, after the module and runtime load). `FanControl.lua:138-141` calls `startReader()` on every `error|` file and every stale ts. With Fan Control closed (the reader writes `error|Fan Control is not running` and retries), `average()` returns the error branch each 2 s tick, and `startReader` fires every `RETRY = 30` s. That is one elevated pwsh 7 process (about 100-300 ms CPU, 40-60 MB) every 30 s for as long as the skin is up.
Fix: register FanSensors with `-MultipleInstances IgnoreNew` (separate settings object), and only call `startReader` when the file is missing or ts is stale (not on `error|`, since the live reader already retries every 5 s).

### R3-D5 (low) Reader outlives the skin
`Test-Rainmeter` (FanControlSensors.ps1:46-53) looks only for any `Rainmeter.exe`. If the user unloads or disables the Fan Control skin, the elevated reader polls Fan Control's pipe every 2 s until Rainmeter exits. Fix: also stop when the ts file is not being read (e.g. the skin touches a heartbeat file), or when the skin's window is gone; at minimum document it.

### R3-D6 (low) Mutex squatting
`[Mutex]::new($true,'Local\ControlPlaine.FanControlSensors')`: a same-session medium-integrity process creating this name first makes the task exit 0 immediately, so the fan readout stays empty. Fix: a Global mutex with an ACL, or lock a file in the admin-owned folder from R3-D1.

### R3-D7 (low) SignalRGBPort not validated
Input: Settings window -> SignalRGBPort = `16038 -o C:\Users\me\x.txt`. `SignalRGB.lua:411` builds `... http://localhost:16038 -o C:\Users\me\x.txt/api/v1/lighting/...`, so curl gets extra arguments. `InputDone` strips only `#`. It is the user's own input, so impact is low, but the checklist asks for validation. Fix: `local port = tostring(tonumber(v) and math.floor(tonumber(v)) or 16038)` in Initialize, accepting 1-65535 only. Same for the `#SignalRGBPort#` in `mApi` URL (WebParser; there it can only malform the URL).

### R3-D8 (low) Move params reach cmd.exe unescaped
Input: User.inc `SignalRGBMoveParams=a=1" & calc & "`. `apply()` (SignalRGB.lua:421) puts it in `cmd /c start "" /b powershell ... -Url "<url>"`, and cmd runs `calc`. The effect name is %-escaped; the params are not. Not exposed in the Settings UI (only the config file), so low. Fix: percent-encode every character outside `[%w%%&=%-._~]` in `params` and reject `"`.

### R3-D9 (low) Licence auto-accepted
WiFi.lua:218 passes `--accept-license --accept-gdpr` the first time the user clicks the speed-test icon. Consider noting it in the guide page (`docs/guide/wifi`) and the tooltip so the consent is deliberate.

### R3-D10 (low) Wrong account
`fan-tasks.ps1:60` takes `$env:USERDOMAIN\$env:USERNAME` from the elevated session. A standard user who elevates with a separate admin account gets tasks running as the admin, with `$env:TEMP` of the admin, while the skin reads the standard user's `%TEMP%` (FanControl.lua:110). Fan data never appears. Fix: detect via `explorer.exe` owner or a `-User` parameter; warn if the elevating user differs from the interactive user.

### R3-D11 (low) Unquoted config names
`FanMax = "-c $Max"`: `-Max "My Max.json"` registers `-c My Max.json`. Quote the value in the argument.

### R3-D12 (low) schtasks spam when no tasks exist
`FanControlUseTasks` defaults to 1. If fan-tasks.ps1 was never run, `average()` finds no file and calls `startReader()` every 30 s, which launches `schtasks.exe /run` and fails each time (a hidden process spawn, plus Rainmeter log noise). Fix: back off exponentially or stop after N failures; show the existing hint text.

## Checked and clean
- `python tools/lint.py`: 0 problems; `tools/test_*.py`: all pass.
- WiFi speed test: `WiFiSpeedtestPath` is only used if `io.open` succeeds, so a path containing `"` or `&` cannot reach the `call "..."` command line. Output goes to `%TEMP%\ControlPlaine-speedtest.json`; Lua reads it with fixed patterns and bounded loops, and nothing is executed from it. `mSpeedRun` has `Timeout=120000`, and `mSpeedTimer` polling is capped at 480 x 250 ms. No download is made by the skin (the install click only opens https://www.speedtest.net/apps/cli), so there is nothing to pin. TLS is not bypassed anywhere.
- The SSID is returned from `Update()` as text (never parsed as a bang or variable). `fitName` is bounded.
- SignalRGB API: localhost only; curl has `-m 3`; the WebParser is plain `http://localhost` (SignalRGB's API has no TLS or credentials, so there is no token to leak); the regexes extract digits and `true|false` only, so a hostile local listener on the port cannot inject values. Brightness is clamped 0-100. Poll rate backs off (2 s, then 30 s after 15 misses). The free-mode colour is validated as 6 hex digits before it is used.
- SignalRGBApply.ps1 runs only through `-ExecutionPolicy Bypass` on a suite-owned file; `Start-Process $Url` takes a `signalrgb://` URL built from an escaped name and validated hex.
- FanControl.lua: reads only `CACHE` and the sensor file; `FanControlMax` and `FanControlNormal` are used only for string comparison in task mode (the task arguments are fixed); `schtasks /run /tn ControlPlaine\<fixed name>` has no user-controlled part. Parsing uses `tonumber` and bounded patterns. In non-task mode `FanControlPath` is passed as Program, not shell-expanded.
- FanControlSensors.ps1: read-only RPC (`GetAllSensors`), 3 s deadline on every call, and the file is replaced atomically with retries. Output sanitises `|` and newlines in error text. No credentials or network access beyond the local pipe.
- fan-tasks.ps1 principal is the interactive user with `Highest` (not SYSTEM), and the Max config is written to the admin-owned `Configurations` folder with BOM-less UTF-8.
- Media.lua, Volume.lua, Uptime.lua: no process spawns, files or network. Volume sends only `ChangeVolume +/-N` with N from `math.floor(num(...))` and `SetVolume p` with p 1-100. Media's seek sends an integer 0-99 to the plugin. Uptime updates every 15 s with `UpdateDivider=15`.
- MediaOpen.ps1: runs only on click, reads the media session's app id; the process name comes from an `.exe` AUMID or a fixed table; `Start-Process shell:AppsFolder\<aumid>` is an OS-registered id. It is run with `-ExecutionPolicy Bypass` on a suite file only. The `SendKeys`-style Alt tap is a known foreground-lock workaround.
- Update dividers: WiFi 1 s base with divider 2 on all measures and one script; Volume 500 ms (needed for the live volume ring); Fan Control reads one small file every 2 s; the `mRamp`/`mSpin` timers run only during a switch.

## PC-only verification
- R3-D1/D2/D3: with the tasks registered, from a non-admin shell edit `FanControlSensors.ps1` (append `whoami /groups > %TEMP%\x.txt`), run `schtasks /run /tn ControlPlaine\FanSensors`, and confirm whether it runs at High integrity. Check `icacls` on the Skins folder and Fan Control folder.
- R3-D3: confirm the symlink behaviour with Developer Mode on.
- R3-D4: count `pwsh.exe` starts per minute (Process Monitor or Security 4688) with Fan Control closed; confirm `-MultipleInstances` behaviour of `schtasks /run`.
- R3-D5: unload the skin and check that `pwsh.exe` stays alive.
- Ookla CLI behaviour (progress JSON, result line, `--accept-*`), the speed-test timeout kill and `FinishAction` firing on timeout.
- SignalRGB: 403 and offline behaviour without Pro, `curl.exe` PATCH working with the escaped body, the `signalrgb://` registration value, and window hiding by SignalRGBApply.ps1.
- Fan Control: the pipe `\\.\pipe\FanControl` answers only elevated clients, the `.NET 10` DLL load in pwsh 7.4+, `schtasks /run` from Rainmeter (no UAC prompt), the Store alias path for pwsh.exe, and the CACHE file format.
- Media/Volume plugin behaviour and ring seek geometry.
