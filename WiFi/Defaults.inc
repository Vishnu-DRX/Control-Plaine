; Control-Plaine | WiFi: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the WiFi skin; add keys here with the WiFi prefix.

[Variables]
; 1 shows this skin's tooltips, 0 hides them all.
WiFiTooltips=1
; What clicking the icon or name opens: settings (Windows Wi-Fi settings),
; or any program, file or URI.
WiFiClick=settings
; Ookla Speedtest command-line tool (speedtest.exe). winget install Ookla.Speedtest.CLI
; puts it here. If this is empty or wrong, the skin also looks in the usual places.
WiFiSpeedtestPath=%LOCALAPPDATA%\Microsoft\WinGet\Links\speedtest.exe
