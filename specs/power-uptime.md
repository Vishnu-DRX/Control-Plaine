# Spec: Power and Uptime skins

Investigation output for the V1 build. Source of truth for behaviour and look: `docs/DESIGN-V1.md` and the V1 canvas. This file says **how** to build it in Rainmeter, what changes from the design, and what must be checked on Vishnu's PC.

Shared conventions come from `specs/foundation-settings.md` and this spec follows them: the skin template (section 2), `Defaults.inc` per skin, `User.inc` for settings, `State.inc` for runtime state, Core.inc for fade/accent/full-screen, the shared styles, and the agreed keys `PowerFirst`, `PowerConfirm`, `PowerPickerStart`, `UptimeWarnDays`, `UptimeAlways`, `PowerScheduledAt`. No FOUNDATION file is edited by this work.

## Verdict

Everything in the design is achievable with stock Rainmeter (ActionTimer, RunCommand, Uptime measure) plus one Lua script per skin. No third-party plugin is needed. One design detail changes:

- **Scheduled hibernate uses PowerShell `Register-ScheduledTask`, not `schtasks /create /sd /st`.** `schtasks /sd` takes the date in the system's short-date format (dd/mm vs mm/dd differs by locale) and `/st` only has minute precision, so a Lua-built `schtasks` line is fragile. PowerShell with `(Get-Date).AddSeconds(N)` is locale-proof and second-accurate. Cancel and query can stay on `schtasks` (`/delete`, `/query`), which take no dates.

Nothing is impossible. Two known limits are listed under "Limits".

## Power skin

### Files (skin thread owns all of these)
- `Power/Power.ini`: rewrite on the foundation template (Version 2.0.0, Group ControlPlaine, ContextAction opens `Settings\Power.ini`). Sleep becomes Hibernate, the uptime line goes.
- `Power/Defaults.inc`: `PowerFirst=hibernate`, `PowerConfirm=1`, `PowerPickerStart=60`.
- `Settings/Power.ini`: fills the foundation stub. Rows: FIRST BUTTON choice HIBERNATE/SLEEP (`Set('PowerFirst',...,'Power')`), ASK TO CONFIRM toggle (`Toggle('PowerConfirm','Power')`), PICKER START value box 15-1440 step 15 shown as `1 H` (`Step('PowerPickerStart',15,15,1440,'Power')`).
- `@Resources/Scripts/Power.lua`: rewrite; owns all state.
- Icons: foundation renders `docs/icons/power-*.svg` to `@Resources\Icons\power-hibernate.png`, `power-shutdown.png`, `power-restart.png`, `power-lock.png` (128 px, `sIcon`, `IconBox`/`IconPad`). Sleep has no V1 icon: added `docs/icons/power-sleep.svg` (crescent, same stroke style) rendered to `power-sleep.png` with the foundation's pipeline. The old `sleep.png` is no longer used by Power. Tint at runtime with `ImageTint` = `#Ink#`, `#Warn#` or `#Accent#`.
- Styles used: `sHit`, `sIcon`, `sDetail` (labels), `sValue` (picker value, countdown), `sLink` + `sLinkLine` (SCHEDULE, SET, CANCEL), `sWarn`, `sAccent`. Per-icon hover snaps via MouseOverAction (allowed by foundation 4.3); the links fade with `Reveal` from Core.inc.

### Layout (three rows, four columns)
```
row 1  label      HIBERNATE / CLICK AGAIN / SHUT DOWN IN 58 M
row 2  icons      [hib] [shut] [restart] [lock]
row 3  link       SCHEDULE / CANCEL
```
Picker mode replaces rows 1 to 3 with `SHUT DOWN IN` / time `3 H 15 M` with a small vertical double-ended arrow (one connected shape, like a vertical <->) on its left (no outline box; the arrow shows it scrolls). SET sits right under the X (cancel) in the top-right corner. Arrow, title and time are left-aligned in one block centred once and sized for the longest time (`23 H 45 M`), so scrolling never changes any width or position. / `SET` (plus a small `BACK` or click-icon-to-close, see Picker).

Order of icons: hibernate (or sleep, setting), shut down, restart, lock, as in the design.

### Hover without flicker
Each icon gets an invisible **column hit meter** (`sHit`) spanning rows 1 to 3 of its column, so moving from the icon down to SCHEDULE never leaves the column. The icon and link meters sit on top. Rainmeter sends hover only to the topmost meter with mouse actions, so every element (column, icon, link) reports `Over(el)` / `Out(el)` and Power.lua keeps the set of elements under the mouse: the hovered action is that of the element entered last that is still in the set. No timers, and order of the over/leave events does not matter.

The whole-skin hit area stays, so the gaps between columns still count as the skin.

### Immediate actions
All commands are `RunCommand` measures with `State=Hide` (no console window). Lua calls `!CommandMeasure mRun "Run"` after setting `Program`/`Parameter` with `!SetOption`.

| Action | Command | Confirm |
|---|---|---|
| Hibernate | `shutdown.exe /h` | no |
| Sleep (alt first button) | `powershell.exe -NoProfile -WindowStyle Hidden -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Application]::SetSuspendState('Suspend',$false,$false)"` | no |
| Shut down | `shutdown.exe /s /t 0` | second click |
| Restart | `shutdown.exe /r /t 0` | second click |
| Lock | `rundll32.exe user32.dll,LockWorkStation` | no |

Every action has SCHEDULE, lock included. SCHEDULE / CANCEL sit under the icon last hovered and switch position when another icon is hovered. The focused icon only clears when the mouse leaves the skin, so the link never fades out and in between icons. A scheduled lock is a one-time task `ControlPlaineLock` (`rundll32.exe user32.dll,LockWorkStation`), made like the hibernate and sleep tasks.

Sleep note: the current skin uses `rundll32 powrprof.dll,SetSuspendState 0,1,0`, which **hibernates** when hibernation is on. With Hibernate now its own button, Sleep must be a real sleep, hence the PowerShell call.

Second click (when `PowerConfirm=1`, the default; `0` runs shut down and restart on the first click): keep today's pattern. First click arms (icon tint Warn, row 1 `CLICK AGAIN` in Warn), `mDisarm` ActionTimer `Wait #ConfirmTimeout#` (3000) disarms. Second click on the same icon runs it. Clicking another icon disarms the first.

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

**Errors.** Each RunCommand measure has `FinishAction=[!CommandMeasure mPower "Done('<step>')"]`. Lua reads the measure's value (the exit code). `shutdown /a` returning **1116** (nothing was scheduled) counts as success, so cancel-then-set and CANCEL never fail on an already-gone shutdown. Any other non-zero: show `COULD NOT SCHEDULE` (or `COULD NOT CANCEL`) in Warn on row 1 for 3 s and do not write state.

**Scheduled look.** The scheduled action's icon is tinted Accent at full alpha; row 1 shows `SHUT DOWN IN 58 M` in Accent and row 3 shows `CANCEL` (accent underline), all visible at rest. Countdown format: `2 H 58 M`, then `58 M`, and in the last minute `45 S`. Lua recomputes it every update (`Update=1000`).

### Surviving refresh, Rainmeter restart and reboot
State goes in the foundation's git-ignored `@Resources\State.inc` (already in the template as `@include5`; install.ps1 creates it). Keys, with defaults in `Power/Defaults.inc` so a missing State.inc still works (the notes after each key are for the reader; in the file, comments go on their own line):

```
PowerScheduledAt=0          epoch seconds the action fires (Lua os.time()+N); 0 = nothing scheduled
PowerScheduledAction=       shutdown | restart | hibernate | sleep
PowerScheduledBoot=0        boot time in epoch seconds (os.time() - uptime) when it was set
```
Written with `!WriteKeyValue Variables <key> <value> "#@#State.inc"` and also `!SetVariable` locally; read in `Initialize()` with `SKIN:GetVariable`. Writing state must not refresh the skin.

On `Initialize()`:
1. `PowerScheduledAt=0`: normal mode.
2. `now > due + 60`: the time has passed; clear state (and delete the task if hibernate/sleep).
3. Shut down / restart, and the boot time now differs from `PowerScheduledBoot` by more than 120 s: the PC restarted, which cancels any pending `shutdown /t`; clear state.
4. Hibernate / sleep: run `schtasks /query /tn ControlPlaineHibernate` (or `ControlPlaineSleep`); exit code non-zero means the task is gone (deleted elsewhere); clear state. Otherwise resume the countdown.
5. Otherwise resume the countdown from `due`.

When the countdown reaches 0 the skin shows nothing special; it clears state on the next load (step 2) or after `due + 60` while still running.

### Settings
Keys as agreed in the foundation spec: `PowerFirst` (hibernate | sleep), `PowerConfirm` (1 = shut down and restart need a second click), `PowerPickerStart` (minutes). `ConfirmTimeout=3000` stays a skin-local variable, not a setting. Changing `PowerFirst` refreshes Power, which keeps any running schedule (state survives refresh).

## Uptime skin

### Files (skin thread owns)
- `Uptime/Uptime.ini` on the foundation template, `Uptime/Defaults.inc` (`UptimeWarnDays=5`, `UptimeAlways=0`), `@Resources/Scripts/Uptime.lua`.
- `Settings/Uptime.ini`: RESTART REMINDER AFTER value box 1-30 days (`Step('UptimeWarnDays',1,1,30,'Uptime')`), ALWAYS VISIBLE toggle (`Toggle('UptimeAlways','Uptime')`).
- Styles: `sHit`, `sDetail`/`sReveal` (UPTIME label), `sValue` (time), `sWarn` modifier.

### Why the old one went stale, and the fix
The Phenix skin set its text from `IfTrueAction`, which only fires when the condition flips. Here a Lua script measure sets the text **and** the state on every run, unconditionally:
- `[mUptime] Measure=Uptime` (seconds since boot, the same count as Task Manager).
- `[mScript] Measure=Script`, `UpdateDivider=15` with skin `Update=1000`, so the text is never more than 15 s old. It also runs once from `MouseOverAction` so the value is fresh the moment it is revealed.
- No `IfCondition`/`IfTrueAction` anywhere.

### Look and states
- Hit area: `sHit` meter sized to the two text lines. Fully transparent pixels get no mouse events, so alpha 1 is required for "invisible but hoverable".
- "Invisible at rest" is done with text alpha, **not** with `SelfHidden`: a hidden skin cannot be hovered. Uptime never touches `SelfHidden`, so it still hides in full screen through Core.
- Normal: `UPTIME` (Detail) over `14 H 32 M` (Value), alpha `#AlphaHover#*#Reveal#` (group Reveal, Core.inc fade). At rest alpha 0.
- Past threshold (`days >= UptimeWarnDays`): `RESTART RECOMMENDED` over `6 DAYS 3 H` with `sWarn`, visible at rest. Lua sets skin-local `Shown=1` and the meters use alpha `(#Shown#*#AlphaValue#+(#AlphaHover#-#Shown#*#AlphaValue#)*#Reveal#)`, so they sit at rest level and brighten on hover.
- `UptimeAlways=1`: normal state also sets `Shown=1`.
- Format: `< 1 H` gives `45 M`; under a day `14 H 32 M`; from a day `1 DAY 3 H` / `6 DAYS 3 H`.

### Header comment must say
With Fast Startup on, Shut down is a hibernate of the kernel and does **not** reset uptime; only Restart does. To make Shut down reset it, turn off Fast Startup (Control Panel > Power Options > Choose what the power buttons do). Uptime also counts time spent asleep or hibernated, as Task Manager does.

### Settings
`UptimeWarnDays` (keeps its v1 name, so the existing User.inc value carries over) and `UptimeAlways`.

## Limits
1. **A shutdown cancelled outside the skin** (someone runs `shutdown /a`) keeps showing a countdown until it expires. Windows has no clean way to ask "is a shutdown pending?". Restarts are detected (boot time check) and hibernate is verified (task query), so this only affects shut down / restart cancelled by hand.
2. **Fast Startup + scheduled shut down** then power on: boot time does not change, so a stale countdown could show until its due time passes. Does not apply on Vishnu's PC (Fast Startup is off, probe 2026-10-10).

## Check on Vishnu's PC before calling these done

Probe results (2026-10-10, `/mnt/project-files/Control-Plaine-probes.md`): **1 done** (Hibernate available, Fast Startup off, hybrid sleep unavailable), **3 done** for registering without admin (firing on time still to see), **4 done** (query 0 present / 1 absent, delete 0), **5 done** (schedule 0, second 1190, `/a` 0, `/a` with nothing 1116; toast look not seen). Still open: 2, 3 (firing), 6, 7, 8, 9.

1. `powercfg /a` lists Hibernate as available; if not, `powercfg /hibernate on` (admin) is needed for both hibernate paths. Also note whether Fast Startup is on.
2. `shutdown /h` run from the skin (non-elevated) hibernates.
3. The `Register-ScheduledTask` line above works from the skin without admin, fires at the right second while the PC is unlocked and while locked, and does not fire after a wake if the time was missed.
4. `schtasks /query /tn ControlPlaineHibernate` returns 0 when present and non-zero when absent; `/delete /f` works non-elevated.
5. `shutdown /s /t 86400` is accepted; note what Windows 11 shows (toast now and a warning near the end); `shutdown /a` cancels; a second schedule returns 1190 (so the replace order cancel-then-set is right).
6. The Sleep PowerShell line sleeps (not hibernates) with hibernation on.
7. Writing `State.inc` with `!WriteKeyValue` through the junction works and does not trigger a refresh (foundation check 7 covers User.inc the same way).
8. Uptime skin text matches Task Manager > Performance > Up time, and keeps ticking after a sleep/wake and after leaving the PC idle for an hour.
9. The hover column: moving from an icon to SCHEDULE and back never flickers the label at 100% and 250% scale.
