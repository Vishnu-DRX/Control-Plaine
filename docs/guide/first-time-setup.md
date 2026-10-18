# First-time setup

The first time you open Control-Plaine settings on a profile that has not been set up, the Settings window starts a short guided setup instead of the General page. It walks you through which skins you want, what they need, and how they look. Everything is saved in `@Resources\User.inc` as you go, the same file the normal pages write.

You can leave at any time. **SKIP SETUP** changes no setting (skins already switched off in step 2 stay off) and does not ask again. **FINISH** (on the last step) records that setup is done, in `@Resources\State.inc` as `SetupDone=1`. Close the window with the X and it simply starts again the next time you open Settings.

## When it starts

- The installer (`tools\install.ps1`) opens Settings at the end, so the setup begins by itself on a new install.
- Any later right-click, **Control-Plaine settings** opens the setup only while `SetupDone` is not `1` in `State.inc`.
- If you already had a `State.inc` when you ran the installer, it marks setup done so an existing profile is not asked again.
- **General > RUN SETUP AGAIN** (at the right of the LOCK POSITIONS row) starts it whenever you want. Your current settings stay until you change them.

## The steps

The steps are listed down the left; click one to jump to it.

1. **WELCOME.** What was detected: Windows, the number and size of displays, and how many of the apps and plugins your skins use were found.
2. **SKINS.** One switch per skin, the same as General. A skin whose required app is missing starts switched off, with the reason under its name; switch it on if you want it anyway. Skins you switch off are unloaded and have no setup rows.
3. **SETUP.** For each skin you kept, what it needs: a program path, a plugin or a tool. Each row shows **FOUND** or **NOT FOUND** (checked by looking for files and registry entries only; nothing is started). Click a path to type it, the same box as on the skin's page. Click a row for details: why the skin wants it, whether it is **required** (without it the skin stops working) or **optional** (without it only one function is hidden), and what happens if you skip it.
4. **LOOK.** Size, colours (auto, light wallpaper, dark wallpaper), left or right edge for every skin, details on hover or always, tooltips, and the accent. Changes show on the real skins at once. Each skin can still differ later on its own page.
5. **DONE.** What is on, what still needs attention, and where the settings are stored.

A PLACEMENT step (choose a screen and an edge) is planned and is not shown yet.

## Install helpers

For a missing item that has a known install command, the detail shows the **exact command**, where it comes from, and three choices:

- **RUN IT FOR ME** runs that one command, once. If it needs administrator rights, Windows asks first (the UAC prompt); setup does not hide it. When it ends, the row is checked again and shows FOUND or NOT FOUND. If it failed, the last lines of its output and the command are shown so you can run it yourself. It is never retried by itself.
- **COPY COMMAND** puts the command on the clipboard and runs nothing. Run it yourself; the row updates on its own within a few seconds.
- **SKIP** leaves it. Skipping an optional item keeps the skin and leaves that function out (for example no speed test icon). Skipping a required item asks whether to turn the skin off.

The commands come from a fixed list in the repo, `@Resources\Setup\Helpers.txt` (the installer uses the same list). Setup never runs text you type or text from `User.inc`. Current entries: Speedtest CLI (winget, optional for Wi-Fi), the MediaPlayer plugin (required for Media), the IsFullScreen plugin (optional, for HIDE IN FULL SCREEN) and the Fan Control scheduled tasks (optional, needs admin). After installing a plugin, restart Rainmeter once.

## Amber marks

When a skin is loaded and something it needs is missing, an amber **!** shows in Settings:

- at the right of the skin's tab, and left of its name in the General skin list (hover for the reason);
- at the top of the skin's page as **SETUP NEEDED** (a required item is missing) or **SOME FEATURES OFF** (only optional ones), with the list;
- next to HIDE IN FULL SCREEN on General when the IsFullScreen plugin is missing.

Click a mark to open the setup for just that skin. The check repeats about once a minute, so installing the missing item clears the mark without a refresh. The skins hiding their own functions when an optional item is missing is rolled out skin by skin; until then the marks tell you what is missing.

## Troubleshooting

See [troubleshooting.md](troubleshooting.md). To start again from nothing, use **General > RUN SETUP AGAIN**, or delete the `SetupDone` line from `@Resources\State.inc`.
