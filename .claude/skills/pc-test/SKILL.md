---
name: pc-test
description: Test a Control-Plaine change on the real Rainmeter PC, or prepare the PC test list. Use when a change needs live verification or when asked to run the PC pass. Wraps docs/sop/pc-test-protocol.md.
---

# PC test

This skill wraps `docs/sop/pc-test-protocol.md`. The rules are in `CLAUDE.md` and `docs/dev/testing.md`; this file does not copy them, so it cannot go stale.

## 1. Discover and verify before acting

1. Read `CLAUDE.md`, `docs/dev/testing.md` and `docs/sop/pc-test-protocol.md`.
2. Find out where you are: a cloud session cannot run Rainmeter. If you cannot reach the PC, do not guess. Prepare the list of checks from the PR's "needs the PC" section and `docs/pc-gates.md`, hand it over, and say nothing was verified live.
3. On the PC, run `git status` and `git log --oneline -n 5` in the live checkout and `python tools/lint.py`. The live checkout must be on `main` and clean. If it is not, stop and report; never switch branches there.
4. If the protocol names a file, setting or command that no longer exists, trust the repo, say so, and fix the protocol in the same PR.

## 2. Do

Follow the steps in `docs/sop/pc-test-protocol.md`: one command or URI at a time, read the result before the next, no mouse or click automation without the owner's go-ahead in that session, leave working integrations alone, restore any setting you changed.

## 3. Verify and report

Record, per item, pass, fail or not tested, and how it was checked. Never claim a visual result you did not see. Report in the PR thread. A fix goes in a new branch and PR, not as an edit in the live folder.
