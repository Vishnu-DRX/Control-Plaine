# Add an icon

Icons are Lucide-based SVGs rendered to PNGs. Rainmeter tints the white PNG, so one set serves dark and light. Read [README.md](README.md) first for the premise check.

## Steps

1. [ ] **Check the existing set** (`ls docs/icons @Resources/Icons`). Reuse an icon if one fits.
2. [ ] **Add the SVG** as `docs/icons/<name>.svg`, 24 unit viewBox, same stroke style as its neighbours (Lucide, ISC licence; keep attribution as the neighbours do). Lowercase, hyphenated name.
3. [ ] **Choose the box size.** Most icons are drawn in the standard icon box. An icon shown at another size, or in a skin that uses `SizeBoost`, needs an entry in the size tables at the top of `tools/render-icons.js` (read its header comment: the PNG is rendered at the exact pixel size the skin shows it, so Rainmeter never resamples it). Keep the boost constant there in step with `SizeBoost` in `@Resources/Defaults.inc`.
4. [ ] **Render it:** `node tools/render-icons.js` (dev-time; needs Playwright and Chromium, `npm install playwright` if missing). Check that only your icon's PNG changed in `@Resources/Icons/` (`git status`); a wholesale change means the renderer settings differ.
5. [ ] **Use it** in the skin: `ImageName=#@#Icons\<name>.png` with `ImageTint=#Ink#` (or the `sIcon` styles in `Styles.inc`, which tint). Never a hardcoded white. Lint: the icon file must exist.
6. [ ] **White only.** Lint rule L7 (backed by `python tools/check_icons.py`) requires every PNG to be white with alpha so the tint follows light mode. An icon with a coloured badge is the exception: it needs an entry with a reason in `COLOURED` in `tools/check_icons.py` and a `-light` twin from the renderer; the skin picks the file by `#Mode#`. Ask before adding one ([../dev/conventions.md](../dev/conventions.md), Look).
7. [ ] **Check by command:** `python tools/check_icons.py` lists your icon as tintable; `python tools/lint.py` shows `0 problem(s)`.
8. [ ] **PC checks to list in the PR:** the icon is sharp (no soft edges) at Scale 1.0 and 1.25, and black in light mode. The cloud cannot see Rainmeter; say so.

## Do not

- Commit a PNG that was not produced by the renderer from its SVG.
- Resize a PNG in the skin to fit; fix the size in the renderer table instead.
