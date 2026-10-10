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
