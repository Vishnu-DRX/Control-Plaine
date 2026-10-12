; Control-Plaine | SignalRGB: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the SignalRGB skin; add keys here with the SignalRGB prefix.

[Variables]
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

; Free mode (no SignalRGB Pro): the skin applies this effect with the
; signalrgb://effect/apply link and sets brightness by scaling its color.
; Needs an effect with a "color" property, such as Solid Color. Empty =
; launcher only. Set the color to match the one you use in SignalRGB.
SignalRGBEffect=Solid Color
; Full-brightness color, six hex digits, no # (cyan).
SignalRGBColor=00FFFF

; Text before the percentage.
SignalRGBLabel=Case lights
; The double arrow starts this effect (empty hides the arrow) with these
; link parameters, e.g. speed=60&scale=2.
SignalRGBMoveEffect=Cyan Move
SignalRGBMoveParams=
