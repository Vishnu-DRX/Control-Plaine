; Control-Plaine | RecycleBin: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the RecycleBin skin; add keys here with the RecycleBin prefix.

[Variables]
; Which screen edge the skin sits on: left puts the icon first with the text
; after it, right mirrors it (text first, icon last). AlignAll in Settings can
; override it.
RecycleBinAlign=left
; hover shows the text only while hovered, always keeps it visible.
; DetailsAll in Settings can override it.
RecycleBinDetails=hover
; Colours for this skin: auto follows the global Theme, dark = white,
; light = black.
RecycleBinTheme=auto
; 1 shows this skin's tooltips, 0 hides them all.
RecycleBinTooltips=1
; Windows asks to confirm when you click Empty.
RecycleBinConfirm=1
; The size turns orange above this many GB.
RecycleBinWarnGB=10

; ---- Runtime, not settings ----
; Set by the needs check (Needs.lua). RecycleBinHasEmpty: 1 while EMPTY can
; work, 0 hides the EMPTY link. RecycleBinNeedBlocked: 1 hides the skin (the
; Recycle Bin plugin is missing).
RecycleBinHasEmpty=1
RecycleBinNeedBlocked=0
