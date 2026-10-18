; Control-Plaine shared measures. Include after Theme, Defaults, the skin's
; Defaults, User and State, and before Styles.inc.
;
; Gives every skin:
;   #Accent#         Windows accent colour (or the custom one), live within 5 s;
;                    darkened in light mode
;   #Mode#           dark (for dark wallpapers, white skins) or light (black
;                    skins), from Theme / <Skin>Theme. #Ink# #InkContrast# #Warn#
;                    follow it. See specs/theme.md.
;   #AlphaDetail#    rest level for details and icons (RestBrightness, plus
;                    LightBoost in light mode)
;   #AlphaValue#     rest level for values (that + 20)
;   #AlphaRest#      same as AlphaDetail (v1 name)
;   #AlphaHover#     hover level (HoverBrightness, never below rest)
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
;   SkinTheme=#<Skin>Theme#      (auto, dark or light)

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
; Placeholders for the light/dark and brightness values Scripts\Core.lua
; resolves (dark, today's brightness).
Mode=dark
InkContrast=0,0,0
RestEff=#RestBrightness#
HoverEff=#HoverBrightness#
AlphaHover=(Round(#HoverEff#*2.55))
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
AlphaDetail=(#RestEff#*2.55)
AlphaValue=(Min(255,(#RestEff#+20)*2.55))
AlphaRest=(#RestEff#*2.55)
; Dimmed sibling while another row is hovered (Controllers).
AlphaDim=(#RestEff#*2.55*0.6)

; ---------- Accent from Windows ----------
; HKCU\Software\Microsoft\Windows\DWM\AccentColor is a DWORD 0xAABBGGRR.
; Formulas have no bit operators, so split it with division and modulo.
; Scripts\Core.lua reads the result (mAccent) and sets #Accent#.

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
; Missing value (0,0,0) keeps AccentColor (decided in Core.lua).
Measure=String
String=[mAccentR],[mAccentG],[mAccentB]
DynamicVariables=1
UpdateDivider=5
Disabled=(1-#AccentFollowWindows#)

; ---------- Windows light/dark ----------
; 1 = Windows is set to light. A missing value reads 0, which is dark.
; ThemeFollow names the registry value (Theme=auto): SystemUsesLightTheme is
; the taskbar and Start, AppsUseLightTheme is apps.

[mWinTheme]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\Microsoft\Windows\CurrentVersion\Themes\Personalize
RegValue=#ThemeFollow#
UpdateDivider=5

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
