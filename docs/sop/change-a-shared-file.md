# Change a shared file

Shared files affect every skin, so each has one owner at a time. This is the rule from [../../CLAUDE.md](../../CLAUDE.md), made into steps. Read [README.md](README.md) first for the premise check.

## Which files are shared

Start from the list in CLAUDE.md (Hard rules, Ownership) and the ownership table in `specs/foundation-settings.md` section 1, then verify against the repo: a file that every skin includes or that the checks read is shared, whatever the list says. As of writing the list covers the core includes (`Core.inc`, `Theme.inc`, `Styles.inc`, root `Defaults.inc`), `Settings.lua`, `General.ini`, `Chrome.inc` and `tools/lint.py`. Each skin's own folder, Settings page and script belong to that skin's owner.

## Steps

1. [ ] **Find who owns it now.** Ask the project owner (Vishnu or the coordinating session) and check open PRs: `gh pr list` or the GitHub tools, and `git log --oneline -n 20 -- <file>` for recent activity. Programme plans are not in git: ask for the current plan if it matters.
2. [ ] **If another PR or thread is changing the file, do not edit it.** Write the exact change (file, the lines before and after, the reason, which lint rule or test covers it) and send it to the owner. Say in your PR that it depends on that change and whether your PR works without it.
3. [ ] **If you are the owner, or the owner said go:** make the smallest change that does the job. Append rather than reorder; do not reformat. One concern per PR; do not widen it.
4. [ ] **Think about every skin.** `grep -rn "<token or variable>" --include=*.ini --include=*.inc --include=*.lua .` to find users of anything you rename or remove. A change to a token, style or helper is a change to every skin's look: list the skins you checked and the ones that need a PC look.
5. [ ] **Keep defaults safe.** A new shared option must default to today's behaviour. A fresh `User.inc` must still work.
6. [ ] **Update the rules that guard it.** If the change adds a convention, add or extend a rule in `tools/lint.py` (owner permitting) or a `tools/test_*.py`, and update `docs/dev/` or the matching spec in the same PR. Never skip, disable or quarantine a rule to get green.
7. [ ] **Check by command:** `python tools/lint.py` and every `tools/test_*.py` pass.
8. [ ] **PR body** names the shared files touched, who owns them, and what needs a PC (shared looks always do).
