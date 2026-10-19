# Tooltips: the on/off switch

Wording and style of tooltip text are in `foundation-settings.md` 5.1. This page is only about hiding them.

## Settings

| Key | Values | Default | Where |
| --- | --- | --- | --- |
| `<Skin>Tooltips` | `1`, `0` | `1` | The skin's `Defaults.inc`; the TOOLTIPS row on the skin's Settings page. |
| `TooltipsAll` | `skin`, `on`, `off` | `skin` | Root `Defaults.inc`; TOOLTIPS ON ALL SKINS on the Advanced page. |

`skin`: each skin follows its own `<Skin>Tooltips`. `on`: every tooltip shows. `off`: every tooltip is hidden. A skin's own switch keeps working after `TooltipsAll` goes back to `skin`.

## Mechanism (one, variable lookup in Core.inc)

`ToolTipHidden` is in a skin's `[Rainmeter]` section, which Rainmeter reads while the skin loads, before any script runs. So a script (`Core.lua`) cannot resolve it and nothing writes to every skin's keys. The override is a pure variable lookup in `@Resources\Core.inc`:

```
TipHide1_skin=0   TipHide1_on=0   TipHide1_off=1
TipHide0_skin=1   TipHide0_on=0   TipHide0_off=1
TipHidden1=#TipHide1_[#TooltipsAll]#
TipHidden0=#TipHide0_[#TooltipsAll]#
```

Every skin defines `TipHide=#TipHidden[#<Skin>Tooltips]#` in its `[Variables]` after the Core.inc include, and uses `ToolTipHidden=#TipHide#` in `[Rainmeter]` and on every meter with a tooltip (a nested lookup written on a meter is not read by Rainmeter: PC probe 2026-10-19). `<Skin>Tooltips` picks `TipHidden1` or `TipHidden0`, and those pick the value from `TooltipsAll`. The tables are defined before `TipHidden1/0` because Rainmeter replaces a variable as it is defined. `ToolTipHidden` hides every tooltip of the skin, including the ones scripts set with `!SetOption`.

Changing a switch refreshes the affected skins (`'all'` for `TooltipsAll`, the skin for its own row), which is when the line is read again.

## Settings rows

`@Resources\Settings\Tooltips.inc` is the shared TOOLTIPS row. A page sets `TipKey=<Skin>Tooltips` and `TipY=<Y of the label>` (below its last row) and includes it after Chrome.inc. `TipCompact=1` makes it one line without the description (Controllers, whose page is full). `TooltipsAll` has its own choice row on `Settings\Advanced.ini`.

## Lint and test

- T3: a skin with any `ToolTipText` (ini or script) has `TipHide` and `ToolTipHidden=#TipHide#` as above; `TipHidden1/0` in Core.inc look up `[#TooltipsAll]`.
- T4: such a skin has `<Skin>Tooltips=1` in its Defaults.inc and a Settings page that sets `TipKey` and includes `Tooltips.inc`; `TooltipsAll=skin` is in the root Defaults.inc; Advanced has the three `Set('TooltipsAll',...)` choices.
- `python tools/test_tooltips.py` evaluates every skin's real line for every `TooltipsAll` x `<Skin>Tooltips` combination, with variables replaced at definition and at read.

## [PC] checks

- T1: with `<Skin>Tooltips=1` the skin's tooltips appear on hover; with `0` none do.
- T2: `TooltipsAll=off` silences every skin, `on` enables every skin, `skin` returns each to its own setting, and a skin's own toggle still works afterwards.
- The nested `#TipHidden1#` -> `#TipHide1_[#TooltipsAll]#` lookup resolves in real Rainmeter (the single-level form shipped in #74 is known to work).
- Advanced page: the TOOLTIPS row fits at 312 and the rows below it moved 52 down (CLEAN UNKNOWN SETTINGS ends at about 584 of 588).
- Controllers page: the ADVANCED rows moved up (pitch 24) to fit a one-line TOOLTIPS row at 576; check nothing overlaps the footer.
