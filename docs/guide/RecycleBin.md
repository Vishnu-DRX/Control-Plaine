# Recycle Bin

Recycle Bin size, with an Empty link.

*Draft.* Behaviour was read from `RecycleBin/RecycleBin.ini` and its `Defaults.inc` in the repo. It is finalised against the live skin in the final docs pass.

## At rest and on hover

- **At rest:** The trash icon. With `RecycleBinAlign=left` (the default) it is first and the text follows; `right` mirrors it (text first, icon last).
- **On hover:** RECYCLE BIN over the total size appears (the size is orange above `RecycleBinWarnGB`), and EMPTY shows beside the size while there is something to empty. With `RecycleBinDetails=always` the text stays visible.

## Actions

- Click the title, size or icon: open the bin.
- Click EMPTY: empty the bin (Windows asks first when `RecycleBinConfirm` is on).
- Right-click: **Control-Plaine settings** opens this skin's Settings tab.

## Settings

Open it from the right-click menu, or edit `@Resources\User.inc` by hand. Besides the options below, every skin has `RecycleBinTooltips` (the TOOLTIPS row on this skin's page: 1 = show its tooltips, 0 = hide them all; default 1; `TooltipsAll` on the Advanced tab can force all skins on or off). Global options (size, accent, brightness, alignment where available) are on [Settings](settings.md).

> Defaults below were read from `RecycleBin/Defaults.inc` when this page was written. The file is the source of truth; if they differ, trust the file and fix this page.

| Key | Default | What it does |
| --- | --- | --- |
| `RecycleBinAlign` | `left` | `left`: icon first, text after it. `right`: the mirror image inside the same box. `AlignAll` in Settings overrides it. |
| `RecycleBinDetails` | `hover` | `hover`: title, size and EMPTY show on hover. `always`: they stay visible. `DetailsAll` overrides it. |
| `RecycleBinConfirm` | `1` | Windows asks to confirm when you click Empty. |
| `RecycleBinWarnGB` | `10` | The size turns orange above this many GB. Settings has a row for it (scroll the value). |

## Requirements

Rainmeter's bundled RecycleManager plugin; covers all drives.

## Known limits

-
