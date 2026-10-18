; Control-Plaine Settings: the TOOLTIPS row every skin's page ends with.
; Include from the page's [Variables], after Chrome.inc, and set before it:
;   TipKey=<Skin>Tooltips
;   TipY=<Y of the row's label, below the page's last row>
;   TipCompact=1   (optional, default 0 in Defaults.inc) a one-line row
;                  without the description, for a page with no room for two
; (Tab, set by every page, names the skin to refresh.) The global override is
; TooltipsAll on the Advanced page; see specs/tooltips.md.

[TipsLabel]
Meter=String
MeterStyle=sRowLabel
Y=(#TipY#*#PS#)
Text=TOOLTIPS

[TipsDesc]
Meter=String
MeterStyle=sRowDesc
Y=(4*#PS#)R
Hidden=#TipCompact#
Text=Show the hover tips. Advanced can force all skins on or off.

[TipsToggle]
Meter=Shape
MeterStyle=sToggle
X=((#ColR#-30)*#PS#)
Y=((#TipY#+6)*#PS#)
Shape=Rectangle 0,0,(30*#PS#),(16*#PS#),(8*#PS#) | StrokeWidth 0 | Fill Color [&mSettings:Fill('#TipKey#')]
Shape2=Ellipse ([&mSettings:Knob('#TipKey#')]*#PS#),(8*#PS#),(6*#PS#) | StrokeWidth 0 | Fill Color 255,255,255,255
LeftMouseUpAction=[!CommandMeasure mSettings "Toggle('#TipKey#','#Tab#')"]
