; Control-Plaine | FanControl: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the FanControl skin; add keys here with the FanControl prefix.

[Variables]
; Fan Control program (FanControl.exe).
FanControlPath=
; Profile used when MAX is off.
FanControlNormal=userConfig.json
; Profile with every fan at 100%.
FanControlMax=Max.json
; Where the average fan speed is read: lhm or hwinfo.
FanControlSensor=lhm
