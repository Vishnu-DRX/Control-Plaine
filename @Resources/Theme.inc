; Control-Plaine design tokens (Design V1).
; These are the suite's design system, not user settings. User settings live in
; Defaults.inc (general), <Skin>\Defaults.inc (per skin) and User.inc (overrides).
; Values that depend on settings (rest alphas, accent) are set in Core.inc.
;
; Font sizes are points (Rainmeter FontSize is pt): pt = px * 0.75.
; Tracking is px at scale 1 (CharacterSpacing is in DIPs). Apply it on one
; side only, or the gap between letters doubles:
;   left-aligned or centred: CharacterSpacing | 0 | t
;   right-aligned:           CharacterSpacing | t | 0
; Multiply every size by #Scale#.

[Variables]
Version=2.0.0
RepoURL=https://github.com/Vishnu-DRX/Control-Plaine

; ---- Colour (R,G,B) ----
; Ink, InkContrast and Warn are the dark-mode values (for dark wallpapers).
; Core.lua replaces them with the Light values below when the mode is light.
Ink=255,255,255
Warn=255,170,60
; Glyphs drawn on an ink-coloured fill (the charging bolt).
InkContrast=0,0,0
InkLight=0,0,0
InkContrastLight=255,255,255
WarnLight=214,110,0
Dark=18,20,24
Shadow=0,0,0,115
; Text shadows follow their text: shadow alpha = text alpha x ShadowK, so a
; label faded to 0 leaves no dark outline (like CSS opacity on the canvas).
ShadowRGB=0,0,0
ShadowK=0.45

; ---- Alpha (0-255) that do not follow settings ----
; Ring tracks, hairlines (18%).
AlphaTrack=46
; Hover (98%).
AlphaHover=250
; Disabled or unselected (45%).
AlphaOff=115

; ---- Type ----
; Win10 or a PC without Segoe UI Variable: set FontFace=Segoe UI in User.inc.
FontFace=Segoe UI Variable Display
; Display: 52px, Day-Date day name.
SizeDisplay=39
WeightDisplay=400
TrackDisplay=15.6
; Value: 20px (S = 18px, L = 22px). Volume %, track title, uptime.
SizeValue=15
SizeValueS=13.5
SizeValueL=16.5
WeightValue=400
TrackValue=1.8
; Title: 12.5px. RECYCLE BIN, date line.
SizeTitle=9.5
WeightTitle=600
TrackTitle=5
; Detail: 9.5px. Device name, counts, labels, links.
SizeDetail=7.25
WeightDetail=600
TrackDetail=2.4

; ---- Shapes ----
RingRadius=22
RingStroke=5
; Ring look; a skin may override RingColor / RingWidth in its own [Variables].
RingColor=#Accent#
RingWidth=#RingStroke#
RingTrack=Fill Color 0,0,0,0 | StrokeWidth (#RingWidth#*#Scale#) | Stroke Color #Ink#,#AlphaTrack#
RingFill=Fill Color 0,0,0,0 | StrokeWidth (#RingWidth#*#Scale#) | Stroke Color #RingColor#,255 | StrokeStartCap Round | StrokeEndCap Round
; Visual icon size; every icon PNG is a IconBox square with IconPad of
; transparent margin around the icon. PNGs are stored at the size they are
; shown (tools/render-icons.py), so Rainmeter never resamples them.
IconSize=24
IconPad=4
IconBox=32

; ---- Motion (ms) ----
; A fade is FadeSteps steps of FadeStep ms (12 x 15 = 180 ms).
FadeStep=15
FadeSteps=12
; Wait before revealed detail hides after the mouse leaves.
HideDelay=500

; ---- Legacy v1 names ----
; Still used by the v1 skins until each is rebuilt. Do not use in new code.
FontUI=Segoe UI
FontDisplay=Segoe UI
SizeXS=9
SizeS=10
SizeM=12
SizeXL=46
IconGap=10
AlphaFaint=45
; Core.inc replaces these from the user's settings.
AlphaRest=153
AlphaDetail=153
AlphaValue=204
Accent=0,229,255
