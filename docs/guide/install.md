# Install

## Quick way

From the repo folder in PowerShell:

```
powershell -ExecutionPolicy Bypass -File tools\install.ps1
```

*Draft; the installer is changing (onboarding, layout move). Read `tools/install.ps1` for what it does today.* As of this draft it:

1. Links the repo into `Documents\Rainmeter\Skins\Control-Plaine` (a junction, so `git pull` updates the live skins).
2. Creates `@Resources\User.inc` and `@Resources\State.inc` (both git-ignored).
3. Installs the IsFullScreen plugin, downloads `MediaPlayer.dll` into `%APPDATA%\Rainmeter\Plugins`, and installs the Ookla Speedtest CLI with winget if it is missing.
4. Saves your current desktop as a backup layout, installs the Control-Plaine layout and loads it.

After a plugin is installed, exit and restart Rainmeter once.

## By hand

1. Put this folder at `Documents\Rainmeter\Skins\Control-Plaine`.
2. Create empty `@Resources\User.inc` and `@Resources\State.inc`, each containing only `[Variables]`.
3. In Rainmeter: Manage > Skins, load the skins you want, or copy `Layouts\Control-Plaine` into `%APPDATA%\Rainmeter\Layouts` and load it from Manage > Layouts.
4. Install what each skin you use needs (see its page in this folder).

## Skin positions

The shipped layout carries window positions from the author's screen. Drag the skins where you want them (General has a lock option to stop accidental drags) or use Rainmeter's layout manager.

## Updating

`git pull` in the repo folder, then refresh Rainmeter. Your settings live in `@Resources\User.inc`, which git does not touch.
