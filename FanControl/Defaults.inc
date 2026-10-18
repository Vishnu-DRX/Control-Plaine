; Control-Plaine | FanControl: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the FanControl skin; add keys here with the FanControl prefix.

[Variables]
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

; ---- Runtime, not settings (State.inc overrides) ----
; 1 while the MAX profile is active.
FanControlMaxOn=0
