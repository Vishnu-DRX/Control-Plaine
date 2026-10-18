; Control-Plaine | Power: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the Power skin; add keys here with the Power prefix.

[Variables]
; Colours for this skin: auto follows the global Theme, dark = white,
; light = black.
PowerTheme=auto
; 1 shows this skin's tooltips, 0 hides them all.
PowerTooltips=1
; What the first icon does: hibernate or sleep.
PowerFirst=hibernate
; Restart and shut down need a second click.
PowerConfirm=1
; Minutes the schedule picker opens on.
PowerPickerStart=60

; ---- Runtime, not settings ----
; Written by the skin to @Resources\State.inc (git-ignored); these are the
; "nothing scheduled" values for a fresh install.
PowerScheduledAction=
PowerScheduledAt=0
PowerScheduledBoot=0
; 1 while Windows' task scheduler is available. Set by the needs check
; (Needs.lua); 0 hides SCHEDULE.
PowerHasSchedule=1
