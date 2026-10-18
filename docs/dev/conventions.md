# Conventions

> Authoritative rules live in `tools/lint.py` (enforced) and `specs/foundation-settings.md` (explained). This page is the short list. If lint and this page differ, lint wins; fix this page.

## Files

- **ASCII only** in `.ini`, `.inc` and `.lua` (lint). Rainmeter reads other encodings differently on different machines. `.gitattributes` stores `.ini`, `.inc` and `.lua` with CRLF.
- **No inline `;` comments.** Rainmeter has none; a comment goes on its own line (lint). Text values that legitimately contain `;` (`Text=`, `ToolTip`) are exempt.
- **No hardcoded user paths** such as `C:\Users\name\...` (lint). Use `%LOCALAPPDATA%`, `%ProgramFiles%`, a protocol link, or a path setting in `Defaults.inc`.
- No `#` inside stored setting values.
- Do not commit `@Resources\User.inc` or `State.inc` (git-ignored) or third-party binaries (plugins are downloaded by the installer).

## Naming

- Skin folder names: PascalCase, no spaces (`DayDate`, `WiFi`). The folder, `<Skin>.ini`, `Settings\<Skin>.ini`, `Scripts\<Skin>.lua` and the key prefix all use the same name.
- Setting keys: `<Skin>` prefix plus a descriptive name (`VolumeStep`). General settings have no prefix. Every skin has `<Skin>Tooltips`.
- Every user-facing key exists in a Defaults file (lint checks Settings pages against them).
- Runtime keys (not settings) are marked "Runtime, not settings" in the Defaults file and live in `State.inc` when persisted.

## Skin file

- Header comment: `What it shows`, `Designed for` (name the target software and version), `Adjust` (the keys a user would change). Copy the skin template in `specs/foundation-settings.md` section 2.
- `[Rainmeter]` needs `Group=ControlPlaine` and the **Control-Plaine settings** right-click entry (lint). `[Metadata]` is required.
- Use the shared styles and tokens; no hardcoded colours or font sizes. Every size is multiplied by `#Scale#` (or `#Sz#`).
- Invisible hover or click areas use `SolidColor=0,0,0,1`; alpha 0 is not hit-testable.
- Options that use a variable that can change at runtime need `DynamicVariables=1`.
- Hide with `SelfHidden` + `mVisible`, never `!Show`/`!Hide` (lint).

## Look

Design language, in short: quiet at rest, detail on hover, subtle hover, Windows accent, Segoe UI Variable, spaced capitals, no accent underlines, key information always visible and detail on hover. Full rationale in `docs/DESIGN-V1.md`.

- Rings and lines must be sharp: draw with Round caps, keep text X positions on whole pixels, and size icons so Rainmeter never resamples them.
- Icons are Lucide-based SVGs in `docs/icons/`, rendered by `tools/render-icons.js` (dev-time, needs Playwright) to PNGs in `@Resources/Icons/` at the size they are shown. The icon file must exist (lint).
- Orange (`Warn`) only for things needing attention; accent only for active state.

## Performance

- Keep `Update` as slow as the skin allows; use `UpdateDivider` on slow measures.
- Heavy work (processes, network, power) goes in a measure that runs on demand or on a long divider, not every second.
- Helper scripts must not leave processes behind when the skin closes.

## Never

- Edit another thread's owned files without going through the owner (see [CLAUDE.md](../../CLAUDE.md) and the plans owner).
- Switch branches inside the live Skins checkout (see [testing](testing.md)).
- Skip, disable or quarantine a lint rule or CI check to get green.
- Commit personal paths, e-mail addresses, machine names or tokens.
