# Changelog

## Unreleased

- Security: the Fan Control sensor reader now runs from `%ProgramData%\ControlPlaine\FanControl`, an admin-only folder. **Run `tools\fan-tasks.ps1` as admin once after updating** (it also needs PowerShell 7 from Program Files). Until you do, fan speeds may be empty.
- Settings text boxes refuse quotes and line breaks, ports must be numbers, and Reset and CLEAN keep `User.inc.bak`.

## 1.0.0

- First release: Day-Date, Power, Recycle Bin, Volume and Playnite rebuilt on one shared theme, style and hover fade.
