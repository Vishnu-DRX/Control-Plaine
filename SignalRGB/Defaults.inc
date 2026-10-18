; Control-Plaine | SignalRGB: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the SignalRGB skin; add keys here with the SignalRGB prefix.

[Variables]
; Which screen edge the skin sits on: left puts the icon first, right mirrors
; it (text first, icon last). AlignAll in Settings can override it.
SignalRGBAlign=left
; hover shows the text only while hovered, always keeps it visible.
; DetailsAll in Settings can override it.
SignalRGBDetails=hover
; Colours for this skin: auto follows the global Theme, dark = white,
; light = black.
SignalRGBTheme=auto
; 1 shows this skin's tooltips, 0 hides them all.
SignalRGBTooltips=1
; What clicking the icon opens. auto = the SignalRGB launcher, found through
; its signalrgb:// registration (the exe sits in a versioned folder that
; changes with every update). Or a program path, or a link.
SignalRGBPath=auto
; Brightness change per scroll notch (%).
SignalRGBStep=5
; auto = use the local API when it answers (SignalRGB Pro), else just open the
; app. 0 = never use the API.
SignalRGBApi=auto
; Port of SignalRGB's local API.
SignalRGBPort=16038

; ---- Edit in User.inc ----
; Personal values with no Settings row.

; Free mode (no SignalRGB Pro): the skin applies this effect with the
; signalrgb://effect/apply link and sets brightness by scaling its color.
; Needs an effect with a "color" property, such as Solid Color. Empty =
; launcher only. Set the color to match the one you use in SignalRGB.
SignalRGBEffect=Solid Color
; Full-brightness color, six hex digits, no # (Vishnu's cyan).
SignalRGBColor=00AE57

; Text before the percentage.
SignalRGBLabel=Case lights
; The double arrow starts this effect (empty hides the arrow) with these
; link parameters (# is %23, a space %20), e.g. speed=60.
SignalRGBMoveEffect=Side to Side
SignalRGBMoveParams=direction=All%20Directions&color1=%2300AE57&color2=%23000000&speed=11&rainbow=false

; ---- Runtime, not settings ----
; Set by the needs check (Scripts\Needs.lua) at runtime; 1 until it says
; otherwise. 0 hides the function. See docs/guide/first-time-setup.md.
; 0 unless a required need is missing (1 hides the skin).
SignalRGBNeedBlocked=0
; 1 while the Pro API is expected to answer (brightness read-back).
SignalRGBHasApi=1
; 1 while an effect and colour are set (scroll control and percentage).
SignalRGBHasBrightness=1
; 1 while a move effect is set (the double arrow).
SignalRGBHasMove=1
; Written by SignalRGB.lua to @Resources\State.inc; these are the
; start values for a fresh install.
SignalRGBBright=100
SignalRGBMode=solid
