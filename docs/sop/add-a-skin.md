# Add a skin

Use this to add one new skin. Each step names the file to change and what enforces it. "Lint" means `python tools/lint.py`; read the named rule in that file for the exact condition, since rules are added over time. Reference skins to copy from: `SettingsButton/` (smallest) and `SignalRGB/` (scripts, state, extra settings), with their Settings pages in `Settings/`.

## 0. Check the premise

- [ ] Run `git log --oneline -n 10`, `git status`, `python tools/lint.py` (must be clean) and `ls`.
- [ ] Read [../../CLAUDE.md](../../CLAUDE.md), [../dev/architecture.md](../dev/architecture.md), [../dev/conventions.md](../dev/conventions.md), `specs/alignment.md`, `specs/theme.md`, `specs/tooltips.md`.
- [ ] New look? Mock it up and get Vishnu's sign-off first (CLAUDE.md, Design).
- [ ] Which shared files will you touch (steps 3 to 6)? If another PR owns one, send the exact change to its owner instead ([change-a-shared-file.md](change-a-shared-file.md)).
- [ ] Branch from a fresh `main`. One concern per PR.

## 1. Generate the skeleton

- [ ] `python tools/new-skin.py <Name> --title "Display Name" --icon <existing-icon> --summary "One line."`

  It writes `<Name>/<Name>.ini`, `<Name>/Defaults.inc`, `Settings/<Name>.ini` and `docs/guide/<Name>.md` from `tools/templates/`, refuses to overwrite anything, and prints the manual steps. `<Name>` is PascalCase with no spaces; the folder, the ini, the Settings page, the script and the key prefix all use it (conventions: Naming). The generated files are well formed, but lint is not clean until the skin is registered (steps 4 and 7): right after generation it reports I1 (the folder is not in `SKIN_FOLDERS`, and its Settings page is not a known page) and I2 (`docs/INDEX.md` does not list the guide), and once registered it still reports I1 for the General toggle and the layout section. That is expected; work through the steps and finish with lint at zero. The list of manual steps the script prints follows the same order as this page but numbers them differently (it has 3, 3b, 4 and so on); use this page.

## 2. Make the skin ini correct (`<Name>/<Name>.ini`)

- [ ] Header comment: What it shows, Designed for (name the software and version), Adjust (the keys). Enforced by review (conventions: Skin file).
- [ ] `[Rainmeter]` has `Group=ControlPlaine`, the **Control-Plaine settings** right-click entry pointing at `<Name>.ini`, and `[Metadata]` exists. Lint: Group, right-click entry, `[Metadata]` checks.
- [ ] `[Variables]` includes, in order: Theme, Defaults, `<Name>\Defaults.inc`, User, State, skin-local, Core, Styles. Lint: `V2_ORDER` and the own-Defaults include.
- [ ] Alignment keys: `SkinSide=#<Name>Align#`, `SkinDetails=#<Name>Details#`, defaults `left` and `hover`, only the Core helpers (`Mir`, `TA`, `TAT`, `Lead`, `Trail`) in meters, never a private mirror. Lint: the alignment checks (A5, A6, A9). Recipe: `specs/alignment.md` sections 2 to 4.
- [ ] Fixed box: `BoxW` or a `Hit` meter width computed once, in whole pixels, the same on both sides, so flipping the side never resizes the skin. Review (alignment spec, section 4); add an offline check in a new `tools/test_<skin>.py` if there are formulas worth testing (model it on an existing `tools/test_*.py`).
- [ ] Theme: `SkinTheme=#<Name>Theme#`, default `auto`, colours only from `#Ink#`, `#InkContrast#`, `#Accent#`, `#Warn#`, `#Dark#`; Lua that keeps a colour re-reads it in `Update`. Lint: the theme checks (L6, L8). Spec: `specs/theme.md` section 4.
- [ ] Tooltips: every `ToolTipText` is gated by `ToolTipHidden=#TipHidden[#<Name>Tooltips]#` in `[Rainmeter]`. Lint: T3, T4 (active once the skin is in `SKIN_FOLDERS`, step 3). Spec: `specs/tooltips.md`.
- [ ] Hiding uses `SelfHidden` and `mVisible`, never `!Show`/`!Hide`. Lint: the `!Show`/`!Hide` check.
- [ ] Every size multiplied by `#Scale#` or `#Sz#`; invisible hit areas use `SolidColor=0,0,0,1`; options that read runtime variables have `DynamicVariables=1`. Review.
- [ ] ASCII only, no inline `;` comments, no hardcoded user paths. Lint.
- [ ] Optional functions (a needed app, plugin or helper): gate them on the needs-list / `Has<Feature>` mechanism so a missing dependency degrades quietly: an entry in `@Resources/Setup/NeedsList.lua` (step 4) plus a `<Name>Has<Feature>` variable that the meters read. Scripts\Core.lua evaluates the list, so the skin runs no detection of its own. Lint: the GD1 checks (every `Has<Feature>` the ini uses must be declared in the needs list). If the skin needs nothing, the entry is an empty list.
- [ ] A script, if the skin needs one, is `@Resources/Scripts/<Name>.lua` (and its helper `.ps1` beside it). Keep `Update` slow; helpers must not outlive the skin ([../dev/conventions.md](../dev/conventions.md), Performance).

## 3. Defaults (`<Name>/Defaults.inc`)

- [ ] Every user-facing key is here with the `<Name>` prefix and a comment above it; runtime keys go under a `---- Runtime, not settings ----` comment. Lint: Settings pages may only use keys that have a default; B10 fails a setting that has no Settings row (keys after a `---- Edit in User.inc ----` comment are personal values with no row and are exempt).
- [ ] The four standard keys exist: `<Name>Align=left`, `<Name>Details=hover`, `<Name>Theme=auto`, `<Name>Tooltips=1`. Lint: A-checks, L-checks, T4.
- [ ] `<Name>Theme` has its COLOURS row on the Settings page (step 5) through `@Resources/Settings/Theme.inc`; lint fails a themed skin without it.

## 4. Register the skin (shared files, one owner at a time)

Do these as small appends and check ownership first ([change-a-shared-file.md](change-a-shared-file.md)).

- [ ] `tools/lint.py`: add `<Name>` to `SKIN_FOLDERS`. This turns on the "has Defaults.inc and a Settings page" check and the tooltip rules for the skin. Verify by temporarily deleting `<Name>/Defaults.inc` and watching lint fail (restore it).
- [ ] `@Resources/Scripts/Settings.lua`: add `'<Name>'` to `TABS`. It lights the current tab and builds the list of known keys from each listed skin's `Defaults.inc`; a skin missing here would have its saved keys reported as unknown by the cleanup on the Advanced page. Lint: S11 and I1 fail if `TABS` and `SKIN_FOLDERS` differ.
- [ ] `@Resources/Settings/Chrome.inc`: add a `[Tab<Name>]` meter after the last tab with the next row number, before `[TabBar]` (copy the neighbour). Check the tab column still fits the panel. No lint rule; verify on the PC or by reading the Y values.
- [ ] `Settings/General.ini`: add the skin's toggle pair (`[Skin<Name>]`, `[Skin<Name>Toggle]`, calling `SkinOn('<Name>')`) in the SKINS section, copying a neighbour. Lint: I1 fails if a skin has no `SkinOn` toggle. Check the Y does not collide (no lint rule; the PC shows it).
- [ ] `@Resources/Setup/NeedsList.lua`: add `<Name> = {},` (or one entry per app, plugin or path the skin needs: mandatory = the skin is blocked without it, optional = a function is hidden; fields are described at the top of that file). Lint fails without an entry. A feature gate `<Name>Has<Feature>` in the skin ini needs a default `=1` in `<Name>/Defaults.inc`. If an install command exists, add it to `@Resources/Setup/Helpers.txt` and name it as `helper`.
- [ ] `@Resources/Settings/Chrome.inc` and `Settings/General.ini`: copy a neighbour's amber `[Mark<Name>]` and `[ListMark<Name>]` meters for the new skin (they show when its needs are missing).
- [ ] If the skin should join the "size boost" group, that is a one-line comment edit in root `@Resources/Defaults.inc` and `docs/guide/settings.md`; do it only if the skin really uses `SizeBoost`.

## 5. Settings page (`Settings/<Name>.ini`)

- [ ] Includes in order: Theme, Defaults, `<Name>\Defaults.inc`, User, `Tab=<Name>`, Core, Styles, Controls, Chrome, then `AlignKey`, `DetailsKey` and `Align.inc`, then `ThemeKey`, `ThemeY`, `Theme.inc` (the COLOURS row), then `TipKey`, `TipY`, `Tooltips.inc`. Lint: `SETTINGS_ORDER`, the `AlignKey`/`DetailsKey` rule, T4, the COLOURS row, and the row layout check.
- [ ] Own rows start at Y=180 (below the ALIGN and DETAILS rows); set `ThemeY` and `TipY` below the last own row. Lint fails rows that overlap or end below Y=592; use a pitch of 52 or one-line rows if the page is full. Recipes for each control are in the comment block at the top of `@Resources/Settings/Controls.inc`. Lint: every `Fill`/`Knob`/`Toggle`/`Set`/`Step`/`Show`/`ChoiceAlpha`/`ChoiceLine`/`EditPath` key must have a default.
- [ ] More options: follow [add-a-setting.md](add-a-setting.md).

## 6. Icon

- [ ] Own icon: [add-an-icon.md](add-an-icon.md) (SVG in `docs/icons/`, `node tools/render-icons.js`, PNG in `@Resources/Icons/`). Lint: the icon file must exist; L7: the PNG must be tintable white.

## 7. Documentation and listings

- [ ] `docs/guide/<Name>.md`: replace every TODO; defaults match `<Name>/Defaults.inc` (the file wins). Required by the DD5 rule in CLAUDE.md: a PR that changes what a user sees or can set updates the guide in the same PR.
- [ ] `docs/skins.json`: add the entry (it feeds the README and the site; lint I1). `README.md`: add the Skins table row (lint I4). `docs/INDEX.md`: add the guide to the skin list (lint I2). `docs/guide/settings.md` only if it lists the skin's rows. The guide must name every setting key of `<Name>/Defaults.inc` above its "Runtime, not settings" comment (lint I5).
- [ ] `site/index.html`: add a card with an illustration built from the skin's own icons and the tokens in `Theme.inc` (see `site/README.md`), or, for a skin without a card, add its name to the "Also in the suite" line; lint I4 fails a skin the page does not name. What the card says must match the guide (what shows at rest and on hover). Do not publish the site; that waits for Vishnu's go.
- [ ] `CHANGELOG.md` and `tools/layout/Control-Plaine.layout`: integration-owned. Do not edit unless asked, but lint I1 fails until the skin has a layout section, so agree the lines with the owner first; put the suggested lines in the PR body ([../dev/release.md](../dev/release.md)).

## 8. Verify and open the PR

- [ ] `python tools/lint.py` prints `0 problem(s)`.
- [ ] `pip install lupa` then each `tools/test_*.py` passes (CI runs all of them).
- [ ] `git status` shows no `@Resources/User.inc` or `State.inc`.
- [ ] PR body: what was checked, and a **Not checked here (needs the PC)** list: the skin loads without errors in the Rainmeter log, looks sharp left and right at 100% and 125% scale, hover and click work, light and dark, tooltips, the Settings tab and General toggle ([pc-test-protocol.md](pc-test-protocol.md)). Cloud sessions cannot see Rainmeter; say so.
- [ ] Merge, then on the PC `git pull --ff-only` and refresh; never switch branches in the live folder.
