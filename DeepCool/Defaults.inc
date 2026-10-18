; Control-Plaine | DeepCool: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the DeepCool skin; add keys here with the DeepCool prefix.

[Variables]
; Which screen edge the skin sits on: left puts the icon first, right mirrors
; it (text first, icon last). AlignAll in Settings can override it.
DeepCoolAlign=left
; hover shows the label and bulb only while hovered, always keeps them visible.
; DetailsAll in Settings can override it.
DeepCoolDetails=hover
; Colours for this skin: auto follows the global Theme, dark = white,
; light = black.
DeepCoolTheme=auto
; 1 shows this skin's tooltips, 0 hides them all.
DeepCoolTooltips=1
; DeepCool program that drives the case screen.
DeepCoolPath=C:\DeepCool\DeepCool.exe
; Process name used to tell if the app is running.
DeepCoolProcess=DeepCool.exe
; Open straight to the tray, no window.
DeepCoolStartHidden=1
; Extra arguments passed when starting the app (none known for DeepCool).
DeepCoolArgs=
; Hover label: screen (CASE SCREEN) or app (DEEPCOOL).
DeepCoolLabel=screen
; Seconds STOPPING TELEMETRY stays after the app has exited: the case screen takes about
; this long to actually go dark.
DeepCoolOffDelay=7

; ---- Runtime, not settings ----
; Set by the needs check (Scripts\Needs.lua) at runtime; 1 until it says
; otherwise. 0 hides the function. See docs/guide/first-time-setup.md.
; 0 unless a required need is missing (1 hides the skin).
DeepCoolNeedBlocked=0
; 1 while a process name is set (the bulb).
DeepCoolHasBulb=1
