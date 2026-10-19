; Control-Plaine Settings: control styles, and how to build each row.
; Sizes follow the canvas Settings board (px x 0.75 = pt). Every size is
; (n*#PS#). Rows: label at Y, description at Y+20, control right-aligned to
; #ColR# and vertically centred on the row. Row pitch 64.
;
; State comes from Settings.lua through inline Lua, e.g. [&mSettings:Fill('Key')],
; so every control meter needs DynamicVariables=1 (the styles set it).
; Targets (last argument) = which skins to refresh after the write: a skin
; folder name, several separated by commas, 'all', or 'none'.
;
; ---- Toggle ----
; [KeyToggle]
; Meter=Shape
; MeterStyle=sToggle
; X=((#ColR#-30)*#PS#)
; Y=((y+6)*#PS#)
; Shape=Rectangle 0,0,(30*#PS#),(16*#PS#),(8*#PS#) | StrokeWidth 0 | Fill Color [&mSettings:Fill('Key')]
; Shape2=Ellipse ([&mSettings:Knob('Key')]*#PS#),(8*#PS#),(6*#PS#) | StrokeWidth 0 | Fill Color 255,255,255,255
; LeftMouseUpAction=[!CommandMeasure mSettings "Toggle('Key','Targets')"]
;
; ---- Choice (words, selected one underlined in accent) ----
; Words are right-aligned and laid out right to left: the last word at
; X=(#ColR#*#PS#), each earlier one at X=([NextWord:X]-16*#PS#).
; [KeyB]
; Meter=String
; MeterStyle=sChoice
; X=(#ColR#*#PS#)
; Y=((y+8)*#PS#)
; FontColor=#Ink#,[&mSettings:ChoiceAlpha('Key','b')]
; Text=WORD B
; LeftMouseUpAction=[!CommandMeasure mSettings "Set('Key','b','Targets')"]
; [KeyBLine]
; Meter=Image
; MeterStyle=sChoiceLine
; X=[KeyB:X]
; Y=([KeyB:Y]+[KeyB:H])
; W=[KeyB:W]
; SolidColor=#Accent#,[&mSettings:ChoiceLine('Key','b')]
;
; ---- Value box (scroll to change) ----
; [KeyValue]
; Meter=String
; MeterStyle=sValueText
; X=((#ColR#-10)*#PS#)
; Y=((y+4)*#PS#)
; Text=[&mSettings:Show('Key','format')]
;   formats: pct (60 -> 60%), scale (1.5 -> 150%), px, days, hm (minutes -> 1 H 15 M), plain
; MouseScrollUpAction=[!CommandMeasure mSettings "Step('Key',step,min,max,'Targets')"]
; MouseScrollDownAction=[!CommandMeasure mSettings "Step('Key',-step,min,max,'Targets')"]
; [KeyBox]
; Meter=Shape
; MeterStyle=sBox
; X=([KeyValue:X]-10*#PS#)
; Y=([KeyValue:Y]-3*#PS#)
; Shape=Rectangle 0.5,0.5,([KeyValue:W]+20*#PS#),([KeyValue:H]+6*#PS#),(6*#PS#) | Extend Box
;
; ---- Path or text box (click to edit) ----
; [KeyPath]
; Meter=String
; MeterStyle=sPathText
; X=((#ColR#-10)*#PS#)
; Y=((y+6)*#PS#)
; Text=[&mSettings:Show('Key','plain')]
; LeftMouseUpAction=[!CommandMeasure mSettings "EditPath('Key','Targets','KeyPath')"]
; [KeyPathBox] as KeyBox, measuring KeyPath.

[sTab]
X=(52*#PS#)
FontFace=#FontFace#
FontSize=(7.5*#PS#)
FontWeight=600
FontColor=#Ink#,128
InlineSetting=CharacterSpacing | 0 | (2.5*#PS#)
StringEffect=Shadow
FontEffectColor=#Shadow#
SolidColor=0,0,0,1
AntiAlias=1
MouseActionCursor=1
DynamicVariables=1

; Section heading inside a page (e.g. SKINS).
[sSection]
X=(#ColL#*#PS#)
FontFace=#FontFace#
FontSize=(7.5*#PS#)
FontWeight=600
FontColor=#Ink#,128
InlineSetting=CharacterSpacing | 0 | (2.5*#PS#)
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
DynamicVariables=1

; Row label: 11px semibold, 0.25em.
[sRowLabel]
X=(#ColL#*#PS#)
FontFace=#FontFace#
FontSize=(8.25*#PS#)
FontWeight=600
FontColor=#Ink#,250
InlineSetting=CharacterSpacing | 0 | (2.75*#PS#)
StringCase=Upper
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
DynamicVariables=1

; Row description: 12px, 55%, sentence case. Put it at Y=(4*#PS#)R under the label.
; Wraps at 300px so it never runs under a path box or choice words (they start
; about 310px right of ColL); two lines still fit the 64px row pitch.
[sRowDesc]
X=(#ColL#*#PS#)
W=(300*#PS#)
ClipString=2
FontFace=#FontFace#
FontSize=(9*#PS#)
FontWeight=400
FontColor=#Ink#,140
StringEffect=Shadow
FontEffectColor=#Shadow#
AntiAlias=1
DynamicVariables=1

; Choice word: 10px semibold, 0.2em. Selected 255, others 115 (Settings.lua).
[sChoice]
FontFace=#FontFace#
FontSize=(7.5*#PS#)
FontWeight=600
InlineSetting=CharacterSpacing | (2*#PS#) | 0
StringAlign=Right
StringCase=Upper
StringEffect=Shadow
FontEffectColor=#Shadow#
SolidColor=0,0,0,1
AntiAlias=1
MouseActionCursor=1
DynamicVariables=1

; Accent underline under the selected choice word.
[sChoiceLine]
H=(1*#PS#)
DynamicVariables=1

; Value text inside a box: 16px light, right-aligned.
[sValueText]
ToolTipHidden=#TipHide#
FontFace=#FontFace#
FontSize=(12*#PS#)
FontWeight=300
FontColor=#Ink#,240
InlineSetting=CharacterSpacing | (1*#PS#) | 0
StringAlign=Right
StringCase=Upper
SolidColor=0,0,0,1
AntiAlias=1
MouseActionCursor=1
ToolTipText=Scroll to change
DynamicVariables=1

; Path text inside a box: 12px, right-aligned, clipped to 280px.
[sPathText]
ToolTipHidden=#TipHide#
FontFace=#FontFace#
FontSize=(9*#PS#)
FontWeight=400
FontColor=#Ink#,204
StringAlign=Right
ClipString=1
W=(280*#PS#)
SolidColor=0,0,0,1
AntiAlias=1
MouseActionCursor=1
ToolTipText=Click to edit
DynamicVariables=1

; Outline for value and path boxes (1px, 30% white, radius 6).
[sBox]
Box=Fill Color 0,0,0,0 | StrokeWidth 1 | Stroke Color #Ink#,77
AntiAlias=1
DynamicVariables=1

[sToggle]
AntiAlias=1
MouseActionCursor=1
DynamicVariables=1
