# {{Title}}

{{Summary}}

*Draft.* Written from the generated skin; replace this note when the page has been checked against the skin on a PC.

## At rest and on hover

- **At rest:** TODO what is always visible.
- **On hover:** TODO what appears (always, when `{{Name}}Details` is `always`).
- **Side:** `{{Name}}Align` left puts the icon first; right mirrors it (label first, icon last). The box is the same size either way.

## Actions

- TODO click, scroll and other actions.
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `{{Name}}Tooltips` (the TOOLTIPS row on this skin's page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment) are on [Settings](settings.md).

> Defaults below were read from `{{Name}}/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `{{Name}}Align` | `left` | `left` or `right`: which screen edge it sits on. `AlignAll` can override it. |
| `{{Name}}Details` | `hover` | `hover` or `always`: when the label shows. `DetailsAll` can override it. |
| `{{Name}}Theme` | `auto` | `auto`, `dark` or `light`: colours for this skin. `auto` follows the global `Theme`. |

## Requirements

None.

## Known limits

- TODO.
