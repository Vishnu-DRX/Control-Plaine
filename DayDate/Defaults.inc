; Control-Plaine | DayDate: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the DayDate skin; add keys here with the DayDate prefix.

[Variables]
; 1 shows this skin's tooltips, 0 hides them all.
DayDateTooltips=1
; What a click opens: calendar (the Windows calendar flyout, Win+N), or any
; program, file or URI (for example https://calendar.google.com).
DayDateClick=calendar
; Which edge the lines line up to: left or right. AlignAll in Settings can
; override it. The skin's footprint is the same on both sides.
DayDateAlign=left
; hover: dim at rest, brighter on hover (as before). always: both lines stay at
; the hover brightness. DetailsAll in Settings can override it.
DayDateDetails=hover
; show: the small date line is always visible. hover: hidden until the mouse is
; over the skin. (DayDateDetails=always or DetailsAll=always also show it.)
DayDateDateLine=show
