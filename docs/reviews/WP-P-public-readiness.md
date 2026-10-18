# WP-P public-readiness review

Scope: working tree of `main` @ 0f38118 plus this PR, and every revision reachable from every ref of the clone (`git rev-list --all`: 182 commits; `origin/main` alone has 90). History was scanned read-only (`git log --all -p`, `git grep`); nothing was rewritten, tagged, pushed to main or published. Checks WP-P1 to WP-P5; WP-P6 (fresh-profile install) and WP-P7 (Vishnu's go) are not done here.

Decision key: **scrub** = fixed in this PR, **keep** = intended or harmless, **needs Vishnu** = a decision only he can make.

## 1. Secrets (WP-P2)

No tokens, API keys, passwords, private keys or URLs with credentials in any revision. Patterns scanned over every added line of every commit: `ghp_`, `github_pat_`, `sk-`, `AKIA`, `xox`, `BEGIN ... PRIVATE KEY`, `api_key=`, `password=`, `token=`, `://user:pass@`. The only matches are prose in `docs/reviews/R1`/`R4` (an example attack string `1@evil.example`, the word `ghp_` in a grep description) and `id-token: write` in `pages.yml` (a permission, not a secret). Largest blob in history is 35 KB; no binary other than PNG icons was ever added; no `User.inc`, `State.inc`, `.env`, key or log file was ever added.

**needs Vishnu: history rewrite decision** (nothing secret found, so a rewrite is not required for secrets; the only reason would be the e-mail item in section 2).

## 2. Personal e-mail in commit metadata (the main finding)

`origin/main` is clean: 90 commits, author `103368757+Vishnu-DRX@users.noreply.github.com`, committer `noreply@github.com`.

But the repository holds **25 commits authored and committed under two personal Gmail addresses** (`vishnuanilp1010@gmail.com`: 10 commits, 2026-10-10 to 2026-10-14; `vishnuanilpillai@gmail.com`: 15 commits, 2026-10-11 to 2026-10-14). They are not in `origin/main`'s ancestry (squash merges), but they are on 10 other remote branches, which become public with the repo:

| Remote branch | Commits with a Gmail address |
| --- | --- |
| `fix/verification-pass` | 7 |
| `signalrgb-free-effect-brightness` | 7 |
| `sharpness-pass` | 3 |
| `claude/project-thread-mvd6o5` | 3 |
| `claude/project-thread-658ao7` | 2 |
| `claude/project-thread-2b42b3`, `-4jkidq`, `-780y66`, `-ge6jou`, `signalrgb-logo-restore` | 1 each |

Examples: `2ec8c6f` (1.0.0 rebuild), `74faebd`, `40dad3b`, `d831687`, `ca3136d`..`a2d9f5d` (gmail #1); `54a43f6`, `2d3a3c1`, `1733748`, `7ed4fb0`, `e7addf8`..`638208e` (gmail #2). GitHub keeps pull request heads (`refs/pull/N/head`) even after a branch is deleted, so deleting branches may not remove them from the fetchable ref set.

Decision: **needs Vishnu**. Options: (a) accept (the address is then public, and is already visible if he ever pushed under it); (b) delete the 10 stale branches before going public (they are merged or abandoned) and, if he wants the commits gone from GitHub, ask GitHub Support to purge cached PR refs; (c) rewrite history (destructive, would change every SHA and break PR links; not recommended while `origin/main` is clean); (d) create a fresh public repository from a squashed `main`. Either way: set the PC's `git config user.email` to the noreply address and enable "Block command line pushes that expose my email" in GitHub settings.

## 3. Findings in the working tree and history

| # | Hit (file or commit) | What | Severity | Decision |
| --- | --- | --- | --- | --- |
| 1 | `specs/*.md` (app-skins, controllers, daydate-bin-playnite, foundation-settings, power-uptime, volume-media, wifi) | "on Vishnu's PC", "Checks on Vishnu's PC", "Vishnu runs ...", "Vishnu's old skin / User.inc / pad", "his browser" and similar | low | scrub: reworded to "the test PC", "the user", "the maintainer"; rules and reasoning kept |
| 2 | `specs/controllers.md`, `specs/foundation-settings.md` | Drive paths `G:\SteamLibrary\steamapps\common\DSX`, `T:\Development Space\Control-Plaine` | medium (names a machine layout) | scrub: `<Steam library>\...`, "the repo working copy". Still in history: commit 5b4f01b (on `origin/main`) |
| 3 | `specs/daydate-bin-playnite.md` | `C:\Users\<name>\AppData\Local\Playnite\...` (profile name) | medium | already scrubbed on main (now `%LOCALAPPDATA%`); remains in history at 5b4f01b/f480ab2 (on `origin/main`). keep (history), see rewrite note |
| 4 | `specs/app-skins.md` | Hardware inventory of the test PC: motherboard fan controller, fan RPMs, DeepCool CH270 and its HID ids `VID_3633&PID_0016`, install folders, service names | low (no identifiers of a person) | keep (design history; reworded to "test PC"). Needs Vishnu only if he does not want his hardware public |
| 5 | `specs/controllers.md`, `specs/foundation-settings.md` | Probe results with dates, DSX UDP `127.0.0.1:6969`, HidHide state, plugin version list | low | keep (loopback only; no device serials, MACs or IPs) |
| 6 | `@Resources/Styles.inc`, `SignalRGB/Defaults.inc` | Comments "Vishnu wants it crisp", "Vishnu's cyan" | low | scrub |
| 7 | `docs/icons/deepcool.svg` | Comment "traced from Vishnu's image" | low | scrub |
| 8 | `docs/DESIGN-V1.md` | claude.ai artifact link to the private mockup canvas; "Vishnu's is cyan"; "Ask Vishnu which he has installed"; "signed off by Vishnu" | medium (private link, session metadata) | scrub: link and personal wording removed; a note says the canvas is not in the repo. Link remains in history at 5b4f01b |
| 9 | `specs/*.md` | Many "V1 canvas" / "canvas board X" references to that private mockup | low | keep (they now read as references to a design artifact that is not shipped); a stranger loses nothing because sizes are in the spec text |
| 10 | `docs/INDEX.md` | "Vishnu's single full pass" | low | scrub ("The maintainer's") |
| 11 | `CLAUDE.md`, `docs/dev/release.md`, `docs/dev/testing.md`, `docs/sop/*`, `docs/pc-gates.md`, `docs/pc-test-pass.md`, `site/README.md` | "wait for Vishnu's go", "Vishnu's sign-off", "(Vishnu or the coordinating session)" | low | keep: Vishnu is the named maintainer (README/`Author=` credit); these are process rules, not machine data. Needs Vishnu to confirm he is happy being named |
| 12 | 28 skin and Settings `.ini` files, `tools/templates/*` (32 lines in all, also `specs/foundation-settings.md`) | `Author=Vishnu A` | intended credit | keep; **needs Vishnu: confirm the real-name credit is wanted** (the alternative is `Vishnu-DRX`). Lint P2 allows the name only on `Author=` lines |
| 13 | `@Resources/Theme.inc`, `site/index.html`, `specs/foundation-settings.md` | `RepoURL` / GitHub links to `Vishnu-DRX/Control-Plaine` | none | keep (public handle) |
| 14 | `LICENSE` (new) | Copyright line "Vishnu A" | intended | needs Vishnu to confirm name and year |
| 15 | Defaults: `ControllersWheelApp=C:\Program Files (x86)\MOZA Pit House\bin\MOZA Pit House.exe`, `FanControlPath=C:\Program Files (x86)\FanControl\FanControl.exe`, `DeepCoolPath=C:\DeepCool\DeepCool.exe` (and `tools/fan-tasks.ps1` parameter default, `docs/guide/*.md`, `@Resources/Scripts/FanControl.lua`, `FanControlSensors.ps1`) | Absolute `C:` paths | low | keep: they are each vendor's own default install location, contain no user name or personal drive, and each has a Settings row and an onboarding check (`Needs.lua` expands `%ENV%`). Changing them to `%ProgramFiles(x86)%` would change how Rainmeter runs them and cannot be verified here ([PC]). Optional follow-up for the code owners |
| 16 | `Playnite/Defaults.inc` | `%LOCALAPPDATA%\Playnite\...` | none | keep (already portable) |
| 17 | `ControllersDualSenseApp=steam://rungameid/1812620` | Public Steam app id for DSX | none | keep |
| 18 | `FanControlNormal=userConfig.json`, `FanControlMax=Max.json` | Fan Control's own default config name and a documented profile the user creates (or `fan-tasks.ps1` creates) | none | keep |
| 19 | `SignalRGBColor=00AE57`, `SignalRGBMoveParams ... 00AE57` | A colour value, previously described as "Vishnu's cyan" (it is green; only the comment was personal) | low | comment scrubbed; value kept. Needs Vishnu: pick a neutral default (for example the accent) if wanted |
| 20 | `tools/layout/Control-Plaine.layout` | Now neutral (x=24, primary screen). The 1.0.0 history (2ec8c6f, 54a43f6, 2d3a3c1) holds negative `WindowX` values for a portrait second monitor | low | keep (history only) |
| 21 | Drive letters `D:`..`E:` in `tools/test_*.py`, `docs/reviews/R1..R5` | Synthetic examples (`D:\Games [x64]`, `E:\st\speedtest.exe`) | none | keep; allow-listed in lint P2 |
| 22 | IP addresses | Only `127.0.0.1` (DSX UDP 6969, `localhost` SignalRGB API port 16038) and version strings (`3.0.0.0` plugin versions, a number triplet inside an SVG path). No LAN or public IP in any revision | none | keep |
| 23 | Machine, host and device names | No `DESKTOP-`/`LAPTOP-` names, UNC share names, computer names, serial numbers or MACs in any revision. Device names appear only as product names (DualSense, Moza, CH270) | none | keep |
| 24 | claude.ai links in commits | Every commit message from the AI sessions ends with `Claude-Session: https://claude.ai/code/session_...`: 159 trailer lines, 15 distinct session ids (e.g. `session_01Ttxofb9jpyQGH5Sp1emWJU`, 77 commits) plus `Co-Authored-By` lines | low (session metadata, not credentials; the page needs the owner's login) | keep: trailers are by design. No project, thread (`cmsg_`), channel (`chan_`) or environment (`env_`) id in any file or commit message. The private mockup link in item 8 is the only claude.ai link ever committed to a file |
| 25 | Third-party binaries | No `.dll`, `.exe`, `.zip`, `.msi`, `.rmskin` in the tree or in any revision. 41 PNG icons and 2 PNG sources only. Plugins are downloaded by `tools/install.ps1` / the setup window from the pinned list in `@Resources/Setup/Helpers.txt` | none | keep; lint P2 now fails on such a file |
| 26 | C2PA Content Credentials block inside 19 `docs/icons/*.svg` and 7 PNGs in `@Resources/Icons` (bin-empty, bin-full, gamepad, lock, power, restart, sleep) | Embedded provenance manifest saying an AI tool created or modified the file, with a signing certificate chain; no personal data | low | keep (harmless); optional: strip before publishing. Files are listed by `git grep -l c2pa` |
| 27 | `.gitignore` | `User.inc`, `State.inc` ignored; none ever committed | none | keep |
| 28 | `.git/config` and reflog of the cloud clone | Not part of the repo. The PC's local git config/reflog (personal Gmail) is outside what this review can see | n/a | needs Vishnu: set `user.email` to the noreply address on the PC |
| 29 | `docs/reviews/R1..R5`, `docs/pc-gates.md` | Describe attack inputs with fake paths and names (`C:\Users\me\x.txt`, `evil.example`); they are code-review findings | none | keep; they read as ordinary review notes |

## 4. Third-party assets and licences (WP-P5)

Written up in `THIRD-PARTY-NOTICES.md` (new). Summary:

- **Skins and project docs: CC BY-NC-SA 4.0**, consistent across the 32 `License=` metadata lines, `README.md` and the site footer. A `LICENSE` file did not exist; it is added as a **draft**: it states the licence and scope but carries a placeholder instead of the verbatim legal code (the cloud session cannot download it; the 4.0 legal code must be pasted in before going public). The licence choice is Vishnu's to confirm. Note CC licences are not designed for software: the Lua/PowerShell/Python in the repo are covered by the same choice unless he decides otherwise.
- **Icons**: README and the site say "Lucide (ISC)". In fact the 30 SVGs are a mix: some are Lucide-shaped, many have non-Lucide stroke widths (1.4, 1.5, 2.2) and shapes (wheel, DualSense, case screen), `controller-xbox.svg` is a filled glyph that `docs/DESIGN-V1.md` calls "Fluent, MIT", `deepcool.svg` is a traced logo. Wording changed to "based on Lucide"; ISC text is included; the Fluent/MIT notice is listed as pending. **Needs Vishnu / the icon author: confirm the source of each icon.**
- **Logos and app artwork** (SignalRGB app icon `signalrgb-src.png`, DeepCool logo, Playnite controller art): owned by their projects, not open licensed. **Needs Vishnu: accept nominative use for the buttons that launch those programs, or replace with generic icons.**
- **Downloaded, never committed**: MediaPlayer plugin (GPL-3.0, pinned v1.4), IsFullScreen (copied from the user's Vault), Ookla Speedtest CLI (winget, proprietary), Fan Control, HWiNFO, SignalRGB, DeepCool, Playnite, DSX, Moza Pit House (user-installed). Segoe UI Variable ships with Windows.

## 5. Changes made in this PR

- Scrubbed specs, `docs/DESIGN-V1.md`, `docs/INDEX.md`, two comments and one SVG comment (items 1, 2, 6 to 8, 10).
- `tools/lint.py`: new rule **P2** (drive letters other than C:, "<Name>'s PC/cyan/..." text, personal full name outside `Author=`, e-mail addresses other than noreply/example, claude.ai artifact/project/chat/code links, committed `.dll/.exe/.zip/.msi/.rmskin/.bin`) over all tracked text files, with an allow-list (`P2_ALLOW`: `tools/lint.py`, `tools/test_*`, `docs/reviews/`). Verified by planting each violation. The existing P1 rule (profile paths) is unchanged. Documented in `docs/dev/conventions.md`.
- `LICENSE` (draft), `THIRD-PARTY-NOTICES.md`; README and site footer wording.
- Defaults left as they are (item 15): no behaviour change was made.

`python tools/lint.py` = 0 problems; all 15 `tools/test_*.py` pass (lupa installed).

## 6. Decisions Vishnu must make before the repo goes public

1. **Personal Gmail addresses on 10 non-main branches (25 commits).** Accept, delete the branches (and ask GitHub to purge PR refs), start a fresh repo from main, or rewrite history. Also set the PC `user.email` to the noreply address and turn on "Block command line pushes that expose my email".
2. **Licence.** Confirm CC BY-NC-SA 4.0 for skins; decide the licence for the scripts/tools (CC is not meant for code); paste the verbatim legal code into `LICENSE`; confirm the copyright holder line and year.
3. **Credit name.** `Author=Vishnu A` (real name) in 32 lines and in `LICENSE`, or use the GitHub handle.
4. **Icons and logos.** Confirm icon sources (Lucide, Fluent, original), and accept or replace the SignalRGB, DeepCool and Playnite artwork.
5. **Old history that stays on `origin/main`.** The profile folder name (`C:\Users\<name>`), `G:`/`T:` paths and the private mockup link are still in commits 375d640..5b4f01b. Accept, or include in a rewrite if option 1 chooses one.
6. **Hardware inventory in specs/app-skins.md** (board, fan RPMs, case model, HID ids): keep or trim.
7. **Maintainer name in process docs** (CLAUDE.md, SOPs): keep or switch to "the maintainer".
8. **SignalRGB default colour `00AE57`**: keep or switch to a neutral default.
9. **C2PA metadata in 26 icon files**: keep or strip.
10. **Defaults with `C:\Program Files (x86)` paths** (Fan Control, Moza) and `C:\DeepCool`: keep as vendor defaults (recommended) or make them `%ProgramFiles(x86)%` after a PC check.
11. Not done here: **WP-P6** fresh-profile install on a clean Windows profile [PC], and the final go (**WP-P7**). Repo visibility, Pages and any tag stay untouched.
