# Theme and brightness: dark and light skins

Status: built in WP-L0 (theme foundation) with SignalRGB as the pilot. Plan: `plans/phase-3-appearance.md` in the project folder. Where the build differs, the code comments win. Rainmeter behaviour that only the PC can prove is marked **[PC]**.

## 1. Words

The mode is named after the wallpaper:
- **dark**: for dark wallpapers. Skins are white. This is today's look.
- **light**: for light wallpapers. Skins are black.

## 2. Settings

| Key | Values | Default | Meaning |
| --- | --- | --- | --- |
| `Theme` | `dark`, `light`, `auto` | `dark` | The global mode. `auto` follows the Windows light/dark setting. |
| `<Skin>Theme` | `auto`, `dark`, `light` | `auto` | One skin's override. `auto` here means "follow `Theme`". |
| `ThemeFollow` | `SystemUsesLightTheme`, `AppsUseLightTheme` | `SystemUsesLightTheme` | Which Windows setting `Theme=auto` reads (taskbar and Start, or apps). |
| `AccentLight` / `AccentLightK` | `1`/`0`, number | `1`, `0.7` | In light mode the accent's colour channels are multiplied by `AccentLightK` so it stays readable. |
| `RestBrightness` | 30 to 90 | `60` | Rest level of details and icons, in percent. |
| `HoverBrightness` | 30 to 100 | `98` | Hover level, never below rest. |
| `LightBoost` | 0 to 40 | `10` | Percentage points added to the rest level in light mode. |

Settings rows: brightness on General (WP-G); SKINS FOR (`Theme`), LIGHT MODE BOOST and ACCENT DARKENING (`AccentLight`, `AccentLightK`) as one-line rows at the bottom of General (WP-L3). Each skin's COLOURS row (`<Skin>Theme`: AUTO / WHITE / BLACK) comes from `@Resources\Settings\Theme.inc`, included by the skin's page with `ThemeKey` and `ThemeY` set; WP-L2 adds it per skin, and lint fails a skin that sets `SkinTheme` without it. `ThemeFollow` has no row yet (edit `User.inc`).

**Default is `dark`, not `auto`.** The plan decided `auto`, but also needs "defaults leave everything as today" (L8) and says which Windows setting `auto` follows is to be settled on the PC. Shipping `auto` first would turn his skins black if Windows is on its light theme while his wallpaper is dark. Flip `Theme=dark` to `auto` in `Defaults.inc` once the registry choice is confirmed at gate G1.

## 3. What a skin gets

`Scripts\Core.lua` resolves these when the skin loads and again every 5 seconds, so a Windows theme or accent change shows without a refresh:

| Variable | dark | light |
| --- | --- | --- |
| `Mode` | `dark` | `light` |
| `Ink` | `Theme.inc` `Ink` (white) | `InkLight` (black) |
| `InkContrast` | `Theme.inc` `InkContrast` (black) | `InkContrastLight` (white). For a glyph drawn on an ink-coloured fill. |
| `Warn` | `Theme.inc` `Warn` | `WarnLight` (deeper orange) |
| `Accent` | the Windows accent, or `AccentColor` | the same, darkened by `AccentLightK` |
| `RestEff` / `HoverEff` | `RestBrightness` / `HoverBrightness` | rest plus `LightBoost`; hover not below rest; both capped at 100 |
| `HoverTint` | `Accent`, or `Ink` when `HoverAccent=0` | |

`AlphaDetail`, `AlphaValue`, `AlphaRest`, `AlphaDim` and `AlphaHover` are formulas on `RestEff` / `HoverEff` in `Core.inc`, so the brightness is computed in one place. Defaults give the same alphas as before (`Round(98*2.55)` is 250).

Mode resolution, in order: a locked skin is always dark; a `<Skin>Theme` of `dark` or `light` wins; else `Theme` if it is `dark` or `light`; else, for `auto`, the Windows setting (`mWinTheme`, a Registry measure; a missing value reads 0, which is dark); anything else is dark.

**The Settings window is always dark.** A skin is locked when it sets `ThemeLock=1` or names a page in `Tab`, which every Settings page does, so no page needed editing. `Settings\Chrome.inc` also sets `ThemeLock=1` explicitly.

White icons stay tintable: every skin draws icons with `ImageTint=#Ink#`, so a white PNG tinted by black is black with its own alpha and anti-aliasing. The two icons with coloured pixels are WP-L1's job.

## 4. Opting a skin in

1. `<Skin>Theme=auto` in `<Skin>/Defaults.inc`.
2. `SkinTheme=#<Skin>Theme#` in the skin's `[Variables]`, next to `SkinSide`.
3. No colour in the skin hard-coded: use `#Ink#`, `#InkContrast#`, `#Accent#`, `#Warn#`, `#Dark#`. Lint fails a skin that sets `SkinTheme` and writes `255,255,255` or `0,0,0` (other than the invisible `0,0,0,0` and hit-test `0,0,0,1`).
4. Any Lua that keeps a colour must re-read it in `Update`, not only in `Initialize`: the mode can change while the skin runs. SignalRGB's icon tint is the example.

A skin that has not opted in still follows `Theme` (it includes `Core.inc`), but any colour it hard-codes stays white or black. That is why `Theme` defaults to `dark` until the per-skin sweep (WP-L2).

## 5. Checked offline

`python tools/test_core.py` runs `Core.lua` against a fake `SKIN` for every combination of lock, `SkinTheme`, `Theme` and the Windows value (including bad values), checks `Ink`, `InkContrast`, `Warn` and `Accent` for each, the brightness cases (defaults unchanged, boost on rest, `LightBoost=0` restores, caps at 100, garbage falls back), the accent sources, `HoverTint`, a Windows switch picked up by `Update`, and a missing registry measure reading dark (L11).

## 6. What only the PC can show [PC]

1. SignalRGB in both modes on a real light wallpaper: legible black ink at the boosted level, sharp and without haloing (L1, L2, L12), accent readable (L3), layout and hit areas unchanged (L9).
2. `Theme=auto` follows Windows within a few seconds in both directions, and a skin with its own `dark` / `light` does not change (L10). Which of `SystemUsesLightTheme` and `AppsUseLightTheme` fits his setup.
3. The Settings window looks the same in every mode (L5).
4. Test by adding `Theme=light` (or `SignalRGBTheme=light`) to `@Resources\User.inc`: use the COLOURS row on SignalRGB's page and SKINS FOR on General.
