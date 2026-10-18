; Control-Plaine | Controllers: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the Controllers skin; add keys here with the Controllers prefix.

[Variables]
; Which screen edge the skin sits on: left puts the icon first, right mirrors
; it (icon last, battery and percent on the inner side of the name). AlignAll
; in Settings can override it.
ControllersAlign=left
; hover shows every battery and the hovered name only while hovered, always
; keeps them visible. DetailsAll in Settings can override it.
ControllersDetails=hover
; 1 shows this skin's tooltips, 0 hides them all.
ControllersTooltips=1
; At rest, battery shows only under this (%).
ControllersBatteryShow=50
; Program a DualSense click opens. DSX on Steam (app 1812620); an exe path works too.
ControllersDualSenseApp=steam://rungameid/1812620
; Program a wheel click opens (Moza Pit House).
ControllersWheelApp=C:\Program Files (x86)\MOZA Pit House\bin\MOZA Pit House.exe
; What other controllers open.
ControllersOther=ms-settings:bluetooth
; Under this (%), the battery is orange.
ControllersBatteryLow=15
; Seconds between controller scans.
ControllersPoll=3
; Seconds between battery reads (Xbox Bluetooth, DualSense without DSX).
ControllersBatteryPoll=60
; Port of the DSX mod server (DSX settings: incoming UDP).
ControllersDsxPort=6969
