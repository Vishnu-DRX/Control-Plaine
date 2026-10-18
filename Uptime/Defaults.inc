; Control-Plaine | Uptime: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the Uptime skin; add keys here with the Uptime prefix.

[Variables]
; 1 shows this skin's tooltips, 0 hides them all.
UptimeTooltips=1
; Uptime shows itself in orange past this many days.
UptimeWarnDays=5
; What a click opens.
UptimeClick=taskmgr.exe
; Which screen edge the skin sits on: left grows the text rightwards from the
; edge, right grows it leftwards. AlignAll in Settings can override it.
UptimeAlign=left
; hover shows the text only while hovered, always keeps it visible (the
; reminder past UptimeWarnDays shows itself either way). DetailsAll in
; Settings can override it.
UptimeDetails=hover
