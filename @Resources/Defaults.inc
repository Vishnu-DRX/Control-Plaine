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
; Font for all text: Segoe UI Variable Display, or Segoe UI on Windows 10 or a
; PC without the Variable font.
FontFace=Segoe UI Variable Display
; 1 = follow the Windows accent colour, 0 = use AccentColor.
AccentFollowWindows=1
; Custom accent (R,G,B). Also the start value before Windows is read.
AccentColor=0,229,255
; How bright details and icons are when not hovered, 30 to 90 (%).
; Values (volume %, titles) sit 20 points above this.
RestBrightness=60
; How bright a hovered skin is, 30 to 100 (%). Never below the rest level.
HoverBrightness=98
; Colours for the wallpaper: dark = white skins (for dark wallpapers),
; light = black skins (for light wallpapers), auto = follow the Windows
; light/dark setting. Each skin's <Skin>Theme (auto, dark, light) overrides it;
; auto there means "follow this".
Theme=dark
; Which Windows setting auto follows: SystemUsesLightTheme (taskbar and Start)
; or AppsUseLightTheme (apps).
ThemeFollow=SystemUsesLightTheme
; Light mode: percentage points added to the rest level (black on a light
; wallpaper needs more weight to read the same).
LightBoost=10
; Light mode: darken the accent so it stays readable (1/0), and by how much
; (each colour channel is multiplied by this).
AccentLight=1
AccentLightK=0.7
; Which screen edge skins sit on. skin = each skin uses its own <Skin>Align,
; left or right = every aligned skin follows this instead.
AlignAll=skin
; Whether hover-only details stay visible. skin = each skin uses its own
; <Skin>Details, hover or always = every skin follows this instead.
DetailsAll=skin
; 1 = a hovered icon takes the accent colour, 0 = it stays the ink colour.
HoverAccent=1
; Hide every skin while a full-screen app is in front. Off by default: the
; check follows the foreground window on any monitor, so a game or video on
; the main monitor would also hide skins sitting on a second one.
HideFullScreen=0
; How long revealed detail stays after the mouse leaves (ms).
HideDelay=500
; Stop skins from being dragged (Settings applies it with !DraggableGroup).
LockPositions=0

; ---- Runtime, not settings ----
; A skin sets SelfHidden=1 (then !UpdateMeasure mVisible) to hide itself.
SelfHidden=0
; Hover fade level, 0 to 1, driven by mFade.
Reveal=0
; Per skin, set by the skin before it includes Core.inc:
; Fallbacks for a skin that does not arrange itself (Core.lua reads these).
SkinSide=left
SkinDetails=hover
SkinTheme=auto
