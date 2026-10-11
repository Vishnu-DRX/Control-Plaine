# Spec: Volume and Media skins

Investigation output for the V1 build. Look and behaviour come from `docs/DESIGN-V1.md` and the V1 canvas. This file says **how** to build both skins in Rainmeter, which plugin Media uses, and what must be checked on Vishnu's PC.

Aligned with `specs/foundation-settings.md` (template, file ownership, tokens, styles, `SelfHidden`, Settings keys). Where this file and the foundation spec disagree, the foundation spec wins.

PC facts (from `Control-Plaine-probes.md`, 2026-10-11):
- Windows 11 25H2 (build 26200) and Rainmeter 4.5.26 (64-bit), so `Win7AudioPlugin` is the right measure.
- `%APPDATA%\Rainmeter\Plugins` does not exist yet, and neither does MediaPlayer.dll. Integration installs it.
- On 25H2, WebNowPlaying v2.0.7 is the build its own notes warn about, which is another reason it is only the fallback.

## Verdict

Every feature in the design can be done with Rainmeter driving it. No PowerShell helper is needed.

- **Volume**: bundled `Win7AudioPlugin` plus a small Lua script for the ring click and scroll rules. All features were checked against Rainmeter's source.
- **Media**: third-party plugin **MediaPlayer.dll** (i2002/RainmeterMediaPlayer v1.4, GPL-3.0). It reads the Windows media session (GSMTC), which covers Spotify, browsers and any app that shows in the Windows media flyout, with no browser extension. **WebNowPlaying Redux** is the fallback, selected by a setting.
- Both rings use the foundation's `sRingTrack` / `sRing` (Shape `Arc` with round caps, formula-driven, no Lua).
- Media's play, pause and chevron glyphs are Shape meters local to the skin. No icons for them exist in `docs/icons/`.

Limits (not blockers):
- Windows picks which media session is "current", so the skin has no source picker.
- Some sources give no position, and the progress ring stays empty for them.
- The device name is the name in Windows Sound settings. `SOUND BAR - LG` means renaming the device there.

## Files (all SKIN THREAD per foundation section 1)

```
Volume\Volume.ini
Volume\Defaults.inc
Media\Media.ini
Media\Defaults.inc
Settings\Volume.ini            (fills the foundation stub)
Settings\Media.ini             (fills the foundation stub)
@Resources\Scripts\Volume.lua
@Resources\Scripts\Media.lua   (only for the scrolling-title option)
```
Icons used: `@Resources\Icons\speaker.png` and `speaker-muted.png` (the foundation renders them from `docs/icons`).

Not touched by this thread: Theme/Defaults/Core/Styles, `tools\install.ps1` and README. The MediaPlayer.dll install step is a request to integration, see "Installing MediaPlayer.dll".

Both skins start from the foundation template (section 2) exactly. Volume sets `Update=500` instead of 1000, so volume changes made outside the skin show quickly. Media keeps 1000.

## Volume skin

### Data
```ini
[mAudio]
Measure=Plugin
Plugin=Win7AudioPlugin
Group=Volume
```
Checked in Rainmeter's source (`MeasureAudio.cpp`, the same code as the plugin):
- **Number value:** the volume 0 to 100, **-1 when muted**.
- **String value:** `PKEY_Device_DeviceDesc` of the default output device. This is the name shown (and renameable) in Windows Sound settings, not the long "Speakers (Realtek...)" form.
- **Bangs:** `ToggleNext`, `TogglePrevious`, `SetOutputIndex n`, `ToggleMute`, `Mute`, `Unmute`, `SetVolume n`, `ChangeVolume +-n`. `Mute` and `Unmute` exist but are undocumented.
- **`SetVolume` and `ChangeVolume` always unmute.**
- `ToggleNext` cycles active output devices only, and wraps.

Rainmeter's development branch also has a built-in `Measure=Audio` with the same values and bangs. Vishnu runs 4.5.26, so V1 uses `Plugin=Win7AudioPlugin`. Switching later is a one-line change.

```ini
[mMuted]
Measure=Calc
Formula=mAudio < 0 ? 1 : 0
Group=Volume
; drives text, ring colour and icon via !SetOption in IfCondition, or dynamic options
[mLevel]
Measure=Calc
Formula=Max(mAudio,0)/100
Group=Volume
```

### Layout
```
 43%              (  ring  )
 ─────────────    ( speaker)
 SOUND BAR - LG
```

- **`[Pct]`**
  - `MeterStyle=sValue`.
  - Text `[mAudio]%`, or `MUTED` while muted.
- **Hairline**
  - Image meter, height `1*#Scale#`.
  - `SolidColor=#Ink#,#AlphaTrack#`, `Group=Reveal`.
- **`[Device]`**
  - `MeterStyle=sDetail`, `ClipString=1` with a fixed `W`, which adds an ellipsis.
  - Underline on hover: `sLinkLine` under it.
- **`[Ring]`**
  - `MeterStyle=sRingTrack | sRing` with value `mLevel`, on the right.
  - Muted: the arc stroke uses `#Ink#,#AlphaOff#` instead of `#Accent#`. Either the foundation exposes the ring colour as a variable (e.g. `RingColor`), or the skin overrides `Shape2`'s stroke.
- **`[Speaker]`**
  - `MeterStyle=sIconFade`, centred in the ring.
  - `ImageName` switches between `speaker` and `speaker-muted` by `mMuted`.
- **Brightness:** rest and hover come from the styles (values `AlphaValue`, details and icon `AlphaDetail`, to `AlphaHover` by `#Reveal#`).

### Interactions

| Gesture | Where | Action |
|---|---|---|
| Scroll up/down | anywhere (`[Rainmeter]` section) | `[!CommandMeasure mVolume "Scroll(1)"]` / `"Scroll(-1)"` |
| Click | ring band | `[!CommandMeasure mVolume "RingClick($MouseX$,$MouseY$)"]` |
| Click | % text | `[!CommandMeasure mAudio "ToggleMute"]` |
| Click | speaker icon | `["#VolumeMixer#"]` (default `ms-settings:apps-volume`) |
| Click | device name | `[!CommandMeasure mAudio "ToggleNext"]` |

Every action ends with `[!UpdateMeasureGroup Volume][!UpdateMeterGroup Volume][!Redraw]`, so the change shows at once.

**Ring click** (`Volume.lua`)
1. `$MouseX$` and `$MouseY$` are relative to the meter that owns the action. Put `LeftMouseUpAction` on a square `sHit` meter the size of the ring. Draw it **before** `[Speaker]`, so the icon on top keeps its own click.
2. Compute `dx = x - c` and `dy = y - c`, with `c` the ring centre from the foundation formula. Ignore the click when `sqrt(dx^2+dy^2)` falls outside `RingRadius*Scale +- (RingStroke/2 + 6)*Scale`, so only the ring band counts.
3. Compute `t = math.atan2(-dy, -dx)`. That gives 0 at 9 o'clock, clockwise, because screen y grows downward. If `t < 0`, add `2*pi`.
4. Compute `p = floor(t / (2*pi) * 100 + 0.5)`.
   - `p >= 98` becomes 100 (a click just left of the top).
   - `p < 1` becomes 1 (a click at the top never silences the output).
5. Send `!CommandMeasure mAudio "SetVolume p"`. This also unmutes, which is expected when picking a level.

**Scroll** (`Scroll(dir)`)

| State | Scroll up | Scroll down |
|---|---|---|
| Not muted | `ChangeVolume +VolumeStep` | `ChangeVolume -VolumeStep` |
| Muted | `ChangeVolume +VolumeStep` (unmutes) if `VolumeScrollUnmutes=1`, else nothing | nothing (`ChangeVolume` would unmute, which is surprising) |

**Device name**
- Click runs `ToggleNext` only.
- Unwanted outputs, such as monitor HDMI audio, are best disabled in Windows Sound settings.
- An in-skin skip list would have to call `ToggleNext` in a loop, briefly switching audio through every skipped device, so V1 leaves it out.

### Settings (`Volume\Defaults.inc`, page `Settings\Volume.ini`)

| Key | Default | Control |
|---|---|---|
| `VolumeStep` | 2 | value box, 1 to 10 |
| `VolumeScrollUnmutes` | 1 | toggle |
| `VolumeRingStroke` | 5 | value box, 2 to 8. The skin passes it as the ring stroke instead of `#RingStroke#`. |
| `VolumeMixer` | `ms-settings:apps-volume` | path box (e.g. `sndvol.exe`) |

Targets for every row: `Volume`. The v1 `User.inc` already has `VolumeStep`, so no migration is needed.

## Media skin

### Plugin choice: MediaPlayer.dll

| | **MediaPlayer.dll** (i2002, v1.4) | WebNowPlaying Redux (keifufu, v2.0.7) | Built-in NowPlaying |
|---|---|---|---|
| Source | Windows media session (GSMTC) | GSMTC for desktop apps, plus a browser extension for browsers | AIMP, foobar, iTunes, Winamp and WMP only |
| Spotify desktop | yes | yes | no |
| Browser (YouTube etc.) | yes, through GSMTC, no extension | **only with the WNP browser extension** (desktop mode leaves browsers out on purpose) | no |
| Known risk | small and not actively developed; some sources give no position | v2.0.7 release notes warn it can break on Win10 22H2/Win11 after KB5048292, and the fix is a v3 alpha | n/a |
| Licence | GPL-3.0 | MIT | built in |

MediaPlayer.dll wins: it is one DLL, it works with any player, and it needs no extension. Both plugins follow the NowPlaying interface: the PlayerType values `Title`, `Artist`, `State`, `Progress` and `Duration`, and the bangs `PlayPause`, `Next` and `Previous`. State is 0 for stopped or nothing, 1 for playing and 2 for paused. One skin therefore works with either plugin:

Plugin selection: `Media\Defaults.inc` holds `MediaSource=any` (the foundation key) and `MediaPlugin=MediaPlayer`. Every measure uses `Plugin=#MediaPlugin#`, which Rainmeter resolves at load. The Settings choice row writes both keys together: `any` + `MediaPlayer`, or `wnp` + `WebNowPlaying`. Rainmeter variables can't branch, so the DLL name is stored rather than derived.

Measures (each `Measure=Plugin`, `Plugin=#MediaPlugin#`, `Group=Media`):

```
mState     PlayerType=State      0 none/stopped, 1 playing, 2 paused
mTitle     PlayerType=Title
mArtist    PlayerType=Artist
mProgress  PlayerType=Progress   0-100 (ring value = mProgress/100)
mDuration  PlayerType=Duration   seconds, 0 when the source gives none
```

### Installing MediaPlayer.dll
- Foundation found no `%APPDATA%\Rainmeter\Plugins` folder on Vishnu's PC. Rainmeter 4.5 loads `%APPDATA%\Rainmeter\Plugins` and `Skins\@Vault\Plugins`. Don't commit the DLL: it is a GPL binary, and a git pull could not place it anyway.
- **Request to integration (install.ps1 and README):**
  - If missing, download the 64-bit **static** build (no MSVC runtime needed) from the i2002/RainmeterMediaPlayer v1.4 GitHub release into `%APPDATA%\Rainmeter\Plugins\MediaPlayer.dll`, creating the folder if needed.
  - Then tell the user to restart Rainmeter, because a refresh does not load new plugins.
  - Pin the exact asset URL after checking the release page.
- The skin's header comment names the plugin and the release link. If the plugin is missing, Rainmeter logs an error, `mState` reads 0, and the skin just stays hidden, so it fails quietly.

### Layout and states
Same shape as Volume, mirrored content:
```
 BLINDING LIGHTS      (  ring  )
 < ─────────────── >  ( > / || )
 THE WEEKND
```

- **`[Title]`**
  - `MeterStyle=sValue`, using `SizeValueS` (18px) to fit more text.
  - `ClipString=1` with a fixed `W`, giving an ellipsis.
- **`[Artist]`:** `MeterStyle=sDetail`, clipped the same way.
- **Hairline and chevrons**
  - The hairline is the same Image meter as Volume.
  - `<` and `>` sit at its two ends. Each is a Shape meter with two strokes, `StrokeStartCap Round`, colour `#Ink#,` at the style alpha, and its own `sHit` area of at least 16x16 at scale 1 for its click.
- **`[Ring]`**
  - `sRingTrack | sRing`, value `mProgress/100`.
  - When `mDuration = 0` (no position from the source), only the track is shown.
- **Centre glyph**
  - Pause bars while playing, play triangle while paused.
  - Two Shape meters, each with `Hidden=` driven by `mState`.
- **Paused (`State=2`)**
  - Values use `AlphaDetail` instead of `AlphaValue`, so the skin is one step dimmer.
  - The ring arc uses `#Ink#,#AlphaOff#` instead of the accent.
  - The play glyph shows.
- **Hover:** brightens like Volume. Media has no scroll action.

### Hidden when nothing is playing
This follows foundation rule 2: never `!Show` or `!Hide`, use `SelfHidden`. A grace timer stops track changes from flickering.

```ini
[mState]
...
IfCondition=(mState = 0) && (#MediaHideIdle# = 1)
IfTrueAction=[!CommandMeasure mIdle "Execute 1"]
IfFalseAction=[!CommandMeasure mIdle "Stop 1"][!SetVariable SelfHidden 0][!UpdateMeasure mVisible]
DynamicVariables=1

[mIdle]
Measure=Plugin
Plugin=ActionTimer
ActionList1=Wait 2000 | GoIdle
GoIdle=[!SetVariable SelfHidden 1][!UpdateMeasure mVisible]
```
- Core's `mVisible` combines `SelfHidden` with full-screen hiding. A hidden skin keeps updating, so it returns when playback starts.
- Put `SelfHidden=1` in the skin's `[Variables]` after the includes, so a refresh with nothing playing starts hidden rather than flashing.
- Paused sessions stay visible, because that is the paused state in the design.
  - Spotify stays visible paused until it is closed.
  - A paused browser tab stays visible until the tab is closed.
  - Hiding after a long pause is a possible later setting, not in V1.
- With `MediaHideIdle=0`, the idle skin shows its track as `NOTHING PLAYING` (`sDetail`) and an empty ring.

### Interactions

| Gesture | Where | Action |
|---|---|---|
| Click | centre glyph or ring | `[!CommandMeasure mState "PlayPause"]` |
| Click | `<` | `[!CommandMeasure mState "Previous"]` |
| Click | `>` | `[!CommandMeasure mState "Next"]` |

Every click ends with `[!UpdateMeasureGroup Media][!UpdateMeterGroup Media][!Redraw]`.

### Long titles (`MediaScrollTitles`)
- `0` (default): ellipsis through `ClipString=1`.
- `1`: `[Title]` and `[Artist]` each sit in a `Container` meter with `ClipString=0`. `Media.lua` with an ActionTimer moves the text `X` left 1px every 30 ms while it is wider than the box, pauses 1.5 s at each end, and resets on track change (`OnChangeAction` on `mTitle`). It only runs while playing, to keep CPU near zero.

### Settings (`Media\Defaults.inc`, page `Settings\Media.ini`)

| Key | Default | Control |
|---|---|---|
| `MediaHideIdle` | 1 | toggle |
| `MediaSource` | `any` | choice: ANY PLAYER (`any`) / WEBNOWPLAYING (`wnp`). The row also writes `MediaPlugin` (`MediaPlayer` / `WebNowPlaying`, default `MediaPlayer`). |
| `MediaScrollTitles` | 0 | toggle |

Targets: `Media`. Changing `MediaSource` takes effect on the refresh. The WebNowPlaying DLL must already be installed; the row's description says so.

## Header comments
- **Volume** says:
  - It uses the bundled Win7AudioPlugin, so nothing needs installing.
  - The device name is the name in Windows Sound settings.
  - It lists the keys above.
- **Media** says:
  - It reads the Windows media session and needs MediaPlayer.dll (with link).
  - It works with any player that shows in the Windows media flyout.
  - Windows decides which player is shown when several play.
  - How to switch to WebNowPlaying Redux.

## Check on Vishnu's PC before calling these done

Volume
1. Muting shows `MUTED` with a grey ring and the crossed speaker. `Mute` and `Unmute` work on 4.5.26.
2. Device names appear as expected. Rename them in Sound settings if wanted (e.g. `SOUND BAR - LG`).
3. Clicking the device name cycles only the outputs he wants. If not, disable the unused ones in Windows.
4. `ms-settings:apps-volume` opens the volume mixer on his Windows build.
5. A ring click lands on the right level at Scale 100% and 250%.

Media
6. MediaPlayer.dll loads after install and a Rainmeter restart, with no plugin error in the log.
7. Spotify desktop: title, artist, progress, play/pause, next and previous all work.
8. Browser (YouTube in his browser): title, artist and play/pause work. Note whether progress shows; some sites may not give it.
9. The skin hides about 2 s after the player closes, reappears when playback starts, and doesn't flicker between tracks.
10. With two players open, check which one Windows shows, and that switching works from the Windows media flyout.

## Notes for other threads
- **Foundation:** the ring arc colour should be overridable for muted or paused (e.g. a `RingColor` variable used in `sRing`, defaulting to `#Accent#`), as should the stroke (Volume's `VolumeRingStroke`). If `sRing` hardcodes `#Accent#,255` and `#RingStroke#`, this thread overrides `Shape2` locally.
- **Integration:** the MediaPlayer.dll install step above.
- **Wi-Fi thread:** Rainmeter's development branch turns some plugins into built-in measures (`Audio`, `WifiStatus`). This changes nothing for 4.5.26.
