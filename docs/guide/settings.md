# Settings

Right-click any Control-Plaine skin and choose **Control-Plaine settings**. One window opens with a tab per skin plus **General**. Changes apply at once and are saved to `@Resources\User.inc`, which overrides every default. Delete a line there to go back to the default.

## General

| Key | Default | What it does |
| --- | --- | --- |
| `Scale` | `1` | Size of every skin, 0.5 to 3.0 (shown as a percent). |
| `AccentFollowWindows` | `1` | 1 = follow the Windows accent colour, 0 = use `AccentColor`. |
| `AccentColor` | `0,229,255` | Custom accent (R,G,B); also the start value before Windows is read. |
| `RestBrightness` | `60` | How bright details and icons are when not hovered, 30 to 90 (%). Values sit 20 points above. |
| `HoverBrightness` | `98` | How bright a hovered skin is, 30 to 100 (%). Never below the rest level. |
| `HideFullScreen` | `0` | Hide every skin while a full-screen app is in front. Follows the foreground window on any monitor, so it can also hide skins on a second screen. |
| `LockPositions` | `0` | Stop skins from being dragged. |

If `User.inc` holds a setting no skin uses any more, a line at the bottom of General says so and links to the Advanced tab.

## Advanced

| Row | Key | Default | What it does |
| --- | --- | --- | --- |
| ALIGN ALL SKINS | `AlignAll` | `skin` | `skin` = each skin uses its own Align; `left` or `right` forces every skin. |
| DETAILS ON ALL SKINS | `DetailsAll` | `skin` | `skin`, `hover` or `always`, same idea. |
| ACCENT ON HOVER | `HoverAccent` | `1` | A hovered icon takes the accent colour. |
| HOVER LINGER | `HideDelay` | `500` | Milliseconds details stay after the mouse leaves. |
| FONT | `FontFace` | `Segoe UI Variable Display` | Choose `Segoe UI` on Windows 10 or if the Variable font is missing. |
| TOOLTIPS ON ALL SKINS | `TooltipsAll` | `skin` | `skin` = each skin uses its own `<Skin>Tooltips`; `on` shows every tooltip; `off` hides every tooltip. Skins reload when you change it. |
| SIZE BOOST | `SizeBoost` | `1.25` | Extra size for Controllers, Fan Control, DeepCool, Wi-Fi, SignalRGB and Settings Button, on top of Scale. Icons are pre-rendered at 1.25, so other values make them softer. |
| RESET SETTINGS | n/a | n/a | Click, then click again to confirm: empties `User.inc` and refreshes every skin. |
| CLEAN UNKNOWN SETTINGS | n/a | n/a | Lists keys in `User.inc` that no skin defines (for example a removed setting) and deletes them. |

The footer of every page has REFRESH ALL, OPEN SKINS FOLDER and OPEN USER.INC.

Every skin also has a TOOLTIPS row on its own page (`<Skin>Tooltips`, 1 = tooltips on). Per-skin options are on each skin's page: see the [skin list in the README](../../README.md#skins).

## Hand editing

`@Resources\User.inc` is a plain file with a `[Variables]` header and `Key=value` lines. Each skin's `Defaults.inc` documents every key. Refresh the skin after editing.

## Not settings

`@Resources\State.inc` holds runtime state the skins write themselves (for example a pending power schedule). Leave it alone.
