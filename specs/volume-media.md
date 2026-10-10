# Spec: Volume and Media skins

Investigation output for the V1 build. Look and behaviour come from `docs/DESIGN-V1.md` and the V1 canvas. This file says **how** to build both skins in Rainmeter, which plugin Media uses, and what must be checked on Vishnu's PC.

Shared conventions (User.inc keys, accent colour, Scale, Settings refresh, full-screen hide) belong to `specs/foundation-settings.md`. It did not exist when this was written; where it defines a key or file differently, the foundation spec wins.

## Verdict

Every feature in the design can be done with Rainmeter driving it. Nothing needs a PowerShell helper.

- **Volume**: stock `Win7AudioPlugin` plus one Lua script (ring click angle and ring drawing). All features confirmed against Rainmeter's source.
- **Media**: third-party plugin **MediaPlayer.dll** (i2002/RainmeterMediaPlayer, GPL-3.0), which reads the Windows media session (GSMTC). That covers Spotify, browsers and any app that shows in the Windows media flyout, with no browser extension. **WebNowPlaying Redux** is the fallback, and the skin is written so either one is a one-line swap.
- Two shared pieces: `@Resources/Scripts/Ring.lua` (ring arc path, used by both skins and later by SignalRGB) and Shape-drawn media glyphs (no play/pause/chevron icons exist in `docs/icons/`).

Limits (not blockers): Windows picks which media session is "current" (no in-skin source picker); some sources give no position, so the progress ring stays empty for them; the device name shown is the name in Windows Sound settings, so `SOUND BAR - LG` means renaming the device there (or a `Substitute` in User.inc).

## Shared: the ring

Design: radius 22, stroke 5, round caps, track `Ink` at 18%, fill accent, starts at 12 o'clock, clockwise.

Rainmeter's `Roundline` (used today) cannot do round caps. Use a `Shape` meter with an arc:

```
[Ring]
Meter=Shape
; track
Shape=Ellipse #Cx#,#Cy#,#Rs#,#Rs# | Fill Color 0,0,0,1 | StrokeWidth #Ws# | Stroke Color #Ink#,#AlphaTrack#
; level / progress, path built by Ring.lua
Shape2=Path Arc | StrokeWidth #Ws# | Stroke Color [#RingColor] | StrokeStartCap Round | StrokeEndCap Round | Fill Color 0,0,0,0
Arc=#Cx#,(#Cy#-#Rs#) | ArcTo [&mRing:EndX()],[&mRing:EndY()],#Rs#,#Rs#,0,0,[&mRing:Large()]
DynamicVariables=1
```

where `Rs = 22*Scale`, `Ws = 5*Scale`, centre `(Cx,Cy) = ((22+2.5)*Scale)` so the stroke is not clipped. (Path syntax: `ArcTo EndX, EndY, RadiusX, RadiusY, RotationAngle, SweepDirection(0=clockwise), ArcSize(1=large)`.)

`Ring.lua` (measure `mRing`, `Measure=Script`) exposes inline functions for a percent `p` it reads from a named measure (`RingSource` option):

- `θ = 2π·p/100`, `EndX = Cx + Rs·sin θ`, `EndY = Cy − Rs·cos θ`, `Large = θ > π and 1 or 0`.
- `p <= 0`: hide Shape2 (`!SetOption Ring Shape2 ""` or zero stroke) so round caps don't draw a dot.
- `p >= 99.5`: draw a full `Ellipse` instead of the path (an arc whose start equals its end draws nothing).

Use inline Lua section variables (`[&mRing:EndX()]`), which need Rainmeter 4.1+, or have the script `!SetOption Ring Arc ...` on each update; the second avoids per-redraw Lua calls and is the recommended route.

## Volume skin

### Files
- `Volume/Volume.ini` (rewrite: thicker Shape ring on the right, % and device text on the left, speaker icon inside the ring).
- `@Resources/Scripts/Volume.lua` (ring click, mute state, scroll rules) and the shared `Ring.lua`.
- Icons: render `docs/icons/speaker.svg` and `speaker-muted.svg` to white PNG (same pipeline as the other icons), tinted with `ImageTint`.

### Data
```
[mAudio]
Measure=Plugin
Plugin=Win7AudioPlugin
```
Confirmed in Rainmeter's source (`MeasureAudio.cpp`, the code behind this plugin):
- Number = volume 0 to 100, **-1 when muted** (so the current skin's `mAudio < 0` mute test is right).
- String = `PKEY_Device_DeviceDesc` of the default render device, i.e. the device's name as shown (and renameable) in Windows Sound settings, not the long "Speakers (Realtek...)" form.
- Bangs: `ToggleNext`, `TogglePrevious`, `SetOutputIndex n`, `ToggleMute`, `Mute`, `Unmute`, `SetVolume n`, `ChangeVolume ±n`. `Mute`/`Unmute` are undocumented but present. **`SetVolume` and `ChangeVolume` always unmute.**
- `ToggleNext` cycles active render devices only (disabled/unplugged ones are skipped) and wraps.

Note: Rainmeter's development branch also has a built-in `Measure=Audio` with the same bangs and values. Keep `Plugin=Win7AudioPlugin` (works on every released version); switching later is a one-line change.

### Layout and states
```
 43%            (  ring  )
 ───────────    ( speaker)
 SOUND BAR - LG
```
- `[Pct]` Value style, `StringCase=Upper`, text `43%`, or `MUTED` when muted.
- Hairline: `Meter=Shape` rectangle 1px high at `AlphaTrack`.
- `[Device]` Detail style, `StringCase=Upper`, `ClipString=1` with a fixed `W` (ellipsis).
- Ring on the right, speaker icon centred inside it.
- Muted: text `MUTED`, ring fill grey (`Ink` at track alpha + a bit, or just hide Shape2), icon swaps to `speaker-muted`.
- Rest/hover brightness via the shared fade (`Fade.inc`, `#Reveal#`): values 80% → 100%, details/icon 60% → 100%. Device underline (1px accent Shape under `[Device]`) only on hover.

### Interactions

| Gesture | Where | Bang |
|---|---|---|
| Scroll up/down | anywhere (`[Rainmeter]` section) | `!CommandMeasure mVolume "Scroll(1)"` / `"Scroll(-1)"` |
| Click | ring | `!CommandMeasure mVolume "RingClick($MouseX$,$MouseY$)"` |
| Click | % text | `!CommandMeasure mAudio "ToggleMute"` |
| Click | speaker icon | `["ms-settings:apps-volume"]` (setting `VolumeMixer`, fallback `sndvol.exe`) |
| Click | device name | `!CommandMeasure mAudio "ToggleNext"` |

Every action ends with `[!UpdateMeasure mAudio][!UpdateMeasure mVolume][!UpdateMeterGroup Volume][!Redraw]` so the change shows at once, not on the next 500 ms tick.

**Ring click** (`Volume.lua`):
- `$MouseX$`/`$MouseY$` are relative to the meter that has the action, so put `LeftMouseUpAction` on a dedicated square hit meter the size of the ring (`Meter=Image`, `SolidColor=0,0,0,1`), drawn **before** the speaker icon so the icon (on top) keeps its own click.
- `dx = x − cx`, `dy = y − cy`; ignore the click if `sqrt(dx²+dy²)` is outside `Rs ± (Ws/2 + 6·Scale)` (only the ring band counts).
- `θ = atan2(dx, −dy)` (Lua 5.1 `math.atan2`; 0 at 12 o'clock, clockwise because screen y grows down); if `θ < 0` add `2π`.
- `p = floor(θ / 2π · 100 + 0.5)`; clicks just left of 12 o'clock snap to 100 (`p >= 98 → 100`), and the minimum from a click is 1 (`p < 1 → 1`), since a click at the top should never silence the output.
- `!CommandMeasure mAudio "SetVolume p"` (this unmutes, which is the expected result of picking a level).

**Scroll** (`Volume.lua`, `Scroll(dir)`):
- Not muted: `ChangeVolume ±VolumeStep`.
- Muted, scroll up: if `VolumeScrollUnmutes=1` (default), `ChangeVolume +VolumeStep` (unmutes); else do nothing.
- Muted, scroll down: do nothing. (`ChangeVolume` would unmute, which would be surprising.)

**Device name**: `ToggleNext` only. If Vishnu has devices he never wants in the cycle (e.g. a monitor's HDMI audio), the clean fix is disabling them in Windows Sound settings; an in-skin skip list would need `ToggleNext` in a loop, which briefly switches audio to each skipped device, so it is not in V1.

### Settings (User.inc keys; names to match the foundation spec)
- `VolumeStep` (exists, default 2)
- `VolumeScrollUnmutes` (1/0, default 1)
- `VolumeRingWidth` (default 5)
- `VolumeMixer` (default `ms-settings:apps-volume`)
- Optional device rename: `VolumeDeviceSubstitute` used as the `Substitute=` of `[mAudio]` (default `""`).

### Header comment must say
What it shows, that it uses the built-in Win7AudioPlugin (nothing to install), that the device name is the Windows Sound settings name, and the keys above.

## Media skin

### Plugin choice: MediaPlayer.dll

| | **MediaPlayer.dll** (i2002, v1.4) | WebNowPlaying Redux (keifufu, v2.0.7) | Built-in NowPlaying |
|---|---|---|---|
| Source | Windows media session (GSMTC) | GSMTC for desktop apps + browser extension for browsers | AIMP, foobar, iTunes, Winamp, WMP only |
| Spotify desktop | yes | yes | no |
| Browser (YouTube etc.) | yes, via GSMTC, no extension | **only with the WNP browser extension** (desktop mode excludes browsers on purpose) | no |
| Known risk | small, not actively developed; position missing for some sources | v2.0.7 release notes warn it can break on Win10 22H2/Win11 after KB5048292; fix is a v3 alpha | n/a |
| Licence | GPL-3.0 | MIT | built in |

MediaPlayer.dll wins: one DLL, any player, no extension. Both third-party plugins follow the NowPlaying interface (`PlayerType=Title/Artist/State/Progress`, bangs `PlayPause/Next/Previous`), so the skin is written once:

```
[Variables]
; MediaPlayer = MediaPlayer.dll (default). WebNowPlaying = WebNowPlaying Redux.
MediaPlugin=MediaPlayer

[mState]
Measure=Plugin
Plugin=#MediaPlugin#
PlayerType=State
; 0 stopped / nothing, 1 playing, 2 paused (same in both plugins)
[mTitle]  ... PlayerType=Title
[mArtist] ... PlayerType=Artist
[mProgress] ... PlayerType=Progress   ; 0-100
[mDuration] ... PlayerType=Duration   ; seconds, 0 when the source gives none
```

**Installing the plugin**: Rainmeter only loads plugins from `%APPDATA%\Rainmeter\Plugins` (or its program folder), not from the skin folder. Don't commit the DLL (GPL binary, and git-pull installs never place it). Add a step to `tools/install.ps1`: download the 64-bit **static** build (`MediaPlayer.dll`, no MSVC runtime needed) from the i2002/RainmeterMediaPlayer v1.4 GitHub release into `%APPDATA%\Rainmeter\Plugins` if it is missing, then tell the user Rainmeter must be restarted (a refresh doesn't load new plugins). README gets a "Media needs MediaPlayer.dll" line with the release link. The implementer should pin the exact asset name/URL after checking the release page.

### Layout and states
Same shape as Volume, mirrored content:
```
 BLINDING LIGHTS      (  ring  )
 ‹ ─────────────── ›  ( ▶ / ❚❚ )
 THE WEEKND
```
- `[Title]` Value style, `StringCase=Upper`, `ClipString=1` + fixed `W` (ellipsis, the default).
- `[Artist]` Detail style, same clipping.
- Hairline with `‹` and `›` chevrons at its two ends (Shape `Path`, 2 strokes each, round caps), each with its own click.
- Ring = `mProgress` via `Ring.lua`; when `mDuration = 0` (source gives no position), show the track only.
- Centre glyph: pause bars while playing, play triangle while paused (two Shape meters, toggled by `Hidden=` from `mState`).
- Paused (`State=2`): whole skin uses rest alphas even on hover minus a step (dimmer), ring fill grey, play glyph.
- Hover: brightens like Volume. No scroll on this skin.

### Hidden when nothing is playing
`mState` drives visibility, with a short grace so track changes don't flicker:

```
[mState]
...
IfCondition=mState = 0
IfTrueAction=[!CommandMeasure mHideTimer "Execute 1"]
IfFalseAction=[!CommandMeasure mHideTimer "Stop 1"][!Show][!CommandMeasure mFade "Execute 1"]
IfConditionMode=0

[mHideTimer]
Measure=Plugin
Plugin=ActionTimer
ActionList1=Wait 2000 | Hide
Hide=[!Hide]
```
A hidden skin keeps updating its measures, so it shows itself again when playback starts. Paused sessions stay visible (that is the paused state in the design); Spotify paused stays visible until Spotify is closed, a paused browser tab until the tab is closed. If that is too sticky, a later setting `MediaHidePausedAfter` (minutes) can hide on long pauses; not in V1.

Rainmeter loads the skin visible; `OnRefreshAction=[!Hide]` plus the IfCondition above makes it start hidden when nothing plays.

Full-screen hide (foundation spec) must not `!Show` this skin while nothing is playing: the foundation's show logic should call a skin-level `ShowIfActive` action (or set a variable the skin checks) instead of a blind `!Show`. Flagged for the foundation thread.

### Interactions

| Gesture | Where | Bang |
|---|---|---|
| Click | centre glyph (and ring) | `!CommandMeasure mState "PlayPause"` |
| Click | `‹` | `!CommandMeasure mState "Previous"` |
| Click | `›` | `!CommandMeasure mState "Next"` |

`Update=500` on the skin: enough for a smooth-looking progress ring (a 3-minute song moves 0.3% per tick) and snappy state changes. Every click ends with `[!UpdateMeasureGroup Media][!UpdateMeterGroup Media][!Redraw]`.

### Long titles
- Default `MediaTitleOverflow=Ellipsis`: `ClipString=1`.
- `MediaTitleOverflow=Scroll`: put `[Title]` in a `Container` meter of fixed width with `ClipString=0`; an ActionTimer moves its `X` left 1px every 30 ms while the text is wider than the box (`[Title:W] > box`), pauses 1.5 s at each end, and resets on track change (`OnChangeAction` on `mTitle`). Only runs on hover or while playing, to keep CPU near zero.

### Settings (User.inc keys)
- `MediaPlugin` (`MediaPlayer` / `WebNowPlaying`)
- `MediaTitleOverflow` (`Ellipsis` / `Scroll`)
- `MediaHideDelay` (ms, default 2000)

### Header comment must say
That it reads the Windows media session, needs MediaPlayer.dll (link), works with any player that shows in the Windows media flyout, how to switch to WebNowPlaying Redux, and that Windows chooses which player is shown when several play.

## Check on Vishnu's PC before calling these done

Volume
1. Rainmeter version (About), so we know `Win7AudioPlugin` vs the newer built-in `Measure=Audio`.
2. Muting shows `MUTED`; `Mute`/`Unmute` bangs work on his build.
3. Device names as shown; rename in Sound settings if wanted (e.g. `SOUND BAR - LG`).
4. Clicking the device name cycles only the outputs he wants; disable unused ones in Windows if not.
5. `ms-settings:apps-volume` opens the volume mixer on his Windows build.
6. Ring click lands on the right level at Scale 100% and 250% (the hit band must scale).

Media
7. MediaPlayer.dll loads (Rainmeter log has no plugin error) after install and a Rainmeter restart.
8. Spotify desktop: title, artist, progress, play/pause, next, previous all work.
9. Browser (YouTube in his browser): title/artist and play/pause work; note whether progress shows (expected empty for some sites).
10. Skin hides about 2 s after closing the player and reappears when playback starts; no flicker between tracks.
11. With two players open, which one Windows shows, and that switching works from the Windows media flyout.

## Notes for other threads
- `Ring.lua` should be shared with SignalRGB's brightness ring (stroke 2.5).
- Rainmeter's development branch turns several plugins into built-in measures (`Audio`, `WifiStatus`). The Wi-Fi thread may want the same note.
- `Theme.inc` today has `Accent=0,250,200`, `AlphaRest=110` and `FontDisplay=Anurati`, which differ from Design V1 (accent from Windows, 60%/80% rest levels, Segoe UI only). Both skins here assume the foundation spec updates these tokens.
