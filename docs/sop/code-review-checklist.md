# Code review checklist

For a reviewer who did not write the code (check with `git log` on the files). Review, test and report; do not fix in the same thread, and re-check the fix when it lands. Every finding needs a concrete input and failure, not a style opinion. Read [README.md](README.md) first for the premise check.

## Before you read

- [ ] `python tools/lint.py` and each `tools/test_*.py` on the PR branch. A red check is a finding.
- [ ] The PR touches only what it says. Shared files changed? Check ownership ([change-a-shared-file.md](change-a-shared-file.md)). Does the PR update the matching `docs/guide/` page?
- [ ] The PR body lists what was and was not checked, with a PC list.

## Safety

- [ ] **Command injection.** Setting values (paths, URLs, extra parameters, click targets) reach `RunCommand` Program/Parameter, bangs and `curl` or PowerShell arguments. For each: is it quoted, and can `"`, `]`, `;`, `&`, `%` or a space break out? Can a value be re-evaluated as a bang? (`InputDone` in `Settings.lua` strips only `#`.)
- [ ] **Elevation and tasks.** Scheduled tasks and elevated helpers run a fixed script from a location a normal user cannot write; `-ExecutionPolicy Bypass` only on files the suite owns.
- [ ] **File writes.** `User.inc` and `State.inc` writes: injected content, concurrent writers. Files in `%TEMP%` that the skin reads back: predictable names, who else can write them.
- [ ] **Secrets and network.** No tokens or URLs with credentials in config or logs; only localhost or intended endpoints, with timeouts; no TLS bypass; downloads pinned and verified.
- [ ] No personal paths, e-mail addresses, machine names or tokens in the diff.

## Efficiency

- [ ] `Update` and `UpdateDivider` per measure justified; polling that could be event-driven.
- [ ] Process spawns per tick (PowerShell is expensive): how often, cached?
- [ ] Hidden or disabled skins still working; `DynamicVariables` only where needed; Lua doing work every update.
- [ ] Numbers from the PC (CPU, process count at idle) when the change claims an improvement.

## Maintainability and conventions

- [ ] Follows [../dev/conventions.md](../dev/conventions.md): ASCII, no inline `;`, no hardcoded user paths, key prefix, defaults for every key, include order, no `!Show`/`!Hide`.
- [ ] Uses the shared helpers and styles (`Mir`, `TA`, `Lead`, `Trail`, `Ink`, `Accent`, `sReveal`...), not a private copy; no hardcoded colours or sizes.
- [ ] Layout: fixed box, whole-pixel right-anchored values, same hit area on both sides. Formulas hand-checked at several scales.
- [ ] Tooltips gated; theme colours from tokens; Lua re-reads mode-dependent values in `Update`.
- [ ] Duplicated code that belongs in a shared helper; dead code and unused keys; comments that say why; consistent error handling when an app or plugin is missing.
- [ ] A bug fixed here: is there a lint rule or test that would catch it next time? ([fix-a-bug.md](fix-a-bug.md))
- [ ] Docs agree with the code: guide defaults equal the Defaults file; no copied counts or file lists that will rot.

## Report

A table of findings (id, severity, file:line, one line), then per finding the scenario and a suggested fix, then **checked and clean** so the author sees what you looked at. Severity: critical = remote or low-privilege code execution or escalation; high = a plausible malformed setting runs unintended commands or loses data; medium = reliability or noticeable resource waste; low = maintainability. State what only the PC can verify ([pc-test-protocol.md](pc-test-protocol.md)).
