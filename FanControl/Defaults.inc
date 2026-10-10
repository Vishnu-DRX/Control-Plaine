; Control-Plaine | FanControl: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the FanControl skin; add keys here with the FanControl prefix.

[Variables]
; Fan Control program (FanControl.exe). Its configs are in the Configurations
; folder next to it.
FanControlPath=C:\Program Files (x86)\FanControl\FanControl.exe
; Profile used when MAX is off.
FanControlNormal=userConfig.json
; Profile with every fan at 100%.
FanControlMax=Max.json
; Where the average fan speed is read. Only hwinfo (Gadget reporting) in V1.
FanControlSensor=hwinfo
; How the % is worked out: rpm (RPM / RPM at 100%) or duty (sensors are already %).
FanControlMode=rpm
; HWiNFO Gadget indexes of the fans to average, comma separated (up to 8).
FanControlIndexes=0,1,2,3
; RPM of each fan at 100%, same order as the indexes (rpm mode only).
FanControlMaxRPM=1790,1623,1849,1744
; Registry hive HWiNFO reports to: HKEY_CURRENT_USER or HKEY_LOCAL_MACHINE.
FanControlRegHKey=HKEY_CURRENT_USER
; Leave stopped fans (0 RPM, e.g. zero-RPM GPU fans) out of the average.
FanControlIgnoreStopped=1
; Run Fan Control through the ControlPlaine scheduled tasks (tools\fan-tasks.ps1)
; so there is no UAC prompt. 0 launches FanControl.exe directly.
FanControlUseTasks=1

; ---- Runtime, not settings (State.inc overrides) ----
; 1 while the MAX profile is active.
FanControlMaxOn=0
