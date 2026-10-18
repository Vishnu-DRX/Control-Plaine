# Install

## Quick way

From the repo folder in PowerShell:

```
powershell -ExecutionPolicy Bypass -File tools\install.ps1
```

The installer (`tools\install.ps1`):

1. Links the repo into `Documents\Rainmeter\Skins\Control-Plaine` (a junction, so `git pull` updates the live skins). It stops if that folder already exists and is not a link to this repo.
2. Creates `@Resources\User.inc` and `@Resources\State.inc` (both git-ignored).
3. Installs the helpers marked `installer=1` in `@Resources\Setup\Helpers.txt` when they are missing: the IsFullScreen plugin, `MediaPlayer.dll` (into `%APPDATA%\Rainmeter\Plugins`) and the Ookla Speedtest CLI (winget). The first-run setup in Settings uses the same list.
4. Saves your current desktop as a backup layout (`Before Control-Plaine <date time>`, every run), keeps your own `Control-Plaine` layout as `Control-Plaine before update <date time>`, installs the Control-Plaine layout and loads it.
5. Opens Settings, which starts the [first-time setup](first-time-setup.md) unless this profile already had a `State.inc`.

After a plugin is installed, exit and restart Rainmeter once.

## By hand

1. Put this folder at `Documents\Rainmeter\Skins\Control-Plaine`.
2. Create empty `@Resources\User.inc` and `@Resources\State.inc`, each containing only `[Variables]`.
3. In Rainmeter: Manage > Skins, load the skins you want, or copy `tools\layout\Control-Plaine.layout` to `%APPDATA%\Rainmeter\Layouts\Control-Plaine\Rainmeter.ini` (create the folder) and load it from Manage > Layouts. It puts the skins in a column at the left of your main screen; the setup's PLACEMENT step moves them.
4. Install what each skin you use needs (see its page in this folder).

## Skin positions

The shipped layout stacks the skins in one column at the left of your main screen so they start on screen. The first-time setup's PLACEMENT step restacks them on the screen and edge you choose (see [first-time setup](first-time-setup.md)). You can also drag any skin (General has LOCK POSITIONS to stop accidental drags) or use Rainmeter's layout manager.

## Updating

`git pull` in the repo folder, then refresh Rainmeter. Your settings live in `@Resources\User.inc`, which git does not touch.
