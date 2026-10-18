; Control-Plaine shared measures. Include after Theme, Defaults, the skin's
; Defaults, User and State, and before Styles.inc.
;
; Gives every skin:
;   #Accent#         Windows accent colour (or the custom one), live within 5 s
;   #AlphaDetail#    rest level for details and icons (RestBrightness)
;   #AlphaValue#     rest level for values (RestBrightness + 20)
;   #AlphaRest#      same as AlphaDetail (v1 name)
;   mVisible         hides the skin while a full-screen app is in front, or
;                    while the skin sets SelfHidden=1. Skins never call
;                    !Show or !Hide themselves.
;   mFade / #Reveal# the hover fade. The skin's [Rainmeter] section needs:
;     MouseOverAction=[!CommandMeasure mFade "Stop 2"][!CommandMeasure mFade "Execute 1"]
;     MouseLeaveAction=[!CommandMeasure mFade "Stop 1"][!CommandMeasure mFade "Execute 2"]
;   #RevealMin#      the level #Reveal# rests at: 0 (details on hover) or 1
;                    (details always shown), from SkinDetails / DetailsAll
;   Side Mir TA TAT Lead Trail HoverTint
;                    the left/right arrangement helpers, resolved by
;                    Scripts\Core.lua (mCore). See specs/alignment.md.
;
; A skin that arranges itself left or right sets, in its own [Variables]
; before including this file:
;   SkinSide=#<Skin>Align#       (left or right)
;   SkinDetails=#<Skin>Details#  (hover or always)

[Variables]
; Defined here, after User.inc, so they see the user's settings.
; Size of this skin. A skin that opts in to SizeBoost redefines it after
; including this file: Sz=(#Scale#*#SizeBoost#)
Sz=#Scale#
; ToolTipHidden for a skin whose <Skin>Tooltips setting is 1 or 0:
; the [Rainmeter] section reads #TipHidden[#<Skin>Tooltips]#.
TipHidden1=0
TipHidden0=1
Accent=#AccentColor#
; Placeholders for what Scripts\Core.lua resolves when the skin loads (left
; arrangement, details on hover). Meters that use them need DynamicVariables=1.
Side=left
Mir=0
TA=LeftCenter
TAT=Left
Lead=0
Trail=1
RevealMin=0
HoverTint=#Accent#
AlphaDetail=(#RestBrightness#*2.55)
AlphaValue=(Min(255,(#RestBrightness#+20)*2.55))
AlphaRest=(#RestBrightness#*2.55)
; Dimmed sibling while another row is hovered (Controllers).
AlphaDim=(#RestBrightness#*2.55*0.6)

; ---------- Accent from Windows ----------
; HKCU\Software\Microsoft\Windows\DWM\AccentColor is a DWORD 0xAABBGGRR.
; Formulas have no bit operators, so split it with division and modulo.

[mAccentReg]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\Microsoft\Windows\DWM
RegValue=AccentColor
UpdateDivider=5
Disabled=(1-#AccentFollowWindows#)

[mAccentR]
Measure=Calc
Formula=Trunc(mAccentReg) % 256
UpdateDivider=5
Disabled=(1-#AccentFollowWindows#)

[mAccentG]
Measure=Calc
Formula=Trunc(mAccentReg / 256) % 256
UpdateDivider=5
Disabled=(1-#AccentFollowWindows#)

[mAccentB]
Measure=Calc
Formula=Trunc(mAccentReg / 65536) % 256
UpdateDivider=5
Disabled=(1-#AccentFollowWindows#)

[mAccent]
; Missing value (0,0,0) keeps AccentColor.
Measure=String
String=[mAccentR],[mAccentG],[mAccentB]
DynamicVariables=1
UpdateDivider=5
Disabled=(1-#AccentFollowWindows#)
IfMatch=^0,0,0$
IfNotMatchAction=[!SetVariable Accent "[mAccent]"]
IfMatchMode=1

; ---------- Layout helpers ----------

[mCore]
Measure=Script
ScriptFile=#@#Scripts\Core.lua
UpdateDivider=5

; ---------- Visibility ----------

[mFullScreen]
; IsFullScreen plugin (in Skins\@Vault): 1 while the foreground app is full screen.
Measure=Plugin
Plugin=IsFullScreen
Disabled=(1-#HideFullScreen#)

[mVisible]
Measure=Calc
Formula=(((#HideFullScreen#=1) && (mFullScreen=1)) || (#SelfHidden#=1)) ? 0 : 1
DynamicVariables=1
IfCondition=mVisible = 1
IfTrueAction=[!Show]
IfFalseAction=[!Hide]

; ---------- Hover fade ----------
; Drives #Reveal# from 0 to 1 when the mouse enters the skin and back to 0
; (after #HideDelay#) when it leaves. Meters in group "Reveal" follow it.

[mFade]
Measure=Plugin
Plugin=ActionTimer
ActionList1=Repeat FadeIn,#FadeStep#,#FadeSteps#
ActionList2=Wait #HideDelay# | Repeat FadeOut,#FadeStep#,#FadeSteps#
FadeIn=[!SetVariable Reveal "(Clamp([#Reveal]+1/#FadeSteps#,0,1))"][!UpdateMeterGroup Reveal][!Redraw]
FadeOut=[!SetVariable Reveal "(Clamp([#Reveal]-1/#FadeSteps#,#RevealMin#,1))"][!UpdateMeterGroup Reveal][!Redraw]
DynamicVariables=1
IgnoreWarnings=1
