# Spec: Power and Uptime skins

Investigation output for the V1 build. Source of truth for behaviour and look: `docs/DESIGN-V1.md` and the V1 canvas. This file says **how** to build it in Rainmeter, what changes from the design, and what must be checked on Vishnu's PC.

Shared conventions (User.inc keys, state file location, Settings refresh, accent, full-screen hide) belong to `specs/foundation-settings.md`. It did not exist when this was written; where this spec names a file or key that the foundation spec defines differently, the foundation spec wins.

## Verdict

Everything in the design is achievable with stock Rainmeter (ActionTimer, RunCommand, Uptime measure) plus one Lua script per skin. No third-party plugin is needed. One design detail changes:

- **Scheduled hibernate uses PowerShell `Register-ScheduledTask`, not `schtasks /create /sd /st`.** `schtasks /sd` takes the date in the system's short-date format (dd/mm vs mm/dd differs by locale) and `/st` only has minute precision, so a Lua-built `schtasks` line is fragile. PowerShell with `(Get-Date).AddSeconds(N)` is locale-proof and second-accurate. Cancel and query can stay on `schtasks` (`/delete`, `/query`), which take no dates.

Nothing is impossible. Two known limits are listed under "Limits".

## Power skin

### Files
- `Power/Power.ini` (rewrite of the current one; Sleep becomes Hibernate, uptime line removed).
- `@Resources/Scripts/Power.lua` (rewrite; owns all state).
- Icons: render `docs/icons/power-hibernate.svg`, `power-shutdown.svg`, `power-restart.svg`, `power-lock.svg` to PNG at 1x/2x/3x (same pipeline as the existing icons). Tinted at runtime with `ImageTint` (white base PNG, tint = Ink, Warn or Accent).

### Layout (three rows, four columns)
```
row 1  label      HIBERNATE / CLICK AGAIN / SHUT DOWN IN 58 M
row 2  icons      [hib] [shut] [restart] [lock]
row 3  link       SCHEDULE / CANCEL
```
Picker mode replaces rows 1 to 3 with `SHUT DOWN IN` / value box `3 H 15 M` / `SET` (plus a small `BACK` or click-icon-to-close, see Picker).

Order of icons: hibernate (or sleep, setting), shut down, restart, lock, as in the design.

### Hover without flicker
Each icon gets an invisible **column hit meter** (`Meter=Image`, `SolidColor=0,0,0,1`) spanning rows 1 to 3 of its column, so moving from the icon down to SCHEDULE never leaves the column. The visible icon and link meters sit on top. Rainmeter only sends mouse events to the topmost meter that has mouse actions, so moving onto the link fires a leave on the column. To stop that hiding the link:

- `Leave(key)` does not hide immediately; it starts an ActionTimer `Wait 120 | ClearHover`.
- Any `Hover(key)` (column, icon or link) stops that timer first.

The whole-skin hit area stays, so the gaps between columns still count as the skin.

### Immediate actions
All commands are `RunCommand` measures with `State=Hide` (no console window). Lua calls `!CommandMeasure mRun "Run"` after setting `Program`/`Parameter` with `!SetOption`.

| Action | Command | Confirm |
|---|---|---|
| Hibernate | `shutdown.exe /h` | no (setting `PowerConfirm` can add it) |
| Sleep (alt first button) | `powershell.exe -NoProfile -WindowStyle Hidden -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Application]::SetSuspendState('Suspend',$false,$false)"` | no |
| Shut down | `shutdown.exe /s /t 0` | second click |
| Restart | `shutdown.exe /r /t 0` | second click |
| Lock | `rundll32.exe user32.dll,LockWorkStation` | no |

Sleep note: the current skin uses `rundll32 powrprof.dll,SetSuspendState 0,1,0`, which **hibernates** when hibernation is on. With Hibernate now its own button, Sleep must be a real sleep, hence the PowerShell call.

Second click: keep today's pattern. First click arms (icon tint Warn, row 1 `CLICK AGAIN` in Warn), `mDisarm` ActionTimer `Wait #ConfirmTimeout#` (3000) disarms. Second click on the same icon runs it. Clicking another icon disarms the first.

### Scheduling

**Picker**
- SCHEDULE on a column opens picker mode for that action; value starts at `PowerPickerStart` minutes (default 60).
- `MouseScrollUpAction` on the value box: +15 min; down: -15 min; clamp 15 to 1440. No wrap.
- Display: `45 M`, `1 H`, `3 H 15 M`, `24 H`. Title: `HIBERNATE IN` / `SHUT DOWN IN` / `RESTART IN`.
- SET schedules and returns to normal mode. Clicking the action's icon again, or leaving the skin for 3 s (ActionTimer), closes the picker without scheduling.

**One schedule at a time.** Windows allows only one pending `shutdown /t` (a second returns error 1190), and three parallel countdowns would not fit the layout. Setting a new schedule replaces the old one: cancel old, then set new.

**Commands**

| Action | Schedule | Cancel |
|---|---|---|
| Shut down | `shutdown.exe /s /t N` (N seconds) | `shutdown.exe /a` |
| Restart | `shutdown.exe /r /t N` | `shutdown.exe /a` |
| Hibernate | see below | `schtasks.exe /delete /tn ControlPlaineHibernate /f` |
| Sleep | same as hibernate, action = the sleep PowerShell line, task name `ControlPlaineSleep` | `schtasks /delete /tn ControlPlaineSleep /f` |

`shutdown /h` cannot take `/t`, which is why hibernate needs a task. Hibernate task, run via RunCommand:
```
powershell.exe -NoProfile -WindowStyle Hidden -Command "$a=New-ScheduledTaskAction -Execute 'shutdown.exe' -Argument '/h'; $t=New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(N); $s=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; Register-ScheduledTask -TaskName 'ControlPlaineHibernate' -Action $a -Trigger $t -Settings $s -Force"
```
- No `-User`/`-RunLevel`: the task runs as the logged-on user, which needs no admin (verify).
- `StartWhenAvailable` stays off (the default), so a task missed because the PC was asleep or off does **not** fire later on wake.
- Note `shutdown /t N` with N > 0 implies `/f` (apps are closed without asking). That is right for an unattended timer; mention it in the skin's header comment.

**Errors.** Each RunCommand measure has `FinishAction=[!CommandMeasure mPower "Done('<step>')"]`. Lua reads the measure's value (the exit code). Non-zero: show `COULD NOT SCHEDULE` (or `COULD NOT CANCEL`) in Warn on row 1 for 3 s and do not write state.

**Scheduled look.** The scheduled action's icon is tinted Accent at full alpha; row 1 shows `SHUT DOWN IN 58 M` in Accent and row 3 shows `CANCEL` (accent underline), all visible at rest. Countdown format: `2 H 58 M`, then `58 M`, and in the last minute `45 S`. Lua recomputes it every update (`Update=1000`).

### Surviving refresh, Rainmeter restart and reboot
State goes to a git-ignored runtime file, **not** User.inc (that is settings) and not `Power.ini` (that is tracked in git through the junction). Proposed: `@Resources\State.inc` with section `[Variables]`, keys:

```
PowerSchedAction=shutdown|restart|hibernate|sleep|   (empty = none)
PowerSchedDue=<epoch seconds, from Lua os.time()+N>
PowerSchedBoot=<epoch seconds of boot = os.time() - uptime, at scheduling>
```
Written with `!WriteKeyValue Variables <key> <value> "#@#State.inc"`; read in `Initialize()` with `SKIN:GetVariable` (Power.ini `@include`s State.inc; ship `State.example.inc` and have install/first run create it, as with User.inc). Add `@Resources/State.inc` to `.gitignore`.

On `Initialize()`:
1. No action: normal mode.
2. `now > due + 60`: the time has passed; clear state (and delete the task if hibernate/sleep).
3. Shut down / restart, and the boot time now differs from `PowerSchedBoot` by more than 120 s: the PC restarted, which cancels any pending `shutdown /t`; clear state.
4. Hibernate / sleep: run `schtasks /query /tn ControlPlaineHibernate`; exit code non-zero means the task is gone (deleted elsewhere); clear state. Otherwise resume the countdown.
5. Otherwise resume the countdown from `due`.

When the countdown reaches 0 the skin shows nothing special; it clears state on the next load (step 2) or after `due + 60` while still running.

### Settings (User.inc keys, names to match the foundation spec)
- `PowerFirstButton=hibernate` (`sleep`)
- `PowerConfirm=0` (1 = hibernate/sleep also need a second click; shut down and restart always do)
- `PowerPickerStart=60` (minutes, 15 to 1440, scroll in 15s)
- `ConfirmTimeout=3000` stays a skin variable.

## Uptime skin

### Files
- `Uptime/Uptime.ini`, `@Resources/Scripts/Uptime.lua`.

### Why the old one went stale, and the fix
The Phenix skin set its text from `IfTrueAction`, which only fires when the condition flips. Here a Lua script measure sets the text **and** the state on every run, unconditionally:
- `[mUptime] Measure=Uptime` (seconds since boot, the same count as Task Manager).
- `[mScript] Measure=Script`, `UpdateDivider=15` with skin `Update=1000`, so the text is never more than 15 s old. It also runs once from `MouseOverAction` so the value is fresh the moment it is revealed.
- No `IfCondition`/`IfTrueAction` anywhere.

### Look and states
- Hit area: `Meter=Image`, `SolidColor=0,0,0,1` sized to the two text lines. Fully transparent pixels get no mouse events, so alpha 1 is required for "invisible but hoverable".
- Normal: `UPTIME` (Detail) over `14 H 32 M` (Value), both at alpha `#AlphaHover# * #Reveal#` via `Fade.inc` (group Reveal). At rest alpha 0.
- Past threshold (`days >= UptimeWarnDays`): `RESTART RECOMMENDED` over `6 DAYS 3 H`, both in Warn and visible at rest (alpha = rest level, brighter on hover). Lua sets a variable `Due=1`, and the meters use `Max(#Reveal#, #Due#*RestFactor)` like today's `UpWarn`.
- `UptimeAlwaysVisible=1`: normal state visible at rest too.
- Format: `< 1 H` gives `45 M`; under a day `14 H 32 M`; from a day `1 DAY 3 H` / `6 DAYS 3 H`.

### Header comment must say
With Fast Startup on, Shut down is a hibernate of the kernel and does **not** reset uptime; only Restart does. To make Shut down reset it, turn off Fast Startup (Control Panel > Power Options > Choose what the power buttons do). Uptime also counts time spent asleep or hibernated, as Task Manager does.

### Settings
- `UptimeWarnDays=5` (already in User.example.inc)
- `UptimeAlwaysVisible=0`

## Limits
1. **A shutdown cancelled outside the skin** (someone runs `shutdown /a`) keeps showing a countdown until it expires. Windows has no clean way to ask "is a shutdown pending?". Restarts are detected (boot time check) and hibernate is verified (task query), so this only affects shut down / restart cancelled by hand.
2. **Fast Startup + scheduled shut down** then power on: boot time does not change, so a stale countdown could show until its due time passes. Same root cause as 1; acceptable.

## Check on Vishnu's PC before calling these done
1. `powercfg /a` lists Hibernate as available; if not, `powercfg /hibernate on` (admin) is needed for both hibernate paths. Also note whether Fast Startup is on.
2. `shutdown /h` run from the skin (non-elevated) hibernates.
3. The `Register-ScheduledTask` line above works from the skin without admin, fires at the right second while the PC is unlocked and while locked, and does not fire after a wake if the time was missed.
4. `schtasks /query /tn ControlPlaineHibernate` returns 0 when present and non-zero when absent; `/delete /f` works non-elevated.
5. `shutdown /s /t 86400` is accepted; note what Windows 11 shows (toast now and a warning near the end); `shutdown /a` cancels; a second schedule returns 1190 (so the replace order cancel-then-set is right).
6. The Sleep PowerShell line sleeps (not hibernates) with hibernation on.
7. ActionTimer and RunCommand load with no errors in the Rainmeter log (both are in the current skin, so expected fine).
8. Uptime skin text matches Task Manager > Performance > Up time, and keeps ticking after a sleep/wake and after leaving the PC idle for an hour.
9. The hover column: moving from an icon to SCHEDULE and back never flickers the label at 100% and 250% scale.
