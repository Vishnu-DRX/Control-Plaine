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
