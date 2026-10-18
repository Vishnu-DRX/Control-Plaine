# Fix a bug

Read [README.md](README.md) first for the premise check.

## Steps

1. [ ] **Reproduce or locate it.** Get the exact symptom, the skin, the setting values and the Rainmeter log line (it names the file and line). A cloud session cannot run Rainmeter: if the symptom needs it, find the cause by reading and say what the PC must confirm.
2. [ ] **Find the cause, not the symptom.** `git log -n 10 -- <file>` and `git blame` on the lines involved; check whether a recent change introduced it. Check that the premise holds on the current `main` (it may already be fixed).
3. [ ] **Check ownership.** The bug may live in a shared file ([change-a-shared-file.md](change-a-shared-file.md)). If so, send the exact change to the owner or get a go; do not edit it concurrently.
4. [ ] **Branch from `main`, one concern per PR.** Make the smallest change that fixes the cause. No drive-by cleanups, no changed behaviour beyond the fix.
5. [ ] **Add the guard.** If the bug is mechanically checkable, add or extend a rule in `tools/lint.py` (owner permitting) or a `tools/test_*.py` that fails before the fix and passes after. If it is not checkable offline, say so in the PR.
6. [ ] **Update the docs** if what a user sees or can set changed: `docs/guide/<Skin>.md` in the same PR. If a doc or spec was wrong, fix it too.
7. [ ] **Check by command:** `python tools/lint.py` shows `0 problem(s)`; every `tools/test_*.py` passes.
8. [ ] **PR body:** Before/After, the cause in one or two sentences, what was checked, and a **Not checked here (needs the PC)** list with the steps to confirm the fix ([pc-test-protocol.md](pc-test-protocol.md)). Do not claim a visual fix you did not see.
