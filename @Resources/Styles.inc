; Control-Plaine shared meter styles. Include after Theme.inc.

; Text that is always visible.
[sText]
FontFace=#FontUI#
FontSize=(#SizeM#*#Scale#)
FontColor=#Ink#,#AlphaHover#
AntiAlias=1
DynamicVariables=1

; Text that fades in while the mouse is over the skin (needs Fade.inc).
[sReveal]
FontFace=#FontUI#
FontSize=(#SizeS#*#Scale#)
FontColor=#Ink#,(#AlphaHover#*#Reveal#)
AntiAlias=1
DynamicVariables=1
Group=Reveal

; An icon that brightens with the whole skin (single-icon skins).
[sIconFade]
W=(#IconSize#*#Scale#)
H=(#IconSize#*#Scale#)
ImageAlpha=(#AlphaRest#+(#AlphaHover#-#AlphaRest#)*#Reveal#)
SolidColor=0,0,0,1
AntiAlias=1
MouseActionCursor=1
DynamicVariables=1
Group=Reveal

; An icon that brightens on its own hover (rows of icons).
[sIcon]
W=(#IconSize#*#Scale#)
H=(#IconSize#*#Scale#)
ImageAlpha=#AlphaRest#
SolidColor=0,0,0,1
AntiAlias=1
MouseActionCursor=1
DynamicVariables=1
