# Release

> Release steps are owned by the integration package of the plan; nothing here is done by a feature PR. Do not tag, bump versions, or edit `CHANGELOG.md` in a feature PR unless asked.

## Version

The suite version is `Version=` in `@Resources/Theme.inc`; each skin's `[Metadata]` carries its own `Version=`. One version covers the suite: `Theme.inc`, every skin and Settings `[Metadata]`, the templates in `tools/templates` and the newest numbered section of `CHANGELOG.md` must all show it. Lint rule I3 checks this.

## Steps (integration only)

1. `python tools/lint.py` is clean on the release commit and CI is green.
2. User guides, README and the site agree with the merged behaviour (`docs/skins.json` is the shared skin list).
3. Update `CHANGELOG.md`: one section per version, user-visible changes only.
4. Bump the version in `Theme.inc`, every `[Metadata]` block and the templates, and add the `CHANGELOG.md` section (lint I3 fails if one is missed).
5. Merge, then tag. Tagging, publishing the site and changing repo visibility wait for Vishnu's explicit go.
