# Troubleshooting

*Draft, from behaviour documented in the skins and installer. Re-check each item against the live skins in the final docs pass.*

**A skin does not appear.** Check Manage > Skins that it is loaded and that `Skins\Control-Plaine` exists (the installer makes it). Refresh all from the tray menu. If the Rainmeter log shows an error it names the file and line.

**Plugin errors after install ("Unable to load", error 193).** A plugin file is missing or not a real DLL. Re-run `tools\install.ps1`, then exit and restart Rainmeter. Plugins load only at start.

**Media skin never shows.** It is hidden while nothing plays (`MediaHideIdle`). Start a player that appears in the Windows media flyout. Check `MediaPlayer.dll` is in `%APPDATA%\Rainmeter\Plugins` (64-bit) and Rainmeter was restarted.

**Wi-Fi name is blank.** Windows only gives apps the network name when Location services are on (Settings > Privacy & security > Location). On a PC with several wireless adapters set `WiFiInterface` in the skin.

**Wi-Fi speed test does nothing.** Install the Ookla Speedtest CLI (`winget install Ookla.Speedtest.CLI`) and set `WiFiSpeedtestPath` on the Wi-Fi tab if it is not found.

**Fan Control shows no speed, or MAX does nothing.** Fan Control and its sensor feed need admin, so the skin uses scheduled tasks. Run `tools\fan-tasks.ps1` once as administrator (the sensor reader needs PowerShell 7), then check `FanControlPath`, `FanControlNormal` and `FanControlMax` match your install and profile names.

**SignalRGB brightness changes nothing.** On the free tier the skin applies an effect with a `color` property (`SignalRGBEffect`, default Solid Color) in the colour `SignalRGBColor`; set both to match what you use in SignalRGB. Pro uses the local API (`SignalRGBPort`).

**Uptime does not reset after Shut down.** Windows Fast Startup keeps the count; only Restart resets it. Turn Fast Startup off in Power Options if you want Shut down to reset it.

**Skins hide when I play a game.** `HideFullScreen` follows the foreground window on any monitor. Turn it off in General if skins on a second screen disappear.

**Fonts look different.** The suite uses Segoe UI Variable. On Windows 10 set `FontFace=Segoe UI` in `@Resources\User.inc`.

**Reset a setting.** Remove its line from `@Resources\User.inc` and refresh.
