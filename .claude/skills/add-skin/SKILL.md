---
name: add-skin
description: Add a new skin to the Control-Plaine Rainmeter suite. Use when asked to create, scaffold or add a skin. Wraps docs/sop/add-a-skin.md and checks the repo before acting.
---

# Add a skin

This skill is a thin wrapper. The procedure lives in `docs/sop/add-a-skin.md`; the rules live in `docs/dev/conventions.md` and are enforced by `tools/lint.py`. This file holds no file lists, key names or counts, because the repo changes faster than a skill does.

## 1. Discover and verify before acting

1. Read `CLAUDE.md` and `docs/INDEX.md`.
2. Run `git log --oneline -n 10`, `git status` and `python tools/lint.py`. Lint must be clean before you start. If it is not, stop and report.
3. List the real skin folders (`ls`) and open one small existing skin and its Settings page as the reference. Compare what you see with what `docs/sop/add-a-skin.md` assumes. If they differ, trust the repo, and fix the SOP in your PR.
4. If a file the SOP names no longer exists, or a lint rule it names has moved, stop and report instead of improvising.
5. A new look needs sign-off first: mock it up and ask before building (see CLAUDE.md, Design).

## 2. Do

Follow `docs/sop/add-a-skin.md` step by step, starting with `python tools/new-skin.py --help` and then the scaffold. Shared files have one owner at a time: if another PR changes one, send the exact change to its owner instead of editing it (`docs/sop/change-a-shared-file.md`). Update the skin's guide page in `docs/guide/` in the same PR.

## 3. Verify

- `python tools/lint.py` prints `0 problem(s)`.
- Every offline test passes (`for t in tools/test_*.py; do python "$t" || break; done`, needs `pip install lupa`).
- `git status` shows no `User.inc` or `State.inc`.

State plainly what only the PC can check (Rainmeter cannot run in the cloud) in the PR body, as the SOP describes.
