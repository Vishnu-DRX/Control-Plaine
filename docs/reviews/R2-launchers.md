# Review R2: launchers and process control

Branch state: origin/main. Reviewer did not write this code. Read-only. `python tools/lint.py`: 0 problems. `tools/test_controllers.py`, `test_deepcool.py`, `test_media.py`, `test_playnite_uptime.py`: 0 failures.

## Findings

| id | severity | file:line | one line |
| --- | --- | --- | --- |
| R2-L1 | medium | Controllers/Controllers.ini:119, Controllers.ps1:23-27, Controllers.lua:96-99 | Unquoted, unvalidated `-DsxPort #ControllersDsxPort#` can override `-Poll`, or fail the helper into a 30 s respawn loop |
| R2-L2 | medium | Power.lua:196-215, Power.ini:111-135 | RunCommand measures have no Timeout; one hung PowerShell wedges the command queue until refresh |
| R2-L3 | medium | MediaOpen.ps1:41-42,63 | Tray-hidden app (MainWindowHandle 0) falls through to `Start-Process shell:AppsFolder\Spotify.exe`, which fails silently; OpenApp.ps1 already solves this |
| R2-L4 | low | Controllers.ini:199,268,337,406 | `-Target "#RowNTarget#"` breaks on a trailing backslash or `"`; no validation in `InputDone` |
| R2-L5 | low | DeepCool.ini:78,101, HideWindow.ps1:24, DeepCool.ini:52 | Two sources of truth for the process name (`DeepCoolProcess` vs file name of `DeepCoolPath`); `taskkill /IM` uses an unvalidated free-text value |
| R2-L6 | low | DeepCool.ini:78 | `-Arguments "#DeepCoolArgs#"` with a value starting with `-` is probably read as a parameter name, not a value |
| R2-L7 | low | Controllers.lua:39-40 | `-Process DSX` is hard-wired to the DualSense row even when `ControllersDualSenseApp` is another app |
| R2-L8 | low | Controllers.lua:41-42 | Wheel row has no `-Process`, so a double click can start two copies, against the OpenApp.ps1 header |
| R2-L9 | low | Power.lua:321-329 | Idle `paint()` every second: about 15 bangs plus `!Redraw`, with no change cache |
| R2-L10 | low | Controllers.ps1:342-353 | Persistent PowerShell does a full WMI HID query plus `Get-PnpDeviceProperty` for each Bluetooth pad every 3 s, even when the skin is hidden |
| R2-L11 | low | HideWindow.ps1:49-63 | 10 ms busy poll with managed EnumWindows callback for up to 20 s per start |
| R2-L12 | low | OpenApp.ps1, MediaOpen.ps1, Calendar.ps1, HideWindow.ps1 | Hidden launchers swallow every failure (no message, no log); focus code is copied three times |
| R2-L13 | low | RecycleBin.lua:63-67 | `RecycleBinConfirm=0` empties the bin on one click of a link that appears on hover |

No critical or high findings.

## Scenarios and fixes

**R2-L1.** Setting `ControllersDsxPort` is free text (`Settings/Controllers.ini:245` uses `EditPath`; `InputDone` strips only `#`). The value is appended unquoted to a `-File` command line.
- Input `1 -Poll 0`: the helper binds `Poll=0`, `Start-Sleep -Seconds 0` runs, and the loop spins on `Get-CimInstance Win32_PnPEntity` with no pause (100% of a core, constant WMI load). The `Step()` clamp of 1..30 on `ControllersPoll` is bypassed.
- Input `abc` or empty: parameter binding fails and the helper exits. Controllers.lua sees a stale or missing file and re-runs `mHelper` every 30 s, forever, with no message on the skin.
- There is no code injection: `-File` makes PowerShell treat extras as script arguments, not code.
- Fix: in `Controllers.lua`, never pass the raw string. Have `Update`/`Initialize` clamp `num('ControllersDsxPort')` to an integer 1..65535 (fallback 6969), write it to a derived variable, and use that in `mHelper`. Also clamp Poll and BatteryPoll in the script (`[ValidateRange(1,300)]`). Add a lint or test that every numeric arg to a `-File` call uses a validated source. Ownership: Controllers files belong to the Controllers owner.

**R2-L2.** `mShut` and `mPS` are RunCommand measures with no `Timeout` (default is no limit). `Done()` only runs from `FinishAction`, and `runNext()` returns early while `running` is set.
- If Task Scheduler is stuck (`Register-ScheduledTask` or `schtasks /query` blocks) or PowerShell hangs, `running` stays set. Every later click (schedule, cancel, sleep, shutdown) is queued and never starts. The label shows nothing and the user must refresh.
- `check()` at load queues a `query`, so this can happen right after login.
- Fix: add `Timeout=15000` to `mPS` and `mShut` (the `sleep` action blocks until resume, so give `sleep` its own measure without a timeout, or handle the timeout per step). Make `Done()` treat a timeout as code -1 and show `failText`. A watchdog in `runNext()` (clear `running` after N s) is the alternative.

**R2-L3.** `MediaOpen.ps1:41-42` needs `MainWindowHandle -ne 0`. A tray-minimised Spotify, Discord or foobar2000 has no main window handle (the same problem OpenApp.ps1 solves with EnumWindows, see its header).
- Input: Spotify closed to tray, music playing, click the title. `$proc` is null and line 63 runs `Start-Process "shell:AppsFolder\Spotify.exe"`, which is not an app id and throws (`$ErrorActionPreference='Stop'`). Hidden window, no feedback, nothing happens.
- Fix: move the OpenApp.ps1 window finder into one shared helper (dot-sourced `Focus.ps1`) and use it here. For a Win32 `.exe` app id with no window, fall back to launching by process name or path from `Get-Process ... .Path`.

**R2-L4.** `Row1Target` comes from free-text settings (`ControllersWheelApp`, `ControllersOther`, `ControllersDualSenseApp`). The quoting is correct for ordinary paths, but:
- Input `C:\Games\Pit House\` (a folder with trailing backslash): `-Target "C:\Games\Pit House\" -Process ""` is parsed by CommandLineToArgvW with `\"` as an escaped quote, so Target becomes `C:\Games\Pit House" -Process ` and `Start-Process` fails silently.
- A `"` in the value splits the argument.
- An empty `ControllersOther` gives `-Target ""` and a Mandatory-binding error. The tooltip still says "Open controller settings".
- A `]` in the path (for example `C:\Games [x64]\x.exe`) may end the `[...]` bracket command early. Only the PC can confirm this.
- These values are the user's own, so this is not escalation. The failure is a silent no-op.
- Fix: strip `"` for path and target keys in `InputDone` (Settings.lua is a shared file, send the change to its owner). Have `target()` in `Controllers.lua` strip a trailing `\` and fall back to `ms-settings:bluetooth` when empty.

**R2-L5.**
- `HideWindow.ps1:24` watches `Get-Process -Name <file name of DeepCoolPath>`. `DeepCool.lua` and `mStop` use `DeepCoolProcess` (default `DeepCool.exe`, with the `.exe`). If the user sets `DeepCoolPath` to a launcher stub whose process has another name, the window is never hidden and `exit 1` is returned; the skin still shows the state from `mProcess`.
- `taskkill.exe /IM "#DeepCoolProcess#" /T /F` force-kills every process with that image name and its children, using a free-text setting. Input `explorer.exe` makes DeepCool's toggle kill the shell, but only when the Process measure reports it as running, which is user-chosen.
- `/T /F` gives the app no chance to shut down cleanly.
- Fix: derive one name (from `DeepCoolProcess`) and pass it to HideWindow with `-Name`. Try `taskkill /IM name` without `/F` first, then `/F` after a few seconds. Optionally reject names that contain `*` or `\`.

**R2-L6.** PowerShell `-File` binding treats `-x` tokens as parameter names even after `-Arguments`. A value such as `--minimized` likely gives "Missing an argument for parameter 'Arguments'" and the helper exits 1. Defaults say no known args, so this affects only users who set `DeepCoolArgs`. Fix: use `-Arguments:"#DeepCoolArgs#"` (colon form), or pass it through an env var. PC-verify.

**R2-L7.** `target('dualsense')` always returns proc `DSX`. A user who points `ControllersDualSenseApp` at DS4Windows or Steam Input while DSX also runs gets DSX focused instead of their app, and DSX started nothing. Fix: return `DSX` only when the target is the default `steam://rungameid/1812620`, or add a `ControllersDualSenseProcess` setting.

**R2-L8.** The wheel row uses `Process=''`, so `OpenApp.ps1` just runs `Start-Process`. Two clicks within the app's startup time start two copies unless Pit House enforces single-instance itself (only the PC can tell). Fix: add an optional process setting, or derive it from the exe file name when the target ends with `.exe`.

**R2-L9.** `Power.lua` `Update()` runs every 1000 ms and calls `paint()` unconditionally, which does 3 `var()` lookups, one SetVariable per icon, several SetOption bangs, `UpdateMeterGroup` and `!Redraw`. Only the countdown text changes, and only while a schedule exists. Fix: cache the last state string (as `RecycleBin.lua` does) and repaint when it changes. At rest `Update` could return a long divider. This is cheap, but it runs all day.

**R2-L10.** Idle cost of the Controllers helper, every 3 s by default: a WQL query over all `HIDClass` devices (many properties), plus `Get-PnpDeviceProperty` for `KeyConnected` per Bluetooth pad on every scan (`Controllers.ps1:266`, not cached), plus a UDP probe. It runs when the skin has `SelfHidden=1` (no controllers). Fix: cache the PnP list and re-query on a device-change event or every N scans. Only the connected check needs polling. Measure CPU on the PC before changing.

**R2-L11.** `HideWindow.ps1` loops with `Start-Sleep -Milliseconds 10` and a managed EnumWindows callback (a PowerShell scriptblock marshalled per window) for up to 20 s. It is a one-off per click and the loop shortens to 4 s once a window is hidden, so the cost is bounded. The loop can still use noticeable CPU on a busy desktop. Fix: poll at 25-50 ms, or use `SetWinEventHook`. Low priority.

**R2-L12.** `OpenApp.ps1`, `MediaOpen.ps1`, `Calendar.ps1` and `HideWindow.ps1` run hidden and `-NonInteractive`, and report nothing on failure. The DeepCool skin recovers by timeout. The Calendar, Controllers and Media clicks just do nothing. The Win32 declarations and the Alt-tap focus trick are copied in OpenApp and MediaOpen (and the focus recipe is nearly copied in Calendar), so fixes like R2-L3 must be applied twice. Fix: a shared `Focus.ps1` and a one-line log (`%TEMP%\ControlPlaine-launch.log`, rotated) written by a `catch`.

**R2-L13.** With `RecycleBinConfirm=0` (opt-in; default is 1) `EmptyBinSilent` runs on a single click on the EMPTY link, which appears on hover and can end up under the pointer when a size becomes empty/non-empty. This is permanent data loss with no undo. Mitigation exists (the setting). Suggest the second-click arming pattern Power uses (`CLICK AGAIN`) as the silent path.

## Checked and clean

- **Command injection into PowerShell:** every skin-side PowerShell call uses `-File "<repo script>"`, so arguments are script parameters, never parsed as code. No `Invoke-Expression`, `iex` or `-Command` with setting text in the scope. Findings above are break-outs of argument parsing, not code execution.
- **`-ExecutionPolicy Bypass`** only on repo-owned scripts under `@Resources\Scripts`. `Power.ps1` runs from the same folder, which the user already controls. The scheduled sleep task points at the same script as the same user, so there is no privilege gap. No elevation anywhere in this scope (Fan Control tasks are another reviewer's).
- **Power:** task names are fixed (`ControlPlaineHibernate`, `Sleep`, `Lock`). `$Action` is looked up in a hashtable and any other value gives code 2. `Seconds` is `[int]` with a floor of 60. The task actions (`shutdown.exe /h`, `rundll32 ...LockWorkStation`, `powershell ... -File $PSCommandPath sleep`) contain no user text. `ShutArgs` and `PSArgs` are built only in `Power.lua` from fixed strings and a number (picker range 15..1440 minutes). Cancel/query use `schtasks /tn $name` with a fixed name. `StartWhenAvailable` is off, so a missed hibernate is not run late. Commands are serialised, with `queueCancel` before each new schedule. Expired schedules are cancelled and cleared.
- **`%TEMP%` read-back:** Controllers.ps1 and Controllers.lua share `%TEMP%\ControlPlaine-controllers.txt`. It is per-user, written atomically (tmp then Move-Item). The Lua pattern is strict (`^(%w+)|([^|]*)|(%-?%d+)|(%d)$`). Names are fixed strings written by the helper (`XBOX`, `DUALSENSE`...), never device-supplied. A stale file is rejected by timestamp, and removed at load. Only same-user code could plant it, and that adds nothing to what that code can already do. A mutex prevents duplicate helpers, and the helper exits when Rainmeter dies.
- **Controllers.ps1:** read-only, localhost UDP only with a 300 ms timeout, HID read has a timeout and `CancelIoEx`. DSX port is `[int]`-typed when bound (see R2-L1 for the argument path).
- **Playnite:** `["#PlaynitePath#" [#SplashArg[#PlayniteSkipSplash]]]` is quoted and the splash arg comes from a fixed table (`SplashArg0/1`).
- **SettingsButton:** only `!ActivateConfig` with root-config constants. The first-run trigger fires once per load while `SetupDone!=1` and stops after.
- **Calendar.ps1, MediaOpen.ps1:** the `Win` key-up is always sent after key-down (no exception path between them). The media app id comes from the Windows media session (same-user apps only). Wildcard names via `Get-Process -Name` could only be reached by a local app that sets its own AUMID, which is not a boundary here.
- **DeepCool:** no start/stop race in the skin: `Toggle()` ignores clicks while pending; the `pending` state needs process confirmation or the 30 s timeout. `mStart` Timeout 30 s exceeds HideWindow's 20 s. Chosen `Update`s (1000 ms, Process measure) are justified.
- **RecycleBin.lua:** plugin-based (RecycleManager), no process spawns. Change-cached repaint, `UpdateDivider=3` consistent.
- **Style rules:** lint is clean (ASCII, no inline `;`, no `!Show`/`!Hide` in the skin files, no user paths).

## PC-only verification

- Controllers.ini and Playnite `[...]` commands: behaviour with a `]` or trailing `\` in a path; whether Rainmeter expands `%LOCALAPPDATA%` in the Playnite `LeftMouseUpAction` run string.
- R2-L1: set `ControllersDsxPort` to `1 -Poll 0` and `abc` in Settings; watch CPU of `powershell.exe` and process spawns every 30 s.
- R2-L2: stop the Task Scheduler service (or add `Start-Sleep 60` to Power.ps1) and observe whether the skin recovers. Confirm RunCommand's Timeout/FinishAction behaviour on timeout.
- R2-L3: Spotify closed to tray with playing media; click the title. Same for foobar2000, Discord, a browser with minimised windows.
- R2-L6: does `-Arguments "--x"` bind under Windows PowerShell 5.1?
- State=Hide kills: whether the DeepCool app (started via `Start-Process` by HideWindow) and the `mStartShown` child survive a skin refresh or Rainmeter exit.
- DeepCool: hidden-start behaviour per app version; whether the process name of `DeepCoolPath` equals `DeepCoolProcess`.
- Power: sleep via `SetSuspendState` with hibernation on; the scheduled `sleep` task fires and resumes; `Done()` reads the printed exit code after wake; `shutdown /a` 1116; hibernate task skipped when the PC sleeps through it.
- Controllers helper idle CPU (3 s poll), with 0 and with 3 controllers, Bluetooth pad on/off; startup time of the first write against `staleAfter` (15 s).
- OpenApp.ps1: DSX hidden in tray, DSX running without window, Steam launch while DSX not running; double-click on the wheel row.
- Recycle Bin: Windows confirm dialog with `RecycleBinConfirm=1`, no dialog with 0.
- Calendar: Win+N toggle on Windows 10 and 11.
