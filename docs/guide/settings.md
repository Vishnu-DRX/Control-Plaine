# Settings

Right-click any Control-Plaine skin and choose **Control-Plaine settings**. One window opens with a tab per skin plus **General**. Changes apply at once and are saved to `@Resources\User.inc`, which overrides every default. Delete a line there to go back to the default.

*Draft. Alignment, details, tooltip, light/dark and onboarding options are being added; this page lists what exists in `@Resources/Defaults.inc` today. Re-check that file when you update it.*

## General

| Key | Default | What it does |
| --- | --- | --- |
| `Scale` | `1` | Size of every skin, 0.5 to 3.0 (shown as a percent). |
| `SizeBoost` | `1.25` | Extra size for Controllers, Fan Control, DeepCool, Wi-Fi and SignalRGB only, on top of Scale. |
| `AccentFollowWindows` | `1` | 1 = follow the Windows accent colour, 0 = use `AccentColor`. |
| `AccentColor` | `0,229,255` | Custom accent (R,G,B); also the start value before Windows is read. |
| `RestBrightness` | `60` | How bright details and icons are when not hovered, 30 to 90 (%). Values sit 20 points above. |
| `HideFullScreen` | `0` | Hide every skin while a full-screen app is in front. Follows the foreground window on any monitor, so it can also hide skins on a second screen. |
| `LockPositions` | `0` | Stop skins from being dragged. |

Every skin also has a `<Skin>Tooltips` switch (1 = tooltips on). Per-skin options are on each skin's page: see the [skin list in the README](../../README.md#skins).

## Hand editing

`@Resources\User.inc` is a plain file with a `[Variables]` header and `Key=value` lines. Each skin's `Defaults.inc` documents every key. Refresh the skin after editing.

## Not settings

`@Resources\State.inc` holds runtime state the skins write themselves (for example a pending power schedule). Leave it alone.
