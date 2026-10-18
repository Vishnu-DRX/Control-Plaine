---
name: review
description: Review a Control-Plaine pull request or script for safety, efficiency and maintainability. Use when asked to review, audit or check a PR. Wraps docs/sop/code-review-checklist.md.
---

# Review

This skill wraps `docs/sop/code-review-checklist.md`. The conventions live in `docs/dev/conventions.md` and are enforced by `tools/lint.py`. This file holds no rule list of its own.

## 1. Discover and verify before acting

1. Read `CLAUDE.md` and `docs/INDEX.md`.
2. Check you did not write the code (`git log` on the files). A reviewer reviews, tests and reports; the fix is a separate change.
3. Check out the PR branch, then run `python tools/lint.py` and every offline test (`for t in tools/test_*.py; do python "$t" || break; done`, needs `pip install lupa`). A red check is a finding.
4. Read the PR's diff against the shared-file ownership rule in `CLAUDE.md` and `docs/sop/change-a-shared-file.md`.
5. If the checklist names a file, rule or helper that no longer exists, trust the repo and note the stale line; do not invent a rule.

## 2. Do

Walk `docs/sop/code-review-checklist.md`. Every finding needs a concrete input and failure, not a style opinion. Check that the matching `docs/guide/` page was updated when the PR changes what a user sees or can set.

## 3. Report

A table of findings (id, severity, file and line, one line), then the scenario and a suggested fix for each, then what you checked and found clean, then what only the PC can verify. Re-check the fix when it lands.
