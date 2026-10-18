; Control-Plaine | Volume: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the Volume skin; add keys here with the Volume prefix.

[Variables]
; Which screen edge the skin sits on: left puts the ring first with the text
; after it, right mirrors it (text first, ring last). AlignAll in Settings can
; override it.
VolumeAlign=left
; hover shows the text only while hovered, always keeps it visible.
; DetailsAll in Settings can override it.
VolumeDetails=hover
; 1 shows this skin's tooltips, 0 hides them all.
VolumeTooltips=1
; Percent per scroll notch.
VolumeStep=2
; Turning the volume up while muted unmutes.
VolumeScrollUnmutes=1
; Ring thickness in px.
VolumeRingStroke=5
; What the speaker icon opens: ms-settings:apps-volume (Windows mixer) or sndvol.exe (classic).
VolumeMixer=ms-settings:apps-volume
