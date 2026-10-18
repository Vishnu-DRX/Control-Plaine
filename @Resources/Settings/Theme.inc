; Control-Plaine Settings: the COLOURS row a skin's page shows once the skin
; follows the light/dark mode (it sets SkinTheme, see specs/theme.md).
; Include from the page's [Variables], after Chrome.inc, and set before it:
;   ThemeKey=<Skin>Theme
;   ThemeY=<Y of the row's label, below the page's other rows>
; (Tab, set by every page, names the skin to refresh.) The words say what the
; skin looks like: AUTO follows the global SKINS FOR choice on General, WHITE
; is the dark-wallpaper look (dark), BLACK the light-wallpaper look (light).

[ThemeLabel]
Meter=String
MeterStyle=sRowLabel
Y=(#ThemeY#*#PS#)
Text=COLOURS

[ThemeDesc]
Meter=String
MeterStyle=sRowDesc
Y=(4*#PS#)R
Text=Auto follows SKINS FOR on General. Or white or black for this skin.

[ThemeBlack]
Meter=String
MeterStyle=sChoice
X=(#ColR#*#PS#)
Y=((#ThemeY#+8)*#PS#)
FontColor=#Ink#,[&mSettings:ChoiceAlpha('#ThemeKey#','light')]
Text=BLACK
LeftMouseUpAction=[!CommandMeasure mSettings "Set('#ThemeKey#','light','#Tab#')"]

[ThemeBlackLine]
Meter=Image
MeterStyle=sChoiceLine
X=[ThemeBlack:X]
Y=([ThemeBlack:Y]+[ThemeBlack:H])
W=([ThemeBlack:W]-2*#PS#)
SolidColor=#Accent#,[&mSettings:ChoiceLine('#ThemeKey#','light')]

[ThemeWhite]
Meter=String
MeterStyle=sChoice
X=([ThemeBlack:X]-16*#PS#)
Y=((#ThemeY#+8)*#PS#)
FontColor=#Ink#,[&mSettings:ChoiceAlpha('#ThemeKey#','dark')]
Text=WHITE
LeftMouseUpAction=[!CommandMeasure mSettings "Set('#ThemeKey#','dark','#Tab#')"]

[ThemeWhiteLine]
Meter=Image
MeterStyle=sChoiceLine
X=[ThemeWhite:X]
Y=([ThemeWhite:Y]+[ThemeWhite:H])
W=([ThemeWhite:W]-2*#PS#)
SolidColor=#Accent#,[&mSettings:ChoiceLine('#ThemeKey#','dark')]

[ThemeAuto]
Meter=String
MeterStyle=sChoice
X=([ThemeWhite:X]-16*#PS#)
Y=((#ThemeY#+8)*#PS#)
FontColor=#Ink#,[&mSettings:ChoiceAlpha('#ThemeKey#','auto')]
Text=AUTO
LeftMouseUpAction=[!CommandMeasure mSettings "Set('#ThemeKey#','auto','#Tab#')"]

[ThemeAutoLine]
Meter=Image
MeterStyle=sChoiceLine
X=[ThemeAuto:X]
Y=([ThemeAuto:Y]+[ThemeAuto:H])
W=([ThemeAuto:W]-2*#PS#)
SolidColor=#Accent#,[&mSettings:ChoiceLine('#ThemeKey#','auto')]
