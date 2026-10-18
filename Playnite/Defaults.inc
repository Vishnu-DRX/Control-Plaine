; Control-Plaine | Playnite: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the Playnite skin; add keys here with the Playnite prefix.

[Variables]
; Which screen edge the skin sits on: left puts the art first, right mirrors it
; (label first, art last). AlignAll in Settings can override it.
PlayniteAlign=left
; hover shows PLAYNITE only while hovered, always keeps it visible.
; DetailsAll in Settings can override it.
PlayniteDetails=hover
; Colours for this skin: auto follows the global Theme, dark = white,
; light = black.
PlayniteTheme=auto
; 1 shows this skin's tooltips, 0 hides them all.
PlayniteTooltips=1
; Playnite program.
PlaynitePath=%LOCALAPPDATA%\Playnite\Playnite.DesktopApp.exe
; Open Playnite without its splash screen.
PlayniteSkipSplash=1

; ---- Runtime, not settings ----
; Set by Core.lua from Setup\NeedsList.lua at load and about once a
; minute. BLOCKED (PlaynitePath not found) hides the skin.
PlayniteNeedState=OK
PlayniteNeedBlocked=0
