; Control-Plaine shared meter styles. Include last (after Core.inc).
; Combine with |, later styles win: MeterStyle=sValue | sWarn.
; (Rainmeter styles cannot inherit from each other, so each is complete.)
;
; Text: upper case, Segoe UI, with the suite's hard shadow (Rainmeter shadows
; cannot blur). Tracking goes on the meter, because it depends on alignment:
;   left/centred:  InlineSetting=CharacterSpacing | 0 | (#TrackDetail#*#Scale#)
;   right-aligned: InlineSetting=CharacterSpacing | (#TrackDetail#*#Scale#) | 0
; One side only: setting both doubles the gap between letters.
; Alpha goes from the rest level to AlphaHover as #Reveal# goes 0 -> 1
; (the styles put meters in Group=Reveal, which mFade updates).

; Day-Date day name (52px, 400).
[sDisplay]
FontFace=#FontFace#
StringCase=Upper
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
DynamicVariables=1
FontSize=(#SizeDisplay#*#Scale#)
FontWeight=#WeightDisplay#
FontColor=#Ink#,(#AlphaValue#+(#AlphaHover#-#AlphaValue#)*#Reveal#)
Group=Reveal

; Values: volume %, track title, uptime (20px, 300).
[sValue]
FontFace=#FontFace#
StringCase=Upper
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
DynamicVariables=1
FontSize=(#SizeValue#*#Scale#)
FontWeight=#WeightValue#
FontColor=#Ink#,(#AlphaValue#+(#AlphaHover#-#AlphaValue#)*#Reveal#)
Group=Reveal

; Titles: RECYCLE BIN, date line (12.5px, 600).
[sTitle]
FontFace=#FontFace#
StringCase=Upper
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
DynamicVariables=1
FontSize=(#SizeTitle#*#Scale#)
FontWeight=#WeightTitle#
FontColor=#Ink#,(#AlphaValue#+(#AlphaHover#-#AlphaValue#)*#Reveal#)
Group=Reveal

; Details: device name, counts, labels (9.5px, 600).
[sDetail]
FontFace=#FontFace#
StringCase=Upper
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
DynamicVariables=1
FontSize=(#SizeDetail#*#Scale#)
FontWeight=#WeightDetail#
FontColor=#Ink#,(#AlphaDetail#+(#AlphaHover#-#AlphaDetail#)*#Reveal#)
Group=Reveal

; Detail text that only shows while hovered.
[sReveal]
FontFace=#FontFace#
StringCase=Upper
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
DynamicVariables=1
FontSize=(#SizeDetail#*#Scale#)
FontWeight=#WeightDetail#
FontColor=#Ink#,(#AlphaHover#*#Reveal#)
Group=Reveal

; Action links (OPEN, EMPTY, SCHEDULE, SET, CANCEL), shown on hover.
; Put an Image meter with sLinkLine right below it.
[sLink]
FontFace=#FontFace#
StringCase=Upper
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
DynamicVariables=1
FontSize=(#SizeDetail#*#Scale#)
FontWeight=#WeightDetail#
FontColor=#Ink#,(#AlphaHover#*#Reveal#)
SolidColor=0,0,0,1
MouseActionCursor=1
Group=Reveal

; 1px accent underline for a link. On an Image meter right after the link:
;   Meter=Image
;   MeterStyle=sLinkLine
;   W=[<LinkMeter>:W]
[sLinkLine]
X=r
Y=(#LinkGap#*#Scale#)R
H=(1*#Scale#)
SolidColor=#Accent#,(255*#Reveal#)
DynamicVariables=1
Group=Reveal

; Colour modifiers, used after a text or icon style. They restate the alpha.
[sWarn]
FontColor=#Warn#,(#AlphaValue#+(#AlphaHover#-#AlphaValue#)*#Reveal#)
ImageTint=#Warn#

[sAccent]
FontColor=#Accent#,(#AlphaValue#+(#AlphaHover#-#AlphaValue#)*#Reveal#)
ImageTint=#Accent#

; Icons. PNGs are IconBox squares with IconPad of margin (holding the shadow),
; so put the meter IconPad up and left of where the visible icon starts:
;   X=((x-#IconPad#)*#Scale#)
; sIcon brightens on its own hover (rows of icons: set ImageAlpha from Lua or
; the meter's MouseOverAction). sIconFade brightens with the whole skin.
[sIcon]
W=(#IconBox#*#Scale#)
H=(#IconBox#*#Scale#)
ImageTint=#Ink#
ImageAlpha=#AlphaDetail#
SolidColor=0,0,0,1
AntiAlias=1
MouseActionCursor=1
DynamicVariables=1

[sIconFade]
W=(#IconBox#*#Scale#)
H=(#IconBox#*#Scale#)
ImageTint=#Ink#
ImageAlpha=(#AlphaDetail#+(#AlphaHover#-#AlphaDetail#)*#Reveal#)
SolidColor=0,0,0,1
AntiAlias=1
MouseActionCursor=1
DynamicVariables=1
Group=Reveal

; Invisible hover/click backing (alpha 0 is not hit-testable, 1 is).
[sHit]
SolidColor=0,0,0,1
DynamicVariables=1

; Rings: a Shape meter using #RingTrack# and #RingFill# (Theme.inc).
;   c = ((#RingRadius#+#RingWidth#/2+1)*#Scale#)   centre, both axes
;   R = (#RingRadius#*#Scale#)
;   a = 2*PI*value, from 12 o'clock, clockwise
;   Shape=Ellipse c,c,R | #RingTrack#
;   Shape2=Arc c,(c-R),(c+R*Sin(a)),(c-R*Cos(a)),0,0,(a>PI ? 1 : 0) | #RingFill#
; At value >= 0.999 draw Shape2 as a full Ellipse (an arc with equal ends draws
; nothing); at 0 hide it. Override RingColor / RingWidth in the skin's
; [Variables] (or with !SetVariable) for a grey or thinner ring.
[sRing]
AntiAlias=1
DynamicVariables=1

; ---- Legacy v1 style, used by the v1 skins until they are rebuilt ----
[sText]
FontFace=#FontUI#
FontSize=(#SizeM#*#Scale#)
FontColor=#Ink#,#AlphaHover#
AntiAlias=1
DynamicVariables=1
