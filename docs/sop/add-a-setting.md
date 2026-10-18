# Add a setting

Use this to add or change one user-facing option of an existing skin (or a general one). Read [README.md](README.md) first for the premise check.

## Steps

1. [ ] **Decide the key.** Skin settings are `<Skin>` prefix plus a descriptive name; general settings have no prefix; booleans are `0`/`1`, enums are lowercase words, colours are `R,G,B`, values never contain `#` ([../dev/conventions.md](../dev/conventions.md), Naming). Check it does not already exist: `grep -rn "<Key>" --include=*.inc --include=*.ini --include=*.lua .`
2. [ ] **Give it a default** with a one-line comment above it, in `<Skin>/Defaults.inc` (skin setting) or `@Resources/Defaults.inc` (general; shared file, see [change-a-shared-file.md](change-a-shared-file.md)). Lint: a Settings page may only use a key that has a default. A fresh install with an empty `User.inc` must work.
3. [ ] **Runtime state is not a setting.** If the skin writes it itself, put it under a `---- Runtime, not settings ----` comment in the Defaults file; it lives in `State.inc`. Lint rule B10 exempts keys under that comment and otherwise wants a Settings row for every key.
4. [ ] **Read it in the skin** as `#Key#`. Options that read a variable that can change need `DynamicVariables=1`. A setting that changes alignment, details, theme or tooltips uses the shared mechanisms (`specs/alignment.md`, `specs/theme.md`, `specs/tooltips.md`), not a private one.
5. [ ] **Add a Settings row** on `Settings/<Skin>.ini`. Copy the recipe for the control you need (toggle, choice, value box, path box) from the comment block at the top of `@Resources/Settings/Controls.inc`, using the same call the recipe shows (`Toggle`, `Set`, `Step`, `EditPath`; the last argument names the skin(s) to refresh). Keep the `TipY` row below the last own row. Lint: the key in each call must have a default.
6. [ ] **Document it** in `docs/guide/<Skin>.md` (key, default, what it does) and in `docs/guide/settings.md` if it is a general option. Defaults in the guide must equal the Defaults file. Same PR (CLAUDE.md rule).
7. [ ] **Check by command.** `python tools/lint.py` shows `0 problem(s)` and no new B10 warning for your key; `for t in tools/test_*.py; do python "$t"; done` passes.
8. [ ] **PC checks to list in the PR:** the row appears and fits the panel at 100% and 125%; clicking or scrolling writes the key to `@Resources\User.inc` and the skin reacts after the refresh; deleting the line from `User.inc` restores the default.

## Do not

- Put a user-facing key only in `User.inc` or only in a skin ini.
- Add a setting that needs a new shared style or token without going through the owner of `Styles.inc` or `Theme.inc`.
