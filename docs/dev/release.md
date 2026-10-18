# Release

> Release steps are owned by the integration package of the plan; nothing here is done by a feature PR. Do not tag, bump versions, or edit `CHANGELOG.md` in a feature PR unless asked.

## Version

The suite version is `Version=` in `@Resources/Theme.inc`; each skin's `[Metadata]` carries its own `Version=`. At the time of writing these and `CHANGELOG.md` are not in step (check with `grep -rn "Version=" --include=*.inc --include=*.ini .` and read the changelog). The integration step makes them agree.

## Steps (integration only)

1. `python tools/lint.py` is clean on the release commit and CI is green.
2. User guides, README and the site agree with the merged behaviour (`docs/skins.json` is the shared skin list).
3. Update `CHANGELOG.md`: one section per version, user-visible changes only.
4. Bump the version in `Theme.inc` and the skin `[Metadata]` blocks.
5. Merge, then tag. Tagging, publishing the site and changing repo visibility wait for Vishnu's explicit go.
