; Control-Plaine | {{Name}}
; What it shows: TODO one or two sentences. An icon and the label {{LABEL}};
;   the label shows on hover (or always, see {{Name}}Details).
; Designed for: TODO name the target software and version, or "nothing extra".
; Adjust (Settings > {{LABEL}}, or User.inc):
;   {{Name}}Align=left or right   which screen edge it sits on (icon first,
;                               or label first with the icon last)
;   {{Name}}Details=hover or always   when the label shows
;   {{Name}}Theme=auto, dark or light   colours for this skin
;   {{Name}}Tooltips=1 or 0   show or hide this skin's tooltips
[Rainmeter]
; {{Name}}Tooltips=0 hides every tooltip of this skin (see Core.inc).
ToolTipHidden=#TipHide#
Update=1000
AccurateText=1
DynamicWindowSize=1
Group=ControlPlaine
ContextTitle=Control-Plaine settings
ContextAction=[!ActivateConfig "#ROOTCONFIG#\Settings" "{{Name}}.ini"]
MouseOverAction=[!CommandMeasure mFade "Stop 2"][!CommandMeasure mFade "Execute 1"]
MouseLeaveAction=[!CommandMeasure mFade "Stop 1"][!CommandMeasure mFade "Execute 2"]

[Metadata]
Name=Control-Plaine | {{Name}}
Author=Vishnu A
Information={{Summary}}
Version=2.0.1
License=MIT

[Variables]
@include=#@#Theme.inc
@include2=#@#Defaults.inc
@include3=#ROOTCONFIGPATH#{{Name}}\Defaults.inc
@include4=#@#User.inc
@include5=#@#State.inc
; Read by Core.inc (Scripts\Core.lua) to arrange the skin; see specs/alignment.md and specs/theme.md.
SkinSide=#{{Name}}Align#
SkinDetails=#{{Name}}Details#
SkinTheme=#{{Name}}Theme#
@include6=#@#Core.inc
; One resolved tooltip switch (a nested lookup is not read on a meter).
TipHide=#TipHidden[#{{Name}}Tooltips]#
; TODO keep this line only if the skin sits with the app skins (boosted size);
; otherwise use Sz=(#Scale#) and say so in the guide.
Sz=(#Scale#*#SizeBoost#)
@include7=#@#Styles.inc

; ---------- Meters ----------

[RefLabel]
; Invisible copy of the label. The label never changes, so its width fixes the
; box: Hit is icon + gap + this width on both sides, and the window never
; resizes. Its X keeps the text inside the box when right-aligned. It only
; sets the width, it is never seen.
Meter=String
MeterStyle=sReveal
FontColor=0,0,0,0
FontEffectColor=0,0,0,0
InlineSetting=CharacterSpacing | (#Lead#*#TrackDetail#*#Sz#) | (#Trail#*#TrackDetail#*#Sz#)
X=(#Mir#*120*#Sz#)
Y=((#IconBox#/2)*#Sz#)
StringAlign=#TA#
Text={{LABEL}}

[Hit]
Meter=Image
MeterStyle=sHit
X=0
Y=0
W=(Round((#IconBox#+4)*#Sz#+[RefLabel:W]))
H=(#IconBox#*#Sz#)

[Icon]
; Dim at rest, brighter on hover; accent while the pointer is on the icon.
Meter=Image
MeterStyle=sIconFade
ImageName=#@#Icons\{{Icon}}.png
X=(#Mir#*Round([Hit:W]-#IconBox#*#Sz#))
Y=0
ToolTipText={{Title}}
MouseOverAction=[!SetOption Icon ImageTint "#HoverTint#"][!UpdateMeter Icon][!Redraw]
MouseLeaveAction=[!SetOption Icon ImageTint "#Ink#"][!UpdateMeter Icon][!Redraw]
; TODO the click action, for example LeftMouseUpAction=[!CommandMeasure ...]

[Label]
Meter=String
MeterStyle=sReveal
InlineSetting=CharacterSpacing | (#Lead#*#TrackDetail#*#Sz#) | (#Trail#*#TrackDetail#*#Sz#)
X=(#Mir#*Round([Hit:W]-(#IconBox#+4)*#Sz#)+(1-#Mir#)*(#IconBox#+4)*#Sz#)
Y=((#IconBox#/2)*#Sz#)
StringAlign=#TA#
SolidColor=0,0,0,1
MouseActionCursor=1
Text={{LABEL}}
ToolTipText={{Title}}
