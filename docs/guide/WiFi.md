# Wi-Fi

Wi-Fi signal and network name, with a manual speed test.

*Draft.* Behaviour was read from `WiFi/WiFi.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** Wi-Fi icon (lit arcs = signal strength). Warnings show at rest: NO INTERNET, NOT CONNECTED, AIRPLANE MODE; a wired link shows ETHERNET.
- **On hover:** The network name, and a speed test icon at its right. A test shows a spinner and live speed, then download, upload and ping, which fade out and the name returns.

## Left or right

`WiFiAlign` = `left` puts the icon first and the text after it. `right` mirrors the skin inside the same box: text first, icon last, and the speed test result reads from the icon inward (down, up, ping). The window never moves or resizes. `WiFiDetails` = `hover` shows the network name and speed test only on hover; `always` keeps them visible. The global ALIGN and DETAILS rows on [Settings](settings.md) can override both.

## Actions

- Click the icon or name: opens `WiFiClick` (default: Windows Wi-Fi settings).
- Click the speed test icon, or right-click > Run speed test.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `WiFiTooltips` (1 = show its tooltips, 0 = hide them all; default 1). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `WiFi/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `WiFiAlign` | `left` | `left` or `right`. |
| `WiFiDetails` | `hover` | `hover` or `always`. |
| `WiFiClick` | `settings` | `settings` (Windows Wi-Fi settings) or any program, file or URI. |
| `WiFiSpeedtestPath` | `%LOCALAPPDATA%\Microsoft\WinGet\Links\speedtest.exe` | Ookla Speedtest CLI. If empty or wrong the skin also looks in the usual places (WinGet Links and Packages folders, Programs\\Ookla, Program Files), so an empty box still runs the test when it is installed. |
| `WiFiInterface` | `0` | Which wireless adapter to read (0 = first). Under ADAPTER (ADVANCED) in Settings. |

## Requirements

Ookla Speedtest CLI 1.x for the speed test (`winget install Ookla.Speedtest.CLI`; the installer tries it). Windows must allow the network name to be read (see [troubleshooting](troubleshooting.md)).

## Known limits

If the name stays blank on a PC with more than one wireless adapter, raise `WiFiInterface` (Settings > WI-FI > ADAPTER).
