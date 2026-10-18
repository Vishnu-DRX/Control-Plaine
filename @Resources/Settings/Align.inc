; Control-Plaine Settings: the ALIGN and DETAILS rows every aligned skin's
; page starts with. Include from the page's [Variables], after Chrome.inc,
; and set the page's keys before the include:
;   AlignKey=<Skin>Align
;   DetailsKey=<Skin>Details
; (Tab, set by every page, names the skin to refresh.) The page's own rows
; start at Y=(180*#PS#): ALIGN (Y=52) and DETAILS (Y=116) are each 64 high.

[AlignLabel]
Meter=String
MeterStyle=sRowLabel
Y=(52*#PS#)
Text=ALIGN

[AlignDesc]
Meter=String
MeterStyle=sRowDesc
Y=(4*#PS#)R
Text=Which screen edge it sits on. Text grows inward.

[AlignRight]
Meter=String
MeterStyle=sChoice
X=(#ColR#*#PS#)
Y=(60*#PS#)
FontColor=#Ink#,[&mSettings:ChoiceAlpha('#AlignKey#','right')]
Text=RIGHT
LeftMouseUpAction=[!CommandMeasure mSettings "Set('#AlignKey#','right','#Tab#')"]

[AlignRightLine]
Meter=Image
MeterStyle=sChoiceLine
X=[AlignRight:X]
Y=([AlignRight:Y]+[AlignRight:H])
W=([AlignRight:W]-2*#PS#)
SolidColor=#Accent#,[&mSettings:ChoiceLine('#AlignKey#','right')]

[AlignLeft]
Meter=String
MeterStyle=sChoice
X=([AlignRight:X]-16*#PS#)
Y=(60*#PS#)
FontColor=#Ink#,[&mSettings:ChoiceAlpha('#AlignKey#','left')]
Text=LEFT
LeftMouseUpAction=[!CommandMeasure mSettings "Set('#AlignKey#','left','#Tab#')"]

[AlignLeftLine]
Meter=Image
MeterStyle=sChoiceLine
X=[AlignLeft:X]
Y=([AlignLeft:Y]+[AlignLeft:H])
W=([AlignLeft:W]-2*#PS#)
SolidColor=#Accent#,[&mSettings:ChoiceLine('#AlignKey#','left')]

[DetailsLabel]
Meter=String
MeterStyle=sRowLabel
Y=(116*#PS#)
Text=DETAILS

[DetailsDesc]
Meter=String
MeterStyle=sRowDesc
Y=(4*#PS#)R
Text=Show the text only on hover, or always.

[DetailsAlways]
Meter=String
MeterStyle=sChoice
X=(#ColR#*#PS#)
Y=(124*#PS#)
FontColor=#Ink#,[&mSettings:ChoiceAlpha('#DetailsKey#','always')]
Text=ALWAYS
LeftMouseUpAction=[!CommandMeasure mSettings "Set('#DetailsKey#','always','#Tab#')"]

[DetailsAlwaysLine]
Meter=Image
MeterStyle=sChoiceLine
X=[DetailsAlways:X]
Y=([DetailsAlways:Y]+[DetailsAlways:H])
W=([DetailsAlways:W]-2*#PS#)
SolidColor=#Accent#,[&mSettings:ChoiceLine('#DetailsKey#','always')]

[DetailsHover]
Meter=String
MeterStyle=sChoice
X=([DetailsAlways:X]-16*#PS#)
Y=(124*#PS#)
FontColor=#Ink#,[&mSettings:ChoiceAlpha('#DetailsKey#','hover')]
Text=HOVER
LeftMouseUpAction=[!CommandMeasure mSettings "Set('#DetailsKey#','hover','#Tab#')"]

[DetailsHoverLine]
Meter=Image
MeterStyle=sChoiceLine
X=[DetailsHover:X]
Y=([DetailsHover:Y]+[DetailsHover:H])
W=([DetailsHover:W]-2*#PS#)
SolidColor=#Accent#,[&mSettings:ChoiceLine('#DetailsKey#','hover')]
