; Control-Plaine | SettingsButton: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the SettingsButton skin; add keys here with the SettingsButton prefix.

[Variables]
; Which screen edge the skin sits on: left puts the gear first, right mirrors
; it (label first, gear last). AlignAll in Settings can override it.
SettingsButtonAlign=left
; hover shows SETTINGS only while hovered, always keeps it visible.
; DetailsAll in Settings can override it.
SettingsButtonDetails=hover
; 1 shows this skin's tooltips, 0 hides them all.
SettingsButtonTooltips=1
; Colours for this skin: auto follows the global Theme, dark = white,
; light = black.
SettingsButtonTheme=auto
