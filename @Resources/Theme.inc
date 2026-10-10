; Control-Plaine design tokens.
; Every skin includes this file. Change a value here, refresh all, and the whole suite follows.

[Variables]
; ---- Colour (R,G,B; alpha comes from the levels below) ----
Ink=255,255,255
Accent=0,250,200
Warn=255,170,60

; ---- Alpha levels (0-255) ----
; Rest: how things look when you are not touching them.
AlphaRest=110
; Hover: brightened state and revealed detail.
AlphaHover=235
; Faint: tracks, dividers, hints.
AlphaFaint=45

; ---- Type ----
FontUI=Segoe UI
FontDisplay=Anurati
SizeXS=9
SizeS=10
SizeM=12
SizeXL=46

; ---- Layout ----
; Global size multiplier for the whole suite.
Scale=1
IconSize=24
IconGap=10

; ---- Motion (ms) ----
; A fade is FadeSteps steps of FadeStep ms (10 x 15 = 150 ms).
FadeStep=15
FadeSteps=10
; Wait before revealed detail hides after the mouse leaves.
HideDelay=500
