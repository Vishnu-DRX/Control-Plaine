# CLAUDE.md

Control-Plaine is a suite of Rainmeter skins for Windows (Day-Date, Power, Uptime, Volume, Media, Recycle Bin, Playnite, Wi-Fi, Fan Control, SignalRGB, DeepCool, Controllers) plus a Settings window, sharing one design system. The repo changes fast: **verify before you act and trust the repo over any doc, including this one.**

## Before you start

1. `git log --oneline -n 10` and `git status`: see what just changed and whether you are on a fresh branch from `main`.
2. `python tools/lint.py`: it must be clean before and after your change.
3. `ls`: list the actual skin folders. Read `docs/INDEX.md` for the doc map, then only the docs your task needs.
4. If something here or in `docs/` does not match what you see, say so, follow the repo, and fix the doc in your PR.

## Commands that matter

| Task | Command |
| --- | --- |
| Check the suite's rules (and the docs: links, skin lists, guide coverage) | `python tools/lint.py` (CI runs it on every push and PR) |
| Offline tests (formulas, Lua scripts, Settings engine, scaffold) | `pip install lupa`, then `for t in tools/test_*.py; do python "$t" || break; done` (CI runs them too) |
| Scaffold a new skin | `python tools/new-skin.py <Name>`, then follow `docs/sop/add-a-skin.md` |
| Install on a PC | `powershell -ExecutionPolicy Bypass -File tools\install.ps1` |
| Render icons from `docs/icons/*.svg` | `node tools/render-icons.js` (dev-time, needs Playwright + Chromium) |
| Fan Control tasks (admin, once) | `powershell -ExecutionPolicy Bypass -File tools\fan-tasks.ps1` |

Rainmeter itself cannot run in the cloud. A cloud session cannot verify how a skin looks or behaves: say what you could not check.

## Hard rules

- Files are **ASCII**. No inline `;` comments (a comment is its own line). No hardcoded user paths. No `!Show`/`!Hide` in skins (use `SelfHidden` + `mVisible`). Lint enforces these.
- A v2 skin includes, in order: Theme, Defaults, `<Skin>\Defaults.inc`, User, State, (skin-local), Core, Styles. See `docs/dev/architecture.md`.
- Every user-facing setting has a default in a Defaults file and a prefix with the skin name. Do not commit `@Resources\User.inc` or `State.inc`.
- **Ownership.** Shared files (`Core.inc`, `Theme.inc`, `Styles.inc`, root `Defaults.inc`, `Scripts/Core.lua`, `Scripts/Settings.lua`, `Settings/General.ini`, `Settings/Chrome.inc`, `Setup/NeedsList.lua`, `tools/lint.py`, `tools/test_core.py`; the layout and `CHANGELOG.md` belong to integration) and each skin's files have one owner at a time. If another PR or thread is changing a file, do not edit it: send the exact change to the owner. Ask when unsure who owns something.
- Keep a change minimal and in scope. Do not widen a PR.
- A PR that changes what a user sees or can set updates the matching page in `docs/guide/` in the same PR.
- **Never switch branches in the live Skins folder** on the PC. Merge, then `git pull --ff-only` and refresh.
- No mouse or click automation on the PC without the owner's go-ahead. Do not touch working integrations (DeepCool) beyond what the task needs.
- Publishing the site, tagging a release, changing repo visibility or rewriting history wait for an explicit go from Vishnu.

## Commits and PRs

- Commits are authored under Vishnu's GitHub account (do not change the git identity) and end with a `Co-Authored-By: Claude` trailer.
- Follow the PR attribution block the project gives you. Use the repo's PR template if one exists.
- Branch from `main`, one concern per PR, lint clean, say what was and was not checked.

## Design in one paragraph

Quiet at rest, detail on hover, subtle hover, Windows accent (cyan), Segoe UI Variable with spaced capitals, no accent underlines, key information always visible. Skins share a design language, not a layout. Rings and lines must be sharp. Mock up and get sign-off before building something new visually.

## Where things are

- Docs map: `docs/INDEX.md`. Users: `docs/guide/`. Developers: `docs/dev/` (architecture, conventions, testing, release). Every skin appears in `docs/skins.json`, the README table, its guide page and the site; lint checks they agree.
- Rules and reasoning for the foundation and each skin: `specs/`. Original design: `docs/DESIGN-V1.md`.
- Shared look: `@Resources/Theme.inc`, `Core.inc`, `Styles.inc`, `Scripts/Core.lua` (alignment, theme). Settings window: `Settings/` and `@Resources/Scripts/Settings.lua`.
- First run and missing apps: `@Resources/Setup/NeedsList.lua` (what each skin needs), `Helpers.txt` (install allow-list), `Scripts/Needs.lua`, `Scripts/Onboarding.lua`. Shipped layout: `tools/layout/Control-Plaine.layout`.
- Procedures: `docs/sop/` (add a skin or setting or icon, change a shared file, fix a bug, review, PC test). Repo skills in `.claude/skills/` wrap them. What still needs the PC: `docs/pc-gates.md`.
- The site is `site/`; it is not published, and publishing waits for Vishnu's go.
- Skin list as data: `docs/skins.json`.
- Programme plans are not in git; ask for the current plan if your task depends on one.
