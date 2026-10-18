; Control-Plaine | FanControl: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the FanControl skin; add keys here with the FanControl prefix.

[Variables]
; Which screen edge the skin sits on: left puts the fan icon first, right
; mirrors it (text first, icon last). AlignAll in Settings can override it.
FanControlAlign=left
; hover shows the text and snowflake only while hovered, always keeps them
; visible. DetailsAll in Settings can override it.
FanControlDetails=hover
; Colours for this skin: auto follows the global Theme, dark = white,
; light = black.
FanControlTheme=auto
; 1 shows this skin's tooltips, 0 hides them all.
FanControlTooltips=1
; Fan Control program (FanControl.exe). Its configs are in the Configurations
; folder next to it.
FanControlPath=C:\Program Files (x86)\FanControl\FanControl.exe
; Profile used when MAX is off.
FanControlNormal=userConfig.json
; Profile with every fan at 100%.
FanControlMax=Max.json
; Leave stopped fans (0 RPM, e.g. zero-RPM GPU fans) out of the average.
FanControlIgnoreStopped=1
; Run Fan Control through the ControlPlaine scheduled tasks (tools\fan-tasks.ps1)
; so there is no UAC prompt. 0 launches FanControl.exe directly.
FanControlUseTasks=1

; ---- Runtime, not settings ----
; Set by the needs check (Scripts\Needs.lua) at runtime; 1 until it says
; otherwise. 0 hides the function. See docs/guide/first-time-setup.md.
; 0 unless a required need is missing (1 hides the skin).
FanControlNeedBlocked=0
; 1 while the scheduled tasks exist (only checked while FanControlUseTasks=1).
FanControlHasTasks=1
; 1 while the sensor feed task exists (the live fan value).
FanControlHasSensors=1
; 1 while the MAX profile file exists (the snowflake switch).
FanControlHasMax=1
; Written to State.inc by FanControl.lua; State.inc overrides this default.
; 1 while the MAX profile is active.
FanControlMaxOn=0
