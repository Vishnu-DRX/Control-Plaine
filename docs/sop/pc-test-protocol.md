# PC test protocol

For a session or person testing on the real Rainmeter PC. The rules are those in [../../CLAUDE.md](../../CLAUDE.md) and [../dev/testing.md](../dev/testing.md); if they disagree with this page, those win.

## Rules

1. **Never switch branches in the live Skins folder.** The live folder is a junction to the working copy. Test a change by merging the PR, then `git pull --ff-only` in the live checkout, then refresh the skin or run `!RefreshApp`.
2. **No mouse or click automation** unless the owner (Vishnu) said go ahead in that session. He uses the PC while sessions run.
3. **One thing at a time.** Run one command or URI, read the result, then the next.
4. **Leave working integrations alone** (DeepCool is verified working) beyond what the task needs.
5. **Do not edit `Rainmeter.ini`** in `%APPDATA%\Rainmeter` while Rainmeter runs; it rewrites the file on exit.
6. **Anything that starts apps, creates scheduled tasks or runs elevated** (Fan Control tasks, helpers under `@Resources\Scripts`) waits for an explicit go; elevated checks are read-only unless he agrees.
7. **Verify, do not assume.** Do not claim a visual result you did not see.

## Steps

1. [ ] `git status` and `git log --oneline -n 5` in the live checkout: it is on `main`, clean, and has the merged change (`git pull --ff-only` if not).
2. [ ] `python tools/lint.py` is clean on that checkout.
3. [ ] Refresh the skin (`!Refresh` on the skin, or `!RefreshGroup ControlPlaine`). Read the Rainmeter log: an error names the file and line. Fix errors before judging looks.
4. [ ] Walk the PR's **Not checked here (needs the PC)** list item by item. For a skin: left and right (`<Skin>Align`), hover and always (`<Skin>Details`), light and dark, Scale 1.0 and 1.25, sharpness of text, rings and icons, hit area unchanged on a flip, tooltips on and off.
5. [ ] For a global option (`AlignAll`, `DetailsAll`, `Theme`, `TooltipsAll`), test the override and that a per-skin change still works afterwards.
6. [ ] Record per item: pass, fail, or not tested, with how it was checked. Restore any setting you changed in `User.inc`.
7. [ ] Report back in the PR thread: what was checked live, what was not. A fix goes in a new branch and PR from the cloud or a working copy, not an edit in the live folder.
