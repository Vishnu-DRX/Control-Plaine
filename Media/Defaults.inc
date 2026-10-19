; Control-Plaine | Media: setting defaults.
; The Settings window writes changes to @Resources\User.inc, which overrides these.
; Owned by the Media skin; add keys here with the Media prefix.

[Variables]
; left: ring first, text after it. right: text first, ring last.
; The chevrons keep their order on both sides.
MediaAlign=left
; hover: title, artist, hairline and chevrons only on hover (the ring and
; play/pause stay). always: they stay shown. DetailsAll in Settings can override it.
MediaDetails=hover
; Colours for this skin: auto follows the global Theme, dark = white,
; light = black.
MediaTheme=auto
; 1 shows this skin's tooltips, 0 hides them all.
MediaTooltips=1
; The skin disappears when no app is playing.
MediaHideIdle=1
; Which players it follows: any (Windows media session) or wnp (WebNowPlaying Redux).
MediaSource=any
; Long song names slide once when the song changes and again on hover (1),
; or are always cut off with an ellipsis (0).
MediaScrollTitles=1
; Plugin that reads the player, set together with MediaSource:
; MediaPlayer (MediaPlayer.dll, any player) or WebNowPlaying (WebNowPlaying Redux).
MediaPlugin=MediaPlayer

; ---- Runtime, not settings ----
; Set by the needs check (Needs.lua): 1 hides the skin because the plugin it
; reads the player with is missing.
MediaNeedBlocked=0
