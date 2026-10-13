; Control-Plaine general settings: defaults.
; The Settings skin writes changes to User.inc, which every skin includes
; after this file, so User.inc wins. Per-skin defaults live in <Skin>\Defaults.inc.
; Booleans are 0/1.

[Variables]
; Size of every skin, 0.5 to 3.0 (Settings shows it as a percent).
Scale=1
; Extra size for Controllers, Fan Control, DeepCool, Wi-Fi and SignalRGB only,
; on top of Scale (1 = none). Those skins define Sz=(#Scale#*#SizeBoost#).
SizeBoost=1.25
; 1 = follow the Windows accent colour, 0 = use AccentColor.
AccentFollowWindows=1
; Custom accent (R,G,B). Also the start value before Windows is read.
AccentColor=0,229,255
; How bright details and icons are when not hovered, 30 to 90 (%).
; Values (volume %, titles) sit 20 points above this.
RestBrightness=60
; Hide every skin while a full-screen app is in front.
HideFullScreen=1
; Stop skins from being dragged (Settings applies it with !DraggableGroup).
LockPositions=0

; ---- Runtime, not settings ----
; A skin sets SelfHidden=1 (then !UpdateMeasure mVisible) to hide itself.
SelfHidden=0
; Hover fade level, 0 to 1, driven by mFade.
Reveal=0
