# Standard procedures

Short, numbered procedures for the jobs that repeat. They are generic on purpose: they name the file to open and the lint rule to read, never a count, a line number or a copied file list, because the repo changes faster than these pages.

**Before any procedure** (from [CLAUDE.md](../../CLAUDE.md)): run `git log --oneline -n 10`, `git status`, `python tools/lint.py` and `ls`, then compare what you see with what the procedure assumes. If the repo and a procedure disagree, trust the repo, say so in the PR and fix the procedure in the same PR. If a premise is wrong (a file named here no longer exists, a lint rule moved), stop and report instead of improvising.

| Procedure | Use it when |
| --- | --- |
| [add-a-skin.md](add-a-skin.md) | Adding a new skin. Start with `python tools/new-skin.py <Name>`. |
| [add-a-setting.md](add-a-setting.md) | Adding or changing a user-facing option. |
| [add-an-icon.md](add-an-icon.md) | Adding or changing an icon. |
| [change-a-shared-file.md](change-a-shared-file.md) | The change touches a file with one owner (`Core.inc`, `Styles.inc`, `lint.py`...). |
| [fix-a-bug.md](fix-a-bug.md) | Fixing something that is broken. |
| [code-review-checklist.md](code-review-checklist.md) | Reviewing a PR or a script. |
| [pc-test-protocol.md](pc-test-protocol.md) | Anything that runs on the live Rainmeter PC. |

Every procedure ends with a check a command can confirm. A PR that changes what a user sees or can set updates the matching page in `docs/guide/` in the same PR.
