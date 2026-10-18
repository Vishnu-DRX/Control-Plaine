; Control-Plaine | Settings: {{LABEL}}
; One page of the Settings window. Each tab is a variant of the Settings
; config; see @Resources\Settings\Controls.inc for how to build rows.
[Rainmeter]
Update=1000
AccurateText=1
Group=ControlPlaineSettings
OnRefreshAction=[!ZPos 1]
ContextTitle=Close settings
ContextAction=[!DeactivateConfig]

[Metadata]
Name=Control-Plaine | Settings
Author=Vishnu A
Information=Settings for the Control-Plaine suite. Opened from any skin's right-click menu.
Version=2.0.0
License=CC BY-NC-SA 4.0

[Variables]
@include=#@#Theme.inc
@include2=#@#Defaults.inc
@include3=#ROOTCONFIGPATH#{{Name}}\Defaults.inc
@include4=#@#User.inc
Tab={{Name}}
@include5=#@#Core.inc
@include6=#@#Styles.inc
@include7=#@#Settings\Controls.inc
@include8=#@#Settings\Chrome.inc
AlignKey={{Name}}Align
DetailsKey={{Name}}Details
@include9=#@#Settings\Align.inc
; The page's own rows start at Y=128 (ALIGN and DETAILS are rows 1 and 2).
; TipY is the label Y of the TOOLTIPS row: put it below the last own row.
TipKey={{Name}}Tooltips
TipY=180
@include10=#@#Settings\Tooltips.inc
