# Architecture

> The repo changes fast. This page describes the shape and the reasons. Names, counts and exact keys can be stale: before relying on one, check the file named next to it (`ls`, `grep`). When this page and the repo disagree, the repo wins; fix the page in the same PR.

## Layout

```
Control-Plaine\                 config root; always #ROOTCONFIG#, never the literal name
  @Resources\
    Theme.inc                   design tokens (not user settings)
    Defaults.inc                defaults for GENERAL settings only
    User.inc, State.inc         git-ignored: user overrides / runtime state
    Core.inc                    shared measures: accent, full-screen hide, hover fade, rest alphas
    Styles.inc                  shared meter styles
    Settings\Chrome.inc, Controls.inc   Settings window panel and row styles
    Scripts\                    <Skin>.lua per skin, Settings.lua, Onboarding.lua, Needs.lua, helper .ps1 scripts
    Setup\                      NeedsList.lua (what each skin needs), Helpers.txt (install allow-list)
    Icons\                      PNGs rendered from docs\icons\*.svg
  <Skin>\<Skin>.ini             one skin per folder
  <Skin>\Defaults.inc           that skin's setting defaults
  Settings\General.ini, <Skin>.ini    one Settings page per tab
  Layouts\                      shipped layout
  specs\                        per-skin and foundation specs (design history plus rules)
  docs\                         guides (users), dev (this folder), icons, DESIGN-V1.md
  tools\                        lint.py, install.ps1, render-icons, fan-tasks.ps1
```

Skin folders are listed in `SKIN_FOLDERS` in `tools/lint.py`. The Settings tab list is `TABS` at the top of `@Resources/Scripts/Settings.lua`. `specs/foundation-settings.md` section 1 has the ownership table.

## Include order and who wins

Every v2 skin (one that includes `Core.inc`) has this in `[Variables]`, in this order:

1. `#@#Theme.inc`
2. `#@#Defaults.inc`
3. `#ROOTCONFIGPATH#<Skin>\Defaults.inc`
4. `#@#User.inc`
5. `#@#State.inc`
6. skin-local variables
7. `#@#Core.inc`
8. `#@#Styles.inc`

Later files override earlier ones, so `User.inc` beats both defaults files and `State.inc` is runtime state. `Core.inc` and `Styles.inc` come last because they hold sections and compute values from the settings above. `tools/lint.py` enforces the order (`V2_ORDER`); Settings pages add `Settings\Controls.inc` and `Settings\Chrome.inc` after those (`SETTINGS_ORDER`).

## What each shared file is for

- **Theme.inc**: colours, alpha levels that do not follow settings, type sizes and tracking, ring and icon geometry, fade timing. Not user settings. Legacy v1 names sit at the bottom and are being removed; do not use them in new code.
- **Defaults.inc** (root): general settings (scale, accent, brightness, full-screen hide, lock) plus runtime variables marked "not settings".
- **Core.inc**: `#Accent#` (Windows accent or custom, live), `#AlphaDetail#`/`#AlphaValue#` (rest levels from `RestBrightness`), `#Sz#` (the skin's size: `Scale`, times `SizeBoost` for skins that opt in), `TipHidden*` (tooltip gate), the `mVisible` measure and the `mFade` hover fade that drives `#Reveal#` from 0 to 1.
- **Styles.inc**: `sDisplay`, `sValue`, `sTitle`, `sDetail`, `sReveal`, `sLink`, `sWarn`, `sAccent`, `sIcon`, `sIconFade`, `sHit`, `sRing`. Combine with `|` (later wins). Read the comments at the top of the file for the rules of each.

Read these three files before inventing a new token, style or helper. Alignment helpers (left/right) and light/dark tokens are being added to `Core.inc`/`Theme.inc`; check them there, and the plans owner before editing.

## How settings flow

1. A default lives in `Defaults.inc` (general) or `<Skin>\Defaults.inc`. Every user-facing key must exist in one, so a fresh install with an empty `User.inc` works and new keys arrive with `git pull`.
2. The Settings window (`Settings\<Skin>.ini`, a variant of one Settings config) calls `@Resources\Scripts\Settings.lua` (`Toggle`, `Set`, `Step`, `EditPath`...). It writes the key to `@Resources\User.inc`, sets the variable live, and refreshes the target skins.
3. Skins read `#Key#` and refresh. Row-building recipes are in the comment block at the top of `@Resources/Settings/Controls.inc`.
4. Runtime state a skin writes itself (a pending power schedule, the Fan Control MAX flag) goes to `State.inc` and is documented in the skin's `Defaults.inc` under "Runtime, not settings".

## First-run setup and needs

`Settings.lua` `Initialize` checks `State.inc` for `SetupDone`; if it is not `1` it loads `Settings\Onboarding.ini` (one file, step in `OnbStep`) instead of the requested page. `Scripts\Onboarding.lua` drives the steps and reuses `Settings.lua` for every write (`Set`, `EditPath`, `SkinOn`), so no setting is defined twice. What a skin needs lives only in `@Resources\Setup\NeedsList.lua`; `Scripts\Needs.lua` checks it with file-exists and Registry-measure reads (nothing is run, nothing written) and gives each skin a state: OK, DEGRADED (an optional need is missing) or BLOCKED (a mandatory one). Every skin evaluates its own needs: `Scripts\Core.lua` (mCore) does it at load, so the variables are set before the first draw, then about once a minute, and only when a value changed it calls `!UpdateMeter *` and `!Redraw`. It sets `<Skin>Has<Feature>` (0/1), `<Skin>NeedState` and `<Skin>NeedBlocked` on the skin (pcall around everything; a missing list or entry leaves the defaults, meaning present). Skin scripts and measures only read those flags (an `mBlocked` measure turns `NeedBlocked` into `SelfHidden`); none runs its own detection. The Settings window reads the same lists for the amber marks. Install commands come only from `@Resources\Setup\Helpers.txt` (the file `tools\install.ps1` also reads); the setup runs one helper only after its button is clicked. Lint checks the list against the Defaults files, the skin list and the helper file. Offline tests: `tools/test_onboarding.py`, `tools/test_onboarding_flow.py`.

## Hiding and visibility

A skin never calls `!Show` or `!Hide` on itself. It sets `SelfHidden` and updates `mVisible`; `Core.inc` combines that with full-screen hiding. Lint rejects `[!Show]`/`[!Hide]` in v2 skins.

## Scripts and helpers

Lua scripts (`Scripts\<Skin>.lua`) hold skin logic. Windows work that Lua cannot do (power tasks, controller discovery, window hiding) goes through hidden PowerShell helpers; those write to `%TEMP%` or `State.inc` and the skin reads the result. Helpers that start apps or create scheduled tasks are outward-facing: change them with care and test on a PC (see [testing](testing.md)).

## Specs

`specs/*.md` explain why a skin behaves as it does and record what was checked on a real PC. They are design history and are not kept in step line by line. For current behaviour trust the skin file header comment, `Defaults.inc` and the code.
