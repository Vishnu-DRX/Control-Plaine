; Control-Plaine | WiFi: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the WiFi skin; add keys here with the WiFi prefix.

[Variables]
; Which screen edge the skin sits on: left puts the icon first, right mirrors
; it (text first, icon last). AlignAll in Settings can override it.
WiFiAlign=left
; hover shows the network name and speed test only while hovered, always keeps
; them visible. DetailsAll in Settings can override it.
WiFiDetails=hover
; 1 shows this skin's tooltips, 0 hides them all.
WiFiTooltips=1
; What clicking the icon or name opens: settings (Windows Wi-Fi settings),
; or any program, file or URI.
WiFiClick=settings
; Ookla Speedtest command-line tool (speedtest.exe). winget install Ookla.Speedtest.CLI
; puts it here. If this is empty or wrong, the skin also looks in the usual places
; (WiFi.lua: the WinGet Links and Packages folders, Programs\Ookla, Program Files),
; so an empty value still works when speedtest.exe is installed.
WiFiSpeedtestPath=%LOCALAPPDATA%\Microsoft\WinGet\Links\speedtest.exe
; Which wireless adapter WiFiStatus reads (0 = first). Raise it if the network
; name stays blank on a PC with more than one wireless adapter.
WiFiInterface=0
