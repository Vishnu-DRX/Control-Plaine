# Testing

## What lint checks

`python tools/lint.py` (also run by CI on every push and pull request) checks, over every `.ini`, `.inc` and `.lua`: ASCII only, no hardcoded user paths, no inline `;` comments, icons exist, `[Metadata]` present, include order, `Group=ControlPlaine`, the settings right-click entry, no `!Show`/`!Hide`, Settings pages include the shared files and only use keys that have a default, and every skin folder has a `Defaults.inc` and a Settings page. Read the file for the current list; it is short.

Run it before every commit. A green lint is necessary, not sufficient.

## What only a PC can check

Anything that depends on Rainmeter or Windows actually running: layout and sharpness, hover behaviour, fades, plugins loading, tooltips, light/dark, helper scripts, scheduled tasks, app integrations. Cloud sessions cannot verify these; say so in the PR and list what needs a PC check.

## PC test rules (when a PC session or Vishnu is testing)

- Verify, do not assume: test on the real PC rather than guessing. Probing is welcome, but one thing at a time.
- **Never switch branches in the live folder.** The live Skins folder is a junction to the working copy. Test a change by merging the PR and then `git pull --ff-only`, then refresh the skin.
- Rainmeter can be driven through its command-line bangs and URIs; test one command at a time and read the result before the next.
- No mouse or click automation unless Vishnu has approved it for that session (he uses the PC while sessions run).
- Leave working integrations alone (DeepCool is verified working).
- Read the Rainmeter log after a refresh; an error names the file and line.
- Do not edit `Rainmeter.ini` in `%APPDATA%\Rainmeter` while Rainmeter runs; it rewrites the file on exit.

## Reporting

In the PR: what lint says, what was checked live (with how), and what was not checked. Do not claim a visual result you did not see.
