;  Control-Plaine Settings: window chrome shared by every page.
;  Panel 912 x 620 at scale 1 (canvas Settings board), left tab column,
;  footer, close button. Every size is (n*#PS#); PS is Scale, capped so the
;  panel never exceeds 85% of the screen height.
;  Content area for rows: x 248 to 872 (#ColL# to #ColR#), y 48 to 588.

[Variables]
PS=(Min(#Scale#,#SCREENAREAHEIGHT#*0.85/620))
ColL=248
ColR=872
TabY0=128
TabStep=28
; The Settings window ignores Theme and every <Skin>Theme: always the dark
; panel with white ink (specs/theme.md, Core.lua locks on Tab as well).
ThemeLock=1

; ---------- Panel ----------

[Panel]
Meter=Shape
X=0
Y=0
Shape=Rectangle 0.5,0.5,(912*#PS#-1),(620*#PS#-1),(12*#PS#) | Fill Color #Dark#,219 | StrokeWidth 1 | Stroke Color #Ink#,20
DynamicVariables=1

; ---------- Wordmark (drag here) ----------

[Wordmark1]
Meter=String
X=(40*#PS#)
Y=(44*#PS#)
FontFace=#FontFace#
FontSize=(13.5*#PS#)
FontWeight=400
FontColor=#Ink#,250
InlineSetting=CharacterSpacing | 0 | (5.4*#PS#)
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
Text=CONTROL
DynamicVariables=1

[Wordmark2]
Meter=String
X=r
Y=(-2*#PS#)R
FontFace=#FontFace#
FontSize=(13.5*#PS#)
FontWeight=400
FontColor=#Accent#,250
InlineSetting=CharacterSpacing | 0 | (5.4*#PS#)
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
Text=PLAINE
DynamicVariables=1

; ---------- Tabs ----------
; Settings.lua lights the tab named by #Tab# and moves TabBar to it.

[TabGeneral]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+0*#TabStep#)*#PS#)
Text=GENERAL
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "General.ini"]

[TabAdvanced]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+1*#TabStep#)*#PS#)
Text=ADVANCED
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "Advanced.ini"]

[TabDayDate]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+2*#TabStep#)*#PS#)
Text=DAY-DATE
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "DayDate.ini"]

[TabPower]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+3*#TabStep#)*#PS#)
Text=POWER
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "Power.ini"]

[TabUptime]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+4*#TabStep#)*#PS#)
Text=UPTIME
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "Uptime.ini"]

[TabVolume]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+5*#TabStep#)*#PS#)
Text=VOLUME
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "Volume.ini"]

[TabRecycleBin]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+6*#TabStep#)*#PS#)
Text=RECYCLE BIN
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "RecycleBin.ini"]

[TabPlaynite]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+7*#TabStep#)*#PS#)
Text=PLAYNITE
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "Playnite.ini"]

[TabMedia]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+8*#TabStep#)*#PS#)
Text=MEDIA
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "Media.ini"]

[TabWiFi]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+9*#TabStep#)*#PS#)
Text=WI-FI
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "WiFi.ini"]

[TabFanControl]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+10*#TabStep#)*#PS#)
Text=FAN CONTROL
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "FanControl.ini"]

[TabSignalRGB]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+11*#TabStep#)*#PS#)
Text=SIGNALRGB
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "SignalRGB.ini"]

[TabDeepCool]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+12*#TabStep#)*#PS#)
Text=DEEPCOOL
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "DeepCool.ini"]

[TabControllers]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+13*#TabStep#)*#PS#)
Text=CONTROLLERS
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "Controllers.ini"]

[TabSettingsButton]
Meter=String
MeterStyle=sTab
Y=((#TabY0#+14*#TabStep#)*#PS#)
Text=SETTINGS BUTTON
LeftMouseUpAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "SettingsButton.ini"]

; ---------- Needs marks and banner ----------
; An amber "!" at the right of a tab when the skin is loaded and something it
; needs is missing (Settings.lua MarkHidden / MarkTip, from Setup\NeedsList.lua).
; Click opens the setup for that skin. Hidden meters show no tooltip.

[Banner]
Meter=String
MeterStyle=sSection
X=(#ColL#*#PS#)
Y=(26*#PS#)
W=(560*#PS#)
ClipString=1
FontColor=#Warn#,230
SolidColor=0,0,0,1
MouseActionCursor=1
DynamicVariables=1
Text=[&mSettings:Banner()]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('#Tab#')"]

[MarkDayDate]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+2*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('DayDate')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('DayDate')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('DayDate')"]
DynamicVariables=1

[MarkPower]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+3*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('Power')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('Power')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('Power')"]
DynamicVariables=1

[MarkUptime]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+4*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('Uptime')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('Uptime')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('Uptime')"]
DynamicVariables=1

[MarkVolume]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+5*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('Volume')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('Volume')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('Volume')"]
DynamicVariables=1

[MarkRecycleBin]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+6*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('RecycleBin')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('RecycleBin')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('RecycleBin')"]
DynamicVariables=1

[MarkPlaynite]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+7*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('Playnite')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('Playnite')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('Playnite')"]
DynamicVariables=1

[MarkMedia]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+8*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('Media')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('Media')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('Media')"]
DynamicVariables=1

[MarkWiFi]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+9*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('WiFi')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('WiFi')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('WiFi')"]
DynamicVariables=1

[MarkFanControl]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+10*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('FanControl')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('FanControl')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('FanControl')"]
DynamicVariables=1

[MarkSignalRGB]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+11*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('SignalRGB')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('SignalRGB')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('SignalRGB')"]
DynamicVariables=1

[MarkDeepCool]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+12*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('DeepCool')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('DeepCool')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('DeepCool')"]
DynamicVariables=1

[MarkControllers]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+13*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('Controllers')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('Controllers')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('Controllers')"]
DynamicVariables=1

[MarkSettingsButton]
Meter=Shape
X=(214*#PS#)
Y=((#TabY0#+14*#TabStep#+1)*#PS#)
Shape=Rectangle (-4*#PS#),(-3*#PS#),(10*#PS#),(18*#PS#) | Fill Color 0,0,0,1 | StrokeWidth 0
Shape2=Rectangle 0,0,(2*#PS#),(7*#PS#),(1*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Shape3=Ellipse (1*#PS#),(11*#PS#),(1.2*#PS#) | Fill Color #Warn#,255 | StrokeWidth 0
Hidden=[&mSettings:MarkHidden('SettingsButton')]
MouseActionCursor=1
ToolTipText=[&mSettings:MarkTip('SettingsButton')]
LeftMouseUpAction=[!CommandMeasure mSettings "Fix('SettingsButton')"]
DynamicVariables=1

[TabBar]
Meter=Image
X=(40*#PS#)
Y=(#TabY0#*#PS#)
W=(2*#PS#)
H=(20*#PS#)
SolidColor=#Accent#,255
DynamicVariables=1

; ---------- Footer ----------

[Version]
Meter=String
MeterStyle=sTab
Y=(560*#PS#)
FontColor=#Ink#,115
MouseActionCursor=0
Text=VERSION #Version#

[GitHub]
Meter=String
MeterStyle=sTab
Y=(4*#PS#)R
FontColor=#Ink#,200
Text=OPEN ON GITHUB
LeftMouseUpAction=["#RepoURL#"]

[GitHubLine]
Meter=Image
X=[GitHub:X]
Y=(1*#PS#)R
W=([GitHub:W]-12*#PS#)
H=(1*#PS#)
SolidColor=#Accent#,255
DynamicVariables=1

[LinkRefresh]
Meter=String
MeterStyle=sTab
X=(#ColL#*#PS#)
Y=(596*#PS#)
FontColor=#Ink#,153
Text=REFRESH ALL
LeftMouseUpAction=[!RefreshGroup ControlPlaine][!Refresh]

[LinkFolder]
Meter=String
MeterStyle=sTab
X=(24*#PS#)R
Y=r
FontColor=#Ink#,153
Text=OPEN SKINS FOLDER
LeftMouseUpAction=["#ROOTCONFIGPATH#"]

[LinkUser]
Meter=String
MeterStyle=sTab
X=(24*#PS#)R
Y=r
FontColor=#Ink#,153
Text=OPEN USER.INC
LeftMouseUpAction=["#@#User.inc"]

; ---------- Close ----------

[CloseHit]
Meter=Image
X=(868*#PS#)
Y=(20*#PS#)
W=(24*#PS#)
H=(24*#PS#)
SolidColor=0,0,0,1
MouseActionCursor=1
ToolTipText=Close
LeftMouseUpAction=[!DeactivateConfig]
DynamicVariables=1

[Close]
Meter=Shape
X=(874*#PS#)
Y=(26*#PS#)
Shape=Line 0,0,(12*#PS#),(12*#PS#) | StrokeWidth (1.5*#PS#) | Stroke Color #Ink#,153 | StrokeStartCap Round | StrokeEndCap Round
Shape2=Line (12*#PS#),0,0,(12*#PS#) | StrokeWidth (1.5*#PS#) | Stroke Color #Ink#,153 | StrokeStartCap Round | StrokeEndCap Round
DynamicVariables=1

; ---------- Logic ----------

[mSettings]
Measure=Script
ScriptFile=#@#Scripts\Settings.lua
; Once a minute (Update=1000 x 60): Settings.lua re-checks what skins need.
UpdateDivider=60

; SignalRGB's launcher registration, read by the needs check (Needs.lua).
[mRegSignalRGB]
Measure=Registry
RegHKey=HKEY_CLASSES_ROOT
RegKey=signalrgb\shell\open\command
UpdateDivider=-1

[mCommit]
; Scroll edits are written 600 ms after the last notch.
Measure=Plugin
Plugin=ActionTimer
ActionList1=Wait 600 | Commit
Commit=[!CommandMeasure mSettings "Commit()"]
IgnoreWarnings=1

[mInput]
; Path and colour boxes. Settings.lua places it over the clicked box.
Measure=Plugin
Plugin=InputText
FontFace=#FontFace#
FontSize=(9*#PS#)
FontColor=255,255,255,255
SolidColor=30,33,38,255
X=0
Y=0
W=200
H=20
DefaultValue=
Command1=[!CommandMeasure mSettings "InputDone([[$UserInput$]])"]
DynamicVariables=1
