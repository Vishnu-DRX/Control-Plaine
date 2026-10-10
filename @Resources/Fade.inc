; Control-Plaine hover fade. Include after Theme.inc.
; Drives #Reveal# from 0 to 1 when the mouse enters the skin and back to 0
; (after #HideDelay#) when it leaves. Meters in group "Reveal" follow it.
; The skin's [Rainmeter] section needs:
;   MouseOverAction=[!CommandMeasure mFade "Stop 2"][!CommandMeasure mFade "Execute 1"]
;   MouseLeaveAction=[!CommandMeasure mFade "Stop 1"][!CommandMeasure mFade "Execute 2"]
; and Reveal=0 in its [Variables].

[mFade]
Measure=Plugin
Plugin=ActionTimer
ActionList1=Repeat FadeIn,#FadeStep#,#FadeSteps#
ActionList2=Wait #HideDelay# | Repeat FadeOut,#FadeStep#,#FadeSteps#
FadeIn=[!SetVariable Reveal "(Clamp([#Reveal]+1/#FadeSteps#,0,1))"][!UpdateMeterGroup Reveal][!Redraw]
FadeOut=[!SetVariable Reveal "(Clamp([#Reveal]-1/#FadeSteps#,0,1))"][!UpdateMeterGroup Reveal][!Redraw]
DynamicVariables=1
IgnoreWarnings=1
